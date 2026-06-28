# Notas da madrugada — Mithos TD

> Trabalho autônomo enquanto você dormia. Aqui ficam as **decisões que tomei**,
> o que **entreguei**, o que **ficou pendente/incerto** e **como testar**.
> Cada bloco foi commitado separadamente (veja `git log`).

Data de início: 2026-06-28 (madrugada). Base: MVP completo (Camadas 1–6, commit `c8f5a33`).

## O que você pediu
1. Implantar **todos os personagens** comentados (grego, nórdico, japonês, brasileiro…) — **mínimo 50**, à minha escolha.
2. **Atributos profundos** estilo Ragnarok (força, agilidade, vel. de ataque, inteligência, destreza, sorte, vel. de movimento…).
3. **Posicionamento livre** das torres no mapa, com restrição: **melee (Guerreiro) só no meio da rota**, **ranged (Arqueiro/Mago/Sacerdote) só nas laterais**.
4. **Melhorar o visual** + botões padrão: **abandonar partida, pause, lançar onda, fase de preparação** antes da onda.
5. **Balancear** atributos e ouro.

## Decisões de design que tomei (sem poder te perguntar)
- **Atributos (estilo Ragnarok):** STR, AGI, VIT, INT, DEX, LUK. Cada um deriva stats por fórmula (ver `scripts/attribute_set.gd` e `scripts/attribute_stats.gd`). Vel. de movimento e vel. de ataque saem de AGI; sorte (LUK) dá **crítico** e ouro extra.
- **50+ personagens:** gerados por **arquétipos** (presets de atributos por papel) para manter balanço e permitir volume. 6 mitologias.
- **Sacerdote conta como "ranged"** para fins de zona (fica nas laterais). Só o Guerreiro é melee/centro.

## Status por bloco
(atualizado conforme avanço — veja o fim do arquivo para o estado final)

- [x] **Bloco 1 — Atributos + derivação + crítico** (commit). `AttributeSet` (STR/AGI/VIT/INT/DEX/LUK), `AttributeStats` (deriva todos os stats por classe — **ajuste de balanço centralizado aqui**), crítico (LUK/DEX → chance + multiplicador, projétil laranja no crit), vel. de movimento dos bloqueadores via AGI.
- [x] **Bloco 2 — 56 personagens em 7 mitologias** (commit). `Archetypes` (8 presets) + `Roster` (Grega, Nórdica, Japonesa, Brasileira, Egípcia, Chinesa, Asteca). Hub reescrito com **filtro por mitologia + scroll**. Todos desbloqueados (livre escolha).
- [x] **Bloco 3 — Posicionamento livre com zonas** (commit `6199cf1`). Clica em qualquer lugar; Guerreiro só na faixa do meio (< 48px da rota), ranged só nas laterais. Faixa translúcida mostra a zona; toast avisa posição inválida. Esquadrão (6) é o limite de torres.
- [x] **Bloco 4 — Fase de prep + botões de partida** (commit). Botões: **Lancar Onda** (inicia a 1ª / antecipa a próxima com bônus de ouro), **Pause**, **x1/x2** (velocidade) e **Abandonar**. Fase de preparação antes da 1ª onda. `MatchHud` (process ALWAYS p/ funcionar em pause), `WaveManager` refatorado.
- [x] **Bloco 5 — Melhorias visuais** (commit). Mapa com fundo + caminho com borda + base/entrada; **forma própria por classe de torre** (Arqueiro=triângulo, Mago=losango, Guerreiro=quadrado, Sacerdote=círculo+aura), sombras, pips de nível; inimigos com contorno; HUD com painel de fundo + cores; mensagem central de vitória/derrota centralizada. Crítico já pinta o projétil de laranja. **Sem assets externos** (tudo via `_draw`). Auto-stage agora posiciona o esquadrão sozinho (demo jogável).
- [x] **Bloco 6 — Balanceamento + notas** (commit). Simulei as 5 fases (esquadrão variado posicionado, **sem habilidades** = pior caso): **todas vencíveis, incluindo o boss Tálos**. Como vencia com folga, ajustei: ouro inicial 180→**220**, dificuldade da fase 4 (1.5→1.6) e 5 (1.8→**2.1**), ouro da demo 3000→1500. Detalhes de balanço abaixo.

## Como testar amanhã
- Abrir o jogo: `C:/Godot/Godot_v4.7-stable_win64.exe --path c:/projetos/jogoTD`
- Rodar os testes: `Godot..._console.exe --headless --path c:/projetos/jogoTD -s res://test/test_runner.gd`
- Smoke da partida (sem input): `... --quit-after 6000 -- --auto-stage`

## Sessão seguinte (com você acordado) — definições novas
- **Combate melee redesenhado:** personagens melee (Guerreiro; Sacerdote pode ser melee no futuro) **tankam onde forem postos**, travam vários inimigos (capacidade escala STR+VIT+estrelas), levam dano com **defesa/esquiva/regeneração/lifesteal** e, ao cair, **se recuperam** após alguns segundos. Acabaram os "bloqueadores" gerados (BlockerUnit removido).
- **Atributos profundos:** 6 primários (Força/Agilidade/Vitalidade/Inteligência/Destreza/Sorte) que derivam muitos secundários (ATK, defesa, vel. ataque, alcance, crítico, esquiva, regen, lifesteal, penetração, redução de cooldown, capacidade de bloqueio). Inimigos ganharam **defesa** (penetração fura). Tudo em `attribute_stats.gd`.
- **Posicionamento 100% livre** (zonas removidas).
- **Prep de 10s** antes da 1ª onda (com contador) + **abandono com confirmação**.
- Decidido com você; pendências abaixo continuam valendo.

