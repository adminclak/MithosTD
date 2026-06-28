#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Padroniza os sprites de personagens: todos ficam no MESMO tamanho de canvas, com
o personagem escalado para uma altura fixa e com os PES ancorados na base (mesma
linha de chao). Isso da consistencia visual (mesma base) e faz todos "pisarem"
igual no jogo. Mantem a transparencia.

Uso: python tools/normalize_sprites.py            (herois + inimigos)
     python tools/normalize_sprites.py heroes      (so herois)
Recomenda-se rodar depois de gerar arte nova.
"""
import os, sys
from PIL import Image

PROJ = r"C:\projetos\jogoTD"
HEROES = os.path.join(PROJ, "assets", "heroes")
ENEMIES = os.path.join(PROJ, "assets", "enemies")

CANVAS = 256          # canvas final (quadrado)
TARGET_H = 232        # altura do personagem dentro do canvas
BOTTOM_MARGIN = 6     # folga ate a base (pes)
ALPHA_CUT = 12        # limiar de alpha p/ achar o conteudo


def normalize(path):
    im = Image.open(path).convert("RGBA")
    # Bounding box do conteudo (pixels com alpha > limiar).
    alpha = im.split()[3]
    mask = alpha.point(lambda a: 255 if a > ALPHA_CUT else 0)
    bbox = mask.getbbox()
    if bbox is None:
        return False
    cropped = im.crop(bbox)
    cw, ch = cropped.size
    # Escala para a altura alvo (sem ultrapassar a largura do canvas).
    scale = TARGET_H / float(ch)
    if cw * scale > CANVAS - 8:
        scale = (CANVAS - 8) / float(cw)
    nw, nh = max(1, int(round(cw * scale))), max(1, int(round(ch * scale)))
    cropped = cropped.resize((nw, nh), Image.NEAREST)
    # Cola centralizado na horizontal, ancorado na base.
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    x = (CANVAS - nw) // 2
    y = CANVAS - BOTTOM_MARGIN - nh
    canvas.alpha_composite(cropped, (x, y))
    canvas.save(path)
    return True


def run(folder):
    n = 0
    for f in os.listdir(folder):
        if f.endswith(".png"):
            if normalize(os.path.join(folder, f)):
                n += 1
    print("normalizados em %s: %d" % (os.path.basename(folder), n))


def main():
    args = sys.argv[1:]
    if not args or "heroes" in args:
        run(HEROES)
    if not args or "enemies" in args:
        run(ENEMIES)
    print("FIM.")


if __name__ == "__main__":
    main()
