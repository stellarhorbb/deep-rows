# Shop — génération de l'offre

Règles que suit le shop pour piocher son offre à chaque visite.

## Principe

Pool de contenu enrichi progressivement via [les unlocks du Shore](../shore/unlocks.md) (pas encore implémenté). Le shop pioche dans les pools actifs à chaque visite.

## Règles de curation (implémentées)

- Deux rangées séparées, packs fixes + unitaires rerollables — voir [Offre mixte](offre-mixte.md)
- **Catégories random** par slot — pas toutes garanties à chaque visite. La surprise fait partie du dilemme
- **Pas de doublons** de Badges déjà possédées
- **Pas de doublons** de Partitions déjà équipées
- Pour les boutons/spéciaux, doublons possibles (tu peux acheter 2 Fantômes dans la même run)

## Pas encore implémenté

- **Pondération par rareté** — les Common devraient apparaître plus souvent, les Epic très rarement. Tirage actuellement uniforme entre les items d'une catégorie, sans regarder `rarity`. Pas urgent : pas encore de contenu Epic dans le catalogue pour que ça compte.

## Liens

- [Offre mixte](offre-mixte.md)
- [Packs](packs.md)
- [Reroll](reroll.md)
- [Rareté des Badges](../badges/rarete.md)
- [Shore — unlocks](../shore/unlocks.md)
