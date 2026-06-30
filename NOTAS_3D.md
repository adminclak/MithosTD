# Notas técnicas — Virada 2.5D (heróis 3D sobre mapas 2D)

## Decisão (2026-06-30)
O usuário quer **equipamento vestido no herói DENTRO da batalha** e topou ir pro
3D pra isso. Escolha (via pergunta): **2.5D — heróis 3D sobre os mapas 2D**.
Motivo: no 3D, equipamento = "encaixar a malha no osso" (BoneAttachment3D) →
aparece em qualquer ângulo/animação, automático. Resolve de vez o problema que
travou no 2D (peça que não alinha / pose inconsistente da IA).

Caminhos descartados:
- **Rig modular por IA (2D):** poses inconsistentes, peças não alinham. REJEITADO.
- **God Mode AI (sprite generator):** saída é **animação baked** (sprite sheet/vídeo),
  NÃO Spine. Bom pra ANIMAÇÃO, mas equipamento fica "queimado". → reaproveitar
  pra **INIMIGOS** (sprites 2D billboard na cena 2.5D). Teste feito: walk do
  Hércules saiu em 29 frames, fundo transparente (RMBG-2.0), grade 4 colunas.
- **Spine 2D manual:** mantinha o look 2D, mas exigia rig manual por herói. Preterido.

## Proof de conceito (FEITO e validado)
Arquivos: `proof3d/proof.tscn` + `proof3d/proof_main.gd` + `proof3d/CesiumMan.glb`.
Resultado: `_shot_proof3d.png` — personagem 3D riggado andando sobre o mapa Élis 2D,
com uma esfera dourada (o "capacete") **grudada no osso** e seguindo o corpo.

Rodar:
```
"C:/Godot/Godot_v4.7-stable_win64_console.exe" --path . --rendering-driver opengl3 res://proof3d/proof.tscn
```

### Achados técnicos (Godot 4.7)
- **Carregar .glb em runtime SEM pipeline de import:** `GLTFDocument.append_from_file(path, state)`
  + `doc.generate_scene(state)`. Não precisa de `.import`. Ideal para assets que
  chegam depois (heróis gerados por IA).
- **Equipamento no corpo = `BoneAttachment3D`**: `ba.bone_name = <osso>`, adicionar
  como filho do `Skeleton3D`; a malha do item vira filha do BoneAttachment e segue
  o osso em qualquer pose. (CesiumMan só tem osso "neck", sem "head" → a esfera
  ficou deslocada; num modelo com osso de cabeça de verdade ela assenta certinho.
  O OFFSET local depende da orientação do osso — tunar por modelo.)
- **Mapa 2D como chão:** `PlaneMesh` no plano XZ + `StandardMaterial3D.albedo_texture`
  = o PNG do mapa. Lê lindo como a "mesa" do TD.
- **Câmera:** `Camera3D` angulada (~Kingdom Rush). `look_at()` SÓ funciona DEPOIS de
  `add_child` (precisa do transform global) — senão dá "Node not inside tree".
- **Captura:** precisa de renderer real (`--rendering-driver opengl3`); em `--headless`
  o viewport não renderiza. Esperar ~40 `process_frame` antes do `get_image()`.

### Atribuição do asset de teste
`CesiumMan.glb` = Khronos glTF Sample Assets (CC-BY 4.0). É só placeholder do proof;
sai quando entrarem os heróis reais. NÃO é asset final do jogo.

## Arquitetura planejada da batalha 2.5D (TRABALHO GRANDE, pendente)
> Só começar DEPOIS do OK do usuário + ter 1 herói 3D real. NÃO refatorar a
> batalha 2D que já funciona sem isso (quebraria o jogo que ele não pode revisar).

- **Cena de batalha vira `Node3D`:** mapa = quad de chão; câmera angulada fixa.
- **Heróis = modelos 3D** (com equipamento por BoneAttachment3D).
- **Inimigos = sprites 2D billboard** (animações God Mode) virados pra câmera —
  mais leve que 3D para muitos bichos; coeso com o estilo pintado.
- **UI = `CanvasLayer` 2D** por cima (a UI atual é toda Control → reaproveita).
- **Pathing/posicionamento:** converter coords 2D do mapa `(x, y)` → chão 3D
  `(x, 0, y)`. A lógica (waves, torres, dano) é matemática e sobrevive (268 testes).
- **Equipamento:** `item → (slot, tier) → malha` encaixada no osso do slot
  (cabeça=elmo, torso=peito, mão=arma, etc.). Mapear `EquipmentData.Slot` →
  nome do osso do rig padrão.

## Ferramenta de geração 3D — recomendação
**Meshy** (meshy.ai) para os heróis: image-to-3D + **auto-rig humanoide** + **500+
animações** + **plugin nativo Godot** + export **GLB** (formato nativo do Godot),
tudo numa plataforma só. Tier grátis pra testar.
- Alternativa: **Tripo** (topologia mais limpa, bom p/ criaturas/quadrúpedes), mas
  rigging em GLB tem ressalvas — verificar se o rig sobrevive no export.
- Plano: jogar a MESMA arte (a do Hércules 2D do jogo) nos dois grátis, exportar
  GLB, importar no Godot e comparar integridade do rig + limpeza necessária.
