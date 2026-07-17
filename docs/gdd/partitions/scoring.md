# Scoring

**Score = somme des valeurs × mult forme × mult cascade × mult modifiers × mult règle.**

## Multiplicateur fixe par Partition (révisé session 16)

Chaque Partition — lignes comprises — a un **multiplicateur fixe défini sur sa resource `.tres`**, calibré selon la difficulté de placement de sa figure (taille, contrainte de la règle, complexité géométrique sous gravité), peu importe la direction dans laquelle elle se résout. Voir [Catalogue implémenté](catalogue-implemente.md) pour le tableau de tiers et les valeurs.

Ancien système (retiré session 16) : pour les lignes, c'était **la direction du match** qui déterminait le multiplicateur (Verticale x1, Horizontale x1.5, Diagonale x2), pas la longueur — abandonné car cet axe supplémentaire rendait la formule illisible une fois combiné à tous les autres multiplicateurs, et parce que les rainbows/Fibonacci se sont révélés moins durs à l'usage que prévu, indépendamment de leur direction de résolution.

### Losange — deux bases de score différentes (session 12)

Le centre du losange n'entre jamais dans la condition de match, mais son rôle dans le **score** dépend de la rule :

- **Rock** : les 4 jetons du losange sont des rocks, sans valeur — c'est le centre qui est "récolté". `base = valeur du centre`. Si le centre n'est pas un jeton scorable, le score est nul (le match se résout quand même, sans rapporter de points).
- **Famille** (et futures rules) : les 4 jetons du losange sont déjà garantis scorables par la condition de match — le centre est vraiment indifférent, y compris pour le score. `base = somme des 4 jetons du losange`, comme une ligne ou un carré.

## Cascades

x2 par niveau (x2, x4, x8…). `CASCADE_MULTIPLIER_BASE` dans `game_rules.gd`.

Le premier MATCH event = cascade_level 0 (x1). Chaque résolution suivante dans la même chaîne incrémente le niveau.

## Modifiers de cellules

Chaque cellule modifiée traversée par le pattern multiplie le total par son coefficient :

| Modifier | Multi |
|---|---|
| HALF | ×0.5 |
| BOOST | ×1.5 |
| DOUBLE | ×2 |
| TRIPLE | ×3 |

**Dédupliqué par type** (bug corrigé session 18) : plusieurs cellules du même type dans un même pattern ne cumulent plus (deux cellules DOUBLE = ×2, pas ×4) — toucher une case d'un type suffit à l'activer. Des types différents restent cumulatifs entre eux (une case DOUBLE + une case BOOST = ×3). Voir [Modifiers de cellules](../grille/modifiers-cellules.md).

## Multiplicateurs de règle

Alimentés par les [Badges](../badges/principe.md) au `on_round_start`. Stockés dans `RunContext.rule_multiplier_contributions` — dictionnaire gardé par source (`rule → {badge_id → float}`), combiné par **produit** (`RunContext.get_rule_multiplier`, lu par `CascadeResolver._score_group`).

Exemple : le Badge "Famille Unie" pose `family → 2.0` → tous les patterns de rule `family` scorent x2.

## Multiplicateur global (session 13)

`RunContext.global_multiplier_contributions` (`badge_id → float`, combiné par produit via `get_global_multiplier`) — contrairement aux autres champs du contexte (figés au `round_start`), celui-ci peut être **muté en cours de manche** : `RunManager` garde une référence vivante vers le contexte actif, et `set_global_multiplier()` écrit la contribution de ce Badge directement dedans. C'est ce qui permet à un Badge comme Dernier Carré de changer le multiplicateur d'un tour à l'autre selon l'état du deck.

## Bonus par valeur de jeton (session 13)

`RunContext.value_bonus_multiplier_contributions` (`valeur → {badge_id → float}`, combiné par somme via `get_value_bonus_multiplier_sum`). Chaque jeton scorable de cette valeur présent dans la figure qui score ajoute ce bonus au multiplicateur — additif entre jetons, pas multiplicatif (2 jetons à +0.5 donnent x2.0, pas x2.25). Alimenté par les Badges au `round_start` (ex : Petites Mains pose `1 → 0.5`).

**Refactor RunContext (session 18)** : ces trois canaux (règle, global, valeur) partageaient auparavant un même bug — un scalaire écrasé au lieu d'un dictionnaire par source, donc deux Badges sur le même canal s'annulaient l'un l'autre au lieu de cumuler (connu depuis la session 15 pour règle/global, jamais repéré avant pour la valeur). `RunContext` a été réécrit sur un seul pattern (dictionnaire gardé par `badge_id`, combiné par produit ou somme selon le canal) — voir `run_context.gd`. Aucun Badge n'a eu besoin d'être modifié, seul l'interne a changé.

