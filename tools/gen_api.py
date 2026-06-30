#!/usr/bin/env python3
"""Gera a arte do Mithos TD via API PAGA (fal.ai) — qualidade alta e consistente.

Reaproveita as descricoes de cada personagem do assets/ARTE.md (mesmo formato do
gen_art.py local) e aplica UM estilo fixo (cartoon pintado HD, estilo Kingdom Rush)
para o roster ficar coeso. Salva em assets/heroes|enemies|items/<id>.png.

Pre-requisitos do usuario (uma vez):
  1. Conta em https://fal.ai  ->  adicione alguns creditos (centavos por imagem).
  2. Pegue a API key (Dashboard -> Keys) e exporte:
        export FAL_KEY="xxxxxxxx:yyyyyyyy"     (Git Bash / Linux / Mac)
        setx FAL_KEY "xxxxxxxx:yyyyyyyy"        (Windows, reabra o terminal)
  3. pip install requests pillow            (rembg e opcional, p/ fundo transparente)

Uso:
  python tools/gen_api.py heroes zeus artemis medusa     # alguns herois
  python tools/gen_api.py heroes all                     # todos do ARTE.md
  python tools/gen_api.py enemies talos ciclope
  python tools/gen_api.py items mjolnir

Variaveis de ambiente uteis:
  FAL_KEY    (obrigatoria)  chave da fal.ai
  FAL_MODEL  modelo a usar. Padrao: fal-ai/flux/dev. Alternativas:
             fal-ai/bytedance/seedream/v3/text-to-image  (Seedream)
             fal-ai/recraft-v3                            (otimo p/ estilo consistente)
             fal-ai/flux/schnell                          (mais barato/rapido)
  SEED       fixa a seed (mesma "familia" visual). Padrao: aleatoria por imagem.
  NOBG=0     nao tentar remover o fundo (mantem o fundo cinza claro).
"""
import io
import os
import re
import sys
import time
import random

import requests
try:
    from PIL import Image
except ImportError:
    print("Falta Pillow: pip install pillow")
    sys.exit(1)

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _load_dotenv():
    """Le PROJ/.env (KEY=valor por linha) sem dependencia externa.
    So define o que ainda nao estiver no ambiente — assim `export FAL_KEY=...`
    continua tendo prioridade sobre o arquivo."""
    path = os.path.join(PROJ, ".env")
    if not os.path.exists(path):
        return
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            k = k.strip()
            v = v.strip().strip('"').strip("'")
            if k and k not in os.environ:
                os.environ[k] = v


_load_dotenv()

ARTE = os.path.join(PROJ, "assets", "ARTE.md")
DIRS = {
    "heroes": os.path.join(PROJ, "assets", "heroes"),
    "enemies": os.path.join(PROJ, "assets", "enemies"),
    "items": os.path.join(PROJ, "assets", "items"),
    "maps": os.path.join(PROJ, "assets", "map"),
    "scenery": os.path.join(PROJ, "assets", "map"),  # props do mapa (portal/castelo), fundo transparente
    "splash": os.path.join(PROJ, "assets", "map"),   # fundo de tela cheia (ex.: menu_bg), 1280x720
    "logo": os.path.join(PROJ, "assets", "ui"),      # logo do jogo (transparente, wide)
}

# Fundo de tela cheia em CARTOON (mesmo traço dos heróis/mapas — Kingdom Rush), p/ o
# fundo do menu combinar com os personagens (nada de realista/cinematográfico).
SPLASH_STYLE = ("flat 2D cartoon game art, Kingdom Rush mobile game art style, hand-painted, bold "
                "clean black outlines, soft cel shading, vibrant saturated colors, simple clean "
                "shapes, stylized, ancient Greek mythology theme, no characters, no people, no "
                "text, no words, no UI, no letters")
SPLASH_PROMPTS = {
    "menu_bg": ("a stylized cartoon view of Mount Olympus: a grand ancient Greek marble temple with "
                "columns on a green mountain peak above fluffy golden clouds at sunset, sun rays, "
                "distant blue sea, cheerful epic fantasy vista, clean and colorful"),
}

# Logo do jogo (imagem única transparente, larga). Texto estilizado grego.
LOGO_STYLE = ("an ornate fantasy mobile game logo emblem, bold readable title, hand-painted cartoon "
              "style, gold and marble, glowing, centered, plain flat light gray background, no scene, "
              "no background scenery, high quality, crisp")
LOGO_PROMPTS = {
    "logo_mithos": ("the title text \"MITHOS TD\" in big bold ancient Greek letters carved from white "
                    "marble with shiny gold trim and outline, a golden lightning bolt and laurel "
                    "leaves as decoration, epic game logo"),
}

# Props do mapa (portal de entrada, castelo/base). Objeto unico, fundo transparente,
# 192px (mesmo tamanho dos antigos, drop-in). Estilo grego premium, coeso com tudo.
SCENERY_STYLE = ("Kingdom Rush style 2D cartoon tower-defense map structure, single object "
                 "centered, hand-painted, vibrant saturated colors, bold clean outlines, soft "
                 "cel shading, 3/4 top-down view, ancient Greek mythology theme, plain flat light "
                 "gray background, crisp, sharp, high quality, no characters, no people, no text")
