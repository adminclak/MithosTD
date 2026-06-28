#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Gera automaticamente as artes do Mithos TD via API do ComfyUI, com estilo
consistente (IPAdapter usando assets/ref_estilo.png como referencia).

Monta o workflow do zero (nao depende do historico):
  Checkpoint(DreamShaper Turbo) -> IPAdapter[ref, style transfer] -> LayerDiffuse
  -> KSampler(Turbo) -> VAEDecode -> LayerDiffuseDecodeRGBA(transparente) -> SaveImage

Le as descricoes de cada personagem do assets/ARTE.md.

Uso:
  python tools/gen_art.py hercules medusa    # so esses (teste)
  python tools/gen_art.py all                # todos os 64
Pre-requisito: ComfyUI aberto (http://127.0.0.1:8188), modelos DreamShaper +
IPAdapter (clip_vision + ipadapter) instalados, e assets/ref_estilo.png copiada
para a pasta input do ComfyUI.
"""
import urllib.request, json, time, os, shutil, sys, re, random

HOST = "http://127.0.0.1:8188"
PROJ = r"C:\projetos\jogoTD"
ARTE = os.path.join(PROJ, "assets", "ARTE.md")
OUTDIR = r"C:\Users\leoar\AppData\Local\Comfy-Desktop\ComfyUI-Shared\output"
HEROES = os.path.join(PROJ, "assets", "heroes")
ENEMIES = os.path.join(PROJ, "assets", "enemies")

CKPT = "DreamShaperXL_Turbo_V2-SFW.safetensors"
IP_REF = "ref_estilo.png"
IP_PRESET = "PLUS (high strength)"
# Ajustaveis por variavel de ambiente (pra calibrar sem editar):
#   IP_WEIGHT=0 desliga o IPAdapter | IP_START atrasa o estilo (deixa a forma se criar antes)
IP_WEIGHT = float(os.environ.get("IP_WEIGHT", "0.7"))
IP_START = float(os.environ.get("IP_START", "0.40"))  # estilo entra so apos a forma se criar
STEPS = int(os.environ.get("STEPS", "10"))

# Modo PIXEL ART (padrao agora): usa o LoRA Pixel Art XL no lugar do IPAdapter e
# reduz a imagem (nearest) para "pixels" nitidos estilo Tangy TD.
PIXEL = os.environ.get("PIXEL", "1") == "1"
LORA = "pixel-art-xl.safetensors"
PIXEL_LORA_W = float(os.environ.get("PIXEL_LORA_W", "1.1"))
PIXEL_SIZE = int(os.environ.get("PIXEL_SIZE", "256"))
PIXEL_STYLE_HERO = ("pixel art, pixel-art game sprite, full body single character, centered, "
    "front view, dynamic energetic action pose, exaggerated confident expression, big "
    "personality, bold readable silhouette, both hands visible, strong iconic recognizable "
    "features, signature weapon and outfit clearly visible, bold clean outline, vibrant "
    "saturated colors, warm top light, fun heroic Brawlhalla energy, ")
PIXEL_STYLE_ENEMY = ("pixel art, pixel-art game sprite, enemy monster, full body single creature, "
    "centered, front view, menacing, strong iconic recognizable features, bold clean outline, "
    "vibrant saturated palette, ")
PIXEL_NEG = (", blurry, antialiased, smooth shading, gradient, 3d render, realistic, photo, "
    "soft, depth of field")

ENEMY_IDS = {"lacaio", "espectro", "esqueleto", "hidra", "hidra_filhote",
             "centauro", "ciclope", "talos"}

STYLE_HERO = ("2D cartoon game character, mascot style, cute, vibrant saturated colors, "
    "bold clean outlines, soft cel shading, full body with both hands visible, single "
    "character, centered, front view, dynamic heroic pose, strong iconic recognizable "
    "features, signature weapon and outfit clearly visible, plain light gray background, "
    "Kingdom Rush and Brawlhalla art style, crisp, high quality, ")
STYLE_ENEMY = ("2D cartoon tower-defense enemy monster, cute but menacing, vibrant "
    "saturated colors, bold clean outlines, soft cel shading, full body, single "
    "character, centered, front view, strong iconic recognizable monster features, "
    "plain light gray background, Kingdom Rush and Brawlhalla art style, crisp, high quality, ")
NEG = ("photorealistic, realistic, 3d render, photograph, blurry, low quality, lowres, "
    "extra limbs, extra fingers, deformed, bad anatomy, text, words, watermark, "
    "signature, multiple characters, cropped, dark, gritty, horror gore")


def api(path, data=None):
    url = HOST + path
    if data is not None:
        req = urllib.request.Request(url, data=json.dumps(data).encode(),
                                     headers={"Content-Type": "application/json"})
    else:
        req = urllib.request.Request(url)
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def build_workflow(pos_text, seed, prefix):
    # MODEL/CLIP base = checkpoint. PIXEL usa LoRA; senao IPAdapter (estilo cartoon).
    model_src = ["1", 0]
    clip_src = ["1", 1]
    neg = NEG + (PIXEL_NEG if PIXEL else "")
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "8": {"class_type": "EmptyLatentImage",
              "inputs": {"width": 1024, "height": 1024, "batch_size": 1}},
        "10": {"class_type": "VAEDecode", "inputs": {"samples": ["9", 0], "vae": ["1", 2]}},
        "11": {"class_type": "LayeredDiffusionDecodeRGBA",
               "inputs": {"samples": ["9", 0], "images": ["10", 0],
                          "sd_version": "SDXL", "sub_batch_size": 16}},
    }
    if PIXEL:
        wf["20"] = {"class_type": "LoraLoader",
                    "inputs": {"model": ["1", 0], "clip": ["1", 1], "lora_name": LORA,
                               "strength_model": PIXEL_LORA_W, "strength_clip": 1.0}}
        model_src = ["20", 0]
        clip_src = ["20", 1]
    elif IP_WEIGHT > 0:
        wf["2"] = {"class_type": "LoadImage", "inputs": {"image": IP_REF}}
        wf["3"] = {"class_type": "IPAdapterUnifiedLoader",
                   "inputs": {"model": ["1", 0], "preset": IP_PRESET}}
        wf["4"] = {"class_type": "IPAdapter",
                   "inputs": {"model": ["3", 0], "ipadapter": ["3", 1], "image": ["2", 0],
                              "weight": IP_WEIGHT, "start_at": IP_START, "end_at": 1.0,
                              "weight_type": "style transfer"}}
        model_src = ["4", 0]
    wf["6"] = {"class_type": "CLIPTextEncode", "inputs": {"clip": clip_src, "text": pos_text}}
    wf["7"] = {"class_type": "CLIPTextEncode", "inputs": {"clip": clip_src, "text": neg}}
    wf["5"] = {"class_type": "LayeredDiffusionApply",
               "inputs": {"model": model_src, "config": "SDXL, Conv Injection", "weight": 1.0}}
    wf["9"] = {"class_type": "KSampler",
               "inputs": {"model": ["5", 0], "positive": ["6", 0], "negative": ["7", 0],
                          "latent_image": ["8", 0], "seed": seed, "steps": STEPS, "cfg": 2.0,
                          "sampler_name": "dpmpp_sde", "scheduler": "karras", "denoise": 1.0}}
    # Reduz para pixels nitidos (nearest) preservando a transparencia (RGBA).
    save_src = ["11", 0]
    if PIXEL:
        wf["13"] = {"class_type": "ImageScale",
                    "inputs": {"image": ["11", 0], "upscale_method": "nearest-exact",
                               "width": PIXEL_SIZE, "height": PIXEL_SIZE, "crop": "disabled"}}
        save_src = ["13", 0]
    wf["12"] = {"class_type": "SaveImage",
                "inputs": {"images": save_src, "filename_prefix": prefix}}
    return wf


def parse_arte():
    jobs = {}
    rx = re.compile(r'`([a-z0-9_]+)\.png`\s*[—\-]+\s*(.+)')
    with open(ARTE, encoding="utf-8") as f:
        for line in f:
            m = rx.search(line)
            if m:
                jobs[m.group(1)] = m.group(2).strip()
    return jobs


def main():
    args = sys.argv[1:]
    if not args:
        print("uso: python tools/gen_art.py <id ...|all>")
        return
    jobs = parse_arte()
    print("descricoes lidas do ARTE.md:", len(jobs))
    ids = list(jobs.keys()) if args == ["all"] else args

    submitted = {}
    for cid in ids:
        if cid not in jobs:
            print("  (sem descricao no ARTE.md):", cid)
            continue
        if PIXEL:
            style = PIXEL_STYLE_ENEMY if cid in ENEMY_IDS else PIXEL_STYLE_HERO
        else:
            style = STYLE_ENEMY if cid in ENEMY_IDS else STYLE_HERO
        wf = build_workflow(style + jobs[cid], random.randint(1, 2_000_000_000), "mithos/" + cid)
        try:
            r = api("/prompt", {"prompt": wf})
        except Exception as e:
            print("  falha ao enfileirar", cid, e)
            continue
        if r.get("node_errors"):
            print("  ERRO de no em", cid, ":", r["node_errors"])
            continue
        submitted[r["prompt_id"]] = cid
        print("  enfileirado:", cid)

    if not submitted:
        print("Nada enfileirado.")
        return
    print("\n%d na fila. Aguardando o ComfyUI gerar..." % len(submitted))
    pending = set(submitted)
    results = {}
    while pending:
        time.sleep(3)
        for pid in list(pending):
            try:
                h = api("/history/" + pid)
            except Exception:
                continue
            if pid in h:
                outs = h[pid].get("outputs", {})
                img = None
                for nd in outs.values():
                    for im in nd.get("images", []):
                        img = im
                        break
                if img:
                    results[submitted[pid]] = img
                pending.discard(pid)
                print("  pronto: %s  (%d restantes)" % (submitted[pid], len(pending)))

    os.makedirs(HEROES, exist_ok=True)
    os.makedirs(ENEMIES, exist_ok=True)
    copied = 0
    for cid, im in results.items():
        src = os.path.join(OUTDIR, im.get("subfolder", ""), im["filename"])
        folder = ENEMIES if cid in ENEMY_IDS else HEROES
        dst = os.path.join(folder, cid + ".png")
        try:
            shutil.copyfile(src, dst)
            copied += 1
        except Exception as e:
            print("  falha ao copiar", cid, e)
    print("\nFIM. Geradas e copiadas: %d imagens." % copied)


if __name__ == "__main__":
    main()
