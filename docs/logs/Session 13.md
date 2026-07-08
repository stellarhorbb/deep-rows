# Session 13 — Contenu (Badges/Partitions), chevauchement de figures, bannière de résolution, Shell persistant

**Date** : 2026-07-07
**Thème** : Retour après 3 jours d'arrêt. Grosse session en deux temps : (1) contenu (Badges + Partitions) et un vrai chantier d'architecture autour du chevauchement de figures, déclenchés par du playtest actif du user en parallèle ; (2) feedback visuel de résolution (bannière décomposée + cascade dédiée) et mise en place d'un Shell d'UI persistant, tous deux également nés de retours de playtest en direct.

---

## 5 nouveaux Badges

Bord à Bord, Un Pour Tous, Régularité, Dernier Carré, Petites Mains — brainstormés puis affinés à l'oral avant codage (rectifs user : Petites Mains limité à la valeur 1 et porté sur le multi plutôt que la valeur brute pour scaler, Dernier Carré confirmé sur le seuil "deck ≤ 4", Régularité avec indicateur de progression demandé).

Deux d'entre eux sortent du pattern "un `.tres` + un script, zéro modif du core" établi jusqu'ici — signalé au user avant de coder :

- **Multiplicateur global dynamique** (`RunContext.global_multiplier`) — mutable en cours de manche via une référence vivante gardée par `RunManager` (`set_global_multiplier`). Nécessaire pour Dernier Carré (réagit au deck restant à chaque tour, pas juste au `round_start` comme tous les Badges existants).
- **Bonus par valeur de jeton** (`RunContext.value_bonus_multipliers`) — bonus additif au multiplicateur d'une figure par occurrence d'une valeur donnée. Nécessaire pour Petites Mains, qui doit lire le contenu exact de la figure qui résout, pas juste sa rule.
- **État libre par Badge** (`RunManager.get_badge_state`/`set_badge_state`, reset chaque manche) — contourne la contrainte "BadgeEffect instancié à neuf à chaque dispatch", débloque les Badges à compteur (Régularité, Un Pour Tous).
- **Indicateur de progression au survol** (`BadgeEffect.get_progress_text()`, virtuelle) — câblé dans `BadgesUI`, générique pour tout futur Badge à compteur.

`CascadeResolver._score_group` intègre les 2 nouveaux multiplicateurs dans la formule complète.

## 4 nouvelles formes de Partitions

Discussion préalable sur le volume idéal de contenu pour une V1 Steam (Partitions ~15-18, Badges ~25-30, Spéciaux ~8-10 — asymétrie liée au coût de prod par item). Premières pistes proposées (lignes verrouillées en direction, carré de rocks) rejetées par le user — senties comme des doublons ou pas prioritaires. Direction retenue : nouvelles géométries.

- **Plus** (croix orthogonale, 5 cellules, centre inclus dans le match — contrairement au Diamond)
- **Cross** (croix diagonale, même principe)
- **Ring** (cadre 3×3, 8 cellules, centre indifférent — le grand frère du Diamond)
- **T** (tétromino, 4 cellules, orientation libre, même score peu importe le sens) — le veto historique sur le T (voir `formes.md`, "bannis pour manque d'identité visuelle") levé une fois qu'un vrai usage s'est dégagé

PLUS/CROSS/RING n'ont nécessité aucune modif du scoring (suivent le chemin générique du Carré). Généralisé la suppression de la cellule centrale dans `cascade_resolver.gd` (`group.has("center")` au lieu de `shape == diamond`), pour couvrir Diamond et Ring proprement.

**Piège évité sur T** : un Plus complet contient toujours 4 T valides simultanément (même pivot). Sans précaution, un cluster physique unique aurait produit 4 matchs T identiques. Une seule orientation retenue par pivot dans `find_t`.

**Bug trouvé en playtest et corrigé** : `find_t` limitait le scan des pivots à `range(1, cols-1)` comme Plus/Cross/Ring (qui en ont vraiment besoin, marge symétrique des 2 côtés). Chaque rotation du T n'a besoin de marge que d'un seul côté — un T posé sur le bord de la grille était donc valide visuellement mais jamais détecté. Corrigé : scan de toute la grille, bornes vérifiées cellule par cellule.

