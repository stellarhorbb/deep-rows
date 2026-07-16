# Inspecteur de deck

Un panneau consultable en cours de manche (touche TAB ou bouton dédié, `DeckInspectorUI`) qui affiche **tout ce qu'il reste au joueur à jouer** cette manche : boutons (famille + valeur), rocks et [jetons spéciaux](../jetons/specials.md), sous forme de comptes agrégés.

## Pourquoi

Avec **un seul passage, pas de reshuffle** ([Décisions tranchées](../meta/decisions-tranchees.md)), ne rien savoir de ce qui reste serait punitif plutôt qu'intéressant — le joueur ne peut ni planifier son [hold](stream-hold.md), ni doser ses prises de risque (ex : garder de la place pour un Fantôme qu'on sait encore dans le deck, ou au contraire savoir qu'il n'en reste plus).

## Ce qu'il montre / ne montre pas

| Affiché | Caché |
|---|---|
| Comptes agrégés par famille + valeur (ex : "3× BÂTONS 6, 1× COUPES 3") | L'ordre de tirage |
| Nombre et type de spéciaux restants | — |
| Nombre de Rocks restants | — |

Le compte inclut la pioche pas encore tirée **ainsi que le jeton courant et les jetons en hold** (`DeckManager.get_remaining_tokens`, corrigé session 19 — ces derniers en étaient exclus par erreur, ce qui sous-comptait ce qu'il restait réellement à jouer). L'ordre de tirage, lui, reste caché : le révéler tuerait la tension du [stream + hold](stream-hold.md) — le joueur compose avec l'incertitude du tirage, pas seulement avec la composition du deck.

## Statut

Implémenté (`DeckInspectorUI`, panneau non-modal, pas de pause du jeu — le joueur peut le laisser ouvert en jouant).

## Liens

- [Deck](deck.md)
- [Stream + Hold](stream-hold.md)
- [Boutons](../jetons/boutons.md)
- [Spéciaux](../jetons/specials.md)
