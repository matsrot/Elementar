# Elementar

Jogo educativo 2D de plataforma sobre a Tabela Periódica (TCC - Sistemas de Informação, FAFRAM).
Feito na Godot Engine 4.

## Como abrir
1. Abra o Godot e use **Importar** na pasta do projeto (`project.godot`).
2. F5 abre a tela inicial (Iniciar, Configurações e Sair).
3. Abra `levels/test_level.tscn` e aperte F6: colete os elementos, aperte **I** para combinar e ganhe estrelas.

## Controles (provisórios)
- Mover: A/D ou setas | Pular: Espaço, W ou seta para cima
- Inventário: I (Esc fecha) | Interagir: E
- Combinar (no inventário): clique nos elementos da tabela (clique de novo para usar mais de um), depois em Combinar. Separar desfaz o composto.

## Estrutura
- `autoload/` Database (elementos e receitas), Inventory (o que o jogador tem) e Progress (missão e estrelas)
- `data/elements`, `data/recipes`, `data/missions` dados do jogo (um arquivo por item)
- `player/`, `levels/`, `elements/`, `ui/`, `main/`
- `assets/` sprites, áudio, fontes

## Fonte pixelada (opcional)
Para o título ficar como no mockup, coloque um .ttf pixelado (ex.: Silkscreen ou Press Start 2P, do Google Fonts)
em `assets/fonts/titulo.ttf`. Sem o arquivo, o jogo usa a fonte padrão.

## Camadas de física
1 mundo | 2 jogador | 3 elementos | 4 obstáculos

## Nota sobre autoria
Os arquivos de estrutura, dados, inventário, coletáveis, interface e combinação (Dias 1 a 4 e fase 2) foram gerados com assistência de IA (Claude)
e devem ser declarados como tal no texto do TCC.

## Missão e estrelas (Dia 3)
- A fase de teste tem a missão "Forme um óxido" (`data/missions/oxidos.tres`).
- Cada receita com `category = "oxido"` vale uma estrela (um método diferente). A primeira mostra o balão "Missão cumprida!".
- Para criar uma nova receita, copie um arquivo de `data/recipes/` e ajuste id, inputs, resultado, explicação e method_id.

## Tela inicial e pausa (Dia 4)
- `main/main.tscn`: menu inicial. Iniciar abre `levels/test_level.tscn`.
- Configurações: volume geral e tela cheia, salvos em `user://settings.cfg`.
- Esc durante a fase abre o menu de pausa (Continuar, Voltar ao menu, Sair); Esc também fecha o inventário.

## Fase 2, novos elementos e áudio
- `levels/level_02.tscn`: fase "Cozinha" com a missão "Forme um sal" (NaCl, KCl, CaCl2 e FeCl3). A fase 1 leva a ela pelo botão "Próxima fase".
- Novos elementos: N, Cl, K e Ca. Novas receitas: sais, HCl, CaO e NH3.
- Missões listam as receitas que valem estrela em `recipe_ids` (arquivos em `data/missions/`).
- Áudio: autoload `GameAudio`. Os sons e músicas em `assets/audio/` foram gerados por síntese com `tools/gerar_audio.py`.
  Para trocar por outros, coloque arquivos .ogg/.wav/.mp3 com os mesmos nomes na pasta.

## Seleção de fase e estrelas salvas
- Iniciar abre a tela "Escolher fase" (título, descrição e estrelas de cada fase). As fases são arquivos em `data/levels/`.
- As estrelas conquistadas ficam salvas em `user://progress.cfg`. Em Configurações há o botão "Apagar estrelas salvas" (útil para começar do zero em cada participante).
- No inventário, todos os elementos aparecem na tabela; os coletados ficam em amarelo, com borda clara e símbolo maior.
- Sons de pulo e coleta foram regerados mais graves e suaves (`tools/gerar_audio.py`).
