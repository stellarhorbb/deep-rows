# Jeton Entity-Skull

Le jeton lâché sur la grille par [l'Entity](../univers/personnages/entity.md). Pas un jeton du deck — il arrive de l'extérieur.

## Comportement

- Tombe par gravité dans la colonne ciblée
- **Ne score pas, ne participe à aucun pattern**
- **Reste sur la grille de manière permanente**
- **Survit au [Dernier Souffle](../manche/dernier-souffle.md)** (les rocks explosent, pas les entity tokens)
- Sujet à la gravité normale (si un jeton en dessous disparaît, il tombe)

## Quand il apparaît

L'[Entity](../univers/personnages/entity.md) le lâche dans une colonne aléatoire non pleine **tous les 6 tours joueur** (`ENTITY_DROP_INTERVAL` dans `game_rules.gd`).

## Design intent

- **Brise les stratégies de stacking pur** sur une colonne (la colonne peut se boucher)
- **Imprévisibilité sans être punitive** — le joueur peut anticiper une fois le rythme compris
- **Base des perturbations futures** — le skull est le premier effet de l'Entity, d'autres s'ajouteront par la couche [modifiers de cellules](../grille/modifiers-cellules.md)

## Liens

- [L'Entity — personnage et perturbations](../univers/personnages/entity.md)
- [Boutons](boutons.md)
- [Rocks](rocks.md)
- [Dernier Souffle](../manche/dernier-souffle.md)
