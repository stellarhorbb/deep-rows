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
- **Pondération par rareté** (session 14) — Dés à coudre et Spéciaux (rareté ajoutée en session 23, voir [Spéciaux](../jetons/specials.md#achat-au-shop)) tirés (unitaires et packs) selon `GameRules.RARITY_WEIGHTS` (COMMON=10, UNCOMMON=5, RARE=2, EPIC=1, LEGENDARY=0.1 — ajouté session 17), via `ShopManager._weighted_pick`/`_weighted_sample` — tirage indépendant avec remise, un item vu-et-refusé peut ressortir au tirage suivant (voulu pour ces deux catégories : usage temporaire, on aime parfois retomber sur le même). Boutons et **Partitions** (rareté retirée en session 19, voir [Décisions tranchées](../meta/decisions-tranchees.md)) restent sans champ `rarity`.
- **File d'apparition pour Badges et Partitions** (session 23, voir `ShopManager._draw_badge_queued`/`_next_sheet_in_queue`) — inspiré de Balatro : contrairement au tirage indépendant ci-dessus, un item vu-et-refusé ne peut pas ressortir avant d'avoir fait le tour complet des autres du même pool (palier de rareté pour les Badges, pool générique/légendaire séparé pour les Partitions). File mélangée une fois par run, remélangée automatiquement une fois épuisée, réinitialisée à chaque nouvelle run (`ShopManager.reset_run`).
- **Taux fixe par palier pour les Badges** (session 23, voir `GameRules.BADGE_RARITY_RATES`) — remplace `RARITY_WEIGHTS` pour les Badges uniquement. COMMON=50%, UNCOMMON=30%, RARE=13%, EPIC=6%, LEGENDARY=1%, indépendant du nombre de Badges dans chaque palier (contrairement au système par poids toujours utilisé par Spéciaux/Dés à coudre) — ajouter un Badge à un palier ne rend plus ce palier plus fréquent, juste plus varié. Un palier sans aucun Badge disponible (tous équipés) est retiré du tirage et les autres se renormalisent automatiquement, même principe que le "resample" de Balatro. Voir [Rareté des Badges](../badges/rarete.md).

## Pas encore implémenté

- Rien côté pondération pour l'instant — reste à retuner les poids au ressenti une fois du contenu Epic réellement testé en jeu.

## Liens

- [Offre mixte](offre-mixte.md)
- [Packs](packs.md)
- [Reroll](reroll.md)
- [Rareté des Badges](../badges/rarete.md)
- [Shore — unlocks](../shore/unlocks.md)
