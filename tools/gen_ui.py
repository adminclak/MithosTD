#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Gera elementos de UI ORNAMENTADOS (fantasia) em alta resolucao, transparentes,
via ComfyUI (sem LoRA pixel — UI do menu pode ser detalhada/HD). Botoes 9-slice,
painel e um brasao/banner para o titulo. Salva em assets/ui/.

Uso: python tools/gen_ui.py            (todos)
     python tools/gen_ui.py ui_btn     (so alguns)
"""
import urllib.request, json, time, os, shutil, sys, random

HOST = "http://127.0.0.1:8188"
PROJ = r"C:\projetos\jogoTD"
OUTDIR = r"C:\Users\leoar\AppData\Local\Comfy-Desktop\ComfyUI-Shared\output"
DST = os.path.join(PROJ, "assets", "ui")
CKPT = "DreamShaperXL_Turbo_V2-SFW.safetensors"

PRE = "ornate fantasy game UI asset, polished, embossed, clean vector-like, centered, "
NEG = ("text, letters, words, numbers, pixelated, lowres, blurry, photo, realistic, "
       "people, person, character, face, cluttered, busy background, scene")

# id -> (prompt, largura, altura, transparente)
# Botoes/painel: preenchem o quadro inteiro (sem transparencia) -> 9-slice limpo.
# Banner/emblema: transparente (formas organicas funcionam bem).
JOBS = {
    "ui_btn": ("a rounded rectangular fantasy button that FILLS THE ENTIRE FRAME edge to "
        "edge, polished dark wood plank with thick golden metal beveled border and corner "
        "rivets, smooth flat center, top-down flat UI, no background", 384, 128, False),
    "ui_btn_hover": ("a rounded rectangular fantasy button that FILLS THE ENTIRE FRAME edge "
        "to edge, warm wood with bright glowing polished gold beveled border, smooth flat "
        "center, top-down flat UI, no background", 384, 128, False),
    "ui_btn_gold": ("a rounded rectangular royal button that FILLS THE ENTIRE FRAME edge to "
        "edge, ornate solid gold beveled border with small red gems, smooth flat center, "
        "top-down flat UI, no background", 384, 128, False),
    "ui_panel": ("a square ornate fantasy UI panel that FILLS THE ENTIRE FRAME edge to edge, "
        "dark parchment center with thick carved gold and wood border and corner flourishes, "
        "top-down flat UI, no background", 256, 256, False),
    "ui_banner": ("wide ornate fantasy title banner, horizontal carved wooden sign with "
        "golden frame, red hanging ribbons on both ends, laurel leaves, big blank empty "
        "center plate for a logo, symmetrical", 896, 320, True),
    "ui_emblem": ("fantasy game emblem crest, golden laurel wreath around a round shield "
        "with crossed sword and lightning bolt, mythological, symmetrical, blank center", 320, 320, True),
    "tex_wood": ("seamless tileable wooden planks texture, warm dark brown fantasy wood "
        "boards with grain, top-down flat, even lighting, no objects", 640, 384, False),
    "tex_parchment": ("seamless tileable old parchment paper texture, warm aged beige with "
        "subtle stains, slightly darker worn edges, flat, no text, no border", 512, 512, False),
    "frame_wood": ("ornate rectangular wooden frame border, thick carved brown wood with "
        "golden corner ornaments and rivets, large completely empty hollow center, fantasy "
        "game UI frame, symmetrical, centered", 768, 512, True),
}


def api(path, data=None):
    req = urllib.request.Request(HOST + path,
        data=(json.dumps(data).encode() if data is not None else None),
        headers={"Content-Type": "application/json"} if data is not None else {})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def workflow(prompt, seed, cid, w, h, transparent):
    wf = {
        "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": CKPT}},
        "6": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["1", 1], "text": PRE + prompt}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["1", 1], "text": NEG}},
        "8": {"class_type": "EmptyLatentImage", "inputs": {"width": w, "height": h, "batch_size": 1}},
        "10": {"class_type": "VAEDecode", "inputs": {"samples": ["9", 0], "vae": ["1", 2]}},
        "12": {"class_type": "SaveImage", "inputs": {"images": ["10", 0], "filename_prefix": cid}},
    }
    model_src = ["1", 0]
    if transparent:
        wf["5"] = {"class_type": "LayeredDiffusionApply",
                   "inputs": {"model": ["1", 0], "config": "SDXL, Conv Injection", "weight": 1.0}}
        model_src = ["5", 0]
        wf["11"] = {"class_type": "LayeredDiffusionDecodeRGBA", "inputs": {"samples": ["9", 0],
                    "images": ["10", 0], "sd_version": "SDXL", "sub_batch_size": 16}}
        wf["12"]["inputs"]["images"] = ["11", 0]
    wf["9"] = {"class_type": "KSampler", "inputs": {"model": model_src, "positive": ["6", 0],
               "negative": ["7", 0], "latent_image": ["8", 0], "seed": seed, "steps": 12,
               "cfg": 2.0, "sampler_name": "dpmpp_sde", "scheduler": "karras", "denoise": 1.0}}
    return wf


def main():
    args = sys.argv[1:]
    ids = args if args else list(JOBS.keys())
    sub = {}
    for cid in ids:
        if cid not in JOBS:
            print("(sem job):", cid); continue
        p, w, h, transp = JOBS[cid]
        r = api("/prompt", {"prompt": workflow(p, random.randint(1, 2_000_000_000), cid, w, h, transp)})
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
    print("FIM. UI gerada:", len(res))


if __name__ == "__main__":
    main()
