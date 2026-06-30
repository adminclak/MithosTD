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


def fal_generate(prompt):
    """Chama a fal.ai (REST sincrono) e devolve os bytes do PNG gerado."""
    url = "https://fal.run/" + MODEL
    headers = {"Authorization": "Key " + FAL_KEY, "Content-Type": "application/json"}
    seed_env = os.environ.get("SEED")
    body = {
        "prompt": prompt,
        "image_size": "square_hd",          # 1024x1024
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
    im = remove_bg(im)
    im = im.resize((OUT_SIZE, OUT_SIZE), Image.LANCZOS)
    os.makedirs(DIRS[category], exist_ok=True)
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
    jobs = parse_arte()
    ids = list(jobs.keys()) if args[1] == "all" else args[1:]
    style = STYLE[category]
    print("Modelo:", MODEL, "| categoria:", category, "| itens:", len(ids))
    for cid in ids:
        desc = jobs.get(cid)
        if not desc:
            print("  (sem descricao no ARTE.md):", cid)
            continue
        prompt = style + ", " + desc
        try:
            t0 = time.time()
            png = fal_generate(prompt)
            out = save(png, category, cid)
            print("  OK  %-16s %5.1fs  -> %s" % (cid, time.time() - t0, out))
        except Exception as e:
            print("  FALHA", cid, "->", e)
    print("Pronto. Abra o Godot uma vez (importa as imagens) e rode.")


if __name__ == "__main__":
    main()
