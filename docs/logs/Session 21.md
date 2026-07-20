# Session 21 — Malus de boss, rareté légendaire, équilibrage post-première-run

**Date** : 2026-07-20
**Thème** : Session en deux temps. D'abord une discussion sur la densité de contenu et le positionnement du jeu (comparaison Balatro/Sol Cesto/Cult of the Lamb, les 4 profils de joueur à toucher), qui a débouché sur un chantier concret : construire le système de malus de boss de A à Z (12 types, vague par vague). Puis, après la première run complète du user gagnée jusqu'au bout, une série de retours de playtest — un bug, deux équilibrages issus du calcul, et un retravail en deux passes des malus Famille/Partition Ternie.

---

## Discussion identité/positionnement

Le user, en plein doute matinal après avoir regardé un run "NaN" de Balatro, se demandait si Deep Rows était "assez" comparé à la référence du genre. Discussion en plusieurs temps :
- Comparaison au run NaN de Balatro jugée trompeuse (mesure la queue extrême de sa méta post-launch, pas son état day-one).
- Densité de systèmes déjà comparable au Balatro de sortie (24 Partitions, 36+ Badges à ce stade, boucle drop→cascade→résolution conditionnelle).
- Positionnement clarifié via Sol Cesto (roguelite tactique indé, scope solide sans complexité AAA) et Cult of the Lamb — les deux confirment que l'identité de ton (déjà actée dans `docs/gdd/univers/ton.md`, "cute-dérangeant") est un axe de différenciation valide, pas un aveu de faiblesse face à Balatro.
- Objectif "toucher large" (enfant, casual, complétionniste, hardcore synergies) reformulé en 4 couches de profondeur du même jeu plutôt que 4 contenus séparés à construire. Le vrai trou identifié : la couche complétionniste (Shore/glossaire) — déjà au roadmap, volontairement différée, rien de nouveau à inventer.

## Système de malus de boss (12 types)

Constat de départ : `docs/gdd/univers/personnages/entity.md` documentait déjà l'intention de malus de boss, mais rien n'existait en code à part la grille cabossée — qui s'applique en réalité à *chaque* manche, pas seulement aux manches boss (correction d'une fausse piste identifiée en cours de discussion).

