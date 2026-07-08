# Inspecteur de deck

Un écran ou panneau consultable en cours de manche qui affiche **ce qu'il reste à tirer** dans le [deck](deck.md) : boutons (famille + valeur) et [jetons spéciaux](../jetons/specials.md) restants, sous forme de comptes agrégés.

## Pourquoi

Avec **un seul passage, pas de reshuffle** ([Décisions tranchées](../meta/decisions-tranchees.md)), ne rien savoir de ce qui reste serait punitif plutôt qu'intéressant — le joueur ne peut ni planifier son [hold](stream-hold.md), ni doser ses prises de risque (ex : garder de la place pour un Fantôme qu'on sait encore dans le deck, ou au contraire savoir qu'il n'en reste plus).

## Ce qu'il montre / ne montre pas

| Affiché | Caché |
|---|---|
| Comptes agrégés par famille + valeur (ex : "3× Bone-6, 1× Wood-3") | L'ordre de tirage |
| Nombre et type de spéciaux restants | Toute position au-delà de la [preview](stream-hold.md) |
| Nombre de Rocks restants | — |

Cacher l'ordre est essentiel : le révéler tuerait la tension du [stream + hold](stream-hold.md) — le joueur compose avec l'incertitude du tirage, pas seulement avec la composition du deck.

## Statut

Idée validée en session, pas encore implémentée. Forme exacte (modale, panneau latéral, pause ou non) à définir.

## Liens

- [Deck](deck.md)
- [Stream + Hold](stream-hold.md)
- [Boutons](../jetons/boutons.md)
- [Spéciaux](../jetons/specials.md)
