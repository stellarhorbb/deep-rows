# Axes de règles

Les Partitions se construisent sur des axes de règles. Un même axe peut se décliner en plusieurs Partitions avec tailles / conditions différentes.

**Changement important (session 12)** : la valeur ne résout plus de patterns sur les formes famille — seuls les axes **famille** et **rock** étaient actifs. **Session 14** : la valeur revient, mais cantonnée à son propre axe séparé (voir "Par chiffre — axe casino" ci-dessous), pas mélangée aux formes famille.

## Par famille (matière) — actif

Même famille alignée (ligne, carré, losange, plus, cross, ring, T — voir [Formes](formes.md)). Pousse vers des packs mono-famille et des [Badges](../badges/principe.md) de boost famille (Famille Unie).

**Rainbow (session 14)** : variante retenue — N familles **toutes différentes** au lieu de toutes identiques. Comme il n'y a que 4 familles (`TokenData.Family`), "toutes différentes" plafonne mathématiquement à des formes de **taille exactement 4** : Square Rainbow, Diamond Rainbow, Line 4 Rainbow. Au-delà (Plus/Cross à 5, Ring à 8), impossible d'avoir 4 familles sans répétition — pas de Rainbow sur ces formes.

**Duo (2 familles) et Alternance (2 familles en alternance stricte) — écartées.** Sans contrainte de position fixe, "exactement 2 familles quelque part" peut être un split 3-1 comme un 2-2 : aucun template visuel unique et reconnaissable d'un coup d'œil, contrairement à Rainbow (toujours "chacune une fois, zéro répétition" peu importe l'arrangement) ou à Famille (toujours "tout pareil"). Leur donner un vrai template (ex : split symétrique N/S vs E/O sur le Diamond) réglerait le problème mais demanderait une logique de matching dédiée par forme, non générique — jugé disproportionné pour le gain. Resterait une piste si un besoin précis émerge.

## Par rock — actif

4 rocks en losange autour d'un centre scorable. Boosté par le Badge Collectionneur. Voir [Rocks](../jetons/rocks.md).

## Par chiffre — axe casino (session 14, à activer)

La valeur redevient un axe de résolution, mais avec deux gardes-fous délibérés pour ne pas reproduire les problèmes de la session 12 :

1. **Vocabulaire séparé, poker/casino** (Suite, Brelan, Carré, Fibonacci...) plutôt que de réutiliser le vocabulaire géométrique de la famille (Ligne/Carré/Losange...) — sépare nettement les deux systèmes dans la tête du joueur, malgré le nom "Carré" qui existe des deux côtés (voir point 2).
2. **Confiné à la Ligne (any direction)** — aucune des autres formes (Carré, Losange, Plus, Cross, Ring, T) ne porte de règle chiffre. Ça évite de réinventer un moteur de détection, réutilise le scan de ligne existant, et surtout ça donne une règle de lecture simple : forme pleine (non-ligne) = toujours famille, ligne = peut-être chiffre. Bonus : "Carré" (poker, 4 même valeur) ne collisionne jamais visuellement avec le Carré 2×2 famille puisqu'il vit sur une ligne, pas sur la forme carrée.

Catalogue retenu (toutes en ligne, any direction, comme les Lignes famille) :

| Partition | Condition | Taille |
|---|---|---|
| Suite | Valeurs consécutives (n, n+1, n+2...) | 3+ |
| Brelan | Même valeur | 3 |
| Carré | Même valeur (clin d'œil poker/quads, pas la forme géométrique) | 4 |
| Fibonacci | N'importe quelle fenêtre de 4 valeurs consécutives dans la suite **1, 1, 2, 3, 5, 8** (1,1,2,3 / 1,2,3,5 / 2,3,5,8 — étendu session 19, pas seulement les 4 premiers termes) | 4 |
| Minima (session 19) | Toutes les valeurs < 3 (`GameRules.MINIMA_MAX_VALUE = 2`) | 3+ |
| Maxima (session 19) | Toutes les valeurs > 7 (`GameRules.MAXIMA_MIN_VALUE = 8`) — demande de la Fusion, le tirage de base plafonne à 5 | 3+ |
| Prime (session 19) | N'importe quelle fenêtre d'**au moins 3** valeurs consécutives dans la suite **2, 3, 5, 7** (2,3,5 / 3,5,7 / 2,3,5,7 — fenêtre minimale, pas fixe contrairement à Fibonacci) | 3+ |

**Lisibilité** : Brelan/Carré/Fibonacci/Prime demandent de lire des chiffres un par un, ce qui avait motivé le family-only en session 12. Compromis retenu : cet axe reste optionnel/spécialisé (un "build casino" choisi), contrairement à avant où la valeur comptait partout par défaut — le coût de lecture n'est payé que par qui choisit ce build. Minima/Maxima restent plus simples à lire (un seuil, pas une égalité/séquence précise) — pensées comme des filets d'entrée/fin de gamme sur cet axe plutôt que des sommets de complexité.

## Genèse — pourquoi ces trois-là (session 19)

Le catalogue de formes (7 primitives) était déjà noté comme épuisé en session 14 — le vrai levier restant, c'est l'axe de règle, pas la géométrie (voir [Décisions tranchées](../meta/decisions-tranchees.md)). Minima/Maxima/Prime comblent le manque ressenti de Partitions *jouables pendant tout le run* (17 actives pour un pool cible de 20-30) sans réinventer une forme — ils tournent sur des valeurs de jetons normales (1-10), pas sur les [figures](../jetons/boutons.md#figures-arcanes-mineurs) qui ne deviennent pertinentes qu'en toute fin de run. Le tiroir "Wedding"/"Royal Court"/"Jackpot" (figures + 9999) reste une piste distincte, volontairement gardée pour le tiroir rare/signature de fin de run — voir [Questions ouvertes](../meta/questions-ouvertes.md).

## Tiroir rare / signature (session 14, hors pool régulier)

Pièces précieuses justement parce qu'elles sont figées, pas génériques — pas un moteur d'expansion du pool, une poignée de récompenses de fin de run :

- **9999 (Jackpot)** — 4 jetons de valeur 9 alignés. N'existe qu'après plusieurs fusions réussies vers 9 (jetons de base 1-5, `MAX_BUTTON_VALUE = 10`) : un vrai jalon de build, pas un tirage de chance.
- **Paires de familles figées** (ex "Cross Deniers+Coupes") — envisagées puis écartées comme axe systématique (RNG punitif si la paire ne tombe jamais dans une run, et 6 paires × 7 formes explose le pool sans identité claire par pièce). Resteraient viables comme loot rare/Shore ponctuel, pas comme contenu de base.

## Par position sur la grille / Par contexte

Ces deux axes (rangée du bas/haut, bord, coin, adjacent à un rock ; incluant le jeton du hold, pendant une cascade, dernier jeton droppé) sont **recadrés côté Badges, pas Partitions** (session 14) — une Partition porte une condition sur la composition des jetons (quoi est posé), pas sur le contexte spatial/temporel (où/quand). Les Badges gèrent déjà ce registre (Dernier Carré réagit au deck, Régularité compte des occurrences). Gardés ici pour mémoire d'idée, à instancier comme Badges le cas échéant.

## Catalogue complet

Les pistes non retenues restent dans `brainstorm-pattern-tags.md`.

## Liens

- [Principe](principe.md)
- [Formes](formes.md)
- [Scoring](scoring.md)
- [Catalogue implémenté](catalogue-implemente.md)
