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
import base64
import zipfile

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
    "rig": os.path.join(PROJ, "assets", "rig"),      # boneco modular: base + pecas encaixaveis
    "autorig": os.path.join(PROJ, "assets", "autorig"),  # entrada p/ auto-rig (God Mode AI -> Spine)
    "prop3d": os.path.join(PROJ, "assets", "prop3d"),    # entrada p/ image-to-3D de PROPS/equipamento (Meshy)
}

# Personagens MODULARES (paper-doll): um corpo-BASE em pose neutra (sem capacete/arma)
# + PECAS encaixaveis (elmo, peito, arma...). Tudo transparente, mesma escala, pose
# frontal previsivel p/ encaixar por offset. Estilo cartoon coeso com o resto.
RIG_STYLE = ("Kingdom Rush 2D cartoon game art, TALL ADULT mature proportions (long legs, normal "
             "sized head, NOT chibi, not a child), hand-painted, bold clean black outlines, soft cel "
             "shading, vibrant saturated colors, crisp, single object centered, strict front view, "
             "plain flat light gray background, no text, no words, no extra objects")
RIG_PROMPTS = {
    "base_hoplite": ("a clothing mannequin reference of a TALL ADULT athletic Greek man, mature "
                     "adult long legs normal head (NOT chibi), standing perfectly straight upright and "
                     "still in a calm symmetric T-pose facing the camera, both arms held out to the "
                     "sides, EMPTY OPEN relaxed hands with nothing in them, wearing only a plain simple "
                     "short white tunic and brown sandals, completely BARE HEAD short brown hair, no "
                     "helmet no hat no crown, no weapon no sword no shield no spear, calm blank "
                     "expression, full body head to toe centered, plain front view"),
    "piece_helmet_bronze": ("a single bronze ancient Greek Corinthian helmet with a tall red "
                            "horsehair crest, STRAIGHT FRONT VIEW facing the camera symmetric, ONLY "
                            "the helmet floating with empty dark face opening, NO head NO face NO neck "
                            "NO person, just the helmet object centered"),
    "piece_chest_bronze": ("a single bronze ancient Greek muscle cuirass breastplate, STRAIGHT FRONT "
                           "VIEW facing the camera symmetric, ONLY the chest armor piece floating, NO "
                           "body NO arms NO head NO person, just the breastplate object centered"),
    "piece_sword_xiphos": ("a single short bronze ancient Greek sword (xiphos) with leather-wrapped "
                           "handle, blade pointing straight up, ONLY the sword object, NO hand, NO "
                           "arm, NO person, just the sword"),
    # Bases T-pose por herói (mantêm a identidade; cabeça nua e mãos vazias p/ encaixar peças).
    "base_hercules": ("a clothing mannequin reference of a TALL very MUSCULAR adult Greek man with "
                      "short brown hair and a short brown beard, standing perfectly straight "
                      "upright still in a calm symmetric T-pose facing camera, arms out to the sides, "
                      "EMPTY OPEN hands holding nothing, wearing only a plain simple short brown tunic "
                      "and sandals, BARE HEAD no helmet no lion hood, no weapon no club, full body "
                      "head to toe centered, front view"),
    "base_artemis": ("a clothing mannequin reference of Artemis, a TALL athletic adult Greek huntress "
                     "woman with long blonde hair in a ponytail, standing perfectly straight upright "
                     "still in a calm symmetric T-pose facing camera, arms out to the sides, EMPTY "
                     "OPEN hands holding nothing, wearing only a plain simple short white tunic and "
                     "sandals, BARE HEAD no helmet, no weapon no bow, full body head to toe centered, "
                     "front view"),
    "base_zeus": ("a clothing mannequin reference of a TALL imposing OLD adult Greek man with "
                  "long white hair and a long white beard, standing perfectly straight upright still "
                  "in a calm symmetric T-pose facing camera, arms out to the sides, EMPTY OPEN hands "
                  "holding nothing, wearing a plain simple white toga and sandals, BARE HEAD no helmet "
                  "no crown, no weapon no staff no stick, full body head to toe centered, front view"),
}

