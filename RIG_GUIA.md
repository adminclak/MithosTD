# Guia do Rig de Personagens (equipamento vestido no corpo)

> ⚠️ **SUPERADO (2026-06-30):** este guia descreve o caminho de **rig 2D
> (Spine/DragonBones)**, que NÃO foi o escolhido. O usuário optou por **2.5D —
> heróis 3D sobre os mapas 2D** (equipamento muito mais simples no 3D). Veja
> **`NOTAS_3D.md`** e **`PENDENTE_VOCE.md`**. Mantido aqui como referência/alternativa.

> Decisão tomada: usar uma **ferramenta de rig esquelético** (Spine 2D ou
> DragonBones) em vez de gerar peças modulares por IA. Motivo: a IA faz
> personagens bonitos, mas **não** mantém a mesma pose/proporção entre eles,
> então peças soltas nunca encaixam. O rig resolve isso de vez — e é exatamente
> como Kingdom Rush e jogos mobile premium fazem.

---

## 1. Por que isso resolve o problema (o conceito de "skin")

Uma ferramenta de rig separa **o esqueleto** (os ossos) **da arte** (as imagens
penduradas nos ossos). A peça-chave para equipamento é a **skin**:

- Um **slot de desenho** é um lugar do corpo (ex.: "cabeça", "tronco", "mão").
- Uma **skin** é um conjunto de imagens encaixadas nesses slots.
- Você pode **trocar a skin em tempo real**: equipou elmo de bronze → o slot
  "cabeça-equipamento" passa a mostrar a imagem do elmo de bronze.

Ou seja: **"equipar o capacete e ele aparecer na cabeça" é literalmente a função
nativa da ferramenta.** Não tem gambiarra.

---

## 2. A grande sacada: 1 esqueleto, equipamento desenhado UMA vez

Se todos os heróis usarem **o mesmo esqueleto** (mesmas proporções humanas):

- Você **rigga e anima UMA vez** (idle / andar / atacar) → todos os heróis herdam.
- Cada herói é só uma **skin de corpo** (cabeça/rosto/pele/roupa base dele).
- Cada equipamento é desenhado **UMA vez** e funciona em **todos** os heróis.

Conta de padeiro do trabalho de equipamento (slots visíveis × tiers):

| Slot visível | Tiers (raridades) | Peças a desenhar |
|---|---|---|
| Elmo | 6 (Comum→Mítico) | 6 |
| Peito | 6 | 6 |
| Pernas | 6 | 6 |
| Botas | 6 | 6 |
| Arma | 6 | 6 |
| Escudo | 6 | 6 |
| **Total** | | **~36 peças** desenhadas 1x, reusadas por todos |

(Amuleto e Anel são miúdos — dá pra ignorar no corpo ou desenhar depois.)

Isso transforma "infinitas combinações" num conjunto **finito e tratável**.

---

## 3. Qual ferramenta usar

### Recomendação: **Spine 2D** (https://esotericsoftware.com)
- **Por quê:** o sistema de skins é o melhor do mercado e foi feito exatamente
  para troca de equipamento. Runtime **oficial e ativo** para Godot 4.x
  (`spine-godot`). É o padrão da indústria mobile.
- **Custo:** licença **Essential ~US$69 (pagamento único)** — já inclui skins,
  que é o que precisamos. (Há trial, mas o trial não exporta.)
- **Pegadinha boa de saber:** o `spine-godot` é um **build do Godot já com o
  Spine embutido** (você baixa o editor Godot+Spine pronto deles) OU a versão
  GDExtension. Eu cuido dessa parte de integração no Godot — você só me manda o
  arquivo exportado (`.spine-json` + atlas + png).

### Alternativa grátis: **DragonBones Pro** (editor grátis)
- **Por quê:** faz a mesma coisa (ossos + skins) de graça. Bom pra **aprender o
  fluxo sem gastar** antes de decidir.
- **Risco honesto:** o runtime para **Godot 4** é comunitário e menos mantido —
  pode dar trabalho de fazer funcionar na 4.7. O editor em si é estável.

**Sugestão de rota:** comece pelo **DragonBones** para aprender o ciclo
cortar→riggar→skin→exportar **com 1 herói** sem gastar nada. Se você curtir o
resultado e o fluxo, eu te ajudo a migrar pro **Spine** para o acabamento e a
confiabilidade de longo prazo.

