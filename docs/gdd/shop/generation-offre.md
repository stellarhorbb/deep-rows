# Shop — génération de l'offre

Règles que suit le shop pour piocher son offre à chaque visite.

## Principe

Pool de contenu enrichi progressivement via [les unlocks du Shore](../shore/unlocks.md) (pas encore implémenté). Le shop pioche dans les pools actifs à chaque visite.

## Règles de curation (implémentées)

- Deux rangées séparées, packs fixes + unitaires rerollables — voir [Offre mixte](offre-mixte.md)
- **Catégories random par slot, sans doublon au sein d'une même rangée** (session 19) — les 2 packs sont toujours 2 catégories différentes, pareil pour les 2 unitaires (`ShopManager._regenerate_packs`/`_regenerate_unitaires`, shuffle plutôt que tirage indépendant). Avant ce fix, rien n'empêchait de retomber sur "spécial" sur toute une rangée (voire les deux à la fois) — contraire au principe "pas de RNG punitif" déjà appliqué ailleurs (deck de départ, Entity). Aucune catégorie n'est encore garantie *présente* à chaque visite, juste non-dupliquée : la surprise fait toujours partie du dilemme
- **Pas de doublons** de Badges déjà possédées
- **Pas de doublons** de Partitions déjà équipées
- Pour les boutons/spéciaux, doublons possibles (tu peux acheter 2 Fantômes dans la même run)
- **Pondération par rareté** (session 14) — Badges et Dés à coudre tirés (unitaires et packs) selon `GameRules.RARITY_WEIGHTS` (COMMON=10, UNCOMMON=5, RARE=2, EPIC=1, LEGENDARY=0.1 — ajouté session 17), via `ShopManager._weighted_pick`/`_weighted_sample`. Spéciaux, Boutons et **Partitions** (retirées du système en session 19, voir [Décisions tranchées](../meta/decisions-tranchees.md)) restent tirés uniformément (pas de champ `rarity`). Poids posés au jugé, jamais playtestés.

## Pas encore implémenté

- Rien côté pondération pour l'instant — reste à retuner les poids au ressenti une fois du contenu Epic réellement testé en jeu.

## Liens

- [Offre mixte](offre-mixte.md)
- [Packs](packs.md)
- [Reroll](reroll.md)
- [Rareté des Badges](../badges/rarete.md)
- [Shore — unlocks](../shore/unlocks.md)
