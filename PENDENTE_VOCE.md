# O que eu preciso de você (quando voltar) 👋

Você ficou off e me deu autonomia. Avancei bastante. Aqui está o resumo e o que
depende de você pra gente continuar.

## ✅ O que eu já fiz enquanto você estava fora
1. **Provei que o 2.5D funciona no SEU Godot.** Tem um print novo:
   **`_shot_proof3d.png`** — um personagem 3D andando em cima do seu mapa Élis 2D,
   com um "capacete" (esfera dourada) **grudado no corpo, seguindo o osso**. É a
   prova de que "equipamento vestido no herói" funciona na batalha. (O capacete
   está deslocado porque o boneco de teste é um manequim grátis sem osso de cabeça
   de verdade — num herói real ele assenta certo.)
2. Confirmei que o **God Mode AI** gera **animação "queimada"** (sprite sheet), não
   esqueleto. Então ele NÃO serve pros heróis (que vão ser 3D), mas é **perfeito
   pros INIMIGOS** (sprites 2D). Não foi crédito perdido.
3. Pesquisei a melhor ferramenta de IA pra gerar os heróis 3D (abaixo).
4. Mantive o jogo intacto e os **268 testes verdes**. Não mexi na batalha que já
   funciona — isso só depois do seu OK.

## 🟡 Decisão/ação que depende de VOCÊ
### 1. Escolher e criar conta na ferramenta de geração 3D
Pra transformar os heróis 2D em 3D (riggados + animados), a recomendação é:

- **Meshy (meshy.ai)** — RECOMENDADO. Faz imagem→3D + **auto-rig** + **500+
  animações** + export **GLB** (formato do Godot), tudo num lugar. Tem tier grátis.
- Alternativa: **Tripo (tripo3d.ai)** — malha mais limpa, mas o rig no GLB tem
  ressalvas.

**O que eu preciso que você faça** (igual fez no God Mode):
1. Criar conta no **Meshy** (e/ou Tripo) — tier grátis primeiro.
2. Subir a arte do Hércules pra gerar o 3D. Use uma destas como entrada:
   - `assets/heroes/hercules.png` (a arte premium do jogo), ou
   - `assets/autorig/hercules.png` (a versão de corpo inteiro que preparei).
3. Gerar o modelo 3D, rodar o **Auto-Rig** e (se der) aplicar uma animação de
   **idle** + **walk** + **attack**.
4. Exportar em **GLB** e salvar em `c:\projetos\jogoTD\assets\models\hercules\`.
5. Me dizer: **(a)** quanto custou de crédito, **(b)** se o auto-rig saiu bom,
   **(c)** se o GLB exportado manteve o rig + animações.

### 2. (Opcional) Guardar a animação de inimigo do God Mode
Se ainda estiver aberta a tela do God Mode: baixe **Clean Sprite** + **Bbox JSON**
e salve em `assets/anim/hercules/`. Vai servir de referência pro pipeline de
inimigos 2D depois.

## ▶️ O que EU faço assim que você trouxer o GLB do herói
- Importo o herói 3D no jogo e ligo as animações.
- Construo a **batalha 2.5D** (mapa 2D vira o chão, heróis 3D em cima, UI por cima).
- Ligo o **equipamento por tier** ao corpo (elmo na cabeça, peito no torso, etc.)
  conectado ao seu inventário, que já existe.
- Mantenho os inimigos como sprites 2D (God Mode) pra ficar leve.

## ❓ Se quiser, me responda na volta
- Topa o **Meshy** como ferramenta? (ou prefere que eu detalhe o Tripo também?)
- Quer que os **inimigos** continuem 2D (sprites God Mode) e só os **heróis** 3D?
  (é o plano mais leve e bonito — recomendo)

Detalhes técnicos completos em **`NOTAS_3D.md`**.