SCENERY_PROMPTS = {
    "portal": ("an ominous ancient Greek monster gateway portal, a tall archway of cracked dark "
               "marble and weathered bronze, glowing swirling magenta and red magical energy "
               "vortex in the center, faint glowing runes, menacing, the gate where enemies emerge"),
    "castle": ("a small heroic Greek fortress keep, a round defensive tower of white marble and "
               "golden bronze with columns, battlements and a bright red banner flag on top, "
               "stately and bright, a stronghold to defend"),
}

# Mapas de fase (16:9, top-down) com a ESTRADA integrada na arte (estilo Kingdom
# Rush): a estrada é clara, bonita e com curvas — depois traçamos os waypoints em
# cima dela. Decoracoes ficam SO ao lado da estrada.
MAP_STYLE = ("top-down flat bird's eye aerial view, 2D cartoon tower-defense game terrain "
             "background, Kingdom Rush mobile game art style, hand-painted, vibrant saturated "
             "colors, clean bold shapes, high detail. IMPORTANT: absolutely NO road, NO path, "
             "NO trail, NO dirt track anywhere; the whole CENTER is wide open empty flat ground; "
             "all trees rocks bushes and decorations are clustered ONLY along the four outer "
             "edges and corners as a frame, never in the central area; no characters, no people, "
             "no units, no text, no words, no UI, no labels, no grid, no lines")
MAP_PROMPTS = {
    "elis": ("a lush bright green flat open grassy meadow, completely open empty grass field in "
             "the center, round trees bushes gray rocks and small orange flowers only clustered "
             "along the outer edges framing the map"),
    "nemeia": ("a flat green forest-floor grass clearing, open empty grass in the center, tall "
               "round pine trees and mossy gray boulders only framing the outer edges"),
    "pantano": ("a flat muddy green swamp clearing, open empty muddy ground in the center, "
                "patches of dark water, green reeds, lily pads and twisted dead trees only along "
                "the outer edges"),
    "desfiladeiro": ("a flat dark grey volcanic basalt rock clearing, open empty stone ground in "
                     "the center, jagged black rocks with glowing orange lava cracks only framing "
                     "the outer edges"),
    "olimpo": ("a flat snowy white mountain plateau, open empty snow-and-stone ground in the "
               "center, white greek marble columns ruins and snow-covered gray rocks only along "
               "the outer edges"),
}

FAL_KEY = os.environ.get("FAL_KEY", "")
MODEL = os.environ.get("FAL_MODEL", "fal-ai/recraft-v3")
# Estilo do Recraft (so usado quando MODEL e recraft). digital_illustration = cartoon
# nitido; realistic_image = mais realista. Substilos: digital_illustration/hand_drawn etc.
RECRAFT_STYLE = os.environ.get("RECRAFT_STYLE", "digital_illustration")
OUT_SIZE = 512  # salva quadrado; o jogo redimensiona

# Estilo FIXO (coeso entre todos). Cartoon pintado HD, igual aos mapas / Kingdom Rush.
STYLE = {
    "heroes": ("Kingdom Rush style 2D cartoon game hero, TALL ADULT character with long legs "
               "and normal sized head (not chibi, mature adult, athletic build), hand-painted, "
               "vibrant saturated colors, bold clean outlines, soft cel shading, full body "
               "single character, centered, front view, dynamic heroic pose, fully clothed, "
               "modest clothing, plain flat light gray background, mobile tower-defense character "
               "art, crisp, sharp, high quality"),
    "enemies": ("Kingdom Rush style 2D cartoon tower-defense enemy monster, cute but menacing, "
                "hand-painted, vibrant colors, bold clean outlines, soft cel shading, full body "
                "single creature, centered, front view, plain flat light gray background, "
                "mobile game enemy art, crisp, high quality"),
    "items": ("2D cartoon game item icon, hand-painted, vibrant colors, bold clean outlines, "
              "soft shading, single object centered, plain flat light gray background, crisp, "
              "high quality, RPG equipment icon"),
}
NEGATIVE = ("chibi, super deformed, big head, oversized head, baby face, child proportions, "
            "photorealistic, realistic, 3d render, photograph, blurry, low quality, lowres, "
            "jpeg artifacts, extra limbs, extra fingers, deformed, mutated, bad anatomy, text, "
            "words, letters, watermark, signature, logo, multiple characters, duplicate, "
            "cropped, out of frame, dark, gritty, horror gore")


def parse_arte():
    """Le {id: descricao} das linhas `<id>.png` — <descricao> do ARTE.md."""
    jobs = {}
    rx = re.compile(r'`([a-z0-9_]+)\.png`\s*[—\-]+\s*(.+)')
    with open(ARTE, encoding="utf-8") as f:
        for line in f:
            m = rx.search(line)
            if m:
                jobs[m.group(1)] = m.group(2).strip()
    return jobs


