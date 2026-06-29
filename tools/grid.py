#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Sobrepõe uma grade de coordenadas (em ESPAÇO DE TELA 1280x720) sobre um mapa, para
"decalcar" com precisão o trajeto pintado e as posições de torre.

Uso: python tools/grid.py assets/map/map_elis.png   -> gera _grid.png
"""
import sys, os
from PIL import Image, ImageDraw, ImageFont

W, H = 1280, 720
STEP = 80

def main():
    if len(sys.argv) < 2:
        print("uso: python tools/grid.py <png>"); return
    src = sys.argv[1]
    img = Image.open(src).convert("RGB").resize((W, H))
    d = ImageDraw.Draw(img, "RGBA")
    try:
        font = ImageFont.truetype("arial.ttf", 13)
    except Exception:
        font = ImageFont.load_default()
    for x in range(0, W + 1, STEP):
        col = (255, 0, 0, 200) if x % 160 == 0 else (255, 255, 255, 90)
        d.line([(x, 0), (x, H)], fill=col, width=1)
        if x % 160 == 0:
            d.text((x + 2, 2), str(x), fill=(255, 255, 0, 255), font=font)
            d.text((x + 2, H - 16), str(x), fill=(255, 255, 0, 255), font=font)
    for y in range(0, H + 1, STEP):
        col = (255, 0, 0, 200) if y % 160 == 0 else (255, 255, 255, 90)
        d.line([(0, y), (W, y)], fill=col, width=1)
        if y % 160 == 0:
            d.text((2, y + 2), str(y), fill=(255, 255, 0, 255), font=font)
            d.text((W - 36, y + 2), str(y), fill=(255, 255, 0, 255), font=font)
    # Saída: _grid_<nome>.png na raiz do projeto (não sobrescreve outras grades).
    base = os.path.splitext(os.path.basename(src))[0]
    out = os.path.join(r"C:\projetos\jogoTD", "_grid_" + base + ".png")
    img.save(out)
    print("grade salva em", out)

if __name__ == "__main__":
    main()
