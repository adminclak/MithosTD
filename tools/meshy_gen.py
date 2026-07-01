# -*- coding: utf-8 -*-
"""
Automatiza o pipeline 3D do Meshy pela API (image-to-3D -> rig -> baixa GLB).
Repete EXATAMENTE a receita que validamos na mao (Meshy 6, remesh 10K triangulo,
textura, a-pose, rig humanoide). Salva em assets/models/<id>/<id>.glb.

REQUISITOS:
- Meshy PRO (a API so existe no plano pago) + creditos.
- Chave de API do Meshy em MESHY_API_KEY (SEGREDO — nunca printar/expor).
  Pegue em https://www.meshy.ai -> API -> Create API key.
- Roda com o python do ComfyUI (tem requests):
  C:\\Users\\leoar\\AppData\\Local\\Comfy-Desktop\\ComfyUI-Installs\\ComfyUI\\standalone-env\\python.exe

USO:
  # valida SEM gastar credito (so imprime o que enviaria):
  python tools/meshy_gen.py hercules --dry-run
  # gera de verdade (gasta credito):
  python tools/meshy_gen.py hercules
  # varios de uma vez:
  python tools/meshy_gen.py hercules ares artemis

Entradas: por padrao usa assets/autorig/<id>.png (arte de corpo inteiro, de pe,
sem arma). Se nao existir, cai pra assets/heroes/<id>.png.
"""

import os
import sys
import time
import base64
import json

try:
    import requests
except ImportError:
    print("ERRO: rode com o python do ComfyUI (tem 'requests').")
    sys.exit(1)

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
API = "https://api.meshy.ai/openapi/v1"


def _load_dotenv():
    """Le PROJ/.env (KEY=valor por linha), so o que ainda nao esta no ambiente."""
    path = os.path.join(PROJ, ".env")
    if not os.path.exists(path):
        return
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            k = k.strip()
            v = v.strip().strip('"').strip("'")
            if k and k not in os.environ:
                os.environ[k] = v


_load_dotenv()
KEY = os.environ.get("MESHY_API_KEY", "")

# ---- RECEITA TRAVADA (a que validamos na mao) ----
AI_MODEL = "meshy-6"        # motor mais novo (o Hercules ficou otimo nele)
MODEL_TYPE = "standard"     # "lowpoly" tambem existe; remesh ja deixa leve
TARGET_POLYCOUNT = 10000    # ~10K = leve p/ mobile e detalhado p/ tela de Equipar
TOPOLOGY = "triangle"       # padrao de engine/Godot
POSE_MODE = "a-pose"        # reposiciona p/ A-pose -> rig MUITO melhor (mata o "torto")
SHOULD_TEXTURE = True
SHOULD_REMESH = True
HEIGHT_METERS = 1.8         # altura p/ escala do rig


def input_image_for(cid):
    for p in (os.path.join(PROJ, "assets", "autorig", cid + ".png"),
              os.path.join(PROJ, "assets", "heroes", cid + ".png")):
        if os.path.exists(p):
            return p
    return None


def to_data_uri(path):
    with open(path, "rb") as f:
        b = base64.b64encode(f.read()).decode("ascii")
    return "data:image/png;base64," + b


def _headers():
    return {"Authorization": "Bearer " + KEY, "Content-Type": "application/json"}


def _poll(url, label):
    """Consulta o status ate SUCCEEDED/FAILED. Devolve o objeto final."""
    last = -1
    while True:
        r = requests.get(url, headers=_headers(), timeout=60)
        r.raise_for_status()
        data = r.json()
        st = data.get("status", "")
        pr = int(data.get("progress", 0) or 0)
        if pr != last:
            print("    %s: %s %d%%" % (label, st, pr))
            last = pr
        if st in ("SUCCEEDED", "FAILED", "CANCELED"):
            return data
        time.sleep(5)


