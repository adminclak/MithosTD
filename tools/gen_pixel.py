#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
PILOTO de pixel art (estilo Tangy TD) via ComfyUI + LoRA Pixel Art XL.
Gera em 1024, reduz para 128 (nearest = pixels nitidos) e reamplia p/ 512 para
visualizar. Fundo solido (sem transparencia) so para validar o ESTILO.

Uso: python tools/gen_pixel.py
"""
import urllib.request, json, time, os, shutil, random

HOST = "http://127.0.0.1:8188"
PROJ = r"C:\projetos\jogoTD"
OUTDIR = r"C:\Users\leoar\AppData\Local\Comfy-Desktop\ComfyUI-Shared\output"
DST = os.path.join(PROJ, "assets", "pixel_pilot")
CKPT = "DreamShaperXL_Turbo_V2-SFW.safetensors"
LORA = "pixel-art-xl.safetensors"

PRE = "pixel art, pixel-art style, crisp pixels, game sprite, vibrant saturated palette, bold clean outline, "
NEG = ("blurry, soft, antialiased, smooth, gradient, 3d render, realistic, photo, "
       "text, watermark, signature, jpeg artifacts")

JOBS = {
    "px_artemis": "full-body greek goddess huntress Artemis with a bow, silver tunic, "
        "confident pose, fantasy hero character, plain neutral background",
    "px_thor": "full-body norse god Thor warrior holding a big hammer, red cape, blonde "
        "beard, heroic stance, fantasy hero character, plain neutral background",
    "px_medusa": "full-body medusa gorgon, green skin, hair made of live snakes, holding a "
        "bow, menacing, fantasy villain character, plain neutral background",
    "px_enemy_slime": "a cute round green slime monster with eyes, simple, enemy creature, "
        "plain neutral background",
    "px_ground": "seamless top-down grass field tile, green meadow with tiny flowers, "
        "flat ground, nothing on it",
}


def api(path, data=None):
    req = urllib.request.Request(HOST + path,
        data=(json.dumps(data).encode() if data is not None else None),
        headers={"Content-Type": "application/json"} if data is not None else {})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def workflow(prompt, seed, cid):
    return {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "2": {"class_type": "LoraLoader", "inputs": {"model": ["1", 0], "clip": ["1", 1],
              "lora_name": LORA, "strength_model": 1.1, "strength_clip": 1.0}},
        "6": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 1], "text": PRE + prompt}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["2", 1], "text": NEG}},
        "8": {"class_type": "EmptyLatentImage", "inputs": {"width": 1024, "height": 1024, "batch_size": 1}},
        "9": {"class_type": "KSampler", "inputs": {"model": ["2", 0], "positive": ["6", 0],
              "negative": ["7", 0], "latent_image": ["8", 0], "seed": seed, "steps": 10,
              "cfg": 2.0, "sampler_name": "dpmpp_sde", "scheduler": "karras", "denoise": 1.0}},
        "10": {"class_type": "VAEDecode", "inputs": {"samples": ["9", 0], "vae": ["1", 2]}},
        "11": {"class_type": "ImageScale", "inputs": {"image": ["10", 0], "upscale_method": "nearest-exact",
               "width": 128, "height": 128, "crop": "disabled"}},
        "12": {"class_type": "ImageScale", "inputs": {"image": ["11", 0], "upscale_method": "nearest-exact",
               "width": 512, "height": 512, "crop": "disabled"}},
        "13": {"class_type": "SaveImage", "inputs": {"images": ["12", 0], "filename_prefix": cid}},
    }


def main():
    sub = {}
    for cid, prompt in JOBS.items():
        wf = workflow(prompt, random.randint(1, 2_000_000_000), cid)
        r = api("/prompt", {"prompt": wf})
        if r.get("node_errors"):
            print("ERRO", cid, r["node_errors"]); continue
        sub[r["prompt_id"]] = cid
        print("enfileirado:", cid)
    pend = set(sub); res = {}
    while pend:
        time.sleep(3)
        for pid in list(pend):
            try:
                hh = api("/history/" + pid)
            except Exception:
                continue
            if pid in hh:
                for nd in hh[pid].get("outputs", {}).values():
                    for im in nd.get("images", []):
                        res[sub[pid]] = im; break
                pend.discard(pid); print("pronto:", sub[pid])
    os.makedirs(DST, exist_ok=True)
    for cid, im in res.items():
        src = os.path.join(OUTDIR, im.get("subfolder", ""), im["filename"])
        shutil.copyfile(src, os.path.join(DST, cid + ".png"))
    print("FIM. piloto em assets/pixel_pilot:", len(res))


if __name__ == "__main__":
    main()
