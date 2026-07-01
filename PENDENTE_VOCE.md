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

## 🟢 PLANO ATUAL (você vai assinar o Meshy PRO + eu automatizo pela API)
O grátis NÃO deixa baixar modelos Meshy 6 (paywall) e a API só existe no PRO.
Você decidiu assinar. Com o PRO, **eu automatizo tudo pela API** — você não clica
mais em cada herói. Script pronto e validado (dry-run): **`tools/meshy_gen.py`**.

**O que preciso de você (uma vez):**
1. Assinar o **Meshy PRO** (~US$20/mês; 1.000 créditos/mês — dá pro jogo todo; dá
   pra cancelar depois). O PRO também dá **licença privada** (sem crédito CC-BY).
2. No site: **API** (menu do topo) → **Create API key** → copie a chave.
3. Defina a variável de ambiente **`MESHY_API_KEY`** com essa chave (igual você fez
   com a `FAL_KEY`, via `setx MESHY_API_KEY <chave>`). **É segredo — não me mande a
   chave no chat.**
4. Me avise que está setada.

**Aí EU rodo** (gasta crédito, mas só quando validado):
```
python tools/meshy_gen.py hercules            # 1 herói de teste
python tools/meshy_gen.py ares artemis ...    # o resto em lote
```
O script faz: image→3D (Meshy 6, remesh 10K triângulo, textura, **a-pose**) → rig
humanoide → baixa o GLB em `assets/models/<id>/<id>.glb` (+ animações andar/correr).

**Plano de validação (pra acertar de primeira, sem desperdício):**
- Antes: eu gero as **imagens de entrada** de cada herói com o fal.ai (barato) e a
  gente **revisa** — assim todo crédito Meshy cai numa imagem boa.
- Teste: rodo **1 herói** (Hércules, entrada já provada), baixo, mostro no Godot,
  você aprova → só então rodo o **lote** dos outros.
- Custo: ~30 créditos (mesh) + rig por herói → 8 heróis ≈ 300–400 de 1.000. Sobra.

---
### (FALLBACK MANUAL, se não quiser API) Gerar no site — passo a passo
Ferramenta: **Meshy (meshy.ai)**. No PRO o download funciona. (No grátis, o Meshy 6
não baixa.)

**0. Conta:** entre em https://www.meshy.ai e crie a conta grátis.

**1. Image to 3D:**
   - Menu **"Image to 3D"** → **Upload** e escolha o arquivo:
     `c:\projetos\jogoTD\assets\autorig\hercules.png`
     (essa é a melhor entrada — corpo inteiro, de pé, sem arma. NÃO use a
     `assets/heroes/hercules.png`, que tem pose dinâmica/arma e atrapalha o rig.)
   - Ligue **"Image Enhancement"** se aparecer.
   - Clique **Generate** e espere (~1 min). Confira o modelo 3D.

**2. Auto-Rig:**
   - No modelo gerado, abra **"Rig"** (Rigging).
   - Tipo de personagem = **Humanoid**. Posicione se pedir e confirme.
   - Ele cria os ossos sozinho em ~30s.

**3. Animar (se o tier grátis deixar):**
   - Abra **"Animate"** e adicione uma animação: **Idle** e/ou **Walk**.
   - ⚠️ No grátis são "20+ animações"; walk/attack podem estar no plano pago.
     **Se estiver bloqueado, TUDO BEM** — só exporte o modelo riggado (T-pose)
     que eu aplico animações grátis depois (Mixamo) ou faço no Godot.

**4. Export:**
   - Exporte em **GLB** (formato nativo do Godot).
   - Salve em: `c:\projetos\jogoTD\assets\models\hercules\hercules.glb`
     (a pasta já existe).

**5. Me avise** na volta: **(a)** quanto gastou de crédito, **(b)** se o auto-rig
   ficou bom, **(c)** se conseguiu animação grátis ou se saiu só riggado (T-pose).

> Alternativa se quiser mais animações de graça: exportar em **FBX** e subir no
> **Mixamo** (mixamo.com, grátis, conta Adobe) — milhares de animações. Mas comece
> pelo GLB do Meshy; o resto eu resolvo.

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
