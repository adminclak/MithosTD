# Mithos TD — Documento de Design & Prompt de Desenvolvimento

> **Status:** v0.3 — design do MVP completo (com propostas a validar).
> Todas as decisões estruturais (D1–D8) estão **fechadas** e o recheio do MVP (economia, fases, inimigos, equipamentos, habilidades) tem proposta concreta. **Pronto para iniciar a Camada 1 da implementação.** O que se ajusta no playtest está listado no fim.

---

## 1. Visão geral

**Mithos TD** é um jogo mobile de **Tower Defense** single-player, de partidas rápidas, com foco em **coleção, evolução e estratégia de composição de torres**. Cada torre é um personagem único inspirado em mitologias e folclores do mundo — começando por **grega, nórdica, japonesa e folclore brasileiro**.

| | |
|---|---|
| **Gênero** | Tower Defense (RPG-TD de coleção) |
| **Plataforma** | Celular (Android/iOS) |
| **Modo inicial** | Single-player |
| **Estilo** | Fantasia mitológica e folclórica, 2D |
| **Público-alvo** | Casuais e jovens/adultos que gostam de partidas rápidas + progressão |
| **Sensação desejada** | Crescimento, desafio, coleção, montar composições fortes e satisfação ao evoluir torres |
| **Referências** | *Realm Defense*, *Kingdom Rush*, *Rush Royale* |

**Premissa:** o jogador defende uma rota contra ondas de inimigos posicionando torres com papéis estratégicos distintos. Vencendo, ganha moedas, experiência e itens, com os quais **evolui suas torres, desbloqueia habilidades e monta composições cada vez mais fortes** — e avança pelas mitologias do mundo.

---

## 2. Pilares de design — decisões fechadas

### D1 — Tipo de jogo / fonte de progressão
**Coleção/investimento em primeiro lugar** — um RPG-TD de coleção. O coração do jogo é **evoluir e colecionar** torres (deuses/seres folclóricos). As torres carregam **poder permanente** entre partidas (nível, equipamentos, evolução). O desafio das fases escala junto com o poder investido.
**Riscos a gerenciar no projeto inteiro:** (1) "auto-win" por excesso de investimento, (2) paywall precoce, (3) explosão de balanceamento.

### D2 — Estrutura do mapa e posicionamento
**Caminho fixo + slots de torre.** Inimigos percorrem uma rota desenhada e fixa; o jogador só constrói em **slots pré-definidos** ao lado dela. O desafio vem de QUAIS torres colocar em CADA slot e quando.

### D3 — Papel mecânico das 4 classes
Papéis distintos e complementares, com **camada tática de bloqueio**:
- **Arqueiro** — dano físico de **alvo único**, longo alcance, cadência alta.
- **Mago** — dano mágico em **área (AoE)**, forte contra grupos, cadência mais lenta.
- **Guerreiro** — **invoca unidades bloqueadoras** que vão ao caminho e prendem inimigos em combate corpo-a-corpo (estilo "quartel"). Inimigos param pra lutar, ficando no alcance das torres de dano.
- **Sacerdote** — **suporte**: melhora torres vizinhas (dano/velocidade), enfraquece inimigos (lentidão) e/ou cura as unidades bloqueadoras do Guerreiro.

> O bloqueio é o sistema mais complexo do core, mas é o que dá sentido às 4 classes e cria a estratégia de **frente × retaguarda × apoio**.

### D4 — Fluxo da partida (loop de gameplay)
**Esquadrão limitado de personagens únicos + economia de ouro dentro da fase.**
- **Antes da fase:** monta um **esquadrão limitado** (proposta MVP: 5–6 personagens) entre as torres que possui.
- **Cada torre é um personagem único:** você tem *uma* instância de cada deus/ser, com nível e equipamento próprios; ocupa **1 slot** por fase (sem cópias).
- **Durante a fase:** começa com pouco **ouro**, ganha matando inimigos/completando ondas, e gasta para **invocar** os personagens nos slots e dar **upgrades temporários** (proposta: até nível 3) que **zeram no fim da fase**.
- **Stats base** vêm do **nível permanente** de cada personagem + equipamentos.
- **Vitória/derrota:** base com pontos de vida; cada inimigo que escapa tira vida; vida zerada = derrota; sobreviver a todas as ondas = vitória.

### D5 — Estrutura de progressão / organização das fases
**Mundos por mitologia.** O jogo se organiza em mundos temáticos — **Grécia → Nórdica → Japão → Brasil** — cada um com fases sequenciais de dificuldade crescente e inimigos do respectivo folclore. Concluir um mundo destrava o próximo. Progredir num mundo é a forma natural de conquistar os personagens daquela mitologia.

