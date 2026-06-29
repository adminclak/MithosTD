# Análise dos TDs de referência (Godot 4) — o que vale replicar no Mithos

Baixei e li 3 repositórios em `~/Downloads/td-refs/`:
- **quiver-td** (`quiver-dev/tower-defense-godot4`) — template antigo do Quiver. Extra: *hit states*.
- **quiver-tutorial** (`quiver-dev/tower-defense-tutorial`, "Outpost Assault") — curso atual: FSM, economia, projéteis, explosões/sons.
- **ape-td** (`ape1121/Godot-4-Tower-Defense-Template`) — data-driven, drag-and-drop, upgrade/venda.

## Veredito rápido
O Mithos **já cobre os fundamentos** que esses templates ensinam:

| Sistema | Mithos já tem? | Onde |
|---|---|---|
| Upgrade de torre (níveis, custo, "Máximo") | ✅ | `build_manager.try_upgrade` / `tower.apply_upgrade` |
| Venda de torre (valor proporcional) | ✅ | `build_manager.sell` / `tower.sell_value` |
| Menu radial ao tocar a torre (Melhorar/Vender) | ✅ | `build_manager` + `build_menu` |
| Flash ao levar dano | ✅ (branco, 0.12s) | `enemy.take_damage` / `_flash` |
| Economia (gastar/ganhar ouro) | ✅ | `GameState.try_spend/add_gold` |
| Ondas com composição por fase + boss | ✅ | `wave_composer.compose` (lacaio/hidra/ciclope/Talos…) |
| Inimigo que se divide (premia AoE) | ✅ | hidra (fase 3) |
| Projétil que persegue o alvo | ✅ (homing simples) | `projectile.gd` (_target) |
| Poderes Supremos / ults | ✅ (os refs não têm) | `ultimates`/`ult_aimer` |
| Bestiário temático | ✅ (os refs têm 3-4 dinos genéricos) | `greek_bestiary.gd` |

Ou seja: **drag-and-drop, vida-de-torre, popup de compra** dos templates seriam *regressões* (o slot fixo + radial do Mithos é mais fiel ao Kingdom Rush).

## Joias que VALE replicar (o que os refs fazem melhor/a mais)

### 1. Feedback de impacto rico — do `ape-td` (`enemy_mover.damage_animation`)
Hoje o Mithos só pisca branco. O ape-td faz um tween com **recuo + "pulinho" (squash) + flash laranja-avermelhado**:
```gdscript
var tween := create_tween()
tween.tween_property(self, "modulate", Color.ORANGE_RED, 0.1)
tween.tween_property(self, "modulate", Color.WHITE, 0.3)
tween.parallel().tween_property(self, "v_offset", -5, 0.2)  # pulinho
tween.tween_property(self, "v_offset", 0, 0.2)
```
+ **número de dano flutuante** (damage popup) sobe e some. Alto impacto visual, baixo custo.

### 2. Slow-on-hit / "hit state" — do `quiver-td` (`states/hit.gd`)
Ao tomar dano, o inimigo **desacelera X% por Y segundos** e depois volta ao normal (usa pilha de estados). No Mithos vira um **atributo de torre** (ex.: torre de gelo/Poseidon aplica `slow`), agregando variedade tática sem refatorar tudo.

### 3. Arco/lob de projétil — do `quiver` (`missile.gd` faz curvatura)
Canhão/catapulta com **trajetória parabólica** (sobe e cai no alvo) em vez de linha reta — charme visual para torres pesadas. O `missile.gd` mostra a interpolação de velocidade; dá pra adaptar para um arco.

### 4. (Arquitetura, opcional) FSM genérico — do `quiver` (`state_machine.gd`+`state.gd`)
Máquina de estados reutilizável. **Só vale** se formos adicionar inimigos com comportamento (parar-e-atirar, fugir do campeão, enrijecer). É refactor grande do `enemy.gd` atual (que usa `_process`); adiar até precisarmos desses comportamentos.

## O que NÃO replicar (seria regressão no estilo KR)
- **Drag-and-drop de torre** (ape-td): o slot fixo + radial é mais KR.
- **Vida/HP + reparo de torre** (quiver): em KR a torre não morre (só os soldados do quartel, que já temos como Reforços).
- **Popup de menu de compra** estilo lista: o radial atual é melhor.

## Padrões de código bons para imitar (sem mudar gameplay)
- **Spawn ponderado por probabilidade** (`spawner._pick_enemy`) e **gating por dificuldade** (`ape-td`: libera inimigos mais fortes conforme `current_difficulty` sobe). Hoje o `wave_composer` é fixo por fase — bom para design fino, mas o padrão ponderado escala melhor se quisermos ondas infinitas/endless.
- **`Shooter` como componente** (quiver): detecção por `Area2D`, rotação suave, `fire_rate` timer, `spread`. O `tower.gd` já faz o equivalente; manter como referência.

## Balanceamento aplicado (usando os refs como referência)
Os refs deram as **razões** (não os números crus, que são de outro estilo): em
`ape-td` `startingGold 100` compra ~2 torres (`cost 50`) e cada kill paga `10`
(razão custo/kill ~5:1); `quiver` usa `kill_reward 100` com torres caras. Daí o
modelo abaixo, verificado por `_test_balance()` no test runner:

- **Economia inicial**: `START_GOLD 220 -> 320` (compra ~3 torres baratas de 100).
  `wave_bonus 20 -> 25`. Kills financiam a expansão (lacaio paga 5 ≥ custo/25).
- **Ouro ≈ esforço**: recompensas normalizadas para a faixa 1.2–6.5 de vida/ouro
  (antes o ouro/vida era irregular: espectro 1.3 vs esqueleto 4.2). Ex.: esqueleto
  11→13, ciclope 30→38, Talos 120→160.
- **Curva de vida suave** (sem pico 50x): cada degrau ≤ ~4x o anterior
  (esqueleto 44 → centauro 60 → ciclope 140 → Talos 480). Talos era 650.
- **Escala de fase limitada**: `hp_mult` topo `2.1 -> 1.8` (e curva 1.0/1.2/1.35/
  1.55/1.8). O **boss efetivo na fase 5** caiu de 1365 para **864** (batível por um
  esquadrão focado, ~nível 4–5). `count_mult` topo 1.45 → 1.4.
- **Defesa**: subtração plana com piso 1 (mantida); defesas dos blindados afinadas
  (esqueleto 5→4, ciclope 8→7, Talos 14→12) para penetração/elemento valerem.

Invariantes ficam travados em `test/test_runner.gd::_test_balance` (7 checagens):
ouro inicial ≥ 3 torres, arqueiro inicial mata o básico em ~2s, ouro proporcional,
kill financia torres, curva suave, hp_mult crescente ≤ 2.0 e boss ef. ≤ 1000.
