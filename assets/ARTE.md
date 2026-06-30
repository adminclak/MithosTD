# Arte do Mithos TD — guia + prompts prontos (ComfyUI / SDXL)

O jogo carrega sprites automaticamente **se** o arquivo existir; senão desenha um
placeholder. Então dá pra adicionar arte aos poucos, sem mexer no código.

## Convenção de arquivos
- Heróis:   `assets/heroes/<id>.png`   (ex.: `assets/heroes/zeus.png`)
- Inimigos: `assets/enemies/<id>.png`  (ex.: `assets/enemies/talos.png`)

**Formato:** PNG quadrado, fundo transparente, **256×256** (o jogo redimensiona).
Personagem de corpo inteiro, centralizado. Depois de copiar os PNGs, abra o
projeto no Godot uma vez (ele importa as imagens) e rode.

---

## Geração via API PAGA (qualidade alta — recomendado p/ o roster final)
`tools/gen_api.py` gera pela **fal.ai** (modelos top: FLUX/Seedream/Recraft),
reaproveitando as descrições deste arquivo + um estilo fixo (cartoon pintado HD).
Custa centavos por imagem.

1. Conta em https://fal.ai → adicione créditos → copie a API key (Dashboard → Keys).
2. No Git Bash, exporte a chave e rode com o **python do ComfyUI** (tem requests+PIL):
```
export FAL_KEY="xxxx:yyyy"
PY="C:\Users\leoar\AppData\Local\Comfy-Desktop\ComfyUI-Installs\ComfyUI\standalone-env\python.exe"
"$PY" tools/gen_api.py heroes zeus artemis medusa   # testa 2-3 p/ travar o estilo
"$PY" tools/gen_api.py heroes all                   # depois, o resto
```
3. (Opcional) Fundo transparente: `"$PY" -m pip install rembg onnxruntime`.
Trocar de modelo: `export FAL_MODEL="fal-ai/bytedance/seedream/v3/text-to-image"`.

---

## Como usar no ComfyUI
O prompt final de cada personagem é:

> **`<ESTILO>` + `,` + `<descrição do personagem (abaixo)>`**

E no campo **negativo** use sempre o mesmo `<NEGATIVO>`.

### ESTILO (cole no começo de TODO prompt positivo)
```
2D cartoon game character, mascot style, cute, vibrant saturated colors, bold clean outlines, soft cel shading, full body, single character, centered, front view, dynamic heroic pose, plain light gray background, mobile tower-defense hero, Kingdom Rush and Brawlhalla art style, crisp, high quality
```

### NEGATIVO (cole no campo negativo — igual para todos)
```
photorealistic, realistic, 3d render, photograph, blurry, low quality, lowres, jpeg artifacts, extra limbs, extra fingers, deformed, mutated, bad anatomy, text, words, letters, watermark, signature, logo, multiple characters, duplicate, cropped, out of frame, dark, gritty, horror gore
```

### Configurações sugeridas
**Modelo instalado: `DreamShaperXL_Turbo_V2-SFW` (SDXL Turbo).** Como é TURBO, use
poucos steps e CFG baixo (senão a imagem "queima"):
- Resolução: **1024×1024** · Steps: **7** (6–8) · CFG: **2.0** (1.5–2.5)
- Sampler: **dpmpp_sde** · Scheduler: **karras**
- (Se um dia trocar por um SDXL **normal** — não-Turbo — volte para Steps **30**, CFG **6–7**, sampler **dpmpp_2m**.)

- **Consistência:** mantenha o MESMO checkpoint e o MESMO ESTILO em todos. Para um traço idêntico entre os 64, fixe uma seed boa ou use IPAdapter com 1 imagem de referência.
- **Transparência:** instale o custom node **ComfyUI-LayerDiffuse** → gera o personagem já recortado (PNG transparente). Sem ele, gere com fundo liso e use remove.bg / rembg.
- Se faltar VRAM (erro "out of memory"): gere em 832×832.

> Dica de cor por classe (opcional, p/ leitura rápida em jogo): Arqueiro=azul,
> Mago=roxo, Guerreiro=vermelho, Sacerdote=dourado/branco. Pode citar a cor no prompt.

---

## HERÓIS — descrição por personagem (arquivo = `<id>.png`)