Brainstorm collaboratif organisé par axe (grille, pioche/stream, famille/figure, scoring, outils) pour garantir de la variété. 12 malus retenus, noms trouvés en cohérence avec le vocabulaire existant (labels courts, majuscules, ton conte-bizarre de l'Entity) :

- **MAIN LIÉE** — Hold verrouillé pour la manche
- **SOL GELÉ** — Shake désactivé pour la manche
- **PLUIE DE CAILLOUX** — 4 rocks supplémentaires injectés dans le deck
- **COUR ENDORMIE** — aucune promotion de figure (Valet+) pour la manche
- **L'ÉTAU** — 2 colonnes bloquées pour toute la manche
- **CIEL BAS** — la rangée du haut bloquée pour toute la manche
- **COLONNE MAUDITE** — 1 colonne re-tirée au hasard avant chaque drop, avec overlay grisé qui suit
- **GRANDE FAIM** — intervalle de drop de l'Entity divisé par 2
- **BOURRASQUE** — le jeton suivant du stream tombe automatiquement dans la même colonne juste après le current, avant toute résolution
- **MÈCHE COURTE** — chaque entity-skull a un countdown individuel (5→0, sprite qui alterne rouge/noir avec le chiffre affiché), explose en supprimant lui + ses 2 voisins sans les scorer
- **FAMILLE TERNIE** / **PARTITION TERNIE** — voir section dédiée plus bas, retravaillées après la première run

Décision actée : malus **one-shot par manche boss**, jamais de stacking sur la run (contrairement aux Ascension de Slay the Spire) — cohérent avec la décision verrouillée "pas de perte progressive" et avec le modèle Boss Blind de Balatro. Le stacking reste une piste possible pour un futur mode difficile *opt-in* (nouveau starter ou seed dédié), pas pour le jeu de base.

**Infrastructure** : `BossMalusManager` (nouveau, vit dans `RunService` pour survivre aux changements de scène entre manches, pas dans `GameScene` comme `EntityManager`) — pool de 12, tirage sans répétition sur la run (relâché si épuisé, jamais atteint avec 4 manches boss/run). Déclenché dans `TurnController.start_round` juste après `reset_round_modifiers()`.

**Points d'implémentation notables** :
- Hold/Shake/figures/rocks : verrous simples sur `RunManager`, remis à zéro chaque manche comme les canaux Badge existants.
- L'Étau/Ciel Bas : réutilisent le mécanisme de trous de la grille cabossée (`GridManager.add_holes`) plutôt qu'un nouveau système — une colonne/rangée entièrement trouée devient naturellement injouable.
- Colonne Maudite : verrou dynamique sur `GridManager` (`_blocked_column`), re-tiré à chaque retour en attente d'un coup, overlay dédié dans `GridVisual` distinct des trous permanents.
- Bourrasque et Mèche Courte factorisent la logique de drop (`TurnController._drop_token`) pour rejouer la séquence complète (placement + animation + effet spécial) sur un 2e jeton/tick sans dupliquer le code.
- Rareté visuelle : hover tooltip natif Godot sur le label de manche (`ZoneLabel.tooltip_text`), description longue par malus dans `BossMalusManager.DESCRIPTIONS`.

**Bug trouvé et corrigé en playtest** : Mèche Courte détonait la grille (skull + voisins) mais ne déclenchait aucune résolution — l'appel était placé *après* la fin du cycle de résolution du tour, donc rien ne se recalculait avant le prochain drop du joueur. Déplacé juste avant `grid_manager.resolve()` (même point que Bourrasque) : la gravité post-explosion est maintenant une cascade animée normale, plus un téléport muet.

## Rareté légendaire visible au shop

`RarityButton`/`RarityTooltip` (déjà utilisés pour les Badges) étaient déjà câblés pour recevoir la rareté d'une Partition dans les packs et au shop, mais `ShopManager.get_rarity` retournait `-1` pour toute Partition, légendaire ou non — aucun badge coloré ne s'affichait jamais, même pour Lost Corners/Royal Square/Last Trick. Corrigé : une Partition `is_legendary` remonte `LEGENDARY`, les normales restent à `-1` (tirage uniforme inchangé, décision session 19 intacte — ce fix ne touche que l'affichage, pas le tirage).

## Retours de première run complète

Après la première run gagnée par le user (avec Mèche Courte en manche 20), quatre retours d'équilibrage traités avec de vrais calculs :

- **Starter Simplet** : LINE 3 + BRELAN partageaient toutes les deux `shape = &"line"` — remplacé BRELAN par SMALL T pour varier les formes dès le starter "sans filtre".
- **Poids des valeurs de boutons en boutique** : `_random_button()` tirait uniforme sur 1-5, aucune dégression entre les valeurs (seul un jackpot à part vers 10 existait). Ajout de `GameRules.SHOP_BUTTON_VALUE_WEIGHTS` (25/25/25/15/10) — vérifié sur 20 000 tirages, distribution conforme à la cible.
- **`LEGENDARY_SHEET_CHANCE`** : 5% → 3%. Calcul (sur ~19 tirages de Partition/run avec les `CATEGORY_WEIGHTS` actuels) : à 5%, ~7-10% de chance de tomber sur les 3 légendaires dans la même run — trop fréquent pour rester "légendaire". À 3%, tombe à ~2%.
- **Lost Corners jugé trop fort** : son multiplicateur (somme de toute la rangée du bas) n'avait aucune contrepartie — rien n'empêchait d'empiler la rangée et de retrigger le combo à l'infini. Corrigé : la rangée du bas se vide (jetons scorables uniquement, sans les scorer) dès que Lost Corners score, la forçant à se "recharger" à chaque usage. Testé en conditions réelles (grille + Sheet chargée + résolution complète) : coins retirés, jeton scorable balayé, Rock épargné comme prévu.

## Famille Ternie / Partition Ternie — deux passes de retravail

Première version : les deux malus plafonnaient le score du groupe entier à 1 ticket flat. Retravaillé en deux temps à la demande du user :

1. **Famille Ternie** : au lieu de plafonner tout le groupe, chaque jeton de la famille ciblée scort comme s'il valait 1 — les multiplicateurs (sheet + Badges) s'appliquent ensuite normalement sur ce total réduit (ex: Line 3 en 5/2/2 sur la famille ciblée → 1+1+1=3 avant multi, pas 1 flat). `CascadeResolver._effective_token_value`.
2. **Partition Ternie**, proposé en miroir par le user : au lieu de plafonner le groupe, neutraliser à 1.0 le multiplicateur *propre à la Partition* (son `score_multiplier` de base, y compris légendaire dynamique type Royal Square/Lost Corners, + son niveau) — les tickets des jetons et les multi de Badges restent intacts. `_is_score_capped` devenu inutile, supprimé.

**Problème identifié après coup** (par le user, pas anticipé avant implémentation) : Royal Square et Lost Corners n'ont quasiment que leur multiplicateur comme raison d'être — les neutraliser sur un run construit autour de l'une des deux peut faire s'effondrer toute la manche sans aucun moyen de s'y préparer, même logique de RNG punitif que la décision session 19. Corrigé : Partition Ternie ne peut plus jamais cibler une Partition légendaire équipée (filtre sur `is_legendary` avant le tirage) ; si le joueur n'a que des légendaires équipées, le malus ne cible simplement rien ce tour-là. Vérifié sur 500 tirages avec une légendaire + une normale équipées : jamais ciblé la légendaire, cible bien la normale.

## Note process

Deux fois cette session, une question "qu'est-ce que t'en penses ?" du user a été suivie d'une implémentation immédiate dans la même réponse, sans lui laisser le temps de réagir à l'idée avant qu'elle soit déjà dans le code. Retenu pour la suite : répondre par l'avis seul et attendre le feu vert, même en plein enchaînement d'implémentation.