# ENTRADA PARA MODELAGEM 3D (Meshy image-to-3D). Bloco PADRÃO de POSE/composição —
# o VISUAL (traço/cor/estilo) vem do RECRAFT_STYLE_ID (estilo criado a partir da
# Medusa), então aqui só definimos a pose mais fácil p/ o 3D entender: personagem de
# FRENTE, pose A neutra e simétrica, corpo inteiro, mãos vazias, fundo limpo.
# Os prompts de cada herói dizem SÓ as características físicas (sem nomes/mitologia).
AUTORIG_STYLE = ("a single character in a clean 2D CARTOON mobile-game ILLUSTRATION style (modern "
                 "hand-drawn RPG hero, flat 2D art NOT a 3d render): smooth soft cel shading, bold "
                 "clean dark outlines, vibrant colors, semi-stylized proportions (not photorealistic, "
                 "not chibi), ONE consistent uniform art style. The character stands facing FORWARD "
                 "toward the viewer, symmetric and still, in a relaxed T-pose with both arms out to "
                 "the sides and both hands OPEN and EMPTY holding nothing, unarmed, no sword no shield "
                 "no spear no bow no staff no wand no objects at all, full body from head to feet "
                 "visible and centered, plain solid white background, no text, no shadow")
# Cada herói = SÓ características físicas (sem nome/mitologia). Combina com AUTORIG_STYLE
# (pose de frente p/ 3D) e com o RECRAFT_STYLE_ID (visual coeso igual à Medusa).
AUTORIG_PROMPTS = {
    "hercules": ("a tall very muscular adult man with short brown hair and a short brown beard, "
                 "wearing a light beige sleeveless tunic with a brown leather belt, brown leather "
                 "wrist wraps and brown strap sandals, bare head"),
    "artemis": ("a slim athletic adult woman with long blonde hair tied back in a ponytail, wearing a "
                "short white and gold sleeveless tunic and brown strap sandals, bare head"),
    "hermes": ("a lean athletic adult man with short brown hair, small white feathered wings on his "
               "upper back and small wings on his ankles, wearing a short blue and white tunic and "
               "sandals, bare head"),
    "ares": ("a muscular adult man with short black hair, wearing red and bronze layered plate armor "
             "over a dark tunic and brown strap sandals, bare head"),
    "atena": ("an adult woman with long brown hair, wearing an ornate blue and gold armored chest "
              "plate over a SHORT white tunic that ends above the knees so both LEGS are fully "
              "visible and separated, and strap sandals, bare head"),
    "apolo": ("a handsome young adult man with short curly brown hair and a golden laurel wreath on "
              "his head, wearing a white and gold toga draped over one shoulder and sandals"),
    "medusa": ("a lean adult woman with smooth green scaled skin, glowing yellow eyes, and many small "
               "green snakes instead of hair, wearing a teal wrap top and a short teal skirt, barefoot"),
    "zeus": ("a stocky old adult man with long white hair and a long full white beard, wearing a plain "
             "white toga draped over one shoulder and sandals, bare head"),
}

# ENTRADA PARA IMAGE-TO-3D DE PROPS/EQUIPAMENTO (Meshy). Objeto UNICO isolado, em
# vista 3/4 (mostra profundidade -> Meshy infere melhor a malha 3D), fundo limpo,
# transparente, alta-res. Serve p/ elmo, peitoral, escudo, arma etc. por tier.
PROP3D_STYLE = ("a single 3D game prop object, Kingdom Rush cartoon style, hand-painted, bold clean "
                "outlines, soft cel shading, vibrant colors, 3/4 perspective view showing volume and "
                "depth, single object centered, plain solid white background, no character, no person, "
                "no hands, no text")
