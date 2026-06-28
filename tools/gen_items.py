#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Gera icones de itens (pixel art, transparente) via ComfyUI + LoRA Pixel Art XL.
- 8 icones genericos (1 por slot) usados pelos itens comuns.
- ~47 icones unicos dos lendarios miticos (Mjolnir, Egide, Olho de Odin...).
Salva em assets/items/<icon>.png (128px, transparente).

Uso: python tools/gen_items.py            (todos)
     python tools/gen_items.py mjolnir     (so alguns)
"""
import urllib.request, json, time, os, shutil, sys, random

HOST = "http://127.0.0.1:8188"
PROJ = r"C:\projetos\jogoTD"
OUTDIR = r"C:\Users\leoar\AppData\Local\Comfy-Desktop\ComfyUI-Shared\output"
DST = os.path.join(PROJ, "assets", "items")
CKPT = "DreamShaperXL_Turbo_V2-SFW.safetensors"
LORA = "pixel-art-xl.safetensors"
SIZE = 128

PRE = ("pixel art, pixel-art game inventory icon, single centered object, item icon, "
       "bold clean outline, vibrant saturated colors, ")
NEG = ("background, scenery, character, person, hands, multiple objects, text, watermark, "
       "blurry, antialiased, smooth, gradient, 3d render, realistic, photo")

GENERIC = {
    "slot_helmet": "a steel knight helmet",
    "slot_armor": "a steel chestplate body armor",
    "slot_legs": "armored leg greaves pants",
    "slot_boots": "a pair of leather boots",
    "slot_weapon": "a steel sword",
    "slot_shield": "a round wooden and iron shield",
    "slot_amulet": "a golden amulet necklace with a gem",
    "slot_ring": "a golden ring with a gem",
}

LEGENDARY = {
    # Grega
    "raio_zeus": "a golden lightning bolt weapon of Zeus, crackling energy",
    "tridente_poseidon": "a golden ocean trident of Poseidon",
    "arco_artemis": "an elegant silver hunting bow with moon motif",
    "harpe_perseu": "a curved bronze sickle sword harpe",
    "egide_atena": "a round shield with a golden Medusa head emblem (Aegis)",
    "escudo_perseu": "a polished mirror-like bronze round shield",
    "elmo_hades": "a dark shadowy helmet of invisibility, purple aura",
    "sandalias_hermes": "a pair of winged golden sandals",
    "pele_leao_nemeia": "a lion pelt armor cloak with lion head hood",
    "lira_apolo": "a golden lyre harp",
    "velocino_ouro": "a glowing golden fleece ram wool",
    "coroa_louros": "a green laurel wreath crown",
    # Nordica
    "mjolnir": "Thor's hammer Mjolnir, short handled war hammer with runes",
    "gungnir": "Odin's spear Gungnir, ornate runic spearhead",
    "olho_odin": "a single mystical glowing eye amulet (Odin's eye)",
    "draupnir": "a golden magic ring dripping smaller rings",
    "brisingamen": "an ornate golden necklace with amber gems",
    "megingjord": "a thick leather strength belt with iron buckle",
    "escudo_valquiria": "a winged valkyrie round shield",
    "botas_vidar": "a pair of thick rugged leather boots",
    # Egipcia
    "olho_horus": "the Eye of Horus amulet, blue and gold",
    "olho_ra": "the Eye of Ra, fiery sun disc weapon",
    "khopesh_real": "a golden egyptian khopesh sickle sword",
    "cetro_uas": "an egyptian was scepter staff",
    "ankh_vida": "a golden ankh symbol amulet",
    "coroa_pschent": "the egyptian double crown Pschent red and white",
    "escudo_anubis": "a black and gold shield with Anubis jackal emblem",
    # Chinesa
    "ruyi_jingu": "a golden red magic staff with golden bands (Ruyi Jingu Bang)",
    "perola_dragao": "a glowing dragon pearl orb amulet",
    "arco_houyi": "an ornate red and gold chinese longbow",
    "rodas_nezha": "wind fire wheels, flaming golden wheels",
    "armadura_guanyu": "ornate green chinese general lamellar armor",
    # Japonesa
    "kusanagi": "a glowing katana sword (Kusanagi no Tsurugi)",
    "espelho_yata": "a sacred bronze round mirror (Yata no Kagami)",
    "joia_yasakani": "a curved magatama jade jewel necklace",
    "oyoroi": "ornate samurai o-yoroi armor",
    "kabuto_oni": "a samurai kabuto helmet with demon oni mask",
    # Brasileira
    "gorro_saci": "a red magic phrygian cap floppy hat",
    "pes_virados": "a pair of backward-facing bare feet, jungle",
    "olhos_boitata": "a fiery serpent eye amulet, glowing red",
    "couraca_mapinguari": "a thick shaggy beast fur armor",
    "muiraquita": "a green jade frog amulet (muiraquita)",
    # Asteca
    "macuahuitl": "an aztec wooden club sword with obsidian blades",
    "chimalli_quetzal": "an aztec round feather shield with quetzal feathers",
    "espelho_fumegante": "a black obsidian smoking mirror amulet",
    "penacho_moctezuma": "an aztec green quetzal feather headdress",
    "coracao_obsidiana": "a black obsidian heart gem amulet",
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
        "20": {"class_type": "LoraLoader", "inputs": {"model": ["1", 0], "clip": ["1", 1],
               "lora_name": LORA, "strength_model": 1.1, "strength_clip": 1.0}},
        "6": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["20", 1], "text": PRE + prompt}},
        "7": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["20", 1], "text": NEG}},
        "8": {"class_type": "EmptyLatentImage", "inputs": {"width": 1024, "height": 1024, "batch_size": 1}},
        "5": {"class_type": "LayeredDiffusionApply",
              "inputs": {"model": ["20", 0], "config": "SDXL, Conv Injection", "weight": 1.0}},
        "9": {"class_type": "KSampler", "inputs": {"model": ["5", 0], "positive": ["6", 0],
              "negative": ["7", 0], "latent_image": ["8", 0], "seed": seed, "steps": 10,
              "cfg": 2.0, "sampler_name": "dpmpp_sde", "scheduler": "karras", "denoise": 1.0}},
        "10": {"class_type": "VAEDecode", "inputs": {"samples": ["9", 0], "vae": ["1", 2]}},
        "11": {"class_type": "LayeredDiffusionDecodeRGBA", "inputs": {"samples": ["9", 0],
               "images": ["10", 0], "sd_version": "SDXL", "sub_batch_size": 16}},
        "13": {"class_type": "ImageScale", "inputs": {"image": ["11", 0],
               "upscale_method": "nearest-exact", "width": SIZE, "height": SIZE, "crop": "disabled"}},
        "12": {"class_type": "SaveImage", "inputs": {"images": ["13", 0], "filename_prefix": "item_" + cid}},
    }


def main():
    jobs = {}
    jobs.update(GENERIC)
    jobs.update(LEGENDARY)
    args = sys.argv[1:]
    ids = args if args else list(jobs.keys())
    sub = {}
    for cid in ids:
        if cid not in jobs:
            print("(sem prompt):", cid); continue
        wf = workflow(jobs[cid], random.randint(1, 2_000_000_000), cid)
        r = api("/prompt", {"prompt": wf})
        if r.get("node_errors"):
            print("ERRO", cid, r["node_errors"]); continue
        sub[r["prompt_id"]] = cid
    print("enfileirados:", len(sub))
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
                pend.discard(pid)
                if len(pend) % 10 == 0:
                    print("  restantes:", len(pend))
    os.makedirs(DST, exist_ok=True)
    for cid, im in res.items():
        src = os.path.join(OUTDIR, im.get("subfolder", ""), im["filename"])
        shutil.copyfile(src, os.path.join(DST, cid + ".png"))
    print("FIM. icones gerados:", len(res))


if __name__ == "__main__":
    main()
