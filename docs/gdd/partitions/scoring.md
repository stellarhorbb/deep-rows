# Scoring

**Score = somme des valeurs × mult forme × mult cascade × mult modifiers × mult règle.**

## Multiplicateur fixe par Partition (révisé session 16)

**Décidé, pas encore implémenté** : chaque Partition — lignes comprises — a désormais un **multiplicateur fixe défini sur sa resource `.tres`**, calibré selon la difficulté de placement de sa figure (taille, contrainte de la règle, complexité géométrique sous gravité), peu importe la direction dans laquelle elle se résout. Voir [Catalogue implémenté](catalogue-implemente.md) pour le tableau de tiers et les valeurs cibles.

Ancien système (encore actif dans le code aujourd'hui, à remplacer) : pour les lignes, c'était **la direction du match** qui déterminait le multiplicateur (Verticale x1, Horizontale x1.5, Diagonale x2), pas la longueur — abandonné car cet axe supplémentaire rendait la formule illisible une fois combiné à tous les autres multiplicateurs, et parce que les rainbows/Fibonacci se sont révélés moins durs à l'usage que prévu, indépendamment de leur direction de résolution.

Carrés, losanges et toutes les autres formes gardent le même principe qu'avant : un multiplicateur défini dans leur resource `.tres`.

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

**Cumulatif** : deux cellules DOUBLE dans un même pattern = ×4. Voir [Modifiers de cellules](../grille/modifiers-cellules.md).

## Multiplicateurs de règle

Alimentés par les [Badges](../badges/principe.md) au `on_round_start`. Stockés dans `RunContext.rule_multipliers: Dictionary` (StringName → float), lus par `CascadeResolver._score_group`.

Exemple : le Badge "Famille Unie" pose `family → 2.0` → tous les patterns de rule `family` scorent x2.

## Multiplicateur global (session 13)

`RunContext.global_multiplier: float` — contrairement aux autres champs du contexte (figés au `round_start`), celui-ci peut être **muté en cours de manche** : `RunManager` garde une référence vivante vers le contexte actif, et `set_global_multiplier()` l'écrit directement dedans. C'est ce qui permet à un Badge comme Dernier Carré de changer le multiplicateur d'un tour à l'autre selon l'état du deck. Écrase au lieu de cumuler si deux Badges dynamiques sont équipés en même temps — même limitation connue que les rule_multipliers.

## Bonus par valeur de jeton (session 13)

`RunContext.value_bonus_multipliers: Dictionary` (int valeur → float bonus). Chaque jeton scorable de cette valeur présent dans la figure qui score ajoute ce bonus au multiplicateur — additif entre jetons, pas multiplicatif (2 jetons à +0.5 donnent x2.0, pas x2.25). Alimenté par les Badges au `round_start` (ex : Petites Mains pose `1 → 0.5`).

## Chevauchement de figures — Double Partition (session 13, révisé session 15)

Deux groupes différents peuvent matcher sur des cellules qui se recouvrent (voir [Catalogue implémenté](catalogue-implemente.md) pour le détail et [Décisions tranchées](../meta/decisions-tranchees.md) pour le raisonnement). `CascadeResolver.resolve` calcule le score de tous les groupes candidats, les trie par score décroissant, puis compare chaque candidat à l'ensemble de cellules de chaque groupe déjà retenu :

- **Inclusion totale** (dans un sens ou l'autre — ex : T entièrement contenu dans Plus, mêmes jetons) → simple doublon, seule la mieux payée compte.
- **Chevauchement partiel** (au moins une cellule commune, aucune inclusion totale — ex : Square Rainbow et Brelan qui convergent sur le jeton qu'on vient de poser sans que l'un ne contienne l'autre) → **Double Partition** : les deux scorent, et leur total combiné est multiplié par `GameRules.PATTERN_COMBO_MULTIPLIER` (x2 actuellement). Bannière dédiée dans `ResolutionBanner.play_combo_announcement`, jouée après le détail des deux groupes.

## Formule complète

```
score_group = int(value_sum × shape_mult × cascade_mult × modifier_mult × rule_mult × level_mult × global_mult × value_bonus_mult)
```

Toutes les valeurs de balancing sont dans `game_rules.gd` et dans les `.tres` des Partitions.

## Liens

- [Principe](principe.md)
- [Formes](formes.md)
- [Level up](level-up.md)
- [Modifiers de cellules](../grille/modifiers-cellules.md)
- [Badges — principe](../badges/principe.md)
