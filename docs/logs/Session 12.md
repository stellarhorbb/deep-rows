# Session 12 — Badges (ex-Echoes), sélection de Partition de départ, vente

**Date** : 2026-07-02
**Thème** : Chantier posé en fin de session 11 avant le vrai playtest — rename thématique Echo → Badge, écran de choix de Partition de départ, mécanique de vente, 4 nouveaux Badges. Discussion préalable sur le scope de chaque point avant implémentation.

---

## Rename Echo → Badge

Décision : coller au thème couture/épingle déjà en place pour les Partitions, et au fil rouge "gamin perdu qui accumule des badges sur son vêtement". Rename complet — code, dossiers, fichiers, ressources `.tres`, scènes, docs GDD (hors `docs/logs/`, laissés en l'état comme comptes-rendus datés).

- `EchoData`/`EchoEffect`/`EchoManager` → `BadgeData`/`BadgeEffect`/`BadgeManager`, `scripts/echoes/` → `scripts/badges/`, `resources/echoes/` → `resources/badges/`
- `MAX_ECHO_SLOTS` → `MAX_BADGE_SLOTS`, `SHOP_TAG_ECHO_OFFER_COUNT` → `SHOP_TAG_BADGE_OFFER_COUNT`
- `docs/gdd/echoes/` → `docs/gdd/badges/`, `principe.md` réécrit pour parler de badges/épingles plutôt que de cartes
- Vérifié par un boot headless Godot (`--headless --quit`) : zéro warning, zéro erreur après nettoyage du cache `.godot/` (UID de scripts devenus obsolètes après le rename hors-éditeur, régénérées par un passage éditeur headless)

## Sélection de Partition de départ

Nouvel écran `scenes/partition_select/partition_select.tscn`, devient la `main_scene` du projet (et le point de retour après chaque fin de run, via `EndScreenUI`). Tire 3 Partitions au hasard dans tout le catalogue (`RunManager.draft_starter_partitions`), le joueur en choisit 1, gratuite. Les 2 anciens starters codés en dur (`line_family_4`, `line_number_3`) rejoignent le catalogue normal du shop avec un prix (6, à tuner).

Prep rareté : champ `rarity: Rarity` ajouté sur `PatternData` (même enum que `BadgeData`), pas encore de tirage pondéré — juste le terrain pour plus tard.

## Vente de Partitions et Badges

`RunManager.sell_tag`/`sell_badge` : 50% du prix remboursé en mouches, aucun plancher (vendable jusqu'à 0), disponible à tout moment façon Balatro.

Détail d'archi qui a évité un refactor : `TurnController` snapshote les tags équipés dans `PatternManager` au `start_round` — vendre une Partition en cours de manche ne perturbe donc pas la résolution en cours, l'affichage se met à jour à la manche suivante (même principe que le level up des Partitions). Les Badges, eux, sont lus en direct par `BadgeManager` à chaque dispatch — la vente est donc immédiate côté effets et affichage.

**Itération UX en cours de session** : premier jet en "clic n'importe où sur la carte = vend" → retour user immédiat, ventes accidentelles. Remplacé par un vrai bouton **VENDRE** dédié par slot (coin haut-droit, visible seulement si le slot est occupé), créé une fois dans `setup()` et repositionné à chaque `_draw()`.

## 4 nouveaux Badges

Cellule Double, Écume, Pourboire, Numérologie — même archi que les 4 existants (1 `.tres` + 1 script d'effet, zéro modif du core).

**Bug trouvé et corrigé** : Écume ("rangée du bas x1.5") utilisait `GameRules.ROWS - 1` pour désigner la rangée du bas — mais `row 0` est le bas logique (destination de la gravité dans `gravity_system.gd`) et `GridVisual` inverse l'axe pour l'affichage (`visual_row = ROWS - 1 - row`). Donc `ROWS - 1` pointait visuellement vers le **haut**. Corrigé en `row 0`.

## Points techniques à garder en tête

- Le cache `.godot/` a été régénéré pendant cette session (UID de scripts, imports de polices/sprites) — normal que Godot réimporte au premier boot après ce commit
- `docs/content/echoes.csv` référencé dans l'ancienne doc n'a jamais existé — référence retirée au passage
- Slot de hold supplémentaire (idée notée en session 11) toujours pas câblé — nécessite un refactor de `DeckManager._hold` (slot unique → compteur) avant de pouvoir l'écrire comme un badge simple

## Playtest — première vague de retours

Une dizaine de parties plus tard :

- **Ça scale trop vite** : des moves à 250 points dès la manche 6 (Écume + Famille Unie + Partition niveau 3 + boutons fusionnés à 11-14). Cause racine : la fusion de boutons n'avait aucun plafond, question déjà ouverte dans le GDD, tranchée ici (voir plus bas, `MAX_BUTTON_VALUE`).
- **1 seule Partition de départ trop punitif** : si elle ne matche jamais en début de manche, l'entrée en jeu peut être ruinée. Le pick est repassé à **2 Partitions parmi 3** (`PartitionSelectUI`, toggle + bouton "COMMENCER (x/2)").
- **Stacking vertical trop facile / cascades trop rares** : diagnostic plus profond — le jeu n'était ni du Puissance 4 (pas d'adversaire réactif, décision assumée : pas d'IA à construire) ni du Candy Crush (grille jamais dense, jamais de plateau à lire). Le stacking colonne évite le jeu spatial en 2D dans les deux sens à la fois.

## Détour — expérience swap sur plateau plein (branche `experiment/swap-full-grid`)

Test rapide de l'hypothèse "et si on penchait vers Candy Crush" : nouvelle scène isolée (`scenes/experiments/swap_proto/`) réutilisant tel quel `PatternMatcher`/`GravitySystem`/`CascadeResolver` — grille pleine, swap au clic, régénération des cases vidées après chaque résolution.

Verdict après test : **rejeté**. Avec seulement 3 familles, le plateau ne se stabilise jamais (plafond de sécurité à 40 passes systématiquement atteint), et surtout le multiplicateur de cascade existant (`CASCADE_MULTIPLIER_BASE = 2.0`, x2 par niveau) explose littéralement : 100 000 points en 10 coups. Enseignement qui reste valable pour le jeu principal : **ce multiplicateur est fragile dès que la profondeur de cascade augmente**, à surveiller maintenant que les cascades sont voulues plus fréquentes (voir ci-dessous). Le drop reste donc le geste central — pas de pivot vers le swap.

## Retour au drop — family-only et grille cabossée

Plusieurs ajustements convergents pour recréer de la tension spatiale sans toucher au geste :

- **La valeur ne résout plus jamais de pattern** — seule la famille (et rock) compte pour matcher. La valeur devient un pur levier de score, appliqué une fois le match résolu. Les Tags/Badge liés à la valeur (lignes/carré/suite chiffre, Numérologie) restent sur le disque, juste hors catalogue actif.
- **4e famille "Ink"** ajoutée (`TokenData.Family`, `GameRules.FAMILY_COUNT`) — sprites déjà présents dans les assets, câblage à coût quasi nul. Nécessaire pour que le family-only ne soit pas trivial (3 familles = matchs presque garantis partout).
- **Fusion plafonnée à 10** (`GameRules.MAX_BUTTON_VALUE`) — tranche la question ouverte du GDD sur le plafond de valeur après fusion.
- **Grille cabossée** : 5 à 8 trous générés aléatoirement à chaque manche (jamais en row 0, le sol reste garanti). Contrairement à un Rock, un trou est traversé par la gravité sans jamais pouvoir arrêter un jeton — a nécessité de rendre `GravitySystem`, `CascadeResolver` et les 3 spéciaux (Fantôme/Bombe/Marée via `SpecialEffects`) trou-aware, pas juste le point d'atterrissage.
- **Grille passée en 7×7** (au lieu de 6×8) — `GridVisual` repositionné (x=675→600) pour ne pas chevaucher le `StreamUI` avec la largeur en plus.

Verdict user après tests : "vraiment pas mal", ça force à expérimenter.

## Shop v2 — trop de catégories affichées à plat

Retour : le shop donnait le tournis (5 catégories + Fusion en overlay à part, jamais de vue restreinte). Référence donnée : Balatro (2 boosters parmi plusieurs types + 2 cartes visibles + reroll, jamais tout d'un coup).

Découverte en creusant : ce système était **déjà designé dans le GDD** (`docs/gdd/shop/packs.md`, `offre-mixte.md`, `generation-offre.md`, `reroll.md`, HOB-13) mais jamais implémenté — le shop codé plus tôt cette session était explicitement noté "v1, catalogue unitaire sans curation".

Décisions prises en discussion (certaines corrigent le GDD existant) :
- **Un seul contenant générique** pour toutes les catégories (pas 4-5 objets/gestes différents comme documenté) — pas de DA à valider avant que la boucle soit jugée solide.
- **La Fusion devient gatée** derrière un item "Dés à coudre" (une fusion par achat, fermeture auto du panel) plutôt qu'un bouton permanent spammable — devenu nécessaire une fois `MAX_BUTTON_VALUE` en place.
- **Structure finale, à la Balatro** : **2 packs fixes** (jamais régénérés par le reroll) + **2 slots "en vitrine"** (régénérés à chaque reroll, Dés à coudre inclus dedans comme catégorie). Premier jet à 5 slots plats tout-aléatoire s'est révélé insuffisant en pratique (le joueur peut ne jamais croiser une catégorie de toute la visite) — corrigé après un premier retour de test.

Deux bugs trouvés et corrigés pendant la vérification headless : un scope de classe pas encore rescanné par le cache Godot (`PackPanelUI`), et un souci de typage strict GDScript (`Array` générique assigné à `Array[String]`).

## Contenu — 4 Partitions et 6 Badges au total maintenant

Ajoutés cette session : Ligne Famille 5, Family Diamond (Partitions) ; Collectionneur (rock x2, symétrique de Famille Unie), Vertige (bonus si cascade de profondeur 2+, premier badge sur `on_turn_resolved`), Colonne Chanceuse (Badges).

**Family Diamond** a nécessité un vrai changement moteur : `PatternMatcher.find_diamonds` ne reconnaissait que les diamants de Rocks. Étendu pour détecter aussi les diamants "4 jetons scorables de même famille autour d'un centre indifférent".

Deux bugs trouvés au playtest et corrigés :
- **Label UI** : `TagsUI._format_tag_label` affichait "DIAMOND ROCK" en dur pour toute Partition de forme diamant (reliquat de l'époque où une seule existait).
- **Level up ne progressait pas** : le scoring des diamants dépendait du jeton central (`center_token.value`), cohérent pour Diamond Rock (les 4 rocks n'ont pas de valeur, le centre est "récolté") mais pas pour Family Diamond où le centre doit être vraiment indifférent — un centre vide/rock donnait un score de 0, donc aucune progression. Corrigé : les diamants `rule == "rock"` scorent toujours sur le centre, les autres (`family`, futures rules) scorent sur la somme des 4 jetons du losange, comme une ligne ou un carré.

## Points techniques à garder en tête

- Le cache `.godot/` a été régénéré plusieurs fois pendant cette session — normal que Godot réimporte au premier boot après ce commit
- `docs/content/echoes.csv` référencé dans l'ancienne doc n'a jamais existé — référence retirée au passage
- Slot de hold supplémentaire (idée notée en session 11) toujours pas câblé — nécessite un refactor de `DeckManager._hold` (slot unique → compteur)
- **Nerf du multiplicateur vertical (`LINE_MULT_VERTICAL`) discuté mais jamais appliqué** — reste à `1.0`, toujours identifié comme le levier le plus simple contre le stacking colonne
- Branche `experiment/swap-full-grid` conservée avec son historique (proto swap + fix de hang + fix de rendu) au cas où, mais direction abandonnée
- Rien commité depuis `b98d995` malgré l'ampleur du chantier — tout est en attente de validation user

## Prochaine étape

Le user est content de la boucle ("franchement fun"). Prochain palier évoqué : encore plus de Partitions/Badges, cases spéciales sur la grille, malus de boss (zones), et à plus long terme la direction artistique (déjà en tête côté user, pas encore matérialisée). Le nerf du vertical reste la tâche de tuning la plus immédiate et la moins chère.
