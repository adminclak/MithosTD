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
       "buildings, towers, castle, houses, walls, grid, "
       "antialiased, gradient, flowers, colorful dots, confetti, "
       "many flowers, red flowers, blue flowers, busy, cluttered, "
       "fortress, fort, keep, ruins, garden, building, "
       "pagoda, asian temple, chinese, japanese, thai, oriental, curved roof")

# id -> (prompt, transparente, largura, altura)
JOBS = {
    "map_grass": ("seamless top-down grass field texture, flat empty green meadow ground, "
        "uniform short cartoon grass with subtle color variation, a few tiny scattered "
        "wildflowers and small dirt patches, even soft lighting, hand-painted game tile, "
        "completely empty, nothing on it", False, 1024, 576),
    "world_map": ("illustrated fantasy world map seen from above, distinct regions "
        "(green greek hills, snowy norse fiords, golden egyptian desert, lush jungle, "
        "misty asian mountains), a winding road connecting them, rivers, parchment edges, "
        "vibrant cartoon painterly style, cinematic, no text, no labels", False, 1024, 576),
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
    # Prédios das 4 torres (estilo Kingdom Rush), transparentes.
    "tower_archer": ("stone archer watchtower building with wooden top, battlements and "
        "arrow slits, small flag, top-down three-quarter view, tower defense building", True, 512, 512),
    "tower_warrior": ("stone barracks fort building with closed wooden gate and a banner, "
        "sturdy, top-down three-quarter view, tower defense building", True, 512, 512),
    "tower_mage": ("blue magic mage guild tower with glowing crystal orb on top and runes, "
        "top-down three-quarter view, tower defense building", True, 512, 512),
    "tower_priest": ("ancient greek parthenon temple building, white marble with tall doric "
        "columns and a triangular pediment, golden divine glow inside, top-down three-quarter "
        "view, tower defense building, european classical, not asian, no pagoda", True, 512, 512),
    # --- MAPAS pintados em HD (estilo Kingdom Rush), bioma nas bordas baked ---
    # O centro fica PLANO e VAZIO (o caminho/torres/castelo são desenhados por cima).
    "map_elis": ("top-down 2D painted cartoon forest clearing battlefield, Kingdom Rush map "
        "art style, a large flat green grass meadow, a single PALE SANDY BEIGE light tan dirt "
        "road (warm light brown earth color, NOT grey, NOT asphalt, NOT stone), medium width, "
        "crossing the meadow from the LEFT edge to the RIGHT edge in a relaxed horizontal S "
        "shape with two or three gentle bends, lots of open grass around it, the road bends "
        "around rocks and trees and never crosses them, framed on all four edges by a dense "
        "ring of round-canopy green trees, warm soft shadows, vibrant hand-painted",
        False, 1024, 576),
    "map_nemeia": ("flat top-down game level map seen straight from directly above, "
        "orthographic bird eye view, NO sky NO horizon NO perspective NO vanishing point, "
        "NO standing tree trunks, NO tilted view, 2D painted cartoon Kingdom Rush level map, "
        "a large flat dark green forest grass GROUND filling the whole frame, ONLY ONE single "
        "clear path and NO other trails, exactly ONE bright LIGHT TAN BEIGE packed dirt trail "
        "(warm sandy beige, clearly lighter than the dark grass), medium width, snaking across "
        "from the LEFT edge to the RIGHT edge in one serpentine S shape with three gentle bends, "
        "lots of open dark grass all around it, the single trail bends around boulders and never "
        "crosses them, edges lined with the ROUND CANOPY TOPS of dense dark green pine and oak "
        "trees seen from straight above (only treetops, no trunks), a few mossy boulders and "
        "ferns, cool soft shadows, vibrant hand-painted", False, 1024, 576),
    "map_pantano": ("flat top-down game level map seen straight from directly above, "
        "orthographic bird eye view, NO sky NO horizon NO perspective NO vanishing point, "
        "2D painted cartoon Kingdom Rush level map, a large flat murky dark green muddy swamp "
        "GROUND filling the whole frame, ONLY ONE single clear path and NO other trails, "
        "exactly ONE bright LIGHT TAN BEIGE dry packed-earth trail (warm sandy beige, clearly "
        "lighter than the dark mud), medium width, snaking across from the LEFT edge to the "
        "RIGHT edge in one serpentine S shape with three gentle bends, lots of open dark mud "
        "ground all around it, NO river, NO water crossing the path, just one small shallow "
        "pond in a corner, the single trail bends around dead trees and reeds and never crosses "
        "them, edges lined with clusters of tall green reeds and gnarled bare dead willow trees "
        "seen from above, foggy, cool soft shadows, vibrant hand-painted", False, 1024, 576),
    "map_desfiladeiro": ("flat top-down game level map seen straight from directly above, "
        "orthographic bird eye view, NO sky NO horizon NO perspective NO vanishing point, "
        "2D painted cartoon Kingdom Rush level map, a large flat VERY DARK charcoal black "
        "volcanic basalt rock GROUND filling the whole frame (deep dark near-black stone), "
        "ONLY ONE single clear path and NO other trails, exactly ONE bright LIGHT TAN BEIGE dry "
        "packed-sand trail (warm pale beige, glowing bright against the dark black rock, very "
        "strong contrast), medium width, snaking across from the LEFT edge to the RIGHT edge in "
        "one serpentine S shape with three gentle bends, lots of open dark black rock ground all "
        "around it, NO river, NO water, NO lava, the single trail bends around boulders and "
        "never crosses them, edges lined with clusters of jagged dark basalt rock spires seen "
        "from above, arid volcanic gorge, warm soft shadows, vibrant hand-painted",
        False, 1024, 576),
    "map_olimpo": ("flat top-down game level map seen straight from directly above, "
        "orthographic bird eye view, NO sky NO horizon NO perspective NO vanishing point, "
        "2D painted cartoon Kingdom Rush level map, a large flat pale grey marble stone GROUND "
        "with patches of white snow filling the whole frame, a single continuous WARM GOLDEN "
        "SANDSTONE paved path (cream golden tan stone, clearly warmer than the pale grey and "
        "white ground), medium width, curving from the LEFT edge to the RIGHT edge in one "
        "gentle wide S arc, lots of open ground around it, the path bends around boulders and "
        "never crosses them, edges lined with white snow drifts, pale marble boulders and a few "
        "small frosty pine trees seen from above, sacred warm golden light, soft shadows, "
        "vibrant hand-painted", False, 1024, 576),
    # --- Chãos por fase grega (detalhados) ---
    "ground_elis": ("seamless top-down lush green grass field, exactly like Kingdom Rush "
        "map ground, two shades of green, dense short cartoon grass with subtle texture, a "
        "few small grass tufts and tiny pebbles, clean and simple, empty, no flowers", False, 1024, 576),
    "ground_nemeia": ("seamless top-down forest grass ground, like Kingdom Rush, rich green "
        "grass with subtle moss patches and a few small ferns, clean cartoon, empty, "
        "no flowers", False, 1024, 576),
    "ground_pantano": ("seamless top-down murky swamp ground, wet dark mud with shallow "
        "green water puddles, moss and small reeds, hand-painted, fine detail, empty",
        False, 1024, 576),
    "ground_desfiladeiro": ("seamless top-down dry rocky canyon ground, cracked reddish "
        "brown earth, gravel and small stones, arid, hand-painted, fine detail, empty",
        False, 1024, 576),
    "ground_olimpo": ("seamless top-down high mountain ground, pale grey stone with marble "
        "tiles and patches of snow, sacred, hand-painted, fine detail, empty", False, 1024, 576),
    # --- Novos elementos temáticos (transparentes) ---
    "olive_tree": ("2D cartoon olive tree, silver-green leaves and gnarled trunk, top-down "
        "three-quarter view, soft shadow, Kingdom Rush style", True, 512, 512),
    "pine": ("2D cartoon tall dark green pine tree, top-down three-quarter view, Kingdom Rush style", True, 512, 512),
    "reeds": ("2D cartoon cluster of swamp reeds and cattails, green, top-down three-quarter "
        "view, Kingdom Rush style", True, 512, 512),
    "lily": ("2D cartoon lily pad with a pink flower on water, top-down view, Kingdom Rush style", True, 512, 512),
    "cliff_rock": ("2D cartoon tall reddish rocky boulder cliff chunk, top-down three-quarter "
        "view, Kingdom Rush style", True, 512, 512),
    "dead_tree": ("2D cartoon bare dead leafless tree, twisted branches, top-down three-quarter "
        "view, Kingdom Rush style", True, 512, 512),
    "column": ("2D cartoon broken greek marble column ruin, top-down three-quarter view, "
        "Kingdom Rush style", True, 512, 512),
    "statue": ("2D cartoon greek marble warrior statue on a pedestal, top-down three-quarter "
        "view, Kingdom Rush style", True, 512, 512),
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
        tw = 512 if not transparent else 192  # chao em 512 = pixels menores/mais detalhe
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
