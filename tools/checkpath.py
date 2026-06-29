#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Sobrepõe a POLYLINE dos waypoints (por onde os inimigos realmente andam) sobre o
mapa de cada fase, para ver se o trajeto bate com a trilha pintada na arte.
Salva _check_<tema>.png (1280x720). Portal=verde (1º wp), castelo=azul (último).
"""
import os
from PIL import Image, ImageDraw

W, H = 1280, 720
PROJ = r"C:\projetos\jogoTD"
MAPDIR = os.path.join(PROJ, "assets", "map")

PATHS = {
    "elis": [(262,-30),(258,96),(244,200),(196,256),(156,352),(168,452),(238,520),
        (356,544),(520,520),(720,500),(900,500),(1040,520),(1130,542),(1210,512)],
    "nemeia": [(866,-30),(860,120),(818,252),(750,360),(694,446),(770,512),(892,550),
        (1014,580),(1140,604),(1245,600)],
    "pantano": [(-30,468),(90,452),(195,438),(262,408),(318,352),(375,305),(445,288),
        (515,298),(595,293),(662,258),(722,192),(778,128),(828,92),(905,82),(978,110),
        (1045,158),(1110,140),(1190,118),(1255,110)],
    "desfiladeiro": [(-30,540),(150,525),(310,552),(450,505),(565,425),(680,350),
        (795,312),(905,295),(968,360),(1000,460),(1002,560),(992,620)],
    "olimpo": [(-30,500),(120,545),(225,600),(365,595),(495,575),(610,588),(700,596),
        (820,585),(940,600),(1060,578),(1165,528),(1245,482)],
}


def main():
    for theme, pts in PATHS.items():
        src = os.path.join(MAPDIR, "map_%s.png" % theme)
        if not os.path.exists(src):
            print("sem mapa:", src); continue
        img = Image.open(src).convert("RGB").resize((W, H))
        d = ImageDraw.Draw(img, "RGBA")
        # Faixa semitransparente larga (por onde os inimigos passam) + linha central.
        d.line(pts, fill=(255, 0, 0, 90), width=40, joint="curve")
        d.line(pts, fill=(255, 0, 0, 230), width=3, joint="curve")
        for i, (x, y) in enumerate(pts):
            r = 5
            d.ellipse([x-r, y-r, x+r, y+r], fill=(255, 255, 0, 255))
        # Portal (1º) verde, castelo (último) azul.
        px, py = pts[0]
        d.ellipse([px-12, py-12, px+12, py+12], outline=(0, 255, 0, 255), width=4)
        cx, cy = pts[-1]
        d.ellipse([cx-12, cy-12, cx+12, cy+12], outline=(0, 120, 255, 255), width=4)
        out = os.path.join(PROJ, "_check_%s.png" % theme)
        img.save(out)
        print("ok:", out)


if __name__ == "__main__":
    main()
