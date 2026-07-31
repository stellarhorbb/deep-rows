# Rareté des Sortilèges

Échelle qui dicte la fréquence d'apparition au shop et la puissance relative.

| Rareté | Taux fixe au shop (session 23) | Puissance |
|---|---|---|
| Common | 50% | Boost simple, un seul axe |
| Uncommon | 30% | Boost significatif ou multi-axe |
| Rare | 13% | Changement de règle ou synergie forte |
| Epic | 6% | Build-defining, transforme la stratégie |
| Legendary (session 17) | 1% | Extrêmement puissant, débloqué via le Shore + tirage shop rare |

Portée par le champ `rarity: Rarity` dans `SpellData`.

**Taux fixe par palier, pas par item (session 23)** — `GameRules.SPELL_RARITY_RATES` remplace l'ancien système par poids (`RARITY_WEIGHTS`, toujours utilisé par Spéciaux/Dés à coudre). La différence : avant, ajouter des Sortilèges à un palier rendait ce palier plus fréquent (poids = taux unitaire × nombre de Sortilèges dedans) ; maintenant chaque palier a une probabilité constante peu importe combien de Sortilèges y vivent — ajouter un Epic ne change pas la fréquence du palier Epic, juste la variété dedans (inspiré de Balatro, voir [Génération de l'offre](../shop/generation-offre.md)). Les tirages passent aussi par une [file d'apparition](../shop/generation-offre.md) : un Sortilège vu-et-refusé ne repasse pas avant d'avoir fait le tour du même palier.

## Design intent

- **Common** — filets accessibles qui apparaissent souvent. Sortilèges de départ, boostent sans casser.
- **Uncommon** — le gros du pool, Sortilèges qui valent l'achat.
- **Rare** — le moment "ah celui-là il est cool, je le prends direct". Change comment tu joues.
- **Epic** — build-defining. Tu redessines ton build autour.
- **Legendary** — 5 à 10 Sortilèges au catalogue complet visé, volontairement démesurés. Débloqués principalement via des conditions spéciales au [Shore](../shore/unlocks.md), avec 1% de chance de tirage naturel au shop (`GameRules.SPELL_RARITY_RATES`). **5 écrits en session 23** : Poker Face (10% de chance qu'un jeton qui score gagne +1 de valeur), Sacre (+1.0 multi par figure dans un groupe qui score), Virtuose (les Partitions équipées démarrent au niveau Maestro), Dresseur Fou (les spéciaux mobiles ne disparaissent plus jamais) et Souffle Obscur (deuxième vague au Dernier Souffle, les entity-skulls disparaissent aussi) — chacun capstone d'un pilier du jeu déjà entamé par des Sortilèges de rareté inférieure (figures : Couronne/Diadème ; boss : Rescapé, écarté ; obstacles permanents : unique en son genre), plutôt qu'un système inédit. Tous à 8 mouches, aligné sur les Epic — la rareté du tirage (1%) fait déjà le travail de rendre ça spécial, pas besoin d'un prix gonflé en plus.

## Pool et génération

Le [shop](../shop/offre-mixte.md) tire les Sortilèges par rareté à taux fixe, via une file d'apparition (voir ci-dessus et [Génération de l'offre](../shop/generation-offre.md)). Les Sortilèges Epic sont aussi principalement débloqués au [Shore](../shore/unlocks.md).

## Liens

- [Principe](principe.md)
- [Sortilèges implémentés](sortileges-implementes.md)
- [Shop — génération de l'offre](../shop/generation-offre.md)
- [Shore — unlocks](../shore/unlocks.md)
