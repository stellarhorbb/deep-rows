# Rareté des Badges

Échelle qui dicte la fréquence d'apparition au shop et la puissance relative.

| Rareté | Fréquence au shop | Puissance |
|---|---|---|
| Common | Fréquent | Boost simple, un seul axe |
| Uncommon | Régulier | Boost significatif ou multi-axe |
| Rare | Peu fréquent | Changement de règle ou synergie forte |
| Epic | Très rare | Build-defining, transforme la stratégie |

Portée par le champ `rarity: Rarity` dans `BadgeData`.

## Design intent

- **Common** — filets accessibles qui apparaissent souvent. Badges de départ, boostent sans casser.
- **Uncommon** — le gros du pool, Badges qui valent l'achat.
- **Rare** — le moment "ah celui-là il est cool, je le prends direct". Change comment tu joues.
- **Epic** — build-defining. Tu redessines ton build autour.

## Pool et génération

Le [shop](../shop/offre-mixte.md) pondère la génération par rareté. Les Badges Epic sont principalement débloqués au [Shore](../shore/unlocks.md).

## Liens

- [Principe](principe.md)
- [Badges implémentés](badges-implementes.md)
- [Shop — génération de l'offre](../shop/generation-offre.md)
- [Shore — unlocks](../shore/unlocks.md)