### D6 — Aquisição de personagens (motor da coleção)
**Desbloqueio por progresso.** O jogador conquista personagens avançando na campanha e batendo marcos; uma loja com moeda do jogo pode complementar. Sem gacha no modelo base — justo, previsível, fácil de balancear. Gacha/fragmentos podem ser somados no futuro.

### D7 — Escopo do primeiro marco + Engine
- **Engine:** **Godot 4** (2D). Grátis, leve, ótima pra 2D mobile, GDScript acessível, exporta Android/iOS, boa pra desenvolvimento assistido por IA.
- **Escopo-alvo:** **MVP completo** — 1 mundo (Grécia) com fases, ~8–10 personagens cobrindo as 4 classes, níveis/XP, habilidades, equipamentos, loja e save local.
- **Método (importante):** ainda que o alvo seja o MVP completo, a **implementação será feita em camadas jogáveis** (ver seção 8), nunca tudo de uma vez — para sempre haver algo testável e detectar cedo o que não diverte.

---

## 3. Loop de jogo (resumo executável)

**Loop de partida (dentro da fase):**
1. Monta o esquadrão (5–6 personagens).
2. Entra na fase: caminho fixo, slots vazios, pouco ouro, base com vida cheia.
3. Ondas começam → invoca personagens nos slots gastando ouro.
4. Guerreiros seguram a linha; Arqueiros/Magos detonam; Sacerdotes sustentam.
5. Gasta o ouro ganho em upgrades temporários (até nível 3) conforme a pressão aumenta.
6. Sobrevive a todas as ondas = vitória.

**Loop de meta (entre partidas):**
Vence fase → ganha XP + ouro + itens permanentes → personagens sobem de nível, equipam, evoluem e desbloqueiam habilidades → esquadrão fica mais forte → encara fases/mundos mais difíceis → desbloqueia novos personagens.

---

## 4. Personagens / torres

### Roster planejado (20 — plano total)

| Mitologia | Personagem | Classe |
|---|---|---|
| **Grega** | Hércules | Guerreiro |
| | Atena | Sacerdote |
| | Ártemis | Arqueiro |
| | Hermes | Arqueiro |
| | Medusa | Mago |
| | Ares | Guerreiro |
| | Zeus | Mago |
| | Apolo | Sacerdote |
| **Nórdica** | Thor | Guerreiro |
| | Odin | Mago |
| | Heimdall | Arqueiro |
| | Freya | Sacerdote |
| | Fenrir | Guerreiro |
| **Japonesa** | Susanoo | Guerreiro |
| | Amaterasu | Sacerdote |
| | Tsukuyomi | Arqueiro |
| | Raijin | Mago |
| | Yamata no Orochi | Guerreiro |
| **Brasileira** | Curupira | Arqueiro |
| | Boitatá | Mago |
| | Iara | Sacerdote |
| | Saci | Mago |
| | Mapinguari | Guerreiro |

### Personagens do MVP — panteão grego expandido (8 personagens, 2 por classe)  ✅
O MVP foca no **mundo grego**. Para dar variedade real de esquadrão (2 opções por classe), o roster grego foi expandido:

| Personagem | Classe | Identidade mecânica | Habilidade ativa (assinatura) |
|---|---|---|---|
| Hércules | Guerreiro | Bloqueador-tanque: muita vida, segura a linha | **Força Indomável** — fica invulnerável e provoca os inimigos próximos por alguns segundos |
| Ares | Guerreiro | Bloqueador agressivo: mais dano, menos vida | **Fúria de Guerra** — golpe giratório em área + buff de dano temporário |
| Ártemis | Arqueiro | Sniper: dano de alvo único, alcance altíssimo | **Flecha Perfurante** — tiro que atravessa a fila inteira com dano pesado |
| Hermes | Arqueiro | Metralhadora: cadência muito rápida, dano menor | **Velocidade Divina** — frenesi de tiros por alguns segundos |
| Medusa | Mago | AoE com petrificação (lentidão/atordoamento) | **Olhar Petrificante** — petrifica (paralisa) todos os inimigos numa área |
| Zeus | Mago | Raio em cadeia entre vários inimigos | **Tempestade do Olimpo** — raios que saltam entre vários inimigos |
| Atena | Sacerdote | Buff de dano/velocidade nas torres vizinhas | **Égide de Atena** — buff forte de dano e velocidade nas torres de uma área |
| Apolo | Sacerdote | Cura as unidades bloqueadoras + debuff de luz | **Luz Solar** — cura em área dos bloqueadores + queima inimigos |