Nettoyage label "FAMILY" — redondant puisque quasi tout le catalogue actif est en rule `family`. Fait à la fois dans `TagsUI._format_tag_label` (affichage réel en jeu) et dans le champ `.label` de chaque `.tres` (shop, écran de sélection de départ). Diamond Rock garde "ROCK", pas redondant.

## Chevauchement de figures — le vrai chantier de la session

Déclenché par un aller-retour de playtest user en direct. Trois découvertes successives, chacune vérifiée par un test headless avant d'agir :

1. **Double-scoring découvert** : deux Tags équipés (Plus + T) peuvent matcher des groupes qui se recouvrent sur le même tour — un Plus complet contient toujours un T valide sur 4 de ses 5 cellules. Sans garde-fou, un seul cluster physique scorait deux fois (28 au lieu de 18 sur le cas testé).
2. **Premier correctif** : `CascadeResolver.resolve` trie les groupes candidats par score décroissant, rejette tout groupe qui partage une cellule avec un groupe déjà retenu. Le user a immédiatement soulevé la question inverse : "T sera toujours posé avant que je puisse compléter un Plus, non ?" — vrai, parce que T est un sous-ensemble strict de Plus (résolution immédiate à chaque tour, principe verrouillé) et qu'aucun ordre de pose naturel n'évite de passer par l'état "T valide" avant de compléter le 5e jeton. Même problème identifié ensuite pour Ligne 3 / Ligne 4. Décision : pas de règle d'exclusivité entre Tags, le joueur gère via la vente (déjà disponible à tout moment) — cohérent avec "base simple, pas de règles empilées".
3. **Raffinement final** : le user a illustré (captures à l'appui) un cas où il *voulait* que deux figures scorent ensemble — un T et une Ligne diagonale qui convergent sur une seule cellule commune (le jeton qu'on vient de poser), pas un sous-ensemble strict. Distinction ajoutée : `GameRules.PATTERN_SHARED_CELL_TOLERANCE` (1) — 1 cellule commune = combo délibéré, les deux scorent ; 2+ = une figure qui en avale une autre, seule la mieux payée compte.

Chaque étape vérifiée par un test headless dédié avant d'être considérée acquise (y compris un faux positif en cours de route : des jetons de support identiques dans un test formaient accidentellement leur propre ligne — bug de test, pas du moteur, corrigé avec des Rocks comme support).

## Deck de départ structuré

Le user a remarqué que `RunManager._generate_starter_buttons()` tirait famille et valeur 100% au hasard pour les 30 boutons de départ — repéré comme contraire au principe "pas de RNG punitif" déjà appliqué à l'Entity (un mauvais tirage pouvait saboter une Partition équipée sans faute du joueur). Remplacé par une génération structurée : 2 exemplaires de chaque combinaison (famille, valeur), soit 40 boutons (`DECK_BASE_COUNT` maintenant calculé — `FAMILY_COUNT × valeurs × STARTER_COPIES_PER_VALUE` — plutôt que codé en dur, pour ne pas driver si un des facteurs change).

## Rename UI "Score/Target" → "Tickets"

Pur habillage textuel demandé par le user (le score s'appelle "Tickets" à l'affichage). Touche `ScoreLabel`, `TargetLabel`, l'écran de fin de run, le message "BOMBE +X". Attention notée dans `monnaies.md` : homonymie avec la vraie monnaie de progression "Tickets" (mécanique non formalisée) — à surveiller si ça devient ambigu.

## Bannière de résolution décomposée

Deuxième grand chantier de la session, sur le fil rouge "priorité n°1 = lisibilité du calcul de score". Trois allers-retours de cadrage avant de coder :

1. **Proposition initiale** (décomposition complète des 8 facteurs du score) jugée trop lourde par le user — "faut pas que ça tue le tempo du jeu"
2. **Simplifiée** : nom de la Partition → valeur brute → multi intrinsèque combiné → résultat en plus gros, à la Balatro (chips × mult = score)
3. **Enrichie** une dernière fois : le user voulait un "petit shot de dopamine" identifiant precisément quel Badge contribue, pas juste noyé dans le multi générique

