# Session 30 — RNG jackpot, contenu Rocks/Skulls, refonte du Couronnement des figures

**Date** : 2026-08-07
**Thème** : Session mixte réflexion + code, partie discutée pendant un run réel du user (Marais 4/5). Plusieurs chantiers indépendants, du plus léger au plus structurant.

---

## RNG jackpot et équilibrage

Le user rapporte un run avec un triple empilement de multiplicateurs (case mystère jackpot ×10, case bonus ×1.5, bonus jackpot Colonne Convoitée ×10) sur un Diamond simple : 4500 tickets pour 150 demandés, Partition Diamond passée de niveau 1 à 4 d'un coup. Décision : ne rien changer — moment "run cassée" rare (3 RNG indépendantes à aligner) et mémorable, plus gênant en apparence qu'en réalité. Noté dans `questions-ouvertes.md` comme point de vigilance : le vrai risque, si ça se reproduit souvent, c'est que n'importe quelle Partition commune peut se faire exploser par le même empilement — corriger à la source (un seul multiplicateur "jackpot-tier" par résolution) plutôt que sur le symptôme (courbe de level) si besoin.

Discussion en parallèle sur le Dés à coudre : le user n'utilise jamais Réduire/Scinder/Changer de famille, uniquement Fusionner. Diagnostic : ces outils ont été pensés pour de la précision de complétion (viser une valeur exacte pour Fibonacci/Suite, compléter une figure famille) plutôt que pour la puissance brute — un playstyle différent de celui joué ce run-là, mais aussi un signal que ce style de jeu est devenu moins intéressant depuis l'arrivée de la Colonne Convoitée et des cases mystère (swings beaucoup plus gros). Resté en discussion, rien de tranché.

## Contenu Rocks & Skulls

