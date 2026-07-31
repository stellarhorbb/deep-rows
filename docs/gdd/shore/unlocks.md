# The Shore — unlocks

Ce que le joueur peut débloquer au Shore pour enrichir ses futures runs.

## Nouvelles [grilles](../grille/format.md)

Nouvelles formes de terrain avec dimensions différentes, layouts spéciaux ([modifiers](../grille/modifiers-cellules.md) pré-placés), mécaniques uniques. Depuis la session 16, la grille est pensée comme **liée au biome** — la découvrir en atteignant une zone pour la première fois est en soi un unlock de type "Thématique/biome" (voir [Structure du run — Biomes](../progression/structure-run.md#biomes)), pas une "classe" choisie en début de run (ce rôle revient au pack de démarrage ci-dessous).

## Nouveaux [packs de démarrage](../progression/structure-run.md#choix-de-départ)

**LE** choix structurant de départ façon "deck" Balatro / "personnage" Slay the Spire — une fois débloqué au Shore, un pack devient sélectionnable au lancement d'une run, fixe et déterministe pour tout le run (deck éventuellement retouché + modificateur de règle/économie + 1-2 Partitions fixes, jamais de random). **Roster figé en session 19, day-one révisé en session 25** : seul Le Simplet reste day-one ; Le Généreux/Le Prévoyant/Le Collectionneur se débloquent en chaîne (gagner une run avec le précédent), les 6 autres restent à débloquer — voir [Structure du run](../progression/structure-run.md#choix-de-départ) et [Brainstorm — Packs de démarrage](../../brainstorms/brainstorm-starter-packs.md#roster-final--jour-1-vs-débloqué-session-19) pour le détail.

## Déblocage en jeu — implémenté (session 25)

Première brique technique de persistance réelle (jusque-là, rien ne survivait à un redémarrage du jeu) :

- **`MetaProgression`** (autoload) — sauvegarde disque (`user://meta_save.tres`) d'une simple liste d'IDs débloqués. Un seul point de vérité, pas de flag `locked` coché à la main par contenu.
- **`unlock_id`** — chaque ressource gatée (Partition, pack) porte un ID technique stable et préfixé par catégorie (`sheet:`, `pack:`), séparé de son nom affiché pour survivre à un renommage. À répliquer pour Sortilèges/Spéciaux/Grilles quand leur tour viendra.
- **Chaîne de déblocage par victoire** — `StarterPackData.unlock_requires_win_of` pointe vers le pack prérequis ; gagner une run avec ce pack (`RunManager.record_starter_win`) débloque le suivant. Implémente pour de vrai le "gagner avec X débloque Y" évoqué en session 19 ci-dessous, appliqué pour l'instant uniquement à la chaîne des 4 packs day-one/proches — pas encore aux 6 packs à débloquer ni aux Découvertes.
- **Contenu verrouillé visible** — un pack pas encore débloqué reste affiché (pas masqué) dans le carrousel de sélection, avec sa condition de déblocage en clair et un bouton désactivé à la place de "COMMENCER".
- **Outils de test** — deux boutons debug sur l'écran de sélection (tout débloquer / reset save), pour ne pas avoir à rejouer chaque unlock un par un en playtest.

## Nouveaux [jetons spéciaux](../jetons/specials.md)

Nouveaux outils qui apparaissent dans le pool du shop.

## Nouvelles [Partitions](../partitions/principe.md)

Nouvelles manières de scorer. Deux tiroirs distincts :

- **5 des 20 Partitions actives** (Plus, Maxima, Cross, Ring, Diamond Rock — voir [Catalogue implémenté](../partitions/catalogue-implemente.md#accès-générique-vs-verrouillé)) sont verrouillées dès aujourd'hui, chacune liée à un pack de démarrage vecteur ci-dessus (double unlock : débloquer le pack débloque aussi la Partition, pour toujours)
- Le **tiroir rare/signature** (9999, Wedding, Royal Court, paires de familles figées) reste un contenu entièrement à part, non implémenté, pour de futures Partitions au-delà des 20 actives

## Nouvelles [Sortilèges](../sortileges/principe.md)

Nouveaux passifs qui enrichissent le pool du shop. Les Cartes [Epic](../sortileges/rarete.md) sont principalement débloquées ici.

## Trois niveaux d'accès au contenu (session 16)

Que ce soit une grille, un pack, un spécial, une Partition ou un Sortilège, le contenu du jeu se répartit en trois niveaux d'accès (voir [Structure du run — Biomes](../progression/structure-run.md#biomes) pour le détail) :

1. **Générique** — disponible dès le début de n'importe quelle run
2. **Thématique/biome** — débloqué en atteignant un biome pour la première fois, toutes runs confondues
3. **Achievement/Découverte** — débloqué par un exploit précis en jeu (voir "Découvertes" ci-dessous)

Une fois débloqué par n'importe lequel de ces trois chemins, le contenu reste acquis pour toujours — le shop doit filtrer sur ce flag "débloqué" avant d'appliquer sa génération pondérée par rareté (session 14, voir [Génération de l'offre](../shop/generation-offre.md)).

## Ressource de meta-progression

À trancher. Pistes :

- **Compteur de progression** accumulé en fin de run (proportionnel à la progression atteinte), nom à trouver — pas "Tickets", qui désigne déjà le score (voir [Monnaies](../progression/monnaies.md))
- **Découvertes** : certains unlocks se font par des achievements en jeu ("former un pattern de 6+ pour la première fois", "finir une manche avec exactement le score cible", "compléter une run sans acheter de spécial", "faire 5 cascades d'affilée")
- **Progression par biome** : atteindre un biome pour la première fois débloque son contenu thématique (voir ci-dessus) — un troisième pilier à côté des deux précédents, pas juste une variante des découvertes puisqu'il est lié à la position dans la descente, pas à un exploit de jeu
- **Combinaison** des trois

**Vecteur privilégié pour les packs de démarrage (session 19)** : gagner une run avec un pack donné débloque du contenu permanent (nouveau pack, Sortilège, Partition, Spécial) — ça donne enfin une vraie fonction au Shore. Mais le déclencheur "gagner avec X débloque Y" est le modèle Balatro/StS/Isaac ; à privilégier plutôt via les **Découvertes** (exploit en jeu, pas seulement victoire) pour rester plus proche du codex de Hades et du pilier "mystères et secrets" ([`univers/ton.md`](../univers/ton.md)) — cohérent avec l'identité du jeu plutôt qu'un unlock générique de genre. "Gagner avec X" reste un déclencheur valable, mais secondaire, pas le seul.

## Liens

- [Principe](principe.md)
- [Boucle narrative](boucle-narrative.md)
- [Monnaies](../progression/monnaies.md)
- [Sources de scaling](../progression/sources-scaling.md)