Résultat implémenté :
- `CascadeResolver._score_group` calcule toujours exactement la même formule (score inchangé, testé) mais attache un `score_breakdown` à chaque groupe : label, valeur brute, multi intrinsèque (forme/direction/niveau/modifiers), multi Badge + ses sources
- **Attribution précise limitée à 5 Badges** (Famille Unie, Collectionneur, Dernier Carré, Régularité, Petites Mains — ceux avec un mapping 1:1 clair rule/global/value_bonus → Badge). Les Badges à modifiers de cellule (Écume, Tranchée, Bord à Bord...) ne sont pas attribués individuellement — tracer la provenance de chaque case modifiée aurait été un chantier à part, jugé disproportionné pour un effet visuel
- `set_rule_multiplier`/`set_global_multiplier`/`add_value_bonus_multiplier` prennent un paramètre `source` optionnel (id du Badge), les 5 scripts concernés passent leur propre id
- `ResolutionBanner` (nouveau) joue la séquence en central, un groupe à la fois si plusieurs résolvent le même tour ; `BadgesUI.tilt_badge(id)` fait flasher le Badge concerné
- Remplace entièrement les anciens popups "+X" et labels de pattern par groupe dans `grid_visual.gd` — code mort supprimé (`_build_pattern_text`, `_spawn_pattern_label`, `_spawn_score_popup`, `_format_multiplier`, `_group_center`, le script `ScorePopup` entier)

**Corrections en cours de route, toutes déclenchées par du playtest immédiat** :
- Bloc sombre derrière le texte (`show_behind_parent = true`) — texte clair illisible sur fond clair
- Le compteur TICKETS affiché ne bougeait plus au bon moment : `score_manager.add_score()` (logique) arrivait *avant* l'animation du match, donc le compteur sautait déjà à la valeur finale pendant que la bannière égrenait encore le calcul. Découplé : nouveau signal `GridVisual.group_score_revealed(amount)`, émis à la fin de la séquence de chaque groupe, c'est lui qui pilote l'incrément visuel — la Bombe (instantanée, hors bannière) garde sa propre révélation immédiate

## Fix timing victoire + message YOU WIN

Bug trouvé en testant la bannière : la victoire de manche (`round_won`) ne attendait la fin de l'animation que dans le cas Dernier Souffle — dans le cas normal, le délai de transition vers le shop démarrait *en même temps* que la bannière, pas après. Corrigé : `is_target_reached()` attend toujours `timeline_done_ack` avant de déclarer la victoire. Ajouté un message "YOU WIN" (réutilise `MessageDisplay`, un type `&"win"` déjà prévu mais jamais utilisé) pendant le délai avant transition boutique. Idée notée pour plus tard, pas urgente : un vrai écran de victoire/défaite avec score final, mouches gagnées (bonus/malus) et bouton d'encaissement — rejoint deux questions déjà ouvertes dans le GDD (ordre des écrans de transition, surplus de score).

## Shell d'UI persistant (Partitions/Badges/Deck toujours visibles)

