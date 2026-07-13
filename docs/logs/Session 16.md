# Session 16 — Google Sheet, refonte du mult des Partitions, structure du run, implémentation (you-win, Vertige/Pourboire, outils de deck)

**Date** : 2026-07-13
**Thème** : Grosse session en deux temps. D'abord discussion/GDD pure (Sheet, balancing, refonte du mult des Partitions, structure du run biomes/boss/mode infini) — voir sections ci-dessous, commitée en premier. Puis implémentation concrète : le mult des Partitions en code, l'écran de récompense "you win", Vertige/Pourboire, et un gros chantier de généralisation de la Fusion en rubrique d'outils de deck ("Dés à coudre"). Plus deux bugs trouvés et corrigés en testant.

---

## Lecture de la Google Sheet

Le connecteur Drive ne remonte que le premier onglet par défaut sur `read_file_content` — contourné en exportant le fichier entier en xlsx (`download_file_content`) et en le parsant avec `openpyxl` pour lire les 4 onglets (partitions, badges, specials, progression).

Nouveautés trouvées :
- **777** et **9999** (idées, axe casino) — rejoignent le tiroir "rare/signature" déjà noté en questions ouvertes
- **Mouche mélomane** (idée, Badge économie) — +5 mouches à chaque level up de Partition, proche de la piste "scaling permanent" du brainstorm Badges

## Balancing décidé, pas encore implémenté