Brainstorm sur l'ajout de Partitions dédiées aux Rocks et Skulls, avec la contrainte de créer de vrais nouveaux concepts de score plutôt que des reskins des formes famille existantes. Détour utile : vérification du code a révélé que le contenu Skull existant était déjà riche (Skull Line, Shadow Dance, Adjacence Sombre, Accoutumance, Souffle Obscur) — pas besoin d'en ajouter plus, les skulls étant une ressource semi-contrôlée via la Colonne Convoitée (le joueur peut cibler une colonne pour les faire s'accumuler).

Idée retenue et implémentée pour les Rocks : **Rock Bookends / "SERRE-LIVRES"** — 2 rocks horizontaux (direction imposée, exploite le fait que deux rocks tombent indépendamment par gravité, les aligner sur la même rangée n'est jamais un choix direct du joueur) encadrant 2-3 jetons scorables. Score = somme des jetons entre les rocks, multi = nombre de rocks sur toute la grille au moment du score (même famille de mécanique que Skull Line/Black Hole : lire un état de grille en live). Non légendaire, prix 12.

Autre décision : **Shadow Dance sort du pool légendaire** (5 légendaires restants : Lost Corners, Royal Square, Skull Line, Black Hole, Last Trick), rejoint la file shop normale.

Fix ponctuel : la description tooltip de Diamond Rock était inversée ("autour d'un Rock" au lieu de "coins en Rock, centre récolté").

## Line 3 — découverte d'un doc périmé

En repérant "LINE 3" équipée sur le screenshot du run du user, on a découvert que `catalogue-implemente.md` affirmait à tort que Line 3 avait été retirée du shop et des starters en session 23. En réalité elle n'a jamais quitté le code : elle reste dans `ShopManager.SHEET_PATHS` et sert de socle d'onboarding imposé (`fixed_sheet_a`) sur les 4 starters day-one, pour donner un point d'entrée lisible ("aligne des couleurs") avant de vendre et viser plus fort. Doc corrigée. Décision actée : la garder volontairement achetable au shop malgré la redondance avec Line 4 — filet de sécurité pour de futurs starters plus hardcore, où un joueur pourrait vouloir apaiser son jeu.

## Refonte du Couronnement des figures (le gros chantier)

Point de départ : le user questionne si l'auto-promotion des figures au score est toujours une bonne idée, sentant que ça "punit" un bon score. Vérification dans le code : c'est pire qu'un ressenti — **l'auto-promotion était garantie à 100%** (`CascadeResolver._roll_face_promotions`, aucun jet de probabilité), et **Wedding se détruisait mécaniquement dès son premier succès** (Roi+Reine exigé exactement ; scorer promeut la Reine en Roi, cassant la paire). Royal Court subissait la même chose par décalage de toute la séquence.

Plusieurs pistes explorées et écartées avant la version finale :
- Fix chirurgical (exempter juste les cellules `faces`/`royal_court` de l'auto-promotion) — écarté par le user : trop arbitraire, pas un système, demande de mémoriser une exception.
- Déplafonner Augmenter/Fusion (Dés à coudre) pour atteindre les figures — écarté : `FACE_CARD_VALUES = [11, 12, 15, 20]` n'est pas linéaire, la somme de Fusion ne peut pas produire ces valeurs proprement.
- Couronnement via la Colonne Convoitée uniquement — bonne mécanique (risque/frisson voulu par le user), mais insuffisante seule pour les joueurs qui évitent la CC.
- "Tout rendre accessible" (aucune restriction) — écarté : n'évite pas le problème Fusion, et aplatit le statut "arcanes mineurs" des figures.

**Version finale, deux chemins qui coexistent :**
1. **Couronnement via la Colonne Convoitée** — un jeton déjà à 10+ qui touche un Boost (n'importe quel palier) est promu d'un cran, au lieu de gagner de la valeur.
2. **Nouveau Spécial "Couronnement"** (Epic, prix 4, asset fourni par le user) — déterministe, sans risque, promeut un jeton 10+ adjacent orthogonalement.

Plus aucune promotion automatique au score, pour aucune Sheet. Le malus de boss "Cour endormie" a été déplacé pour bloquer les deux nouveaux chemins plutôt que l'ancien. Vérification a posteriori : le signal `figure_promoted` (trigger du Sortilège Adoubement) aurait été cassé silencieusement si le Couronnement n'était pas routé par `RunManager.promote_matching_button` — corrigé avant de livrer.

**Fichiers touchés** : `cascade_resolver.gd`, `cursed_column_rewards.gd`, `run_manager.gd`, `entity_manager.gd`, `boss_malus_manager.gd`, `game_rules.gd`, `run_context.gd`, `token_data.gd`, `special_effects.gd`, `grid_manager.gd`, `turn_controller.gd`, `game_scene.gd`, `token_visual.gd`, plus les ressources `special_couronnement.tres` et l'asset `couronnement.png`. Doc `boutons.md` réécrite pour la partie Figures, `colonne-convoitee.md` et `specials.md` mis à jour.

## GDD — passe de correction plus large

En creusant les Sheets, on a constaté que `catalogue-implemente.md` désignait comme "non implémentés" plusieurs Sheets en fait déjà en jeu depuis les vagues 1-3 : Skull Line, Shadow Dance, Black Hole, Lost Corners, Royal Square, Last Trick, Wedding, Royal Court, 777, 9999. Corrigé ponctuellement, mais une resynchronisation complète du fichier reste à faire (même chantier déjà identifié pour `sortileges-implementes.md`) — noté dans `questions-ouvertes.md`.

## Process

Le user a recadré une récidive : réponse à une question de design ("les deux peuvent cohéxister non ?") directement suivie d'implémentation complète, sans feu vert explicite. Mémoire mise à jour (4e occurrence du même piège).

## Reste ouvert

- Le Spécial Couronnement n'a pas encore été testé en run réelle — prix (4) et rareté (Epic) posés par cohérence avec le reste du tier, pas calibrés au playtest.
- Résynchronisation complète de `catalogue-implemente.md` (voir ci-dessus).
- Rien de tranché sur le futur du Dés à coudre (Réduire/Scinder/Changer de famille peu utilisés).
- Empilement de multiplicateurs (case mystère + CC) — à surveiller si ça se reproduit souvent.