## Bonus flat au value_sum (session 17)

Canal parallèle à `value_bonus_multipliers` (ci-dessus) : au lieu de multiplier, ces Badges **ajoutent directement à `value_sum`**, avant toute la chaîne de multiplicateurs — traités exactement comme si un jeton valait plus cher, pas comme un multiplicateur à part. Calculé par `CascadeResolver._value_sum_bonus`, alimenté par 4 champs de `RunContext` (posés par les Badges au `round_start`, tous cumulatifs entre Badges) :

- **Retrigger** (`retrigger_values : int → true`) — un jeton scorable dont la valeur est marquée recompte sa propre valeur une deuxième fois dans le groupe qui score. Ex : "Vingt-trois" marque {2, 3} → un 3 qui score vaut 6 points. Idempotent : deux Badges qui ciblent la même valeur ne la font pas compter trois fois.
- **Bonus de famille** (`family_score_bonus : Family → int`) — chaque jeton scorable de la famille ciblée présent dans le groupe qui score ajoute ce bonus, peu importe la rule du pattern (session 19, remplace l'ancien "une fois par pattern de rule `family`"). Ex : "Tickets Hivernal" pose `DENIERS → 2` par jeton DENIERS.
- **Bonus de paire** (`pair_score_bonus : int`) — le groupe qui score contient au moins deux jetons de même valeur → bonus ajouté une seule fois (peu importe le nombre de paires). Ex : "Y'en a pas deux".
- **Bonus rangée du haut** (`top_row_score_bonus : int`) — tant qu'au moins une cellule de la dernière rangée de la grille **entière** (pas seulement le groupe qui score) est occupée, chaque pattern qui score ajoute ce bonus. Ex : "Sommet".

Ces bonus sont fondus dans `value_sum`/`base_value` avant multiplication (donc profitent de `shape_mult`/`cascade_mult`/etc. comme un vrai jeton) mais gardent leur attribution individuelle (quel Badge, pour combien) — voir la section Bannière de résolution ci-dessous.

## Bannière de résolution — Badges groupés par type (session 17)

Retour de playtest : dès que 2-3 Badges de cette session contribuent à la même résolution, l'ancien affichage fondu ("BADGE x2.3" en une seule ligne, tous les Badges tiltant simultanément) ne permettait plus de voir *qui* avait déclenché *quoi*, ni dans quel ordre. Remplacé par une séquence en 4 temps, jouée par `ResolutionBanner.play_breakdown` :

1. **Tickets bruts** — `raw_value`, la somme des valeurs des jetons seule, aucun Badge impliqué.
2. **Badges "points" un par un, dans l'ordre des slots** — chaque Badge qui ajoute des points flat (retrigger, famille, paire, rangée du haut, scaling flat) tilte individuellement et affiche sa contribution (`+5 ENCRÉE`), collé juste après les tickets bruts — deuxième retour de playtest : un Badge qui ajoute des points doit apparaître comme faisant partie de la même "somme" que les jetons, pas mélangé avec les Badges multi qui suivent.
3. **Multi intrinsèque** — `base_mult` (forme × modifiers de cellule × level up de la Partition), toujours seul.
4. **Badges "multi" un par un, dans l'ordre des slots** — même principe que l'étape 2 mais pour les multiplicateurs (`x1.5 RÉGULARITÉ`).

Construit par `CascadeResolver._attach_breakdown` à partir de deux dictionnaires calculés à la volée : `_value_sum_bonus` retourne les contributions flat par badge (retrigger/famille/paire/rangée du haut/scaling flat), `_mult_contributions` retourne les contributions multiplicatives par badge (rule/global/value_bonus/scaling mult) — les deux sont fusionnés en une seule liste ordonnée selon `equipped_badges` (`score_breakdown.badge_steps`, chaque entrée taguée `kind: "flat"|"mult"`), que la bannière filtre en deux passes (flat d'abord, mult ensuite) plutôt que de la parcourir une seule fois dans l'ordre des slots. Les modifiers de cellule (Cellule Triple, Tranchée...) restent hors de cette attribution — ils vivent sur la grille en continu, pas sur une résolution ponctuelle, et ont déjà leur propre feedback (bordures colorées).

Important : ce regroupement ne change que l'**affichage**, pas le calcul réel — la formule reste `(value_sum + tous les bonus flat) × (tous les facteurs multi)`, order-independent (voir "Ordre des Badges" dans les décisions du GDD).

## Scaling permanent (session 17)

Deux canaux réservés aux Badges qui **grossissent sur toute la run**, jamais remis à zéro à chaque manche (contrairement à tous les autres champs du contexte) :

- **`scaling_mult_bonus : float`** — facteur additif, applique `(1.0 + scaling_mult_bonus)` dans la formule, à côté de `global_mult` mais avec sa propre attribution (voir `CascadeResolver._attach_breakdown`, distinct exprès de `global_multiplier` pour ne pas entrer en collision avec Dernier Carré/Régularité). Ex : "Jetons sacrés", +0.1 par jeton spécial joué.
- **`flat_score_bonus : int`** — variante inconditionnelle du canal "bonus flat au value_sum" ci-dessus : s'applique à **chaque** groupe qui score, pas seulement sous condition. Ex : "Quatre quart", +5 par pattern de 4 jetons scoré.

Chaque badge de ce type pose sa contribution via `RunManager.set_scaling_mult_bonus`/`set_flat_score_bonus` (clé = son propre id, jamais écrasé par un autre Badge — les contributions de plusieurs Badges scaling s'additionnent). L'état qui *grossit vraiment* (compteur brut, ex : nombre de spéciaux joués) vit dans `RunManager.get_run_badge_state`/`set_run_badge_state`, un dictionnaire séparé de `_badge_state` qui n'est remis à zéro qu'au démarrage d'une nouvelle run (`init_run`), jamais entre deux manches. Nettoyage automatique si le Badge est revendu (`unequip_badge` efface sa contribution).

## Upgrade en direct — Poker Face (session 17)

Un cas à part : pas un multiplicateur, une **mutation du deck** décidée pendant la résolution elle-même plutôt qu'après coup. `RunContext.token_upgrade_chance` (0.0-1.0, cumulatif entre badges) est lu par `CascadeResolver._roll_upgrades` **pendant** `_score_group`, avant que le jeton ne soit retiré de la grille — chaque jeton scorable a cette chance de gagner +1 de valeur dans le deck. Le tirage est nécessairement fait ici (pas dans le badge après coup, comme le reste) : c'est la seule façon de séquencer visuellement "le jeton monte d'un cran" **avant** qu'il disparaisse.

Découpage en 3 étapes, chacune dans sa couche :
1. **`CascadeResolver`** (logique pure) tire et attache `group["upgrade_candidates"]` (cellule + famille + valeur), uniquement pour les groupes retenus après filtrage des doublons/Double Partition. Un nouvel événement `EventType.UPGRADE` est inséré dans la timeline entre le `MATCH` et le `REMOVE` de la même cascade.
2. **`TurnController`** lit cet événement et applique la mutation réelle sur le pool via `RunManager.upgrade_matching_button` (même effet que l'action "Augmenter" des [Dés à coudre](../jetons/boutons.md), recherche un jeton du même family/valeur encore dans le deck).
3. **`GridVisual._animate_upgrade`** joue l'animation juste avant `_animate_remove` : flash doré sur le sprite, et mise à jour du label numérique si `GameRules.DEBUG_SHOW_TOKEN_VALUE` est actif (la valeur des jetons n'a pas encore de représentation visuelle en dehors de ce mode debug).

Premier (et pour l'instant seul) consommateur : "Poker Face", posé au `round_start`.

## Chevauchement de figures — Double Partition (session 13, révisé session 15)

Deux groupes différents peuvent matcher sur des cellules qui se recouvrent (voir [Catalogue implémenté](catalogue-implemente.md) pour le détail et [Décisions tranchées](../meta/decisions-tranchees.md) pour le raisonnement). `CascadeResolver.resolve` calcule le score de tous les groupes candidats, les trie par score décroissant, puis compare chaque candidat à l'ensemble de cellules de chaque groupe déjà retenu :

- **Inclusion totale** (dans un sens ou l'autre — ex : T entièrement contenu dans Plus, mêmes jetons) → simple doublon, seule la mieux payée compte.
- **Chevauchement partiel** (au moins une cellule commune, aucune inclusion totale — ex : Square Rainbow et Brelan qui convergent sur le jeton qu'on vient de poser sans que l'un ne contienne l'autre) → **Double Partition** : les deux scorent, et leur total combiné est multiplié par `GameRules.PATTERN_COMBO_MULTIPLIER` (x2 actuellement). Bannière dédiée dans `ResolutionBanner.play_combo_announcement`, jouée après le détail des deux groupes.

## Formule complète

```
score_group = int(value_sum × shape_mult × cascade_mult × modifier_mult × rule_mult × level_mult × global_mult × value_bonus_mult × scaling_mult)
```

`value_sum` inclut déjà les bonus flat (retrigger, famille, paire, rangée du haut, scaling) avant cette multiplication — voir les deux sections dédiées ci-dessus.

Toutes les valeurs de balancing sont dans `game_rules.gd` et dans les `.tres` des Partitions.

## Liens

- [Principe](principe.md)
- [Formes](formes.md)
- [Level up](level-up.md)
- [Modifiers de cellules](../grille/modifiers-cellules.md)
- [Badges — principe](../badges/principe.md)