def image_to_3d(cid, dry=False):
    img = input_image_for(cid)
    if img is None:
        print("  (sem imagem de entrada p/ %s em assets/autorig|heroes)" % cid)
        return None
    body = {
        "image_url": to_data_uri(img),
        "ai_model": AI_MODEL,
        "model_type": MODEL_TYPE,
        "should_texture": SHOULD_TEXTURE,
        "should_remesh": SHOULD_REMESH,
        "target_polycount": TARGET_POLYCOUNT,
        "topology": TOPOLOGY,
        "pose_mode": POSE_MODE,
        "target_formats": ["glb"],
    }
    if dry:
        show = dict(body)
        show["image_url"] = "<data-uri de %s (%d KB)>" % (
            os.path.relpath(img, PROJ), os.path.getsize(img) // 1024)
        print("  [DRY] POST %s/image-to-3d" % API)
        print("        " + json.dumps(show, ensure_ascii=False))
        return "DRY_TASK_ID"
    r = requests.post(API + "/image-to-3d", headers=_headers(), json=body, timeout=120)
    if r.status_code >= 300:
        raise RuntimeError("image-to-3d %d: %s" % (r.status_code, r.text[:300]))
    tid = r.json().get("result")
    print("  image-to-3d task: %s" % tid)
    res = _poll(API + "/image-to-3d/" + tid, "mesh")
    if res.get("status") != "SUCCEEDED":
        raise RuntimeError("image-to-3d falhou: %s" % res.get("task_error"))
    print("    creditos gastos (mesh): %s" % res.get("consumed_credits"))
    return tid


def rig(cid, input_task_id, dry=False):
    body = {"input_task_id": input_task_id, "height_meters": HEIGHT_METERS}
    if dry:
        print("  [DRY] POST %s/rigging" % API)
        print("        " + json.dumps(body, ensure_ascii=False))
        return None
    r = requests.post(API + "/rigging", headers=_headers(), json=body, timeout=120)
    if r.status_code >= 300:
        raise RuntimeError("rigging %d: %s" % (r.status_code, r.text[:300]))
    tid = r.json().get("result")
    print("  rigging task: %s" % tid)
    res = _poll(API + "/rigging/" + tid, "rig")
    if res.get("status") != "SUCCEEDED":
        raise RuntimeError("rigging falhou: %s" % res.get("task_error"))
    print("    creditos gastos (rig): %s" % res.get("consumed_credits"))
    return res.get("result", res)


def download(url, cid, suffix=""):
    outdir = os.path.join(PROJ, "assets", "models", cid)
    os.makedirs(outdir, exist_ok=True)
    out = os.path.join(outdir, cid + suffix + ".glb")
    r = requests.get(url, timeout=180)
    r.raise_for_status()
    with open(out, "wb") as f:
        f.write(r.content)
    print("  OK -> %s (%d KB)" % (os.path.relpath(out, PROJ), len(r.content) // 1024))
    return out


def run(cid, dry=False):
    print("== %s ==" % cid)
    tid = image_to_3d(cid, dry=dry)
    if tid is None:
        return
    res = rig(cid, tid, dry=dry)
    if dry:
        print("  [DRY] baixaria rigged_character_glb_url -> assets/models/%s/%s.glb" % (cid, cid))
        return
    glb = res.get("rigged_character_glb_url")
    if glb:
        download(glb, cid)
    # animacoes basicas (andar/correr) que o rig ja devolve
    for name, urls in (res.get("basic_animations") or {}).items():
        u = urls.get("glb") if isinstance(urls, dict) else None
        if u:
            download(u, cid, suffix="_" + name)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry = "--dry-run" in sys.argv
    if not args:
        print(__doc__)
        return
    if not dry and not KEY:
        print("ERRO: defina MESHY_API_KEY (chave da API do Meshy PRO).")
        return
    for cid in args:
        try:
            run(cid, dry=dry)
        except Exception as e:
            print("  FALHA %s -> %s" % (cid, e))


if __name__ == "__main__":
    main()
