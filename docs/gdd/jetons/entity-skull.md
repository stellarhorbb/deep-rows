# Jeton Entity-Skull

Le jeton lâché sur la grille par [l'Entity](../univers/personnages/entity.md). Pas un jeton du deck — il arrive de l'extérieur.

## Comportement

- Tombe par gravité dans la colonne ciblée
- **Ne score pas, ne participe à aucun pattern**
- **Reste sur la grille de manière permanente**
- **Survit au [Dernier Souffle](../manche/dernier-souffle.md)** (les rocks explosent, pas les entity tokens)
- Sujet à la gravité normale (si un jeton en dessous disparaît, il tombe)

## Quand il apparaît (revu session 26)

L'[Entity](../univers/personnages/entity.md) le lâche dans une colonne aléatoire non pleine, avec une **chance croissante depuis le dernier drop** plutôt qu'un intervalle fixe : `GameRules.ENTITY_DROP_BASE_CHANCE` (5%) au premier tour qui suit, +`ENTITY_DROP_INCREMENT` (5%) par tour supplémentaire raté. Un pourcentage ne peut pas dépasser 100%, donc le plafond est naturel — pas de règle "forcée" codée à part. Moyenne simulée ~5.3 tours, quasiment identique à l'ancien intervalle fixe (5), mais impossible à compter à l'avance.

Malus de boss GRANDE FAIM : double l'incrément (`EntityManager.drop_chance_multiplier`) plutôt que de diviser l'ancien intervalle par deux — même intention (deux fois plus fréquent), adaptée au système probabiliste.

## Design intent

- **Brise les stratégies de stacking pur** sur une colonne (la colonne peut se boucher)
- **Imprévisibilité réelle, pas juste cachée** (session 26) — la première version testée (intervalle fixe) était comptable au tour près, ce qui tuait la tension ("je sais qu'un skull va tomber dans exactement N tours"). Deux jets de calibrage avant celui-ci : un premier trop généreux en base (20%+10%, moyenne ~3 tours, jugé trop fréquent en playtest), retenu à 5%+5% pour retrouver la fréquence d'origine tout en gardant l'incertitude
- **Base des perturbations futures** — le skull est le premier effet de l'Entity, d'autres s'ajouteront par la couche [modifiers de cellules](../grille/modifiers-cellules.md)

## Liens

- [L'Entity — personnage et perturbations](../univers/personnages/entity.md)
- [Boutons](boutons.md)
- [Rocks](rocks.md)
- [Dernier Souffle](../manche/dernier-souffle.md)
- [Persistance entre manches](../manche/persistance-entre-manches.md) — un skull posé au sommet d'une colonne bloque la persistance du bouton en dessous
