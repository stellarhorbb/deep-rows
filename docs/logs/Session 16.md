# Session 16 — Google Sheet, refonte du mult des Partitions, structure du run (biomes/boss/mode infini)

**Date** : 2026-07-13
**Thème** : Le user a rempli la Google Sheet (Partitions + Badges), ce qui a lancé une discussion de balancing (Vertige, Pourboire) puis une refonte du scoring des Partitions, puis un gros chantier de design sur la structure du run (biomes, boss, mode infini). Session très orientée discussion/GDD, aucun code touché.

---

## Lecture de la Google Sheet

Le connecteur Drive ne remonte que le premier onglet par défaut sur `read_file_content` — contourné en exportant le fichier entier en xlsx (`download_file_content`) et en le parsant avec `openpyxl` pour lire les 4 onglets (partitions, badges, specials, progression).

Nouveautés trouvées :
- **777** et **9999** (idées, axe casino) — rejoignent le tiroir "rare/signature" déjà noté en questions ouvertes
- **Mouche mélomane** (idée, Badge économie) — +5 mouches à chaque level up de Partition, proche de la piste "scaling permanent" du brainstorm Badges

## Balancing décidé, pas encore implémenté

- **Vertige** : le user confirme +10 mouches (pas +5) mais seulement sur une cascade de **profondeur 2+** (pas 1+ comme aujourd'hui) — 2 cascades d'affilée est jugé assez rare pour justifier le montant. Nécessite juste de changer le seuil et la constante dans `effect_vertige.gd`.
- **Pourboire** : passe de `on_round_start` à une fin de manche — doit apparaître sur un futur écran "you win" qui décompte les mouches gagnées sur la manche. Vérifié dans le code : aucun trigger `on_round_end` n'existe aujourd'hui (seulement `on_round_start/on_token_drop/on_cascade_step/on_turn_resolved/on_last_breath`), et aucun écran de ce type n'existe. Plus gros que prévu — reporté après la refonte du mult.

## Refonte du mult des Partitions (décidée, pas encore implémentée)

Point de départ : en remplissant la Sheet, le user trouve l'empilement `direction × cascade × modifiers × rule × level up × global × value bonus` illisible, en particulier l'axe directionnel des lignes (V x1/H x1.5/D x2). Décision : un **multiplicateur fixe par Partition**, peu importe la direction, calibré par tier de difficulté réelle plutôt que par géométrie brute.

Vérifié dans le code avant de proposer des chiffres : `cascade_resolver.gd` écrase déjà `score_multiplier` par la direction pour toute forme `line` — le champ existe sur les `.tres` mais est ignoré. Les valeurs réelles en base (`TOKEN_MIN/MAX_VALUE = 1-5`, `FAMILY_COUNT = 4`) ont aussi corrigé deux intuitions de premier jet : les Rainbow (4 familles distinctes) et Fibonacci sont en fait plus faciles que prévu — avec seulement 4 familles, obtenir 4 familles différentes est statistiquement plus facile qu'obtenir 4 fois la même.

Tiers retenus (voir [Catalogue implémenté](../gdd/partitions/catalogue-implemente.md) pour le détail) : Amorce (x1.5), Facile (x2, inclut désormais Line 4 Rainbow et Square Rainbow), Medium (x2.5, inclut Fibonacci), Difficile (x3, Diamond Rainbow pas encore tranché), Très dur (x4, Cross remonté de x3), Extrême (x5, Ring inchangé), hors échelle (Diamond Rock, 777, 9999).

Au passage, deux valeurs de Rainbow corrigées dans le GDD car périmées : Square/Diamond Rainbow affichaient encore x3/x3.5 (avant les nerfs sessions 14-15), alors que le code est déjà à x2.0 pour les deux.

## Level up : retrait du plafond de Maestro

Le user remarque que Maestro (2200 de score cumulé sur une seule Partition, quasi le budget de score d'un run entier à ~2700) ne rapporte qu'un doublement (x2) — payoff faible pour l'investissement. Décision : garder `[1.0, 1.25, 1.5, 1.75, 2.0]` tel quel pour les niveaux nommés, mais laisser le niveau continuer en "dan" au-delà de Maestro (Maestro 1er dan, 2e dan...), avec un incrément générique plutôt que calé sur un nombre de manches précis. Formule exacte pas tranchée — liée à la fois à la courbe du score cible et à la longueur réelle d'un run.

## Structure du run : biomes, boss, mode infini

Parti d'une question simple (rythme du boss : every 3 ou every 5 ?), la discussion est montée d'un cran vers l'identité du jeu — le user hésite entre l'axe "casino/complétionniste" et l'axe "narratif". Résolu en pointant que `boucle-narrative.md` avait déjà tranché cette question ("double motivation de relancer : mécanique + narrative") et que le modèle cité (Hades) prouve que les deux ne s'opposent pas.

Décisions qui en sortent :
- **Biomes en ordre fixe**, jamais aléatoire — cohérent avec le pilier "la descente" (zone 1 familière → zone finale étrangère), qui n'a de sens que si la position dans la séquence est stable. Modèle Hades : ordre macro fixe, contenu randomisé à l'intérieur.
- **Boss de zone** : malus tiré d'un pool **global et aléatoire** (pas spécifique au biome, façon Balatro) — justifié narrativement par l'Entity, persistante sur toute la run et pas rattachée à un lieu. Contenu du pool de malus non inventé.
- **Contenu à 3 niveaux d'accès** : générique (dispo direct), thématique/biome (débloqué en atteignant un biome, permanent ensuite), achievement/découverte (débloqué par un exploit, ex "5 cascades d'affilée" = spécial rare). Prolonge le pilier "Découvertes" déjà noté dans `shore/unlocks.md`.
- **Grille vs pack, deux rôles séparés** : la grille est liée au biome (identité de lieu, découverte en progressant) ; le pack de boutons devient LE choix structurant de départ façon "deck" Balatro (débloqué au Shore, choisi avant le run). Résout une ambiguïté qui traînait depuis la session 13 ("vision d'origine classes, grille + pack, jamais implémentée").
- **Mode infini** ("Cosmos", nom provisoire à relier à l'univers) : option de continuer après le boss de la zone 4 ("you win" → continuer, façon Balatro post-Ante 8), difficulté croissante jusqu'au game over inévitable. C'est la vraie destination des dan sans plafond et d'une courbe de score cible exponentielle — deux systèmes qui servent peu dans une campagne à durée fixe.

Conséquence directe : les 12 manches actuelles (`ROUNDS_PER_ZONE = 3 × ZONES_PER_RUN = 4`) ne sont plus considérées comme définitives — l'ajout d'une manche boss par zone remet ce chiffre en jeu (exemple discuté : 5 manches/zone → 20 manches/run), sans rien trancher de final.

## GDD mis à jour

Douze fichiers touchés : `scoring.md`, `catalogue-implemente.md`, `formes.md`, `level-up.md` (Partitions), `structure-run.md`, `sources-scaling.md` (Progression), `format.md` (Grille), `unlocks.md` (Shore), `decisions-tranchees.md`, `questions-ouvertes.md`, `00-index.md` (Meta). Nettoyage au passage : référence cassée à `docs/content/*.csv` (dossier qui n'existe plus depuis le passage à Google Sheets) remplacée par le lien vers la Sheet ; question `LINE_MULT_VERTICAL` supprimée (résolue par la décision de retirer l'axe directionnel).

Rien touché côté code/`.tres` — tout ce chantier reste au stade GDD, l'implémentation est la prochaine étape.

## Prochaine étape

Dans l'ordre convenu avec le user : commit de cette session, puis implémentation de la refonte du mult des Partitions (code + `.tres`), puis Vertige/Pourboire (Pourboire nécessite le nouveau trigger `on_round_end` et l'écran "you win").