---

## 4. O fluxo de trabalho (passo a passo)

Para **cada herói** (a primeira vez é a mais lenta; depois vira receita):

1. **Arte-base pronta pra rig.** Uma imagem do herói de **frente**, pose neutra
   (A-pose), traço chapado (cartoon), **sem arma** na frente do corpo e com
   **braços/pernas levemente afastados** do tronco (pra dar pra cortar). → Eu
   gero isso pra você pelo pipeline fal.ai (Recraft), otimizado pra recorte.
2. **Cortar em partes** (no Photopea grátis / Photoshop / GIMP): cabeça, tronco,
   braço-superior E, antebraço E, mão E, braço-superior D, antebraço D, mão D,
   coxa E, canela E, pé E, coxa D, canela D, pé D. Cada parte = um **PNG
   transparente**. (Eu te passo um gabarito de nomes.)
3. **Montar o esqueleto** na ferramenta: criar os ossos e pendurar cada PNG no
   osso certo. (Faz UMA vez; os outros heróis reusam o esqueleto.)
4. **Criar as skins de equipamento:** desenhar/encaixar elmo, peito etc. nos
   slots de equipamento, um por tier. → Eu gero as **artes das peças** pelo
   pipeline; você só encaixa.
5. **Animar:** idle (respiração), andar, atacar. (UMA vez no esqueleto base.)
6. **Exportar** (JSON + atlas/PNG) e me mandar.
7. **Integração no Godot:** **eu faço.** Carrego o esqueleto, e ligo o sistema de
   equipamento do jogo à troca de skin (ver seção 5).

---

## 5. Como ligar no jogo (parte que é minha)

O jogo já tem tudo de que o rig precisa nos dados:

- Slots: `EquipmentData.Slot` = `HELMET, ARMOR, LEGS, BOOTS, WEAPON, SHIELD, ...`
- Tiers: `EquipmentData.Rarity` = `COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHIC`

Regra de nome de skin (você nomeia as skins assim na ferramenta):

```
<slot>/<tier>      ex.:  helmet/bronze   chest/iron   weapon/legendary
```

No Godot, quando o herói tiver `{HELMET: item_bronze, ARMOR: item_ferro}`, eu
combino as skins `helmet/bronze` + `chest/iron` sobre a skin de corpo do herói.
É a função nativa de "combinar skins" do runtime — direto, sem hack.

Mapa tier→material sugerido (cor/acabamento da peça):

| Rarity | Material/visual |
|---|---|
| Comum | couro |
| Incomum | bronze |
| Raro | ferro |
| Épico | aço élfico/rúnico |
| Lendário | ouro |
| Mítico | prata divina/brilho |

---

## 6. Divisão de trabalho

| Faço EU | Faz VOCÊ (uma vez, na ferramenta) |
|---|---|
| Gerar as artes-base dos heróis prontas p/ recorte | Instalar a ferramenta (Spine ou DragonBones) |
| Gerar as ~36 artes de peças por tier | Cortar a arte em partes (Photopea) |
| Gabaritos de nomes de ossos/slots/skins | Montar o esqueleto + pendurar as partes |
| Toda a integração no Godot (troca de skin) | Criar as skins de equipamento e animar |
| Ligar com loja/inventário/partida | Exportar e me mandar os arquivos |

---

## 7. Próximo passo imediato

1. Você escolhe começar pelo **DragonBones (grátis, pra aprender)** ou já ir pro
   **Spine (US$69, definitivo)** e instala.
2. Eu **gero a arte-base do primeiro herói** otimizada pra rig (te aviso o custo
   antes — é API paga) + te entrego o **gabarito de recorte e nomes**.
3. Você faz o primeiro recorte/esqueleto; eu monto a integração no Godot e
   testamos a troca de equipamento de ponta a ponta com 1 herói.
4. Validado o fluxo, escalamos para os demais heróis e as 36 peças.

> Filosofia: provar o ciclo completo com **1 herói + 2 peças** antes de investir
> em escala. Assim você não gasta tempo/dinheiro num caminho antes de ver
> funcionando no jogo.
