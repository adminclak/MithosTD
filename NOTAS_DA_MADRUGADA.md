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
- [ ] Bloco 6 — Balanceamento

## Como testar amanhã
- Abrir o jogo: `C:/Godot/Godot_v4.7-stable_win64.exe --path c:/projetos/jogoTD`
- Rodar os testes: `Godot..._console.exe --headless --path c:/projetos/jogoTD -s res://test/test_runner.gd`
- Smoke da partida (sem input): `... --quit-after 6000 -- --auto-stage`

## Pendências / incertezas (ler!)
(preenchido ao longo do trabalho)
