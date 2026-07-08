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
- **Pondération par rareté** (session 14) — Tags et Badges tirés (unitaires et packs) selon `GameRules.RARITY_WEIGHTS` (COMMON=10, UNCOMMON=5, RARE=2, EPIC=1), via `ShopManager._weighted_pick`/`_weighted_sample`. Spéciaux et boutons restent tirés uniformément (pas de champ `rarity`). Poids posés au jugé, jamais playtestés.

## Pas encore implémenté

- Rien côté pondération pour l'instant — reste à retuner les poids au ressenti une fois du contenu Epic réellement testé en jeu.

## Liens

- [Offre mixte](offre-mixte.md)
- [Packs](packs.md)
- [Reroll](reroll.md)
- [Rareté des Badges](../badges/rarete.md)
- [Shore — unlocks](../shore/unlocks.md)