### Grega
- `artemis.png` — Artemis, greek goddess of the hunt, young agile huntress, silver longbow and arrow, crescent moon emblem, white and gold short tunic, archer
- `hermes.png` — Hermes, greek messenger god, winged sandals and winged helmet, fast and nimble, holding a short bow, blue accents, archer
- `hercules.png` — Heracles, mighty greek hero, very muscular, lion pelt hood, wooden club, red accents, melee warrior tank
- `ares.png` — Ares, greek god of war, fierce, crested helmet, red battle armor, spear and round shield, melee warrior
- `atena.png` — Athena, greek goddess of wisdom and war, golden armor, spear, aegis shield, owl companion, supportive aura, priest
- `apolo.png` — Apollo, greek god of sun and healing, golden laurel wreath, lyre, radiant warm light, healer, priest
- `medusa.png` — Medusa, a beautiful but fierce woman, on her head she has NO hair at all, instead many small green snakes grow out of her scalp like hair (snakes replacing her hair), feminine female face, glowing green eyes, green scaled skin, snake-tail lower body, holding a magic staff, green and teal tones
- `zeus.png` — Zeus, king of the greek gods, mighty bearded man wearing a white tunic and toga (fully clothed), crackling lightning bolt in hand, golden aura, mage

### NPCs (loja)
- `merchant.png` — friendly cheerful greek market merchant shopkeeper, plump bearded man, simple cream tunic with a brown leather apron, olive wreath, holding up a clay amphora and a coin pouch, welcoming open-hand gesture, warm inviting smile, NOT a warrior, no weapon

### Nórdica
- `heimdall.png` — Heimdall, norse guardian of the rainbow bridge, golden horn Gjallarhorn, watchful eyes, ornate armor, archer
- `ullr.png` — Ullr, norse god of archery and winter, fur cloak, bow, snow and ice theme, skis, archer
- `thor.png` — Thor, norse god of thunder, red cape, warhammer Mjolnir, lightning sparks, braided beard, melee warrior
- `tyr.png` — Tyr, norse war god with one hand, sturdy shield and sword, stoic guardian, melee warrior tank
- `freya.png` — Freya, norse goddess of love and war, falcon-feather cloak, golden necklace, gentle healing light, priest
- `frigg.png` — Frigg, norse queen goddess of foresight, regal blue gown, spindle, serene, supportive, priest
- `odin.png` — Odin, norse allfather, one eye, eyepatch, two ravens, spear Gungnir, grey beard, magic runes, mage
- `loki.png` — Loki, norse trickster god, sly grin, green and gold outfit, swirling mischievous green flames, mage

### Japonesa
- `tsukuyomi.png` — Tsukuyomi, japanese moon god, elegant pale robes, crescent moon, moonlight bow, calm, archer
- `hachiman.png` — Hachiman, japanese god of war and archery, samurai armor, yumi longbow, dove emblem, archer
- `susanoo.png` — Susanoo, japanese storm god, fierce, katana Kusanagi, dark armor, storm clouds, melee warrior
- `benkei.png` — Benkei, giant japanese warrior monk, naginata polearm, many weapons on back, loyal guardian, melee tank
- `amaterasu.png` — Amaterasu, japanese sun goddess, radiant white and gold kimono, glowing sun halo, supportive, priest
- `kannon.png` — Kannon, japanese goddess of mercy, serene, white robes, lotus, soft healing light, priest
- `raijin.png` — Raijin, japanese thunder god, muscular oni-like, ring of taiko drums, lightning, mage
- `fujin.png` — Fujin, japanese wind god, green skin, large wind bag over shoulders, gusts of wind, mage

### Brasileira
- `curupira.png` — Curupira, brazilian folklore forest guardian, bright flaming red hair, backwards feet, agile, blowgun, green leaves, archer
- `anhanga.png` — Anhanga, brazilian spectral protector deer spirit, ghostly translucent, glowing fiery eyes, archer
- `mapinguari.png` — Mapinguari, brazilian giant sloth-like beast, thick brown fur, tough armored hide, mouth on belly, melee tank
- `cuca.png` — Cuca, brazilian folklore witch with alligator head, blond hair, claws, green, fierce, melee warrior
- `iara.png` — Iara, brazilian mermaid of the rivers, green hair, fish tail, enchanting, healing water aura, priest
- `boto.png` — Boto, brazilian pink river dolphin shapeshifter, charming man in white suit and straw hat, supportive, priest
- `saci.png` — Saci, brazilian one-legged trickster boy, red magic cap, smoking pipe, spinning whirlwind, mischievous, mage
- `boitata.png` — Boitata, brazilian giant fiery serpent, glowing fire eyes, body of flames, mage

