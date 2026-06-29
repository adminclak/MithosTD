# Notas — sessão de VISUAL (trabalho autônomo)

> Você pediu um salto visual ("está melhor mas ainda bem fraco"), com foco em
> **movimento/combate**, **cenários por mitologia**, **Poderes Supremos (ults)** e
> **testar todos os personagens**. Trabalhei com autonomia, em 2D, commitando por
> partes. Este doc resume tudo e as decisões.

## >>> MADRUGADA: KR puro (slots + campeão) + ANIMAÇÃO
(você saiu e pediu pra eu trabalhar a madrugada toda sozinho, foco em animação)

### Feito (tudo commitado, 184/184 testes, verificado por PRINTS via `--shot`)
- **Partida estilo Kingdom Rush (slots)**: pontos estratégicos fixos no mapa → toca
  → **menu radial** com as 4 torres + custo → constrói com ouro; toca na torre →
  **Melhorar / Vender**. (`build_manager.gd` + `radial_menu.gd` + slots no `level.gd`.)
- **Prédios das 4 torres** (arqueira / quartel / guilda de magos / templo) — geradas
  por IA, no lugar dos "bonecos".
- **ANIMAÇÃO de ações** (`anim.gd` → `Anim.draw_action`): o sprite é fatiado e cada
  fatia se move conforme a AÇÃO — **andar** (passada + bob + vira na direção),
  **atacar** (investida), **aguardar** (respiração), **defender** (agacha). Aplicado
  aos **inimigos** (andam de verdade, não só pulam).
- **CAMPEÃO** (`champion.gd`): **1 herói do esquadrão que ANDA no mapa** (clique no
  chão = mover, estilo KR), vai até os inimigos e luta (melee trava e bate / ranged
  atira), **cai e revive**. Tem barra de vida, coroa e anel do elemento; usa
  elemento/atributos/equip do herói.
- **HUD no layout KR**: HP/ouro/onda no canto, controles no topo, e **2 PODERES nos
  cantos inferiores** — **Reforços** (esquerda: invoca 3 soldados no ponto) e **Poder
  Supremo** (direita). Os dois carregam durante a partida e usam a mira no mapa.
- **Pop-up "ONDA X/Y"** em pergaminho no início de cada onda.
- Ferramenta: `--shot game` fotografa a PARTIDA (além dos menus) p/ eu iterar.

### ❓ PRECISO QUE VOCÊ RESPONDA AMANHÃ
1. **Campeão**: hoje o campeão é automaticamente o **1º herói do esquadrão**. Quer
   **escolher** qual herói é o campeão (na tela de Heróis)? E pode ter **mais de 1**
   campeão por partida?
2. **Onde os sistemas se aplicam**: como as torres são genéricas (KR puro),
   **elemento/equipamento/sets/sinergia** hoje fazem efeito **no campeão**, não nas
   torres. Tá certo assim, ou você quer esses sistemas valendo também nas torres?
3. **Animação — nível**: fiz animação **procedural** (corpo fatiado: anda/ataca/
   defende/aguarda) que vale pra TODOS automaticamente. O nível "estúdio" (ossos/
   Skeleton2D recortando cada herói em braço/perna) é **manual por personagem** e
   bem mais lento. Quer que eu faça o rig com ossos pra alguns (campeão + chefes)?
4. **Reforços/Ult**: os custos/recargas estão bons? (Reforços recarrega ~18s; ult
   ~28s.)

### Pendente (faço a seguir / amanhã)
- **Loja temática** (cena com balcão + vendedor, estilo KR) e card **"Novo Inimigo"**.
- Habilidade de assinatura do **campeão** disparando sozinha.
- Polir números (economia das torres com ouro, dano elemental visível).