Demande du user en playtest : Partitions/Badges/Deck doivent rester visibles et accessibles sur tous les écrans (notamment le shop, pour vendre avant d'acheter), **à des positions fixes qui ne bougent jamais** — pas juste "présents sur chaque écran" mais un vrai layout persistant.

Chantier de structure, pas d'ajout de nœuds :
- Nouvelle scène **Shell** (`scenes/shell/shell.tscn`), devient la scène principale du projet (remplace `partition_select.tscn`). Contient `TagsUI`/`BadgesUI`/`DeckButton`/`DeckInspectorUI` à des positions fixes, plus un `ContentContainer` où `SceneRouter` instancie l'écran actif — jamais détruite entre les écrans, contrairement à avant (`change_scene_to_file` complet)
- `SceneRouter` réécrit : ne swap plus toute la scène, juste le contenu du conteneur du Shell
- `TagsUI` découplé du `PatternManager` (snapshot figé, scope manche uniquement) — lit désormais `RunManager.get_equipped_tags()` en direct, comme `BadgesUI` le faisait déjà. Condition nécessaire pour s'afficher hors manche active
- `game.tscn` perd ces 4 nœuds (déplacés dans le Shell) ; `game_scene.gd` les récupère via `SceneRouter.shell` au lieu de `$NodePath`
- Bouton DECK reste à la même position partout mais désactivé hors manche active (pas de deck de manche au shop — concept différent du pool de boutons possédé) plutôt que de bricoler une vue de remplacement non demandée

Pose les bases pour la vraie UI/DA plus tard : la structure (positions fixes, persistance) ne sera pas à refaire, seul le rendu interne de `TagsUI`/`BadgesUI` (actuellement `_draw()` procédural, pas de sprites/thème) le sera.

**Limite connue** : impossible de tester la navigation complète en headless — les autoloads (`RunService`, `SceneRouter`) ne se chargent pas en mode `--script`, seulement au vrai boot du projet. Vérifié par un test de fumée partiel + boot propre, mais la validation visuelle reste à faire en jeu.

## Fix softlock grille pleine

Repéré par le user sur un screenshot (grille très chargée, plus rien ne se résout, deck pas vide). Confirmé dans le code : rien ne vérifiait jamais "existe-t-il une colonne encore jouable ?", seulement "cette colonne précise est-elle jouable ?". Une grille totalement pleine avec un deck non épuisé plantait le jeu dans un silence total — pas de crash, un vrai softlock.

Détail utile trouvé en creusant : le Fantôme peut déjà cibler une colonne pleine (`SpecialEffects.can_play`, `FANTOME: return true`) — la soupape de sécurité existait déjà pour ce cas, juste incomplète (rien si pas de Fantôme sous la main).

Fix : `TurnController._has_legal_move()` vérifie si le jeton courant ou celui au hold a au moins une colonne jouable ; si non, même traitement que le deck vide — Dernier Souffle, puis verdict normal (score atteint ou non). Pas une 3e issue, le même chemin que le deck épuisé. Testé (grille pleine sans Fantôme → bloqué ; avec Fantôme → débloqué ; grille avec de la place → toujours jouable).

## Bannière de cascade dédiée

Suite à une clarification de vocabulaire avec le user (une "cascade" = 2+ résolutions chaînées par la gravité, pas juste 2 figures simultanées sur un seul drop) et une vérification par test que le multiplicateur de cascade était bien appliqué (fondu dans le "MULTI" générique, jamais perdu), le user a demandé de le sortir pour lui donner un vrai temps fort. `cascade_mult` retiré du `base_mult` affiché (score réel inchangé) ; nouvelle méthode `ResolutionBanner.play_cascade_announcement(mult)` — texte plus gros, couleur distincte, petit pop d'échelle — jouée une fois par niveau de cascade avant le détail des groupes de ce niveau.

## Brainstorm — build "Dernier Souffle"

En traitant le softlock, discussion sur le potentiel du trigger `on_last_breath` — actuellement le seul des 5 triggers sans aucun Badge. Pistes notées dans `docs/brainstorms/brainstorm-badges.md` (multi dédié au Dernier Souffle, plus de Rocks dans le deck, Bombe à retardement, récompenser le softlock volontaire) : objectif un build "stressant dans le bon sens" où le joueur construit vers ce moment plutôt que de le craindre.

## Points techniques à garder en tête

- `scenes/shop/shop.tscn` a été légèrement modifié par un des boots headless (normalisation UID Godot, même phénomène que la session 4c79...) — cosmétique, sans risque.
- Cache `.godot/` des `class_name` pas à jour après création de `Shell` — un premier boot headless plantait sur "Could not find type Shell", résolu par un passage `--headless --editor --quit-after` pour forcer le rescan. Même phénomène déjà rencontré en session 12.
- Tous les tests de cette session étaient des scripts headless jetables dans le scratchpad, pas versionnés dans le repo — reproductibles si besoin mais rien à committer côté tests.
- GDD mis à jour en profondeur cette session (pas juste ajouté en fin) : `formes.md` corrigeait une fausse affirmation ("T banni"), `triggers.md` et `scoring.md` avaient des sections obsolètes par rapport au code déjà en place avant même cette session.

## Prochaine étape

Rien de formellement décidé pour la suite — la session s'est terminée sur un enchaînement naturel de fixes déclenchés par du playtest actif plutôt que sur un plan fixé à l'avance. Le user a testé abondamment en direct tout du long ; à ce rythme, la suite se dessinera probablement pareil, au fil du jeu plutôt que d'un backlog.