> Nomes e papéis são proposta — fáceis de trocar. As outras mitologias serão expandidas da mesma forma quando seus mundos chegarem.

---

## 5. Progressão & sistemas meta

### Dois eixos de poder permanente (D8)  ✅
Cada personagem cresce por **dois eixos independentes**:

**Nível (gradual)**
- Sobe ganhando **XP** ao participar de partidas.
- Cada nível dá um incremento pequeno de stats (vida / dano / cadência etc.).
- O **teto de nível depende da evolução atual**.

**Evolução / estrelas (em saltos)**
- Tiers: ⭐ → ⭐⭐ → ⭐⭐⭐ (proposta MVP: 3 tiers).
- Evoluir é um **salto grande** de poder, **aumenta o teto de nível** e **muda o visual**.
- Custa **Essência Mitológica** (recurso de evolução): dropa em fases e pode ser comprada na loja. Cada salto exige Essência + ouro em quantidade crescente (proposta: ⭐→⭐⭐ = 10 Essências + ouro; ⭐⭐→⭐⭐⭐ = 25 Essências + mais ouro).
- Na evolução máxima, o personagem fica **"aceso"** — ápice visual.
- ❌ **Descartado:** "evolução por horas jogadas" do plano original (incentivava idle/exploits).

**Proposta de números do MVP (a validar no playtest):**

| Estrela | Teto de nível |
|---|---|
| ⭐ | até 10 |
| ⭐⭐ | até 20 |
| ⭐⭐⭐ | até 30 |

### Habilidades  ✅
- **Modelo:** cada personagem tem **1 habilidade ATIVA de assinatura**, acionada pelo jogador via botão no HUD (com **cooldown**, sem custo de mana — simplicidade mobile). É o poder icônico do deus. Ver a coluna de habilidades na seção 4.
- **Disponibilidade:** a habilidade ativa já vem desde ⭐ (nível 1) — faz parte da identidade do personagem.
- **Cooldown (proposta):** 25–40s conforme o impacto (as mais fortes, como petrificação em área, têm cooldown maior).
- **Passivas (por evolução):** ⭐⭐ destrava 1 passiva (ex.: +10% dano / +alcance / chance de atordoar); ⭐⭐⭐ destrava uma 2ª passiva OU potencializa a habilidade ativa (-cooldown, +área).

### Equipamentos  ✅
- **2 slots por personagem (MVP):** **Arma** (poder ofensivo) e **Relíquia** (stat secundário conforme a classe).
  - *Arma:* +dano (p/ Guerreiro, +dano dos bloqueadores; p/ Sacerdote, +potência de buff/cura).
  - *Relíquia:* +um stat secundário — alcance, cadência, vida dos bloqueadores, raio/intensidade de aura, redução de cooldown.
- **Raridades (MVP):** Comum → Raro → Épico (magnitude crescente).
- **Fontes:** drop em fases (chance; raridades melhores em fases avançadas) + compra na loja.
- **Sem nível de equipamento no MVP** (stat fixo pela raridade) — evita mais uma camada de balanceamento agora.

### XP — regra (proposta)  ✅
- Ao **concluir uma fase**, **todos os personagens do esquadrão levado** ganham XP (mesmo os pouco usados) — incentiva levar quem você quer evoluir, sem punir composição.
- **Vitória** dá XP cheio; **derrota** dá fração (ex.: 30%), pra reduzir frustração.
- **Quantidade (proposta):** XP_base da fase × multiplicador de dificuldade. Ex.: Fase 1 ≈ 50 XP, crescendo ~+25% por fase.

---

## 6. Mundos & fases

- Estrutura em **mundos temáticos** (Grécia → Nórdica → Japão → Brasil), cada um com uma sequência de fases de dificuldade crescente.
- Cada mundo tem **inimigos temáticos** próprios:
  - Grego: hidras, centauros, harpias…
  - Nórdico: draugr, gigantes de gelo, lobos…
  - Japonês: oni, yokai…
  - Brasileiro: seres do folclore…
### Inimigos do mundo grego (MVP)  ✅
Todos terrestres no MVP (sem voadores — evita exigir torres anti-aéreas agora).

