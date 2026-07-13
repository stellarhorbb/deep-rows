# Format de la grille

**Taille actuelle** : 7 colonnes × 7 lignes (`COLS`, `ROWS` dans `game_rules.gd`). Passée de 6×8 à 7×7 en session 12 pour accompagner la [grille cabossée](trous.md) — un format plus carré équilibre mieux la densité de trous entre colonnes et lignes.

Assez grand pour des cascades intéressantes, assez dense pour que les jetons se touchent.

**Objectif** : jamais plus de 30-40 % de remplissage à un instant T.

## Grille cabossée

Depuis la session 12, chaque manche démarre avec quelques **trous** générés aléatoirement sur la grille — voir [Grille cabossée](trous.md) pour le détail. Ce n'est pas une variation du format lui-même (toujours 7×7), mais une couche d'imprévisibilité posée par-dessus à chaque manche.

## La grille comme identité de biome (revu session 16)

Direction revue : la grille n'est plus un choix fait une fois en début de run (ce rôle de "classe" façon Balatro est repris par le [pack de boutons de départ](../progression/structure-run.md#choix-de-départ)). Elle est désormais liée au [biome](../progression/structure-run.md#biomes) traversé — chaque zone a potentiellement sa propre grille, découverte en y entrant, cohérente avec son identité visuelle et narrative plutôt qu'un choix stratégique fait à l'aveugle avant le run. Chaque grille peut quand même orienter vers une stratégie différente :
- Grille large → builds horizontaux (Partitions horizontales plus faciles)
- Grille profonde → builds verticaux et cascades monstrueuses
- Grille à trous → chaos calculé, placements créatifs

**Statut** : pas encore implémenté — la grille est fixe (7×7) pour tout le monde actuellement, aucune variation par biome. Noms et layouts à redéfinir selon les zones de l'univers. Les placeholders maritimes du brouillon initial (Abysses, Récif…) ont été écartés avec le pivot vers l'univers halluciné.

Clin d'œil : l'idée "Grille à trous → chaos calculé" listée ci-dessus a en partie été réalisée en session 12, mais comme couche universelle à chaque manche plutôt que comme trait permanent d'une classe — voir [Grille cabossée](trous.md).

## Liens

- [Gravité et résolution](gravite-resolution.md)
- [Modifiers de cellules](modifiers-cellules.md)
- [Structure du run](../progression/structure-run.md)
