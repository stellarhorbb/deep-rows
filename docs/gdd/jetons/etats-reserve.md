# États de jetons — réserve

**Déprioritisé** — à implémenter plus tard si le jeu manque de profondeur après les [Badges](../badges/principe.md) et les [modifiers de cellules](../grille/modifiers-cellules.md).

**Revisité en session 25** — l'idée d'un état généralisé (ex. un état "électrique" qui ferait scorer un groupe de jetons connectés en dehors de toute Partition) est ressortie en discussion, mais jugée trop coûteuse à maintenir/comprendre en plus de tout ce qui existe déjà. L'appétit a été redirigé vers une poignée de [spéciaux réactifs](../jetons/specials.md#spéciaux-réactifs--famille-identifiée-session-25) ciblés (Électrique, Cristal, Diamant, Amplificateur), qui réutilisent l'architecture Spécial existante au lieu d'ouvrir une nouvelle couche transversale. Cette page reste en réserve pour un système d'état généralisé — pas remplacée, juste toujours pas prioritaire.

## Principe

Un [bouton](boutons.md) pourrait recevoir un **état** qui ajoute un effet bonus tout en gardant sa famille et son chiffre. Exemple : `Bâtons 4 "Explosif"` — reste un Bâtons 4 pour les patterns, mais déclenche un effet bonus à la résolution.

## Fonctionnement envisagé

- Les recettes d'états seraient débloquées au [Shore](../shore/unlocks.md)
- Une fois débloquée, la recette permettrait d'appliquer l'état à un bouton au shop
- L'état serait permanent pour le run
- Un bouton ne pourrait avoir qu'un seul état

## Pistes d'états

| État | Déclenchement | Effet |
|---|---|---|
| Explosif | Quand résolu dans un pattern | Score aussi tous ses voisins hors pattern |
| Magnétique | Quand résolu | Attire les jetons adjacents vers le vide laissé |
| Réplicateur | Quand résolu | Se copie dans une case vide adjacente avant de disparaître |
| Volatile | Quand résolu | Double sa propre valeur dans le calcul du pattern |

## Risque principal

**Trop d'indicateurs visuels rendent la grille difficile à lire.** À tester quand on aura la vraie DA et qu'on pourra juger la lisibilité.

## Liens

- [Boutons](boutons.md)
- [Badges](../badges/principe.md)
- [Modifiers de cellules](../grille/modifiers-cellules.md)
- [Shore — unlocks](../shore/unlocks.md)