| Inimigo | Papel |
|---|---|
| Lacaio (servo de Hades) | Básico equilibrado — preenche ondas |
| Espectro veloz | Rápido e frágil — pressiona quem não tem bloqueio |
| Soldado esqueleto | Lento e resistente — esponja de dano |
| Hidra menor | Ao morrer, divide em 2 menores — premia AoE |
| Centauro | Elite: rápido E forte — exige bloqueio + foco |
| Ciclope | Mini-boss tanque, dano alto de perto |
| **Tálos, o Colosso de Bronze** | **BOSS** do mundo grego (fase 5): muita vida, investidas |

### As 5 fases do mundo grego (MVP)  ✅
Dificuldade e nº de slots crescentes; cada fase introduz/explora um conceito.

| # | Fase | Slots | Ondas | Foco / novidade |
|---|---|---|---|---|
| 1 | Campos de Élis | 5 | 5 | Tutorial: invocar, atacar, vida da base |
| 2 | Bosque de Neméia | 6 | 6 | Espectros velozes → ensina o **bloqueio** (Guerreiro) |
| 3 | Pântano da Hidra | 6 | 7 | Hidras que se dividem → premia **AoE** (Mago) |
| 4 | Desfiladeiro dos Centauros | 7 | 8 | Mistura pesada → exige **composição completa** |
| 5 | Encosta do Olimpo | 8 | 8 + boss | **Tálos** → exige esquadrão evoluído e uso de habilidades |

> Rotas e disposição exata dos slots serão desenhadas na Camada 6 (conteúdo), direto no editor do Godot.

---

## 7. Escopo do MVP (alvo)

Single-player, **mundo grego completo** como fatia vertical do jogo final:

- 1 modo de jogo (single-player), save **local**
- 1 mundo (Grécia) com **~5 fases** sequenciais
- Caminho fixo + slots por fase
- **8 personagens gregos** (2 por classe)
- Sistema de **esquadrão** (montar 5–6 antes da fase)
- **Combate completo** das 4 classes (incluindo bloqueio do Guerreiro)
- **Economia de partida** (ouro, invocar, upgrades temporários)
- **Meta-progressão:** XP, níveis, desbloqueio de personagens por fase
- **Equipamentos** (sistema simples) + **habilidades** + **loja**
- Sem backend e sem multiplayer

---

## 8. Plano de implementação em camadas

> Constrói-se **uma camada jogável de cada vez**, testando antes de empilhar a próxima.

1. ✅ **Esqueleto da partida** — mapa, caminho, slots, torre que atira, ondas, vida da base. **CONCLUÍDA**: jogável, validada (vitória confirmada + 13 testes), publicada no GitHub.
2. ✅ **As 4 classes** — Arqueiro (alvo único), Mago (AoE), Guerreiro (bloqueadores) e Sacerdote (aura de buff/lentidão/cura). **CONCLUÍDA**: comportamento data-driven via `TowerData`, validada (smoke test + 40 testes).
3. ✅ **Economia da partida** — invocar torres clicando nos slots (painel das 4 classes + custo), upgrade temporário (Nv 1→2→3) e venda; bônus de ouro por onda. **CONCLUÍDA**: `BuildManager`/`BuildMenu`/`TowerSlot`, validada (smoke test + 63 testes). Montagem de esquadrão movida para a Camada 4.
4. ✅ **Meta-progressão** — 8 personagens gregos, XP/níveis permanentes, desbloqueio por fase, montagem de esquadrão (Hub) e save local em `user://` (JSON). 5 fases com dificuldade crescente. **CONCLUÍDA**: autoload `Progression`, fluxo Hub→Partida→Resultado, validada (smoke + 83 testes).
5. ✅ **Equipamentos + habilidades + loja** — habilidade ativa de assinatura por personagem (botão no HUD com cooldown; 5 tipos de efeito: dano/atordoar/buff/cura/escudo), equipamentos (Arma+Relíquia, raridades, bônus nos stats), loja com ouro meta, evolução de estrela por Essência (tetos 10/20/30). **CONCLUÍDA**: `AbilityData`/`AbilityBar`, `EquipmentData`/`EquipmentList`, `CollectionScreen`, validada (smoke + 116 testes).
6. ✅ **Conteúdo** — bestiário grego data-driven (7 inimigos: Lacaio, Espectro, Esqueleto, Hidra que se divide, Centauro, Ciclope e o boss Tálos), composição de ondas temática por fase (`WaveComposer`) e o boss na fase 5. **CONCLUÍDA**: `EnemyData`/`GreekBestiary`, validada (smoke + 126 testes). *Obs.: rota única reutilizada (variando slots/dificuldade/ondas) — rotas geográficas distintas por fase ficam para o editor, como o design previa.*

