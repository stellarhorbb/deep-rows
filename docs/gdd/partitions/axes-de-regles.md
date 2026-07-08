# Axes de règles

Les Partitions se construisent sur des axes de règles. Un même axe peut se décliner en plusieurs Partitions avec tailles / conditions différentes.

**Changement important (session 12)** : la valeur ne résout plus de patterns — seuls les axes **famille** et **rock** sont actifs dans le catalogue courant. Les axes "par chiffre" ci-dessous restent documentés pour mémoire et pourraient revenir plus tard (contenu rare, Shore), mais leurs Partitions et le Badge Numérologie sont hors catalogue actif — voir [Boutons](../jetons/boutons.md) et [Catalogue implémenté](catalogue-implemente.md).

## Par famille (matière) — actif

Même famille alignée (ligne, carré, ou losange — voir [Formes](formes.md)). Pousse vers des packs mono-famille et des [Badges](../badges/principe.md) de boost famille (Famille Unie).

Variantes possibles : rainbow (N familles différentes alignées), duo opposé (exactement 2 familles), alternance stricte.

## Par rock — actif

4 rocks en losange autour d'un centre scorable. Boosté par le Badge Collectionneur. Voir [Rocks](../jetons/rocks.md).

## Par chiffre (identité) — dormant

Même chiffre aligné. Pousse vers des packs avec chiffres répétés.

Variantes : tous pairs, tous impairs, alternance pair/impair, tous dans un intervalle.

## Par chiffre (séquence) — dormant

Suites consécutives (3-4-5), Fibonacci, progressions arithmétiques, nombres premiers, carrés parfaits.

Récompense les builds qui maîtrisent l'ordre de placement.

## Par chiffre (arithmétique) — dormant

Somme = cible (ex : 10, 15, 20), produit = cible, moyenne = médiane, différence constante.

## Mixtes — dormant tant que le chiffre est dormant

- Même famille **ET** même chiffre (Parfait)
- Même famille ET suite
- Rainbow ET suite

## Par position sur la grille

- Sur la rangée du bas (facile)
- Sur la rangée du haut (risqué, proche du game over)
- Touchant un bord latéral
- Dans un coin
- Adjacent à un [rock](../jetons/rocks.md)

## Par contexte

- Incluant le jeton qui vient de sortir du hold
- Pendant une cascade (niveau ≥ 2)
- Incluant le dernier jeton droppé

## Catalogue complet

Les pistes non implémentées sont dans `brainstorm-pattern-tags.md` et `docs/content/partitions.csv`.

## Liens

- [Principe](principe.md)
- [Formes](formes.md)
- [Scoring](scoring.md)
- [Catalogue implémenté](catalogue-implemente.md)