## Habilidades únicas (B8)
- **56 habilidades temáticas** (nome do mito por personagem) reaproveitando **11 famílias de efeito**: dano em área, perfurante (LINE), raio em cadeia (CHAIN), atordoar (STUN), lentidão (SLOW), empurrão (KNOCKBACK), veneno/fogo (DOT), buff de torres, cura de aliados, escudo de aliados e invocar aliado (SUMMON). Catálogo em `scripts/abilities.gd` (mexer aqui muda nome/efeito/números). Inimigos ganharam status: lentidão, DoT e knockback (`enemy.gd`).
- Pendente (polish): os efeitos ainda são por FAMÍLIA (ex.: vários "dano em área" idênticos em números); dá pra afinar números por personagem depois. Nomes/temas já são únicos.

## Conquista de personagens (B9)
- **Gating religado:** começa com **7 iniciais** (1 por mitologia, `Roster.STARTERS`); o resto é conquistado.
- **4 caminhos:** (1) **fases** de campanha desbloqueiam um herói cada (`STAGE_UNLOCKS`); (2) **quests** (campanha + diárias) dão Ambrosia (`scripts/quests.gd` + tela `quests_screen.gd`); (3) **gacha** "Altar dos Deuses" gasta Ambrosia, sorteia por raridade — novo desbloqueia, repetido vira **fragmentos** (`gacha_screen.gd`); (4) **loja** recruta heróis bloqueados com Ambrosia (na `collection_screen.gd`).
- **Moedas:** Ambrosia (gacha/recrutar, ganha jogando) · Ouro meta (loja de itens) · Fragmentos por personagem (evoluem estrelas) · Essência (secundária).
- **Evolução de estrela** agora gasta **fragmentos do personagem + ouro** (era essência).
- Raridade por personagem em `Roster.rarity_of` (Comum/Raro/Épico/Lendário) — afeta chance do gacha, preço e fragmentos.
- Botões no Hub: Coleção/Loja, Altar (Gacha), Missões. Atalhos de smoke: `-- --gacha`, `-- --quests`.

## Onde mexer no balanceamento (centralizado)
- **Fórmulas de stats por atributo:** [scripts/attribute_stats.gd](scripts/attribute_stats.gd) — muda TUDO de uma vez (dano, alcance, cadência, vida de bloqueador, aura, crítico).
- **Atributos por arquétipo:** [scripts/archetypes.gd](scripts/archetypes.gd) — base e crescimento por nível de cada papel.
- **Dificuldade/recompensa das fases:** [scripts/stage_list.gd](scripts/stage_list.gd) — vida/contagem dos inimigos, XP por fase.
- **Inimigos:** [scripts/greek_bestiary.gd](scripts/greek_bestiary.gd) — vida, velocidade, ouro de cada um.
- **Composição das ondas:** [scripts/wave_composer.gd](scripts/wave_composer.gd).
- **Economia da partida:** `START_GOLD` em [scripts/game_screen.gd](scripts/game_screen.gd); `wave_bonus`/`early_bonus` em [scripts/wave_manager.gd](scripts/wave_manager.gd).
- **Custos/venda/upgrade:** constantes no topo de [scripts/tower.gd](scripts/tower.gd).
- **Zonas de posicionamento:** `MELEE_BAND`/`MIN_SPACING` em [scripts/build_manager.gd](scripts/build_manager.gd).
- **Recompensas meta (loja):** `grant_rewards`, `evolve_cost` em [scripts/progression_manager.gd](scripts/progression_manager.gd).

## Pendências / incertezas (ler!)
1. **Balanço fino precisa de PLAYTEST humano.** Minha simulação dá ouro generoso e não usa habilidades; não reflete a economia real (ouro limitado, ganho ao longo da fase). Joga e me diz se está fácil/difícil demais.
2. **Todos os 56 personagens começam desbloqueados** (decisão p/ "livre escolha"). Se quiser progressão de coleção, dá pra religar o gating por fase/loja (a infra `unlock_stage`/`mark_stage_cleared` continua lá).
3. **Habilidades reusam 5 tipos de efeito** entre os 56 (nomes por arquétipo, não únicos). Cada mitologia/personagem ainda não tem efeito 100% único — bom alvo de polish.
4. **Variações por personagem são pelo arquétipo** (8 moldes). Dois personagens do mesmo arquétipo são mecanicamente iguais (só nome/mito diferem). Dá pra individualizar atributos depois.
5. **Uma rota só** reutilizada em todas as fases (variações de slot/onda/dificuldade). Rotas geográficas por fase ficam para o editor.
6. **Visual é todo `_draw`** (formas/cores), sem arte. Funcional e limpo, mas placeholder.
7. **Coleção/Loja** lista os 56 numa rolagem longa, sem filtro por mitologia (o Hub tem filtro; a Coleção não). Fácil de adicionar.
8. **Save do dev** pode ter progresso dos meus testes — apague `user://mithos_save.json` se quiser começar limpo (no Windows: `%APPDATA%/Godot/app_userdata/Mithos TD/`).

## Resumo do que rodar
- **Jogar:** abrir o projeto no Godot e dar Play (ou o exe sem `--headless`).
- **Ver uma demo automática:** `Godot...win64.exe --path . -- --auto-stage 3` (joga a fase 3 sozinho, com torres posicionadas). Troque o número (1–5).
- **Abrir direto na Loja:** `... -- --collection`.
- **Testes:** `Godot..._console.exe --headless --path . -s res://test/test_runner.gd` → **132/132**.

Tudo commitado na branch `main` (6 commits "Madrugada Bn"). **Não fiz push** — me peça se quiser enviar pro GitHub.
