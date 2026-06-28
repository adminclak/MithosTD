# Arte do Mithos TD — como adicionar (sem mexer no código)

O jogo carrega sprites automaticamente **se** o arquivo existir. Enquanto não
existir, desenha um "boneco/monstrinho" placeholder. Então você pode ir
adicionando arte aos poucos.

## Convenção de arquivos
- Heróis:  `assets/heroes/<id>.png`   (ex.: `assets/heroes/zeus.png`)
- Inimigos: `assets/enemies/<id>.png` (ex.: `assets/enemies/talos.png`)

**Formato:** PNG quadrado com fundo transparente, **256x256** recomendado
(o jogo redimensiona). Personagem de corpo inteiro, centralizado.

Depois de copiar os PNGs, abra o projeto no Godot uma vez (ele importa as
imagens automaticamente) e rode — os sprites aparecem no lugar dos placeholders.

## Estilo (para a IA)
Prompt-base sugerido (cole e troque a descrição do personagem):

> cute cartoon style, vibrant saturated colors, mobile tower-defense hero,
> clean vector shapes, bold outlines, full body, centered, transparent
> background, friendly and readable silhouette, in the style of Kingdom Rush
> and Brawlhalla — <DESCRICAO DO PERSONAGEM>

Para inimigos, troque por: `... cute but menacing monster, ...`.

## IDs dos HERÓIS (arquivo = `<id>.png`)
Grega: artemis, hermes, hercules, ares, atena, apolo, medusa, zeus
Nordica: heimdall, ullr, thor, tyr, freya, frigg, odin, loki
Japonesa: tsukuyomi, hachiman, susanoo, benkei, amaterasu, kannon, raijin, fujin
Brasileira: curupira, anhanga, mapinguari, cuca, iara, boto, saci, boitata
Egipcia: horus, neith, anubis, set, isis, thoth, ra, sekhmet
Chinesa: houyi, nezha, sunwukong, guanyu, nuwa, guanyin, longwang, erlang
Asteca: mixcoatl, camazotz, huitzilo, mictlan, xochi, tezca, quetzal, tlaloc

## IDs dos INIMIGOS (arquivo = `<id>.png`)
lacaio, espectro, esqueleto, hidra, hidra_filhote, centauro, ciclope, talos

> Dica: comece pelos mais vistos — inimigos (lacaio, esqueleto, hidra, talos) e
> os heróis iniciais (artemis, odin, benkei, iara, horus, longwang, huitzilo).