PROP3D_PROMPTS = {
    "helmet_bronze": ("an ancient Greek bronze Corinthian helmet with a tall red horsehair crest "
                      "plume on top, hollow and empty with no head inside, seen from a 3/4 front "
                      "angle, a single object floating centered"),
    # --- Conjunto LENDÁRIO/MÍTICO (dourado, divino, com brilho) — 1 de cada slot ---
    "helmet_legend": ("a legendary divine golden ancient Greek Corinthian helmet with a radiant "
                      "white and red crest and glowing blue gems, ornate laurel engravings, hollow "
                      "empty with no head inside, seen from a 3/4 front angle, single object floating"),
    "armor_legend": ("a legendary divine golden ancient Greek muscle cuirass chest breastplate with "
                     "a glowing sunburst emblem and blue runes, ornate, seen from a 3/4 front angle, "
                     "single object floating, no body no person"),
    "legs_legend": ("a pair of legendary divine golden ancient Greek leg greaves armor with laurel "
                    "engravings and blue glow, seen from a 3/4 front angle, single object floating, "
                    "no legs no person"),
    "boots_legend": ("a pair of legendary divine golden ancient Greek winged sandals boots with "
                     "small white feathered wings and blue glow, seen from a 3/4 front angle, single "
                     "object floating, no feet no person"),
    "sword_legend": ("a legendary divine golden ancient Greek short sword xiphos with a glowing blue "
                     "blade and an ornate jeweled handle, blade pointing up, seen from a 3/4 angle, "
                     "single object floating, no hand no person"),
    "shield_legend": ("a legendary divine round golden ancient Greek hoplon shield with an ornate "
                      "gorgon medusa face emblem and a glowing blue rim, seen from a 3/4 front angle, "
                      "single object floating, no arm no person"),
    "amulet_legend": ("a legendary divine golden ancient Greek amulet necklace pendant with a large "
                      "glowing blue gem and laurel design, seen from a 3/4 front angle, single object "
                      "floating, no neck no person"),
    "ring_legend": ("a legendary ornate golden ancient Greek ring with a glowing blue gem, close up, "
                    "seen from a 3/4 angle, single object floating, no finger no hand no person"),
    "bow_legend": ("a legendary divine golden ancient Greek longbow with ornate limbs, laurel motifs "
                   "and a glowing blue string, seen from a 3/4 angle, single object floating, no hand "
                   "no person"),
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
    "pedestal": ("an ornate round ancient Greek marble pedestal podium platform, white marble with "
                 "golden trim and a laurel motif, viewed slightly from above, empty top, a base for "
                 "a hero to stand on, no character"),
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
# ESTILO POR REFERENCIA: id de um estilo custom do Recraft (criado com `gen_api.py style
# <ref>` a partir de uma imagem de referencia). Quando definido, TODA geracao recraft usa
# esse estilo -> visual COESO e igual a referencia (ex.: a Medusa). Vence o RECRAFT_STYLE.
RECRAFT_STYLE_ID = os.environ.get("RECRAFT_STYLE_ID", "")
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


def fal_generate(prompt, landscape=False, size=None):
    """Chama a fal.ai (REST sincrono) e devolve os bytes do PNG gerado.
    `size` sobrescreve o image_size (ex.: 'portrait_4_3' p/ corpo inteiro do auto-rig)."""
    is_recraft = "recraft" in MODEL
    # Com estilo por referencia, usa o endpoint text-to-image que aceita style_id.
    if is_recraft and RECRAFT_STYLE_ID:
        url = "https://fal.run/fal-ai/recraft/v3/text-to-image"
    else:
        url = "https://fal.run/" + MODEL
    headers = {"Authorization": "Key " + FAL_KEY, "Content-Type": "application/json"}
    seed_env = os.environ.get("SEED")
    body = {
        "prompt": prompt,
        "image_size": size if size else ("landscape_16_9" if landscape else "square_hd"),
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
    if is_recraft:
        # style e style_id NAO podem ir juntos. Referencia (style_id) tem prioridade.
        if RECRAFT_STYLE_ID:
            body["style_id"] = RECRAFT_STYLE_ID
        else:
            body["style"] = RECRAFT_STYLE
    r = requests.post(url, json=body, headers=headers, timeout=180)
    if r.status_code != 200:
        raise RuntimeError("fal.ai %d: %s" % (r.status_code, r.text[:300]))
    data = r.json()
    img = (data.get("images") or [data.get("image")])[0]
    img_url = img["url"] if isinstance(img, dict) else img
    return requests.get(img_url, timeout=120).content


def fal_upload(data_bytes, content_type, file_name):
    """Sobe um arquivo pro storage do fal e devolve a URL publica (para inputs *_url)."""
    init = requests.post(
        "https://rest.alpha.fal.ai/storage/upload/initiate",
        json={"content_type": content_type, "file_name": file_name},
        headers={"Authorization": "Key " + FAL_KEY, "Content-Type": "application/json"},
        timeout=60)
    if init.status_code != 200:
        raise RuntimeError("upload initiate %d: %s" % (init.status_code, init.text[:200]))
    j = init.json()
    up = requests.put(j["upload_url"], data=data_bytes,
                      headers={"Content-Type": content_type}, timeout=180)
    if up.status_code not in (200, 201, 204):
        raise RuntimeError("upload put %d: %s" % (up.status_code, up.text[:200]))
    return j["file_url"]


def fal_create_style(png_paths, base_style="digital_illustration"):
    """Cria um ESTILO custom no Recraft a partir de imagens de referencia (ate 5 PNGs).
    Zipa os PNGs, sobe pro storage do fal e chama o create-style. Devolve o dict."""
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as z:
        for p in png_paths:
            z.write(p, arcname=os.path.basename(p))
    zip_url = fal_upload(buf.getvalue(), "application/zip", "style_refs.zip")
    url = "https://fal.run/fal-ai/recraft/v3/create-style"
    headers = {"Authorization": "Key " + FAL_KEY, "Content-Type": "application/json"}
    body = {"images_data_url": zip_url, "base_style": base_style}
    r = requests.post(url, json=body, headers=headers, timeout=180)
    if r.status_code != 200:
        raise RuntimeError("create-style %d: %s" % (r.status_code, r.text[:300]))
    return r.json()


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
    elif category == "rig":
        # Peça/base modular: fundo transparente, 512px (escala comum p/ encaixar).
        im = remove_bg(im)
        im = im.resize((512, 512), Image.LANCZOS)
        out = os.path.join(DIRS[category], cid + ".png")
    elif category in ("autorig", "prop3d"):
        # Entrada do auto-rig / image-to-3D: fundo transparente, alta-res, SEM forçar
        # quadrado (preserva a proporção). Lado maior = 1024px.
        im = remove_bg(im)
        w, h = im.size
        scale = 1024.0 / max(w, h)
        im = im.resize((max(1, int(round(w * scale))), max(1, int(round(h * scale)))), Image.LANCZOS)
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
    # Comando especial: cria um ESTILO custom no Recraft a partir de imagens de
    # referencia (em assets/autorig/<id>.png). Uso: python gen_api.py style medusa
    if args and args[0] == "style":
        refs = [os.path.join(DIRS["autorig"], a + ".png") for a in (args[1:] or ["medusa"])]
        refs = [p for p in refs if os.path.exists(p)]
        if not refs:
            print("ERRO: nenhuma imagem de referencia encontrada em assets/autorig/")
            return
        print("Criando estilo Recraft a partir de:", [os.path.basename(p) for p in refs])
        res = fal_create_style(refs)
        sid = res.get("style_id") or res
        print("STYLE_ID:", sid)
        print("=> Adicione ao .env:  RECRAFT_STYLE_ID=%s" % sid)
        return
    if len(args) < 2 or args[0] not in DIRS:
        print("uso: python tools/gen_api.py <heroes|enemies|items> <id ...|all>")
        return
    category = args[0]
    is_maps = category == "maps"
    is_scenery = category == "scenery"
    is_splash = category == "splash"
    is_logo = category == "logo"
    is_rig = category == "rig"
    is_autorig = category == "autorig"
    is_prop3d = category == "prop3d"
    if is_maps:
        jobs = MAP_PROMPTS
    elif is_scenery:
        jobs = SCENERY_PROMPTS
    elif is_splash:
        jobs = SPLASH_PROMPTS
    elif is_logo:
        jobs = LOGO_PROMPTS
    elif is_rig:
        jobs = RIG_PROMPTS
    elif is_autorig:
        jobs = AUTORIG_PROMPTS
    elif is_prop3d:
        jobs = PROP3D_PROMPTS
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
    elif is_rig:
        style = RIG_STYLE
    elif is_autorig:
        style = AUTORIG_STYLE
    elif is_prop3d:
        style = PROP3D_STYLE
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
            png = fal_generate(prompt, landscape=(is_maps or is_splash),
                               size=("square_hd" if (is_autorig or is_prop3d) else None))
            out = save(png, category, cid)
            print("  OK  %-16s %5.1fs  -> %s" % (cid, time.time() - t0, out))
        except Exception as e:
            print("  FALHA", cid, "->", e)
    print("Pronto. Abra o Godot uma vez (importa as imagens) e rode.")


if __name__ == "__main__":
    main()
