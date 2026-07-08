# Level up des Partitions

Les Partitions **montent en niveau par le score cumulé**. Plus tu scores avec une Partition, plus son multiplicateur augmente.

## Vocabulaire musical

Cohérent avec les [grenouilles orchestre](../univers/personnages/grenouilles-orchestre.md). Le niveau affiché combine chiffre (lisibilité) + mot (caractère) :

| Niveau | Nom affiché |
|---|---|
| 1 | **Pianissimo** |
| 2 | **Piano** |
| 3 | **Forte** |
| 4 | **Fortissimo** |
| 5 | **Maestro** |

Affichage typique : `Lv.3 — Forte`.

## Fonctionnement

- Chaque Partition a un **score cumulé** qui monte à chaque résolution déclenchée
- En atteignant des seuils (ex : 150, 400, 800, 1500 pts cumulés), la Partition passe au niveau suivant
- Chaque niveau augmente son multiplicateur de base

**Statut** : vocabulaire musical décidé, seuils et multiplicateurs par niveau à tuner au playtest.

## Design intent

- Récompense la **qualité du placement** — un Trio de 5-5-5 fait monter la barre plus vite qu'un Trio de 1-1-2
- Le build se **spécialise par la performance** — tes Partitions les plus jouées deviennent les plus fortes
- Source principale de **scaling organique** zone après zone
- Les [Badges](../badges/principe.md) peuvent booster le level up ("les cascades comptent double pour le level up")

## Liens

- [Principe](principe.md)
- [Scoring](scoring.md)
- [Catalogue implémenté](catalogue-implemente.md)
- [Sources de scaling](../progression/sources-scaling.md)
