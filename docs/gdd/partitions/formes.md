# Formes supportées

Sept primitives au total (session 13 : Plus, Cross, Ring et T ont rejoint Ligne/Carré/Losange — le veto initial sur le T a été levé une fois qu'une vraie identité visuelle s'est dégagée).

## Ligne droite de 3+

Horizontale, verticale, ou diagonale (montante / descendante). Les jetons doivent être exactement alignés sur un axe, **sans trou**.

Pas de direction imposée par défaut : une Partition "Ligne famille" accepte les 4 axes, et depuis la session 16 la direction n'influence plus le score — chaque Partition ligne a un multiplicateur fixe comme les autres formes (voir [Scoring](scoring.md), décidé mais pas encore implémenté). Certaines Partitions exigent tout de même une direction spécifique pour matcher (ex : "Ligne Chiffre 4 Horizontale" ne score que sur l'axe horizontal) — ça reste une contrainte de détection, indépendante du multiplicateur.

## Carré 2×2

Quatre jetons formant un bloc 2×2 plein. Multiplicateur fixe porté par la Partition.

## Losange (diamond)

Quatre jetons disposés en croix autour d'un centre (haut/bas/gauche/droite). Le centre **n'entre jamais dans la condition de match** — peu importe ce qu'il y a dessus.

Deux variantes (`PatternMatcher.find_diamonds`) :
- **Rock** : les 4 jetons du losange sont des [rocks](../jetons/rocks.md). Le centre doit être un jeton scorable pour que le match rapporte des points (c'est lui qui est "récolté").
- **Famille** (session 12) : les 4 jetons du losange sont de même famille. Le centre est vraiment indifférent, y compris pour le score — voir [Scoring](scoring.md) pour le détail (les deux variantes ne scorent pas sur la même base).

## Plus (croix orthogonale)

Cinq jetons : un centre + haut/bas/gauche/droite. Contrairement au losange, **le centre entre dans la condition de match** — les 5 jetons doivent être de la même famille. `PatternMatcher.find_plus`.

## Cross (croix diagonale)

Même principe que Plus, mais sur les 4 diagonales plutôt que les 4 côtés. `PatternMatcher.find_cross`.

## Ring (cadre 3×3)

Le grand frère du losange : les 8 jetons du cadre 3×3 autour d'un centre, qui reste indifférent (comme le losange, pas comme Plus/Cross). Rareté épique — 8 jetons de même famille d'affilée est volontairement très rare. `PatternMatcher.find_ring`.

## T (tétromino)

Quatre jetons : une barre de 3 + un pied au centre, dans une des 4 orientations — peu importe laquelle, même score. Une seule orientation retenue par pivot pour éviter de compter plusieurs fois le même cluster (un Plus complet contient toujours 4 T valides simultanément). `PatternMatcher.find_t`.

## Ligne — contenant partagé famille et chiffre (session 14)

La Ligne 3+ est la seule forme utilisée par les deux axes de règles : famille (voir [Axes de règles](axes-de-regles.md)) et le nouvel axe casino chiffre (Suite/Brelan/Carré/Fibonacci). Toutes les autres formes (Carré, Losange, Plus, Cross, Ring, T) restent exclusivement famille — division volontaire pour que le joueur sache d'un coup d'œil quoi vérifier : forme pleine = famille, ligne = famille ou chiffre.

## Formes à développer plus tard

Brainstorm en exploration dans `brainstorm-pattern-tags.md` — pyramides (`Chapelle`), carrés 3×3 pleins, etc. À autoriser si on veut étendre le pool.

## Liens

- [Principe](principe.md)
- [Axes de règles](axes-de-regles.md)
- [Scoring](scoring.md)
- [Catalogue implémenté](catalogue-implemente.md)
- [Rocks](../jetons/rocks.md)
