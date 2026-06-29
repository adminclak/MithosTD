#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Detecta automaticamente a TRILHA pintada em cada mapa e extrai os waypoints que
seguem o MIOLO dela (assim os inimigos andam exatamente sobre a trilha da arte).

Como: segmenta a cor da trilha por bioma -> limpa -> pega o componente que liga a
entrada (portal) à saída (castelo) -> distance transform (centro da trilha) ->
A* entrada->saída preferindo o miolo -> simplifica (Douglas-Peucker).

Saída: imprime os waypoints em GDScript e salva _trace_<tema>.png p/ conferência.
Uso: python tools/tracepath.py [tema ...]   (sem args = todos)
"""
import sys, heapq
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

W, H = 1280, 720
SCALE = 0.40
WW, HH = int(W * SCALE), int(H * SCALE)
PROJ = r"C:\projetos\jogoTD"
DEBUG = True

# Entrada (portal) e saída (castelo) aproximadas, em coords de tela 1280x720.
ENDS = {
	"elis":         ((262, 8),   (1244, 520)),
	"nemeia":       ((4, 352),   (1276, 360)),
	"pantano":      ((4, 470),   (1252, 112)),
	"desfiladeiro": ((250, 12),  (956, 10)),
	"olimpo":       ((4, 500),   (1252, 482)),
}


def trail_mask(theme, im):
	r = im[..., 0].astype(int); g = im[..., 1].astype(int); b = im[..., 2].astype(int)
	lum = (r + g + b) / 3.0
	mx = np.maximum(np.maximum(r, g), b); mn = np.minimum(np.minimum(r, g), b)
	sat = (mx - mn) / (mx + 1.0)
	if theme in ("elis", "nemeia", "pantano"):
		# trilha bege: clara, quente (r>b), não dominada pelo verde
		return (lum > 118) & (lum < 240) & (r > b + 12) & (r > g - 18) & (b < 190)
	if theme == "desfiladeiro":
		# trilha bege CLARA e quente sobre rocha basáltica escura (alto contraste);
		# exclui a rocha (lum baixo) e pedras cinza (r~b).
		return (lum > 120) & (lum < 245) & (r > b + 12) & (r > g - 18) & (b < 190)
	if theme == "olimpo":
		# trilha de terra marrom (r>g>b), nem neve branca nem pedra cinza
		return (r > g + 6) & (g > b + 6) & (lum > 95) & (lum < 205)
	return lum > 150


def snap(mask_pts, p):
	d = (mask_pts[:, 1] - p[0]) ** 2 + (mask_pts[:, 0] - p[1]) ** 2
	i = int(np.argmin(d))
	return (int(mask_pts[i, 0]), int(mask_pts[i, 1]))  # (row, col)


def astar(mask, dist, start_rc, goal_rc):
	maxd = dist.max() if dist.max() > 0 else 1.0
	cost = 1.0 + 6.0 * (1.0 - dist / maxd)  # miolo (dist alto) = barato
	h, w = mask.shape
	def heur(rc):
		return ((rc[0] - goal_rc[0]) ** 2 + (rc[1] - goal_rc[1]) ** 2) ** 0.5
	open_h = [(heur(start_rc), 0.0, start_rc)]
	g = {start_rc: 0.0}
	came = {}
	nbrs = [(-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (-1, 1), (1, -1), (1, 1)]
	while open_h:
		_, gc, cur = heapq.heappop(open_h)
		if cur == goal_rc:
			break
		if gc > g.get(cur, 1e18):
			continue
		for dr, dc in nbrs:
			nr, nc = cur[0] + dr, cur[1] + dc
			if nr < 0 or nr >= h or nc < 0 or nc >= w or not mask[nr, nc]:
				continue
			step = cost[nr, nc] * (1.414 if dr and dc else 1.0)
			ng = gc + step
			if ng < g.get((nr, nc), 1e18):
				g[(nr, nc)] = ng
				came[(nr, nc)] = cur
				heapq.heappush(open_h, (ng + heur((nr, nc)), ng, (nr, nc)))
	if goal_rc not in came and goal_rc != start_rc:
		return None
	path = [goal_rc]
	while path[-1] != start_rc:
		path.append(came[path[-1]])
	path.reverse()
	return path


def rdp(points, eps):
	if len(points) < 3:
		return points
	a = np.array(points[0]); b = np.array(points[-1])
	ab = b - a; nrm = np.hypot(*ab) + 1e-9
	dmax = 0.0; idx = 0
	for i in range(1, len(points) - 1):
		p = np.array(points[i])
		d = abs(np.cross(ab, p - a)) / nrm
		if d > dmax:
			dmax = d; idx = i
	if dmax > eps:
		left = rdp(points[:idx + 1], eps)
		right = rdp(points[idx:], eps)
		return left[:-1] + right
	return [points[0], points[-1]]


def trace(theme):
	src = "%s/assets/map/map_%s.png" % (PROJ, theme)
	im = np.asarray(Image.open(src).convert("RGB").resize((WW, HH)))
	mask = trail_mask(theme, im)
	# fecha bem (une fragmentos separados por sombras/objetos) e remove ruído
	mask = ndimage.binary_closing(mask, structure=np.ones((3, 3)), iterations=3)
	mask = ndimage.binary_opening(mask, structure=np.ones((3, 3)), iterations=1)
	# mantém o MAIOR componente conectado (a trilha principal)
	lbl, n = ndimage.label(mask)
	if n == 0:
		print("# %s: trilha nao detectada" % theme); return None
	sizes = ndimage.sum(np.ones_like(lbl), lbl, index=range(1, n + 1))
	mask = lbl == (1 + int(np.argmax(sizes)))
	if DEBUG:
		Image.fromarray((mask * 255).astype(np.uint8)).save("%s/_mask_%s.png" % (PROJ, theme))
	pts = np.argwhere(mask)
	(sx, sy), (gx, gy) = ENDS[theme]
	s = snap(pts, (sx * SCALE, sy * SCALE))
	gl = snap(pts, (gx * SCALE, gy * SCALE))
	dist = ndimage.distance_transform_edt(mask)
	path = astar(mask, dist, s, gl)
	if path is None:
		print("# %s: sem caminho entrada->saida" % theme); return None
	# para coords de tela e simplifica
	scr = [(c / SCALE, r / SCALE) for (r, c) in path]
	simp = rdp(scr, 7.0)
	wps = [(int(round(x)), int(round(y))) for (x, y) in simp]
	# estende a 1ª e última pontas p/ fora da tela (portal/castelo entram pela borda)
	_extend_ends(wps)
	_draw(theme, src, wps)
	_print_gd(theme, wps)
	return wps


def _extend_ends(wps):
	if len(wps) >= 2:
		# empurra o 1º ponto um pouco para fora, na direção de entrada
		import math
		def push(a, b, out):
			dx, dy = a[0] - b[0], a[1] - b[1]
			n = math.hypot(dx, dy) + 1e-9
			return (int(a[0] + dx / n * out), int(a[1] + dy / n * out))
		wps[0] = push(wps[0], wps[1], 36)
		wps[-1] = push(wps[-1], wps[-2], 24)


def _draw(theme, src, wps):
	img = Image.open(src).convert("RGB").resize((W, H))
	d = ImageDraw.Draw(img, "RGBA")
	d.line(wps, fill=(255, 0, 0, 90), width=40, joint="curve")
	d.line(wps, fill=(255, 0, 0, 235), width=3, joint="curve")
	for x, y in wps:
		d.ellipse([x - 4, y - 4, x + 4, y + 4], fill=(255, 255, 0, 255))
	img.save("%s/_trace_%s.png" % (PROJ, theme))


def _print_gd(theme, wps):
	print('\t"%s": [' % theme)
	line = "\t\t"
	for i, (x, y) in enumerate(wps):
		line += "Vector2(%d, %d), " % (x, y)
		if (i + 1) % 4 == 0:
			print(line.rstrip()); line = "\t\t"
	if line.strip():
		print(line.rstrip())
	print("\t],")


def main():
	themes = sys.argv[1:] or list(ENDS.keys())
	for t in themes:
		trace(t)


if __name__ == "__main__":
	main()