### Egípcia
- `horus.png` — Horus, egyptian falcon-headed god, Eye of Horus, blue and gold, bow, archer
- `neith.png` — Neith, egyptian goddess of war and hunt, bow and crossed arrows, red crown, weaver, archer
- `anubis.png` — Anubis, egyptian jackal-headed god of the dead, black and gold, khopesh sword, guardian, melee tank
- `set.png` — Set, egyptian god of chaos and storms, strange beast head, fierce, red desert tones, melee warrior
- `isis.png` — Isis, egyptian goddess of magic, large feathered wings, gold and turquoise, healing, priest
- `thoth.png` — Thoth, egyptian ibis-headed god of wisdom, scribe scrolls, blue and gold, supportive, priest
- `ra.png` — Ra, egyptian sun god, falcon head with golden sun disk, blazing fire, mage
- `sekhmet.png` — Sekhmet, egyptian lioness war goddess, fierce, sun disk, red and gold, fire and plague, mage

### Chinesa
- `houyi.png` — Hou Yi, legendary chinese archer who shot down the suns, mighty ornate red and gold bow, heroic, archer
- `nezha.png` — Nezha, chinese child deity, flaming wind-fire wheels under feet, red ribbon sash, spear, archer
- `sunwukong.png` — Sun Wukong, the Monkey King, golden staff, monkey fur, golden headband, armor, mischievous, melee warrior
- `guanyu.png` — Guan Yu, chinese general, red face, long black beard, green robe, guandao polearm, loyal, melee tank
- `nuwa.png` — Nuwa, chinese creator goddess, upper body human lower body serpent, mending the sky, colorful stones, priest
- `guanyin.png` — Guanyin, chinese goddess of mercy, flowing white robes, willow branch and vase, healing, priest
- `longwang.png` — Long Wang, chinese dragon king, blue-green dragon, water and rain, pearl, mage
- `erlang.png` — Erlang Shen, three-eyed chinese warrior god, glowing third eye beam, armor, loyal dog, mage

### Asteca
- `mixcoatl.png` — Mixcoatl, aztec god of the hunt and stars, atlatl spear-thrower, starry night patterns, archer
- `camazotz.png` — Camazotz, aztec bat god, dark leathery wings, sharp fangs, night theme, archer
- `huitzilo.png` — Huitzilopochtli, aztec sun and war god, hummingbird feathers, fire serpent weapon Xiuhcoatl, blue and gold, melee warrior
- `mictlan.png` — Mictlantecuhtli, aztec god of the dead, skull face, bones, dark underworld theme, melee tank
- `xochi.png` — Xochiquetzal, aztec goddess of flowers and love, floral headdress, butterflies, colorful, healing, priest
- `tezca.png` — Tezcatlipoca, aztec god of night, obsidian smoking mirror, jaguar pelt, dark and gold, supportive, priest
- `quetzal.png` — Quetzalcoatl, the feathered serpent, vibrant green and gold feathers, wind and lightning, mage
- `tlaloc.png` — Tlaloc, aztec rain god, goggle eyes, fangs, blue water and storm, jade, mage

---

## INIMIGOS — descrição por inimigo (arquivo = `<id>.png`)
Para estes, troque no ESTILO "mobile tower-defense hero" por "tower-defense enemy
monster", e pode usar "cute but menacing".

- `lacaio.png` — small dark imp minion of the underworld, little horns, red skin, basic weak enemy, cute but menacing
- `espectro.png` — fast ghostly wraith, translucent pale blue, wispy trailing form, swift, glowing eyes
- `esqueleto.png` — armored skeleton soldier, rusty shield and helmet, slow and tough, bone white
- `hidra.png` — small green multi-headed hydra serpent, three heads, scaly, swamp theme
- `hidra_filhote.png` — tiny baby hydra, single head, big eyes, light green, cute small enemy
- `centauro.png` — fierce centaur warrior, half man half horse, war paint, bow or spear, elite enemy
- `ciclope.png` — big one-eyed cyclops giant, brutish, wooden club, mini-boss, intimidating
- `talos.png` — giant bronze automaton colossus, glowing molten cracks, ancient greek statue come to life, epic boss, imposing

---

> Comece pelos mais vistos: inimigos (lacaio, esqueleto, hidra, talos) e os heróis
> iniciais (artemis, odin, benkei, iara, horus, longwang, huitzilo).