## >>> ATUALIZAÇÃO 4: FOCO GREGO + sistemas + reskin Kingdom Rush
(sessão com brainstorm; referência **Kingdom Rush**; pixel mantido com "energia
Brawlhalla"; tom divertido)

- **Captura de tela p/ eu ver o jogo**: `Godot --path . -- --shot <title|worldmap|
  heroes|collection|gacha|quests>` salva `_shot_<tela>.png`. (Agora eu vejo cada
  tela e itero o visual. Você também pode jogar prints em `C:\Users\leoar\Downloads`.)
- **Foco grego**: `Roster.defs()` = só os 8 gregos (elenco completo em `defs_all()`);
  5 fases gregas; Zeus desbloqueia ao vencer a fase 5 (Olimpo).
- **Elementos** (🔥💧⛰🌪✨🌑): ciclo Água>Fogo>Terra>Ar>Água + Luz↔Trevas (+50%/-25%),
  por herói e inimigo, no combate (`elements.gd`).
- **Sets de equipamento** (2/4 peças): Olimpo/Asgard/Nilo (`equip_sets.gd`).
- **Sinergia de equipe**: mitologia / classe / elemento / duplas-trios icônicos
  (`synergy.gd`) — aparece na tela de Heróis.
- **3 equipes salvas** (abas Equipe 1/2/3) + tela de Heróis intuitiva (clicar p/
  entrar/sair, X fácil no rodapé, elemento e sinergias visíveis).
- **Menu reestruturado**: Tela-título (logo cartoon centralizado) → Mapa-múndi
  (nós com **estrelas** + **moldura de madeira** ornamentada estilo KR) / Heróis /
  Loja / Missões / Altar.
- **Reskin KR**: texturas geradas por IA (`gen_ui.py`): **madeira** (fundo),
  **pergaminho** (painel 9-slice), **moldura** (cantos dourados, centro vazado).
  Aplicado em Heróis/Loja/Gacha/Missões + moldura no mapa.
- **Aprendizado**: IA é ótima p/ arte orgânica (heróis, banner, emblema, texturas)
  e RUIM p/ botão/painel retangular limpo → use kit/StyleBox p/ botões.
- **183/183 testes.**

## >>> ATUALIZAÇÃO 3: UI nova, Poder Supremo, esquadrão salvo, mapa e padronização
(sessão com você saindo 1h; autonomia total)

**Você não precisa importar nada** — baixei tudo por terminal: fontes OFL
(Press Start 2P / Jersey 15 / VT323) e o **kit de UI Kenney (CC0)**. (Canal pra me
dar arquivos no futuro: salvar em `C:\Users\leoar\Downloads`.)

Feito e commitado (170/170 testes + smoke a cada passo):
- **UI com cara de jogo**: tema global (fonte + molduras 9-slice Kenney) em TODAS
  as telas — botões/painéis bonitos. `UiTheme.apply(get_window())`.
- **Poder Supremo CONSERTADO e direcionado**: clica no botão → tela escurece com
  **mira** → **clica no mapa** → animação dispara numa CanvasLayer **acima de
  tudo** (antes não aparecia nada). Corrigi o bug do botão (âncora) e a captura do
  clique (via `_input`).
- **Barras de baixo rotuladas**: "ESQUADRÃO (clique p/ posicionar)" e
  "HABILIDADES (heróis em campo)" — você tinha perguntado o que eram.
- **Menu HD**: `menu_bg` regerado em **alta resolução** (ilustração, sem o pixel
  borrado de antes).
- **Esquadrão salvo**: a comp montada agora **persiste** (Progression.squad/ult);
  a Hub carrega ao abrir e salva ao alterar. Lista mostra a **arte** de cada herói.
- **Padronização dos personagens** ✅: `tools/normalize_sprites.py` deixa todos no
  **mesmo tamanho/base** (recorta, escala p/ altura fixa, ancora os pés). Rodado
  nos 64.
- **Mapa mais bonito**: sombra + listra central no caminho, mais decorações
  (espelhadas) e **vinheta** de profundidade.

### Animação + itens vestidos — ENTREGUE (versão automatizável) ✅
Você disse "pode rushar, faz no máximo". Como recortar **cada um dos 64** em peças
limpas não é viável em lote (a IA gera o boneco "fechado"), entreguei o **máximo
que funciona pra todos automaticamente**:
- **Animação de corpo por deformação** (`Anim.draw_swayed`): o sprite é desenhado
  em fatias com uma onda lateral → o personagem **curva, balança e respira**, e
  **inclina ao atacar** (lean). Inimigos ganham **balanço de caminhada**. Bem mais
  vivo que o "pulo" — e aplicado a todos sem arte nova.
- **Itens vestidos no boneco**: o equipamento (elmo / arma / escudo) aparece
  **desenhado sobre o personagem** em campo, usando os ícones pixel dos itens.

### Polimento OPCIONAL futuro (manual, por personagem)
- **Rig 2D com membros 100% independentes** (braço/antebraço separados via
  `Skeleton2D`): exige recortar cada herói em peças à mão (a IA não separa limpo).
  É um trabalho por personagem; dá pra fazer aos poucos nos principais se você
  quiser esse nível. A deformação atual já cobre "ter movimento" pra todos.

## >>> ATUALIZAÇÃO 2: PIXEL ART (estilo Tangy TD) + SISTEMA DE ITENS
Você pediu pra migrar o visual pra **pixel art 2D** (referência Tangy TD) e criar
**centenas de itens** (míticos + básicos estilo Tibia). Feito e commitado:

- **Pipeline pixel art**: baixei o LoRA *Pixel Art XL* e adaptei o ComfyUI.
  `gen_art.py` tem modo PIXEL (LoRA + transparência + downscale nearest);
  `gen_scenery.py` e `gen_items.py` idem. Godot configurado p/ filtro **nearest**.
- **64 personagens** (56 heróis + 8 inimigos) **regerados em pixel art** (transparentes).
- **Cenários em pixel**: 7 chãos por mitologia + castelo, portal, decorações e o
  fundo de menu (templo ao pôr do sol).
- **Sistema de itens (8 slots estilo Tibia)**: elmo, peito, pernas, botas, arma,
  escudo, amuleto, anel. **203 itens** = básicos (por material: couro→mithril,
  obsidiana, dragão...) + **47 lendários míticos** (Mjölnir, Égide de Atena, Olho
  de Odin, Gorro do Saci, Macuahuitl, Kusanagi, Tridente de Poseidon...).
- **55 ícones em pixel** (8 genéricos por slot + 47 lendários), aparecendo na loja
  e nos slots da Coleção.
- Loja/Coleção atualizadas (grade de 8 slots, cor por raridade, efeitos no texto).
- **170/170 testes** (inclui 8 slots e contagem ≥200) + smoke limpo.

Pendências/ideias: tela de "ficha do personagem" dedicada aos 8 slots com a arte
grande; curar itens/sprites fracos; aplicar pixel também na fonte/HUD se quiser.

## Decisão importante: continuei em 2D (não migrei para 3D)
Você sugeriu "talvez migrar para 3D". **Não migrei** — de propósito. Migrar
exigiria refazer o jogo e usar modelos/rigs/animações 3D, que o ComfyUI **não
gera** de forma utilizável em lote; o resultado na sua volta seria um jogo
quebrado, não "mais bonito". O caminho que entrega beleza de verdade agora é 2D
com sprites + animação por código + cenários temáticos. **3D fica como decisão
pra conversarmos** (se for o rumo, é um projeto à parte, com pipeline de assets 3D).

## O que entreguei nesta sessão (tudo testado: 167/167 + smoke limpo)
### 1. Projéteis de verdade  (commit "Visual combate")
- **Flecha** que gira na direção do voo (haste + ponta + penas) — Arqueiro.
- **Bola de fogo** chamejante que pulsa e **explode** no impacto — Mago (splash).
- **Raio mágico** (orbe com brilho) — Mago alvo único e Sacerdote.
- **Rastro** nos projéteis + **efeito de impacto** (HitEffect: faísca/explosão).

### 2. Movimentação / animações de ataque  (mesmo commit)
- **Respiração idle**: todos os personagens "respiram" parados.
- **Arqueiro**: recua ao atirar, com **arco e corda** que flexionam.
- **Mago**: **orbe de conjuração** acende na ponta do cajado ao lançar.
- **Espadachim** (DPS): **espadada** (arco de swoosh) varrendo na direção do alvo.
- **Escudeiro** (tanque): **escudo** que avança (block shove) ao golpear.
- **Sacerdote**: **halo** dourado + **aura pulsante**.
- Inimigos: balanço ao andar + flash branco ao apanhar (sessão anterior).

### 3. Poderes Supremos / ULTS  (commit "Poder Supremo")
- **1 ult por partida**, escolhido **conforme o personagem do esquadrão** (seletor
  no menu antes de jogar).
- Botão grande na HUD com **barra de carga** (enche durante as ondas); **acende**
  quando pronto. Recarregável (dá pra usar mais de uma vez por partida).
- **Animações de tela cheia** por estilo: meteoro, raio+flash, dilúvio, luz
  divina, nevasca, inferno, terremoto (anéis), vazio.
- Ults **com assinatura** para os icônicos (Zeus=Ira do Olimpo/raio, Poseidon=
  Maremoto, Medusa=Olhar Petrificante, Ra=Sol Abrasador, etc.); os demais herdam
  um estilo pela classe. Efeito forte em todos os inimigos da tela.

### 4. Cenários por mitologia  (commit "Cenarios por mitologia")
- **7 chãos temáticos** gerados (grega, nórdica/neve, egípcia/areia, brasileira/
  selva, chinesa/jade, japonesa, asteca) em `assets/map/ground_<tema>.png`.
- A **campanha virou um tour**: Fase 1 Grécia → 2 Asgard (neve) → 3 Nilo (areia)
  → 4 Selva → 5 Templo de Jade. Cada fase muda chão, **cor do caminho** e
  **decorações**. (Japonesa e Asteca já têm chão pronto p/ fases futuras.)

### 5. Todos os 56 personagens agem  (commit "Sacerdotes agem")
- **Bug do Boto** (e de TODOS os sacerdotes): eles não atacavam, só emitiam aura
  → pareciam parados. Agora o Sacerdote tem **golpe sagrado** (raio dourado) e a
  **aura de cura** cura tanques próximos.
- **Teste novo** garante que os 56 agem em campo (ranged atira, melee trava/fere);
  pega "personagens parados" automaticamente. Rodei: todos passam.

## Pendências / decisões que dependem de você
- **3D ou 2D?** (ver decisão acima) — se quiser 3D, planejamos separado.
- Conferir o visual jogando (Play) e me dizer o que lapidar.
- Curar a arte dos 56 (regenerar fracos): `python tools/gen_art.py <id>`.
- Posso gerar **decorações temáticas** (cactos, totens, lanternas, runas) e
  **bosses/inimigos por mitologia** se quiser mais identidade por mundo.

## Como testar
- Menu/Jogo: abrir no Godot (Play).
- Linha de comando (joga sozinho): `Godot...win64.exe --path . -- --auto-stage 3`
  (troque o número p/ ver cada cenário; no modo auto a ult dispara sozinha).
- Testes: `Godot..._console.exe --headless --path . -s res://test/test_runner.gd`
  → 167/167.
