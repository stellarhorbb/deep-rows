# Les Jetons spéciaux

Les **outils** — coups d'éclat qu'on achète au shop et qu'on joue au bon moment.

**Usage unique à l'utilisation, achat persistant tant qu'il n'est pas joué** (session 15). Un spécial acheté reste dans le deck manche après manche jusqu'à être réellement posé sur la grille — il n'est jamais reperdu "gratuitement" à la fin d'une manche où le joueur ne l'a pas utilisé. La seule façon d'en obtenir un autre est d'en racheter au shop. Le joueur peut en acheter 2-3 pour une manche qu'il sent chaude — ils sont volontairement peu chers et jetables.

## Principes

- Pas de famille ni de chiffre — ils ne participent pas aux [patterns](../partitions/principe.md)
- Ce sont des **outils** qui modifient la grille ou le contexte
- Doivent être assez impactants pour justifier l'achat
- Le joueur les time — LE bon moment dans LA bonne manche

## Spéciaux implémentés (proto)

| Nom | Type | Effet |
|---|---|---|
| **Bombe** | Instantané | Détruit une zone 3×3 autour de sa cellule d'impact |
| **Fantôme** | Posé | Traverse toute la colonne, pousse les jetons vers le haut et laisse un résidu en row 0 |
| **Marée** | Instantané | Pousse la ligne autour du point d'impact vers la gauche et la droite |

## Deux types de comportement

- **Instantanés** — effet immédiat à l'impact, ne restent pas sur la grille
- **Posés** — effet persistant pour la manche, disparaissent au [Dernier Souffle](../manche/dernier-souffle.md) (bonus + explosion)

## Catalogue futur

Pistes brainstorm : Transformateur, Gravité inversée, Abîme, Prisme, Ancre, Corrosif, Siphon, Dualité. Plus thématique : Grenouille qui saute, Cactus, Poudrière.

Catalogue complet (statut + idées + prix) dans `docs/content/specials.csv`.

## Achat au shop

Vendus dans des **malles de music-hall** par les [grenouilles orchestre](../univers/personnages/grenouilles-orchestre.md) — à l'unité ou en pack (3 choix, tu en gardes 1). Très accessibles parce que jetables.

## Liens

- [Boutons](boutons.md)
- [Rocks](rocks.md)
- [Dernier Souffle](../manche/dernier-souffle.md)
- [Shop — packs](../shop/packs.md)
- [Shop — économie](../shop/economie.md)
