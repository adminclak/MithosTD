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
