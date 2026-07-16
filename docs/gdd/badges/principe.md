# Les Badges — principe

Le vrai build du joueur. Les passifs qui transforment des [boutons](../jetons/boutons.md) ordinaires en machine à scorer.

**Thématiquement, ce sont des badges** — objet physique qu'on épingle sur le vêtement, qu'on accumule, qu'on garde, qu'on collectionne. Un poids différent d'un passif abstrait, raccord avec le gamin perdu qui accroche des badges à mesure qu'il traverse ce monde inconnu.

*Nom code : `BadgeData`, `BadgeEffect`, `BadgeManager`. "Badge" est le terme thématique, en jeu comme dans le code.*

## Fonctionnement

- **Permanents** pour toute la durée du run
- **5 slots maximum** (`MAX_BADGE_SLOTS`) — le joueur doit choisir ses passifs
- Chaque Badge a un [trigger](triggers.md) (quand) et un **effet** (quoi)
- Plusieurs Badges peuvent se combiner — c'est la source des synergies épiques

Sans Badges, les boutons sont plats — ils scorent leur valeur brute dans les patterns. Avec les bons Badges, ils deviennent le moteur d'une machine à combos.

## Architecture technique (option B — un script par badge)

Chaque Badge = un `BadgeData.tres` (métadonnées : label, description, price, trigger) + un script `BadgeEffect` dédié qui porte la logique. Le `BadgeManager` (dans `RunService`) écoute les signaux du `TurnController` et dispatche `apply(event, run_manager)` aux Badges équipés dont le trigger correspond.

**Ajouter un Badge = créer un `.tres` + un script court.** Pas de modif du core.

## Achat au shop

Vendus par les [grenouilles orchestre](../univers/personnages/grenouilles-orchestre.md), dans le [contenant générique](../shop/packs.md) commun à toutes les catégories — ou à l'unité.

Plus chers que les spéciaux parce qu'ils sont structurants. Voir [Économie](../shop/economie.md).

## Synergies

La profondeur du jeu vient des **combinaisons** :
- "Famille Unie" + "Cellule Triple" + pack Mono-Bâtons → les patterns Bâtons scorent ×6 sur la cellule triple
- "Mouches en Cascade" + un Badge qui force des cascades → économie qui explose
- "Tranchée" + Partition "Ligne Horizontale" → build qui exploite les colonnes centrales

Les combinaisons émergentes (non prévues par le designer) sont les meilleures.

## Liens

- [Triggers](triggers.md)
- [Badges implémentés](badges-implementes.md)
- [Rareté](rarete.md)
- [Feedback visuel (à faire)](feedback-visuel.md)
- [Shop — packs](../shop/packs.md)
