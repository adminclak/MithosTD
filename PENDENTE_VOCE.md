# Status do 3D — pra você conferir e me dizer o que ajustar

**Tudo commitado e JÁ NO GIT** (github.com/adminclak/MithosTD, branch main).

## ✅ Resolvido nesta rodada (seu feedback)
1. **Tela de Equipar agora é 3D** e mostra o **equipamento vestido no corpo**
   (elmo na cabeça, arma na mão etc.). Corrigi um bug que "vestia tudo" em todo
   herói — agora só aparece o que está realmente equipado.
2. **Consistência de design:** gerei **retratos 3D** de cada herói
   (`assets/portraits/*.png`) e o jogo passou a usá-los na **lista, ícones e cards**.
   Agora a lista, a tela de Equipar e a batalha usam o **mesmo visual 3D**.
3. **Animação:** adicionei um **idle procedural** (respiração + leve balanço) —
   os heróis não ficam mais estáticos. (Animação de andar/atacar de verdade: ver
   pendências abaixo.)
4. **Batalha:** os heróis 3D continuam na partida; o equipamento equipado aparece
   (o elmo é o mais visível no tamanho pequeno da batalha).

## ▶️ Como testar (duplo-clique)
- **`JOGAR.bat`** → jogo completo. Vá em **Equipar** pra ver o herói 3D girando com
  o equipamento; entre numa fase pra ver os heróis 3D no mapa.
- **`VER_HEROIS_3D.bat`** → showcase dos 8 no mapa.

## 🟡 Pendências / decisões pra quando voltar
1. **Animações reais (andar/atacar):** os modelos do Meshy vieram só com pose base
   (1 clip). Pra ter walk/attack de verdade, o caminho é **Mixamo (grátis)** ou a
   **API de animação do Meshy (gasta crédito)** — os créditos do mês estão quase no
   fim. Me diga se quer que eu vá por Mixamo (te passo o passo a passo) no próximo ciclo.
2. **Equipamento por tier real:** hoje uso **1 modelo 3D por slot** (o set lendário
   dourado) como visual de qualquer item daquele slot. Então um "Capacete de Couro"
   aparece como o elmo lendário. Pra cada tier ter seu visual, precisaria gerar mais
   modelos (crédito). Funciona como está, mas o acabamento fino é isso.
3. **Ajuste fino de encaixe** (offsets em `scripts/hero_rig_3d.gd` → `MOUNT`):
   espada meio de lado, greaves de perna assentam perto do quadril. Rápido de refinar.
4. **Segurança:** regenere a `MESHY_API_KEY` (apareceu no terminal antes) — eu atualizo o `.env`.

## Arquitetura (pra referência)
- `scripts/hero_rig_3d.gd` (HeroRig3D): carrega herói, idle, `equip(slot, glb)` no osso.
- `scripts/hero_view_3d.gd` (HeroView3D): herói 3D como "sprite vivo" (SubViewport) na batalha 2D.
- `assets/models/<id>/<id>.glb` (8 heróis) + `assets/models/props/*_legend.glb` (9 itens).
- 268 testes verdes. Detalhes em `NOTAS_3D.md`.
