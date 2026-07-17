# Session 19 — Nettoyage GDD, rééquilibrages, et refonte du démarrage de run

**Date** : 2026-07-17
**Thème** : Session en deux temps. D'abord un passage de nettoyage complet du GDD (resynchronisation avec le code après plusieurs sessions denses), suivi d'une série de petits fixes/rééquilibrages au fil du playtest. Finit par un gros chantier de design purement conversationnel : repenser le démarrage de run de fond en comble, de "ça sent le proto" à un vrai système de packs de démarrage déterministes.

---

## Nettoyage global du GDD

Demande du user : trier, mettre à jour, synchroniser avec le code réel, retirer l'obsolète. Passage chapitre par chapitre (Univers → Grille → Jetons → Partitions → Manche → Badges → Shop → Progression → Shore → Meta), 22 fichiers touchés. Points notables trouvés :

- Un bug de doc identique à un vrai bug de code de session 18 (cumul des modificateurs de cellule) répété deux fois dans le GDD
- Le refactor `RunContext` de session 18 jamais documenté
- Tous les chiffres de prix/mouches périmés après les retunes de session 18 (`REROLL_BASE_PRICE`, `BUTTON_UNIT_PRICE`, `FLIES_PER_ROUND_WON`, prix des packs)
- "12 manches", score cible linéaire, "3 manches/zone" encore présents partout malgré la refonte session 18 (20 manches, courbe exponentielle)
- L'inspecteur de deck marqué "pas encore implémenté" alors qu'il est en jeu
- Contenants de shop thématiques (Bocal/Malle/Recueil) présentés comme actuels à plusieurs endroits, alors que la décision (contenant générique) date de la session 12

`questions-ouvertes.md` et `decisions-tranchees.md` synchronisés (items tranchés retirés, décisions manquantes ajoutées). Committé séparément en cours de session (`docs: nettoyage global du GDD`).

## Fix — inspecteur de deck

`DeckManager.get_remaining_tokens()` ne comptait que la pioche restante, oubliant le jeton courant et les jetons en hold — sous-comptait ce qu'il restait réellement à jouer. Corrigé, et la doc de `inspecteur-deck.md` remise à jour au passage (elle disait encore "pas implémenté"). Committé séparément (`fix: inspecteur de deck inclut le jeton courant et le hold`).

## Badges Tickets — bonus par jeton plutôt que par pattern

Discussion partie d'une remarque du user : les 4 Badges "Tickets" (Hivernal/Automnal/Estival/Printanier) ne se déclenchaient qu'une fois par pattern de rule `family` de la bonne famille — mort sur tout l'axe casino (Suite, Brelan, Rainbow...). Passés à +2 par jeton de la famille qui score, peu importe le pattern (`CascadeResolver._value_sum_bonus` boucle maintenant par jeton comme le retrigger, au lieu de checker `group.match_rule`). Descendus de +5 à +2 pour compenser le fait qu'un gros pattern (Ring) peut maintenant en cumuler plusieurs.

## Fix — seuil mouches confortables

`GameRules.get_round_end_flies_bonus` utilisait `>` strict sur `FLIES_BONUS_REMAINING_THRESHOLD` (10) — exactement 10 jetons restants ne déclenchait pas le bonus. Passé à `>=`.

## Outils de deck — Changer de famille à 2 cibles, rééquilibrage rareté

Suite à une discussion sur l'intérêt de recolorer 2 jetons plutôt qu'1 pour mieux ouvrir les builds mono-famille : `DeckToolData.target_count()` étend le multi-cible (déjà utilisé par Fusionner) à Changer de famille. Rééquilibrage complet de la rareté des 10 actions du Dés à coudre en synchro avec la feuille `deck-control` de la Google Sheet (trouvée cette session — un onglet qui existait déjà mais jamais surfacé) :

| Action | Avant | Après |
|---|---|---|
| Changer de famille (×4) | Common, 1 cible | **Uncommon, 2 cibles** |
| Fusionner | Uncommon | **Rare** |
| Fixer | Rare | **Uncommon** |
| Suppression | Rare | **Epic** (premier outil à occuper ce tier) |

## Fibonacci étendu, 3 nouvelles Partitions, suppression de la rareté des Partitions

Trois sujets distincts mais qui se sont enchaînés dans la même conversation :

**Fibonacci** — passe d'une cible fixe (1,1,2,3) à n'importe quelle fenêtre de 4 valeurs consécutives dans la suite étendue 1,1,2,3,5,8. `PatternMatcher` généralisé (`_sequence_windows`/`_find_sequence_matches`, partagé avec la nouvelle Partition Prime).

**3 nouvelles Partitions casino** — constat du user : 17 Partitions actives se sentaient courtes pour un pool cible de 20-30. Premiers candidats évoqués (Mariage/Wedding, Cour/Royal Court, Jackpot/9999 — liés aux figures) se sont révélés être du contenu de fin de run, pas une réponse au manque ressenti *pendant* le run — gardés de côté dans le tiroir rare/signature. À la place : **Minima** (valeurs < 3, ×1.5), **Maxima** (valeurs > 7, ×3), **Prime** (2,3,5,7, fenêtre minimale 3 — même mécanique que Fibonacci généralisée). Balancing final (mult, noms) posé par le user directement sur la Sheet au fil de la conversation. Catalogue passe de 17 à 20 actives.

