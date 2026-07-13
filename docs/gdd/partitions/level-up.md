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
- En atteignant des seuils (150, 500, 1100, 2200 pts cumulés, retunés session 15), la Partition passe au niveau suivant
- Chaque niveau applique un **multiplicateur séparé** (`tag_level_multipliers`, actuellement `[1.0, 1.25, 1.5, 1.75, 2.0]`), qui se multiplie par-dessus le multiplicateur de base de la Partition — jamais fondu dans ce multiplicateur de base lui-même. Choix voulu : ça permet de tuner la courbe de level up **une seule fois pour tout le catalogue** (au lieu d'une courbe par Partition), et ça laisse la porte ouverte à des Badges qui ciblent spécifiquement l'axe "niveau" (accélérer le level up, lire le niveau d'une Partition comme condition...) sans toucher aux resources `.tres`, qui resteraient sinon un état muté à l'exécution plutôt que des données statiques

## Au-delà de Maestro — les "dan" (piste décidée, session 16)

Maestro (niveau 5, x2.0) est un **plafond dur** aujourd'hui. Or atteindre ce niveau demande 2200 de score cumulé sur une seule Partition — proche du budget de score total d'un run entier (~2700 sur 12 manches actuellement) — donc c'est un investissement de quasi fin de run pour un payoff qui reste modeste (un simple doublement).

Direction retenue : **retirer le plafond**. Au-delà de Maestro, la Partition continue de monter en "dan" (Maestro 1er dan, 2e dan...) — même vocabulaire musical, pas de nouveaux noms. Chaque dan ajoute un **incrément générique** (seuil + multiplicateur) plutôt qu'une valeur calée sur un nombre de manches précis, pour ne pas avoir à retuner la courbe à chaque fois que la longueur d'un run change (voir la remise en question de `ROUNDS_PER_ZONE`/`ZONES_PER_RUN` dans [Structure du run](../progression/structure-run.md)).

C'est la vraie destination de ce système : dans une run classique, Maestro arrive en toute fin, les dan ne servent jamais vraiment. C'est en [mode infini](../progression/structure-run.md#mode-infini) que les dan prennent tout leur sens — un run qui va loin doit pouvoir continuer à faire monter ses Partitions indéfiniment.

**Statut** : direction actée, formule exacte des incréments (seuil et multiplicateur par dan) volontairement laissée ouverte — à trancher avec la courbe du [score cible](../manche/score-cible.md) (elle-même probablement exponentielle en mode infini) une fois qu'on a de vraies données de scaling à calibrer dessus. Voir [Questions ouvertes](../meta/questions-ouvertes.md).

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