> **MVP da fatia vertical grega COMPLETO** (Camadas 1–6). Próximos passos sugeridos: playtest e balanceamento, rotas próprias por fase no editor, arte/áudio, e export Android.

---

## 9. Economia & balanceamento — proposta MVP

> Números **iniciais** só pra destravar o desenvolvimento; serão ajustados no playtest.

### Partida
- **Vida da base:** 20 (cada inimigo que escapa tira 1; elites/boss tiram mais).
- **Ouro inicial:** 150.
- **Ouro por abate:** 5 (lacaio) a 30 (elite); **bônus por onda concluída:** pequeno (ex.: +20).
- **Esquadrão:** 6 personagens; **slots por fase:** 5 a 8 (ver tabela de fases).
- **Custo de invocar no slot (base):** Arqueiro 100 · Guerreiro 120 · Sacerdote 130 · Mago 150.
- **Upgrade temporário na partida:** nível 1→2→3; cada nível ≈ +60% do custo anterior e some no fim da fase.

### Stats base relativos por classe (nível 1, ⭐) — referência
| Classe | Dano | Alcance | Cadência | Observação |
|---|---|---|---|---|
| Arqueiro | médio | alto | rápida | alvo único |
| Mago | alto | médio | lenta | dano em área |
| Guerreiro | — | curto | — | invoca 1–3 bloqueadores (HP/dano/respawn) |
| Sacerdote | baixo/0 | médio (aura) | — | buff/cura em área |

### Crescimento permanente
- **Por nível:** ≈ +4% nos stats principais por nível.
- **Por estrela:** salto de ≈ +25% + aumento do teto de nível (ver seção 5).

---

## 10. Monetização & direção visual

### Monetização (direção — **não** implementar pagamento real no MVP)
- **Moeda premium:** "Ambrosia", comprável com dinheiro (apenas estruturada no MVP, sem loja real ligada).
- **Usos previstos:** acelerar progresso, comprar Essência Mitológica, equipamentos, slots extras de esquadrão.
- **Princípios:** generoso no início; **sem paywall** nas primeiras fases; por ser single-player PvE, evitar "vender poder bruto" que destrua o desafio. Passe de batalha/ofertas ficam **pós-MVP**.
- **No MVP:** só a **loja com moeda do jogo** (ouro + Essência ganhos jogando). Sem dinheiro real.

### Direção visual (provisória — estilo a confirmar)
- **Estilo-alvo provisório:** 2D ilustrado/cartoon limpo e colorido (apelo casual, referência *Kingdom Rush*).
- **No protótipo:** placeholders — formas/ícones coloridos por classe (🔵 Arqueiro · 🔴 Guerreiro · 🟣 Mago · 🟡 Sacerdote) e sprites simples pros inimigos.
- Fonte de arte final (assets/IA/artista) **adiada** até o gameplay estar validado.

---

## 11. Stack técnica & arquitetura proposta (Godot 4) *(proposta a validar)*

- **Engine:** Godot 4, projeto **2D**. Backend/multiplayer fora do MVP.
- **Abordagem data-driven:** definir torres, inimigos, fases e equipamentos como **Resources (`.tres`)** reutilizáveis — facilita criar/balancear conteúdo sem mexer em código.
- **Cenas principais (proposta):**
  - `Main` (gerência de telas) · `Level` (mapa/rota/slots) · `Tower` (base + variações por classe) · `Enemy` · `BlockerUnit` (unidade do Guerreiro) · `Projectile` · `HUD`
  - Telas meta: `SquadSelect` · `Collection` · `Shop`
- **Autoloads/singletons (proposta):** `GameState` (save/load) · `Economy` (ouro da partida) · `ProgressionManager` (XP/níveis/desbloqueios) · `WaveManager` (ondas).
- **Save local:** serialização em `user://` (JSON ou Resource).

---

## 12. Requisitos & setup para começar a codar

### Ferramentas a instalar (checklist)