**Suppression de la rareté des Partitions** — le plus gros changement de design du lot. Parti d'une simple question du user ("des idées pour la rareté des Partitions ?"), la discussion a montré que le principe "plus fort = plus rare" (qui marche pour les Badges, un bonus optionnel) est incohérent pour les Partitions : ce sont la mécanique de résolution elle-même, pas un bonus. Gater les plus fortes derrière une rareté basse revient à priver le joueur d'une partie du jeu qu'il ne croiserait quasiment jamais sur 20 manches — contraire au principe "pas de RNG punitif" déjà appliqué ailleurs. Prix jugé pas totalement fiable non plus comme signal (beaucoup de Partitions viennent de packs à prix plat). Conclusion : le champ `rarity` est supprimé de `PatternData`, toutes les Partitions sont tirées uniformément au shop (unitaires et packs), comme Spéciaux/Boutons.

## Fix — catégories du shop sans doublon par rangée

Repéré par le user : les 4 slots du shop (2 packs + 2 unitaires) tiraient leur catégorie indépendamment — rien n'empêchait de retomber sur "spécial" sur toute une visite. `ShopManager._regenerate_packs`/`_regenerate_unitaires` tirent maintenant les catégories via un shuffle plutôt qu'un tirage indépendant par slot — plus jamais deux packs ou deux unitaires de la même catégorie dans une même rangée.

## Chantier design — refonte du démarrage de run

Discussion longue, entièrement conversationnelle (rien codé), partie d'une remarque du user sur l'écran actuel de sélection de Partition (3 tirées au hasard, 2 choisies) : "ça sent très proto". Plusieurs itérations :

1. **Constat** : le tirage 3/2 est recommençable à volonté en relançant la run — pas un vrai choix, un filtre RNG déguisé. Comparaison Balatro (choix de deck, presque jamais de composition retouchée) / Slay the Spire (personnage = archétype complet).
2. **Direction retenue** : un **pack de démarrage déterministe** (aucun random) remplace l'écran actuel — combine un deck éventuellement retouché, un modificateur de règle/économie (hold, grille, mouches, spéciaux...), et 1-2 Partitions fixes.
3. **Écueil identifié et corrigé** : un deck mono-famille ou mono-valeur casse la mécanique plutôt que de la colorer (mono-famille = résolution quasi garantie, recrée en pire le problème que la grille cabossée corrige déjà ; mono-valeur = tue des pans entiers du catalogue casino). Règle retenue : jouer sur la taille/le contenu spécial/une inclinaison, jamais sur une uniformité totale.
4. **Philosophie bonus-first** : après un premier jet trop orienté malus, pivot vers une majorité de bonus francs — l'objectif est de donner envie de tester TOUS les packs (complétionniste), pas de trouver son préféré. Vérifié que l'interaction avec les Badges existants reste propre sans code spécial (ex : pack "0 hold" + Badge Bénédiction +1 = retour au niveau normal, simple addition).
5. **Fonction du Shore** : finir une run avec un pack débloque du contenu permanent (nouveau pack, Badge, Partition, Spécial) — donne enfin une vraie fonction au Shore. Préféré le modèle "Découvertes" (exploit en jeu) déjà posé dans `shore/unlocks.md` plutôt que "gagner avec X débloque Y", pour rester proche de l'identité du jeu plutôt que de copier un mécanisme de genre.
6. **Vigilance anti-copie-Balatro** — le user a lui-même flagué que le système ressemblait beaucoup à Balatro. Distinction faite entre le squelette (partagé par tout le genre, pas un problème) et l'exécution (modificateurs secs façon stat-block, ça oui c'est très Balatro). Trois leviers retenus pour recoller à l'identité Deep Rows : habillage narratif de chaque pack, préférer les leviers propres au jeu (rocks/grille/hold/cascades) à l'économie pure (mouches/reroll), et le modèle Découvertes plutôt que "gagner avec X".

Tout capturé dans un nouveau brainstorm (`docs/brainstorms/brainstorm-starter-packs.md`) avec deux listes de packs candidats (V1 trop dure, V2 rééquilibrée bonus-first), et répercuté dans `structure-run.md`, `partitions/principe.md`, `shore/unlocks.md`, `shore/principe.md`, `decisions-tranchees.md`, `questions-ouvertes.md`. Rien codé — direction actée, roster et implémentation à faire.

## Statut

- GDD entièrement resynchronisé avec le code (22 fichiers)
- Plusieurs petits fixes/rééquilibrages joués et prêts à tester (Tickets, seuil mouches, Dés à coudre, shop sans doublon)
- Catalogue de Partitions à 20, plus de rareté dessus, Fibonacci généralisé
- **Chantier majeur posé pour la suite** : implémenter le système de packs de démarrage (remplace le draft de Partitions), définir le roster final, construire la sauvegarde inter-runs nécessaire pour le Shore (n'existe pas encore dans le code)
- Idée notée pour plus tard, volontairement différée : un système de Stakes façon Balatro pour les joueurs qui ont tout débloqué