- **Vertige** : le user confirme +10 mouches (pas +5) mais seulement sur une cascade de **profondeur 2+** (pas 1+ comme aujourd'hui) — 2 cascades d'affilée est jugé assez rare pour justifier le montant. Nécessite juste de changer le seuil et la constante dans `effect_vertige.gd`.
- **Pourboire** : passe de `on_round_start` à une fin de manche — doit apparaître sur un futur écran "you win" qui décompte les mouches gagnées sur la manche. Vérifié dans le code : aucun trigger `on_round_end` n'existe aujourd'hui (seulement `on_round_start/on_token_drop/on_cascade_step/on_turn_resolved/on_last_breath`), et aucun écran de ce type n'existe. Plus gros que prévu — reporté après la refonte du mult.

## Refonte du mult des Partitions (décidée, pas encore implémentée)

Point de départ : en remplissant la Sheet, le user trouve l'empilement `direction × cascade × modifiers × rule × level up × global × value bonus` illisible, en particulier l'axe directionnel des lignes (V x1/H x1.5/D x2). Décision : un **multiplicateur fixe par Partition**, peu importe la direction, calibré par tier de difficulté réelle plutôt que par géométrie brute.

Vérifié dans le code avant de proposer des chiffres : `cascade_resolver.gd` écrase déjà `score_multiplier` par la direction pour toute forme `line` — le champ existe sur les `.tres` mais est ignoré. Les valeurs réelles en base (`TOKEN_MIN/MAX_VALUE = 1-5`, `FAMILY_COUNT = 4`) ont aussi corrigé deux intuitions de premier jet : les Rainbow (4 familles distinctes) et Fibonacci sont en fait plus faciles que prévu — avec seulement 4 familles, obtenir 4 familles différentes est statistiquement plus facile qu'obtenir 4 fois la même.

Tiers retenus (voir [Catalogue implémenté](../gdd/partitions/catalogue-implemente.md) pour le détail) : Amorce (x1.5), Facile (x2, inclut désormais Line 4 Rainbow et Square Rainbow), Medium (x2.5, inclut Fibonacci), Difficile (x3, Diamond Rainbow pas encore tranché), Très dur (x4, Cross remonté de x3), Extrême (x5, Ring inchangé), hors échelle (Diamond Rock, 777, 9999).

Au passage, deux valeurs de Rainbow corrigées dans le GDD car périmées : Square/Diamond Rainbow affichaient encore x3/x3.5 (avant les nerfs sessions 14-15), alors que le code est déjà à x2.0 pour les deux.

## Level up : retrait du plafond de Maestro

Le user remarque que Maestro (2200 de score cumulé sur une seule Partition, quasi le budget de score d'un run entier à ~2700) ne rapporte qu'un doublement (x2) — payoff faible pour l'investissement. Décision : garder `[1.0, 1.25, 1.5, 1.75, 2.0]` tel quel pour les niveaux nommés, mais laisser le niveau continuer en "dan" au-delà de Maestro (Maestro 1er dan, 2e dan...), avec un incrément générique plutôt que calé sur un nombre de manches précis. Formule exacte pas tranchée — liée à la fois à la courbe du score cible et à la longueur réelle d'un run.

## Structure du run : biomes, boss, mode infini

Parti d'une question simple (rythme du boss : every 3 ou every 5 ?), la discussion est montée d'un cran vers l'identité du jeu — le user hésite entre l'axe "casino/complétionniste" et l'axe "narratif". Résolu en pointant que `boucle-narrative.md` avait déjà tranché cette question ("double motivation de relancer : mécanique + narrative") et que le modèle cité (Hades) prouve que les deux ne s'opposent pas.

Décisions qui en sortent :
- **Biomes en ordre fixe**, jamais aléatoire — cohérent avec le pilier "la descente" (zone 1 familière → zone finale étrangère), qui n'a de sens que si la position dans la séquence est stable. Modèle Hades : ordre macro fixe, contenu randomisé à l'intérieur.
- **Boss de zone** : malus tiré d'un pool **global et aléatoire** (pas spécifique au biome, façon Balatro) — justifié narrativement par l'Entity, persistante sur toute la run et pas rattachée à un lieu. Contenu du pool de malus non inventé.
- **Contenu à 3 niveaux d'accès** : générique (dispo direct), thématique/biome (débloqué en atteignant un biome, permanent ensuite), achievement/découverte (débloqué par un exploit, ex "5 cascades d'affilée" = spécial rare). Prolonge le pilier "Découvertes" déjà noté dans `shore/unlocks.md`.
- **Grille vs pack, deux rôles séparés** : la grille est liée au biome (identité de lieu, découverte en progressant) ; le pack de boutons devient LE choix structurant de départ façon "deck" Balatro (débloqué au Shore, choisi avant le run). Résout une ambiguïté qui traînait depuis la session 13 ("vision d'origine classes, grille + pack, jamais implémentée").
- **Mode infini** ("Cosmos", nom provisoire à relier à l'univers) : option de continuer après le boss de la zone 4 ("you win" → continuer, façon Balatro post-Ante 8), difficulté croissante jusqu'au game over inévitable. C'est la vraie destination des dan sans plafond et d'une courbe de score cible exponentielle — deux systèmes qui servent peu dans une campagne à durée fixe.

Conséquence directe : les 12 manches actuelles (`ROUNDS_PER_ZONE = 3 × ZONES_PER_RUN = 4`) ne sont plus considérées comme définitives — l'ajout d'une manche boss par zone remet ce chiffre en jeu (exemple discuté : 5 manches/zone → 20 manches/run), sans rien trancher de final.

## GDD mis à jour

Douze fichiers touchés : `scoring.md`, `catalogue-implemente.md`, `formes.md`, `level-up.md` (Partitions), `structure-run.md`, `sources-scaling.md` (Progression), `format.md` (Grille), `unlocks.md` (Shore), `decisions-tranchees.md`, `questions-ouvertes.md`, `00-index.md` (Meta). Nettoyage au passage : référence cassée à `docs/content/*.csv` (dossier qui n'existe plus depuis le passage à Google Sheets) remplacée par le lien vers la Sheet ; question `LINE_MULT_VERTICAL` supprimée (résolue par la décision de retirer l'axe directionnel).

Rien touché côté code/`.tres` — tout ce chantier reste au stade GDD, l'implémentation est la prochaine étape.

## Implémentation de la refonte du mult des Partitions

`cascade_resolver.gd` unifié : `shape_mult` vient désormais uniquement de `score_multiplier` du tag, pour toutes les formes (plus de branche direction pour les lignes). Code mort retiré (`GameRules.get_direction_multiplier`, `LINE_MULT_*`). 8 `.tres` mis à jour avec les nouvelles valeurs de tier.

**Vérification post-implémentation contre la Sheet** (bon réflexe suggéré par le user) : deux vraies divergences trouvées entre ce qu'on avait discuté en chat et ce que le user avait effectivement tapé dans la Sheet — Carré (poker) à 2.5 pas 2.0, Diamond Rainbow à 2.5 pas 2.0 (tier "pas encore tranché" qu'on avait laissé ouvert). Corrigées dans le code et les docs. Diagnostic au passage : certaines valeurs de la Sheet s'affichaient comme des dates (`1,5` lu comme "1 mai") à cause d'un souci de formatage de cellule Google Sheets, pas une erreur du user.

Deux bugs UI remontés en même temps par `pattern_data.gd`/`tags_ui.gd` : le tooltip et le label en jeu affichaient encore l'ancien "Multi direction : v x1/h x1.5/d x2" pour toutes les lignes peu importe leur vraie valeur — corrigés pour afficher le mult fixe comme les autres formes.

## Vertige et Pourboire

- **Vertige** (`effect_vertige.gd`) : seuil `cascade_level >= 1` → `>= 2`, valeur 5 → 10.
- **Pourboire** : nouveau trigger `on_round_end` ajouté (`badge_data.gd`, `badge_manager.gd` — `_dispatch` retourne maintenant `{label_badge: mouches}` par diff avant/après chaque effet). `badge_pourboire.tres` basculé sur ce trigger, même valeur (+3).

## Écran "you win" (YouWinUI)

Nouveau `scripts/ui/you_win_ui.gd` + noeuds dans `game.tscn`, même principe d'overlay que `ResolutionBanner` (le layout de jeu reste visible derrière). Décompose base (10) + bonus jetons restants (palier exclusif : ≥20 restants = +5, ≥10 = +2, `GameRules.get_round_end_flies_bonus`) + bonus badges `on_round_end`, bouton ENCAISSER qui débloque la suite vers le shop.

Détail demandé par le user : le compteur de mouches affiché en haut à droite ne doit visuellement bouger qu'au clic sur ENCAISSER, pas avant (pour ne pas spoiler le total pendant que le détail s'affiche) — la mutation réelle des mouches reste immédiate (source de vérité simple), seule l'écoute du signal `flies_changed` est suspendue puis resynchronisée manuellement au clic.

## Outils de deck — généralisation de la Fusion ("Dés à coudre")

Parti d'un constat en lisant la Sheet des Badges : trois rubriques existent (économie/grille/multi) mais rien ne touche au deck/aux jetons. Généralisation de la Fusion en 9 actions pondérées par rareté, façon Tarot Balatro — voir [brainstorm-outils-deck.md](../brainstorms/brainstorm-outils-deck.md) pour la genèse complète et le raisonnement détaillé (pourquoi maintenant malgré peu de Badges deck-aware, pourquoi Suppression est Rare, pourquoi Scinder est pair-only, pourquoi le prix reste unique par paquet).

Pool final : Augmenter/Réduire (+1/-1, Common), Changer vers Coral/Shell/Rust/Ink (4 actions distinctes, Common), Scinder et Fusionner (Uncommon — Fusion nerfée : n'est plus garantie par achat), Suppression (Rare). Duplication et jeton arc-en-ciel mis de côté (tier Epic vide).

Implémenté : `scripts/data/deck_tool_data.gd`, 9 `.tres` dans `resources/deck_tools/`, `RunManager` (5 nouvelles méthodes de manipulation du pool), `ShopManager` (chargement du pool, tirage pondéré), `ShopUI`.

**Itération UX en cours de test** : premier jet en 2 écrans (choisir l'action, puis voir les cibles). Le user a fait remarquer après un 1er test que voir cibles et actions en même temps guide le choix et évite de choisir une action sans cible valide dans le tirage — refondu en un seul panneau : candidats et actions affichés ensemble, sélectionner des boutons active/désactive les actions selon leur validité, cliquer une action activée l'applique direct (plus de confirmation séparée).

## Bugs trouvés en testant

- **Crash à l'achat du Dés à coudre** : `_tool_choices` typé `Array[DeckToolData]` alors que `draw_deck_tool_choices()` retourne un `Array` générique (même piège potentiel que partout ailleurs où `_weighted_sample` est utilisé, mais les autres call sites utilisaient déjà un `Array` non typé côté appelant). Corrigé + nettoyage de 3 warnings au passage (division entière, UID manquant, paramètre inutilisé préexistant).
- **Touche Tab plus accessible en jeu pour le deck inspector** : pas causé par cette session — remonte à l'introduction du Shell UI persistant (session antérieure). Root cause : Godot, quand rien n'a le focus, donne le focus clavier au premier contrôle "focusable" trouvé dans la scène dès qu'on appuie sur Tab, avant que l'evenement atteigne `_unhandled_input`. Les boutons VENDRE persistants de `TagsUI`/`BadgesUI` (créés une fois, visibles dès qu'une Partition/Badge est équipée — donc quasi tout de suite) et `DeckButton` dans `shell.tscn` étaient tous focusables par défaut. Fix : `focus_mode = 0` sur les quatre (DeckButton, DeckInspectorUI/CloseButton, sell buttons de TagsUI et BadgesUI) — le clic souris reste inchangé, mais plus aucun ne vole le focus clavier.

## GDD mis à jour (2e passe, post-implémentation)

`badges-implementes.md` (Vertige/Pourboire, 6e trigger), `boutons.md` (section Fusion réécrite en outils de deck), `monnaies.md` (nouvelles sources de mouches + YouWinUI), `decisions-tranchees.md` (outils de deck, trigger `on_round_end`), `questions-ouvertes.md` (outils de deck marqués implémentés), `brainstorm-outils-deck.md` (statut implémenté + révision UX documentée).

## Prochaine étape

Le user continue à jouer/tester. Rien de spécifique convenu pour la prochaine session — probablement plus de contenu (Badges/Partitions) ou reprise du chantier biome/boss selon l'envie du user.