**Obrigatório pra começar:**
- [ ] **Godot 4** — versão **Standard** (NÃO a ".NET/Mono"; vamos usar GDScript).
  - Baixar em **godotengine.org/download** → Windows → "Godot Engine 4.x".
  - É um **.zip**: extrair e rodar o **.exe** — não tem instalador, abre direto. Pode deixar numa pasta tipo `C:\Godot\`.
  - Usar a versão **estável** mais recente da linha 4.

**Recomendado (controle de versão):**
- [ ] **Git** — pra salvar versões do projeto e nunca perder trabalho.
  - Mais fácil (interface gráfica): **GitHub Desktop** — desktop.github.com.
  - Linha de comando: **git-scm.com** (instalador padrão, next → next).

**Só no futuro (exportar pra celular — NÃO precisa agora):**
- [ ] Android SDK + Java JDK + chave de assinatura.

**Opcional:**
- [ ] VS Code como editor externo — mas o editor embutido do Godot já basta.

### Ambiente e teste
- **Desenvolver e testar no PC (Windows)** o tempo todo: o Godot roda o jogo direto no editor (botão ▶ Play). Exportar pra Android só quando o gameplay estiver maduro.
- **Requisitos de sistema:** qualquer PC com Windows 10/11 recente roda Godot 2D tranquilo (não precisa de placa de vídeo dedicada).

### Como vamos trabalhar
- Você **não precisa saber programar**: a IA escreve o GDScript; você direciona, roda, testa e dá feedback.
- Vale aprender o básico do editor do Godot (o que é cena, nó, e como dar Play) — eu te oriento conforme aparecer.
- **Versionar com Git desde o dia 1**, com commits a cada camada concluída do plano de implementação.

### Estratégia de execução — desenvolvimento multi-agente
O desenvolvimento **deve usar múltiplos agentes de IA em paralelo** sempre que as tarefas forem **independentes**, para acelerar a produção. Exemplos de bons alvos para paralelização:
- Gerar os dados (Resources `.tres`) dos **8 personagens** gregos.
- Criar os **7 inimigos** do mundo grego.
- Montar **telas de UI** separadas (esquadrão, coleção, loja).
- Escrever **sistemas desacoplados** entre si.

**Porém**, a **lógica central interdependente** — loop de combate, sistema de bloqueio, economia da partida, save/load, gerência de estado — é feita de forma **coordenada e sequencial**, para manter coerência e evitar conflitos entre agentes.

> **Regra de ouro:** paralelizar o que é independente; manter sequencial o que compartilha estado e regras. Cada agente recebe uma tarefa fechada, com contrato claro de entrada/saída.

### Testes & validação automatizada
- **Test runner próprio:** `test/test_runner.gd` — testes em GDScript, sem dependências externas. Rodar:
  `godot --headless --path . -s res://test/test_runner.gd` (sai com código 0/1 — bom pra CI).
- **Smoke test do projeto:** `godot --headless --path . --quit-after 600` carrega a cena principal e executa o jogo por alguns frames, capturando erros de compilação/runtime sem abrir janela.
- **Referência:** o repositório `Godot-Claude-Skills/` (ignorado pelo Godot via `.gdignore`) documenta abordagens de teste/deploy.
- **Upgrades possíveis (sob autorização do usuário):**
  - **GdUnit4** — framework de testes completo (scene runner, simulação de input, asserções ricas). Requer clonar código de terceiros em `addons/` → pedir aprovação antes.
  - **PlayGodot** — automação E2E + screenshots em Python; exige compilar um fork customizado do Godot → fora de escopo por ora.

### Estrutura de projeto (proposta)
```
mithos-td/
  project.godot
  scenes/    (Level, Tower, Enemy, BlockerUnit, Projectile...)
  scripts/   (lógica .gd)
  data/      (Resources .tres: torres, inimigos, fases, equipamentos)
  assets/    (sprites, sons — placeholders no começo)
  ui/        (HUD, menus, telas meta: esquadrão, coleção, loja)
```

### Pendências de requisito (decisões)
- ✅ **Arte:** placeholders no protótipo; fonte da arte final **adiada** (decidir após validar o gameplay).
- ⚠️ **Áudio:** sem som ou placeholder no MVP; decidir depois.

---

## 13. Pontos em aberto & a validar no playtest

Quase todo o design já tem **proposta concreta** no documento. O que resta:

- **Balanceamento fino:** todos os números (ouro, custos, stats, XP, cooldowns) são pontos de partida — ajustar jogando.
- **Cadência de habilidades/passivas:** confirmar cooldowns e quais passivas por estrela.
- **Arte final:** estilo definitivo (ilustrado/pixel/vetor) e fonte (assets/IA/artista) — decidir após validar o gameplay.
- **Áudio:** música e efeitos — fora do MVP inicial.
- **Monetização real:** loja com dinheiro, passe de batalha, ofertas — pós-MVP.
- **Expansão:** demais mundos (Nórdica / Japão / Brasil) e seus personagens/inimigos.
