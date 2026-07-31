# Shop — packs

**Un seul contenant générique**, réutilisé pour toutes les catégories (Partitions, Sortilèges, Spéciaux, Boutons) — décision prise en session 12, revient sur l'idée initiale d'un contenant thématique différent par catégorie.

## Pourquoi le changement

Le plan initial prévoyait 4 objets et 4 gestes d'ouverture distincts (voir "Historique" plus bas). En le confrontant à l'implémentation réelle, ça representait un investissement de DA/interaction pas encore justifié — la boucle mécanique n'était pas encore jugée solide. Cohérent avec la règle "pas de DA avant validation du fun" : un contenant unique coûte moins cher à prototyper, et l'habillage distinct par catégorie pourra revenir plus tard sans toucher aux données (juste la couche visuelle).

## Format

**1 seule taille** : 3 candidats révélés à l'ouverture, le joueur en garde 1 et ferme.

**Exception : les packs de boutons proposent 5 candidats** plutôt que 3 (`GameRules.PACK_SIZE_BUTTON`). Les boutons sont plus nombreux et individuellement moins déterminants qu'une Partition ou un Sortilège — plus de choix n'y nuit pas à la lisibilité de la même façon.

## Double couche de RNG

- RNG 1 : la catégorie du pack, tirée à l'ouverture du shop (voir [Offre mixte](offre-mixte.md)) — **fixe pour toute la visite**, pas de reroll sur les packs
- RNG 2 : les candidats à l'intérieur sont piochés dans le pool de la catégorie, au moment de l'achat (pas avant)

Combiné au choix du joueur parmi les candidats, ça fait **3 paliers de gratification** (voir le pack apparaître, l'ouvrir, choisir).

## Économie

Les packs coûtent plus cher qu'un unitaire équivalent, mais avec un **meilleur ratio par item** (tu payes le "plus de choix mais random"). Voir [Économie](economie.md) pour les prix actuels.

## Historique — contenants thématiques (abandonné pour l'instant)

| Catégorie | Contenant envisagé | Geste envisagé |
|---|---|---|
| Boutons | Bocal | Casser |
| Partitions | Rouleau (recueil/livret) | Feuilleter + arracher |
| Spéciaux | Malle de music-hall | Ouvrir le couvercle |
| Sortilèges | Bulbe des grenouilles | — |

Piste à ressortir une fois la boucle validée, si le budget DA le permet.

## Liens

- [Offre mixte](offre-mixte.md)
- [Reroll](reroll.md)
- [Économie](economie.md)
- [Grenouilles orchestre](../univers/personnages/grenouilles-orchestre.md)