def fal_generate(prompt, landscape=False):
    """Chama a fal.ai (REST sincrono) e devolve os bytes do PNG gerado."""
    url = "https://fal.run/" + MODEL
    headers = {"Authorization": "Key " + FAL_KEY, "Content-Type": "application/json"}
    seed_env = os.environ.get("SEED")
    body = {
        "prompt": prompt,
        "image_size": "landscape_16_9" if landscape else "square_hd",
        "num_images": 1,
        "enable_safety_checker": True,
        "negative_prompt": NEGATIVE,         # ignorado por modelos que nao usam
        "num_inference_steps": 30,
        "guidance_scale": float(os.environ.get("GUIDANCE", "3.5")),
    }
    if seed_env:
        body["seed"] = int(seed_env)
    else:
        body["seed"] = random.randint(1, 2_000_000_000)
    if "recraft" in MODEL:
        body["style"] = RECRAFT_STYLE  # cartoon nitido / consistencia de estilo
    r = requests.post(url, json=body, headers=headers, timeout=180)
    if r.status_code != 200:
        raise RuntimeError("fal.ai %d: %s" % (r.status_code, r.text[:300]))
    data = r.json()
    img = (data.get("images") or [data.get("image")])[0]
    img_url = img["url"] if isinstance(img, dict) else img
    return requests.get(img_url, timeout=120).content


def remove_bg(im):
    """Tenta deixar o fundo transparente (rembg). Sem rembg, devolve como esta."""
    if os.environ.get("NOBG") == "0":
        return im
    try:
        from rembg import remove
        return remove(im)
    except Exception:
        return im  # sem rembg: mantem o fundo cinza claro (o jogo ainda funciona)


def save(png_bytes, category, cid):
    im = Image.open(io.BytesIO(png_bytes)).convert("RGBA")
    os.makedirs(DIRS[category], exist_ok=True)
    if category == "maps":
        # Mapa = fundo cheio (sem recorte), 1280x720, arquivo map_<id>.png.
        im = im.resize((1280, 720), Image.LANCZOS)
        out = os.path.join(DIRS[category], "map_" + cid + ".png")
    elif category == "scenery":
        # Prop do mapa: recorta o fundo e salva 192px (drop-in dos antigos).
        im = remove_bg(im)
        im = im.resize((192, 192), Image.LANCZOS)
        out = os.path.join(DIRS[category], cid + ".png")
    elif category == "splash":
        # Fundo de tela cheia (sem recorte), 1280x720, arquivo <id>.png.
        im = im.resize((1280, 720), Image.LANCZOS)
        out = os.path.join(DIRS[category], cid + ".png")
    elif category == "logo":
        # Logo: recorta o fundo (transparente) e salva 768px, arquivo <id>.png.
        im = remove_bg(im)
        im = im.resize((768, 768), Image.LANCZOS)
        out = os.path.join(DIRS[category], cid + ".png")
    else:
        im = remove_bg(im)
        im = im.resize((OUT_SIZE, OUT_SIZE), Image.LANCZOS)
        out = os.path.join(DIRS[category], cid + ".png")
    im.save(out)
    return out


def main():
    if not FAL_KEY:
        print("ERRO: defina FAL_KEY (sua chave da fal.ai). Veja o cabecalho do arquivo.")
        return
    args = sys.argv[1:]
    if len(args) < 2 or args[0] not in DIRS:
        print("uso: python tools/gen_api.py <heroes|enemies|items> <id ...|all>")
        return
    category = args[0]
    is_maps = category == "maps"
    is_scenery = category == "scenery"
    is_splash = category == "splash"
    is_logo = category == "logo"
    if is_maps:
        jobs = MAP_PROMPTS
    elif is_scenery:
        jobs = SCENERY_PROMPTS
    elif is_splash:
        jobs = SPLASH_PROMPTS
    elif is_logo:
        jobs = LOGO_PROMPTS
    else:
        jobs = parse_arte()
    ids = list(jobs.keys()) if args[1] == "all" else args[1:]
    if is_maps:
        style = ""
    elif is_scenery:
        style = SCENERY_STYLE
    elif is_splash:
        style = SPLASH_STYLE
    elif is_logo:
        style = LOGO_STYLE
    else:
        style = STYLE[category]
    print("Modelo:", MODEL, "| categoria:", category, "| itens:", len(ids))
    for cid in ids:
        desc = jobs.get(cid)
        if not desc:
            print("  (sem descricao):", cid)
            continue
        prompt = (desc + ", " + MAP_STYLE) if is_maps else (style + ", " + desc)
        try:
            t0 = time.time()
            png = fal_generate(prompt, landscape=(is_maps or is_splash))
            out = save(png, category, cid)
            print("  OK  %-16s %5.1fs  -> %s" % (cid, time.time() - t0, out))
        except Exception as e:
            print("  FALHA", cid, "->", e)
    print("Pronto. Abra o Godot uma vez (importa as imagens) e rode.")


if __name__ == "__main__":
    main()
