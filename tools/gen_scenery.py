#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Gera os elementos visuais do mapa/menu (estilo Kingdom Rush) via API do ComfyUI.
Fundos = solidos; objetos (castelo/portal/arvore/pedra) = transparentes.
Salva em assets/map/<id>.png. Sem IPAdapter (cenario tem estilo proprio top-down).

Uso: python tools/gen_scenery.py        (gera tudo)
     python tools/gen_scenery.py castle  (so um)
"""
import urllib.request, json, time, os, shutil, sys, random

HOST = "http://127.0.0.1:8188"
PROJ = r"C:\projetos\jogoTD"
OUTDIR = r"C:\Users\leoar\AppData\Local\Comfy-Desktop\ComfyUI-Shared\output"
MAPDIR = os.path.join(PROJ, "assets", "map")
CKPT = "DreamShaperXL_Turbo_V2-SFW.safetensors"
LORA = "pixel-art-xl.safetensors"
PIXEL = os.environ.get("PIXEL", "1") == "1"
PIXEL_PRE = "pixel art, pixel-art style, bold clean outline, vibrant saturated colors, "

NEG = ("text, words, watermark, signature, ui, interface, blurry, low quality, "
       "lowres, photo, realistic, 3d render, people, humans, characters, "
       "buildings, towers, castle, houses, roads, paths, stone tiles, walls, grid, fences"
       ", antialiased, smooth, gradient")

# id -> (prompt, transparente, largura, altura)
JOBS = {
    "map_grass": ("seamless top-down grass field texture, flat empty green meadow ground, "
        "uniform short cartoon grass with subtle color variation, a few tiny scattered "
        "wildflowers and small dirt patches, even soft lighting, hand-painted game tile, "
        "completely empty, nothing on it", False, 1024, 576),
    "menu_bg": ("epic fantasy game title-screen background illustration, ancient "
        "mythological temple on a green mountain, dramatic golden sunset sky with clouds, "
        "lush scenery, vibrant cartoon painterly Kingdom Rush style, cinematic, no text", False, 1024, 576),
    "castle": ("2D cartoon stone castle fortress keep with towers and colorful banners, "
        "top-down three-quarter view, sturdy walls, Kingdom Rush building style, clean", True, 640, 640),
    "portal": ("2D cartoon dark rocky cave entrance with menacing glowing red eyes inside, "
        "enemy spawn gate, top-down three-quarter view, Kingdom Rush style", True, 640, 640),
    "tree": ("2D cartoon round leafy tree with lush green foliage and brown trunk, "
        "top-down three-quarter view, soft shadow, Kingdom Rush style", True, 512, 512),
    "rock": ("2D cartoon gray boulder rock with moss, top-down three-quarter view, "
        "Kingdom Rush style", True, 512, 512),
    "bush": ("2D cartoon small green bush shrub with little berries, top-down "
        "three-quarter view, Kingdom Rush style", True, 512, 512),
    # Chãos temáticos por mitologia (fundos sólidos, vazios).
    "ground_grega": ("seamless top-down mediterranean meadow, green grass with scattered "
        "white marble pebbles and small olive sprigs, sunny, flat empty ground, "
        "hand-painted game tile, nothing on it", False, 1024, 576),
    "ground_nordica": ("seamless top-down snow field, white snow with patches of frozen "
        "grass and thin ice cracks, cold blue tint, flat empty ground, hand-painted game "
        "tile, nothing on it", False, 1024, 576),
    "ground_egipcia": ("seamless top-down desert sand dunes, golden sand with subtle "
        "ripples and a few small pebbles, warm sunlight, flat empty ground, hand-painted "
        "game tile, nothing on it", False, 1024, 576),
    "ground_brasileira": ("seamless top-down lush jungle floor, dense green foliage, ferns, "
        "moss and fallen leaves, vibrant tropical, flat empty ground, hand-painted game "
        "tile, nothing on it", False, 1024, 576),
    "ground_chinesa": ("seamless top-down misty meadow, jade-green grass with pink lotus "
        "petals and small water puddles, serene, flat empty ground, hand-painted game "
        "tile, nothing on it", False, 1024, 576),
    "ground_japonesa": ("seamless top-down zen grass garden with scattered pink cherry "
        "blossom petals and raked sand patches, calm, flat empty ground, hand-painted "
        "game tile, nothing on it", False, 1024, 576),
    "ground_asteca": ("seamless top-down jungle ground, dark volcanic soil with green vines "
        "and small carved stone bits, warm, flat empty ground, hand-painted game tile, "
        "nothing on it", False, 1024, 576),
}


def api(path, data=None):
    url = HOST + path
    if data is not None:
        req = urllib.request.Request(url, data=json.dumps(data).encode(),
                                     headers={"Content-Type": "application/json"})
    else:
        req = urllib.request.Request(url)
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def build_workflow(prompt, seed, prefix, transparent, w, h):
    pos = (PIXEL_PRE + prompt) if PIXEL else prompt
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "8": {"class_type": "EmptyLatentImage", "inputs": {"width": w, "height": h, "batch_size": 1}},
        "10": {"class_type": "VAEDecode", "inputs": {"samples": ["9", 0], "vae": ["1", 2]}},
        "12": {"class_type": "SaveImage", "inputs": {"images": ["10", 0], "filename_prefix": prefix}},
    }
    model_src = ["1", 0]
    clip_src = ["1", 1]
    if PIXEL:
        wf["20"] = {"class_type": "LoraLoader", "inputs": {"model": ["1", 0], "clip": ["1", 1],
                    "lora_name": LORA, "strength_model": 1.1, "strength_clip": 1.0}}
        model_src = ["20", 0]
        clip_src = ["20", 1]
    wf["6"] = {"class_type": "CLIPTextEncode", "inputs": {"clip": clip_src, "text": pos}}
    wf["7"] = {"class_type": "CLIPTextEncode", "inputs": {"clip": clip_src, "text": NEG}}
    save_src = ["10", 0]
    if transparent:
        wf["5"] = {"class_type": "LayeredDiffusionApply",
                   "inputs": {"model": model_src, "config": "SDXL, Conv Injection", "weight": 1.0}}
        model_src = ["5", 0]
        wf["11"] = {"class_type": "LayeredDiffusionDecodeRGBA",
                    "inputs": {"samples": ["9", 0], "images": ["10", 0],
                               "sd_version": "SDXL", "sub_batch_size": 16}}
        save_src = ["11", 0]
    # Downscale (nearest) p/ pixels nitidos, preservando proporcao.
    if PIXEL:
        tw = 320 if not transparent else 192
        th = int(round(h * tw / float(w)))
        wf["13"] = {"class_type": "ImageScale", "inputs": {"image": save_src,
                    "upscale_method": "nearest-exact", "width": tw, "height": th, "crop": "disabled"}}
        save_src = ["13", 0]
    wf["12"]["inputs"]["images"] = save_src
    wf["9"] = {"class_type": "KSampler",
               "inputs": {"model": model_src, "positive": ["6", 0], "negative": ["7", 0],
                          "latent_image": ["8", 0], "seed": seed, "steps": 10, "cfg": 2.0,
                          "sampler_name": "dpmpp_sde", "scheduler": "karras", "denoise": 1.0}}
    return wf


def main():
    args = sys.argv[1:]
    ids = args if args else list(JOBS.keys())
    submitted = {}
    for cid in ids:
        if cid not in JOBS:
            print("  (sem job):", cid)
            continue
        prompt, transp, w, h = JOBS[cid]
        wf = build_workflow(prompt, random.randint(1, 2_000_000_000), "scene/" + cid, transp, w, h)
        r = api("/prompt", {"prompt": wf})
        if r.get("node_errors"):
            print("  ERRO", cid, r["node_errors"]); continue
        submitted[r["prompt_id"]] = cid
        print("  enfileirado:", cid)
    print("\n%d na fila, aguardando..." % len(submitted))
    pending = set(submitted)
    results = {}
    while pending:
        time.sleep(3)
        for pid in list(pending):
            try:
                hh = api("/history/" + pid)
            except Exception:
                continue
            if pid in hh:
                for nd in hh[pid].get("outputs", {}).values():
                    for im in nd.get("images", []):
                        results[submitted[pid]] = im
                        break
                pending.discard(pid)
                print("  pronto:", submitted[pid], "(", len(pending), "restantes)")
    os.makedirs(MAPDIR, exist_ok=True)
    for cid, im in results.items():
        src = os.path.join(OUTDIR, im.get("subfolder", ""), im["filename"])
        shutil.copyfile(src, os.path.join(MAPDIR, cid + ".png"))
    print("\nFIM. cenario gerado:", len(results))


if __name__ == "__main__":
    main()
