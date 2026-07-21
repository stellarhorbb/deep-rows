# Session 22 — 11 nouveaux Badges, 9 nouveaux Spéciaux (mangeurs/scoreurs), rework starters

**Date** : 2026-07-21
**Thème** : Grosse session en plusieurs vagues. Nettoyage de dette documentaire, chantier des 11 Badges restés en "idea", deux vagues de nouveaux Jetons spéciaux (Enclume/Pétard à mèche puis Cavalier/Frog/Liane/Crow/Underground/Hypercube), une vraie discussion de fond sur l'identité économique des spéciaux qui a débouché sur le concept "mangeur/scoreur", et une série de rééquilibrages ciblés (starters, Suite, Prime, Cairn).

---

## Nettoyage documentaire

- **Multiplicateur de cascade** — question ouverte fermée : le user juge les cascades multiples assez rares/difficiles pour justifier des multis énormes en récompense, pas un risque à corriger. Retiré de `questions-ouvertes.md`.
- **Confusion Tickets score / monnaie fantôme** — reposée une 3e fois par erreur (en confondant l'onglet `progression` vide de la Google Sheet avec cette "économie" jamais construite), le user a confirmé une dernière fois : Tickets = le score, point, jamais eu de vraie monnaie de progression séparée. Nettoyé partout (`monnaies.md`, `questions-ouvertes.md`, `shore/unlocks.md`, `simple-concept.md`, qui portait aussi un vieux "3 manches/zone" resté faux depuis la session 18) et mémoire perso mise à jour pour ne plus jamais reposer la question.
- **État des lieux Google Sheet** — audit des 7 onglets vs code : `progression` totalement vide (0%, le plus gros trou), `specials` à 3/11 implémentés (73% encore idée), badges à 37 implémentés + 12 idées non triées, boss à 12/12 (rien à faire). A servi de point de départ au reste de la session.

## 11 nouveaux Badges

Revue des 12 badges en "idea" de la Sheet (noms placeholder trouvés, rareté/prix calibrés au jugé sur les badges existants du même gabarit) : **Couronne** (Roi +1.0 au multi de figure), **Diadème** (Dame +3.0, plus fort car plus fragile à conserver sans Fixer), **Regain** (+1 charge de Shake par level up), **Sang-froid** (+5 tickets par charge de Shake dispo, tension avec Regain), **Nouvelle Donne** (+3 tickets cumulés par Shake déclenché), **Brocante** (+3 tickets cumulés par Partition vendue), **Adoubement** (points cumulés par promotion de figure, J+1/C+2/Q+3/K+4), **Rescapé** (+2.0 multi cumulé par manche boss survécue), **Cairn** (compte les Rocks, voir rework plus bas), **Petit Point** (+2 tickets cumulés par Dé à coudre vu au shop), **Refrain** (+0.1 multi cumulé par Partition, indépendant par Partition — contrairement à Escalade musicale qui est globale). Un 12e (**Artificier**, déjà nommé) laissé de côté car dépendant du spécial Pétard à mèche, pas encore construit à ce moment — implémenté plus tard dans la session une fois le spécial en place.

**Infrastructure ajoutée** : 4 nouveaux triggers (`on_shake_used`, `on_sheet_sold`, `on_figure_promoted`, `on_deck_tool_shown`) câblés bout en bout, et un nouveau canal de scoring dans RunContext/RunManager/CascadeResolver — un bonus de multiplicateur **par Partition précise** (pas global), suivant exactement la convention "contributions par badge_id, sum/product" posée en session 18. Catalogue porté à 49 badges actifs (48 + Artificier).

## Starter packs retravaillés

Constat déclenché par un playtest : Le Simplet (Line 3 + Small T) avait ses deux Partitions au même palier de multiplicateur (×1.5) et la même rule (`family`) — aucun vrai écart interne. Vérification des 4 packs day-one : même défaut partout (paires toujours au même palier entre elles). Recomposition des 4 paires à partir des 8 mêmes Partitions (aucune nouvelle), en visant systématiquement un écart facile/dur (multiplicateur + type de rule family/casino) :
- Le Simplet : Line 3 + **Suite** (était Small T)
- Le Généreux : **Small T** + Fibonacci (était Diamond)
- Le Prévoyant : Line 4 + **Diamond** (était Suite)
- Le Collectionneur : inchangé (Square + Prime avait déjà le bon contraste)

**Suite recalibrée** au passage : minimum 3→4 jetons, multiplicateur 2.0→2.5 (pour matcher la Google Sheet, jamais synchronisé depuis le début).

## Spéciaux — vague 1 : Enclume et Pétard à mèche

Le user a fourni les images (`assets/special-tokens/`). **Enclume** (instantané) : pousse le sommet de la colonne tout au fond, réutilise le moule Bombe/Fantôme/Marée. **Pétard à mèche** (nouveau comportement "à retardement") : se pose sur la grille avec un countdown de 3 tours (sprite clignotant rouge/noir, chiffre affiché — généralisation du système déjà construit pour l'entity-skull de Mèche Courte, renommage `TokenData.entity_countdown` → `.countdown`), explose en scorant ses 2 voisins directs, disparaît aussi au Dernier Souffle s'il n'a pas fini.

**Bugs trouvés et corrigés en cascade au playtest** :
- Achat d'Enclume/Pétard sans effet : le circuit shop→deck (`RunManager._deck_composition`, `_increment/decrement_special_count`, `DeckManager.build_deck`) ne connaissait que Bombe/Fantôme/Marée — étendu, et fait préventivement pour les 6 spéciaux de la vague 2 pour ne pas répéter l'oubli.
- Pétard : case vide dans le stream (sprite neutre manquant dans `TokenVisual.SPECIAL_SPRITES`), countdown affiché figé (`sync_sprites` ne rafraîchit jamais un sprite déjà créé — ajout de `_refresh_countdown_labels`, corrige au passage le même bug latent sur Mèche Courte), countdown qui saute de 3 à 2 dès la pose (les fonctions de tick tournent dans le même appel que le drop — ajout d'un flag `just_placed` qui saute le premier tick), score du Pétard jamais affiché à l'écran (même classe de bug que la Bombe, qui doit déjà pousser son score manuellement — nouveau signal `petard_scored`).
- **Artificier** implémenté une fois Pétard disponible (1/4 de chance de créer un Pétard à mèche quand un 5 score, même moule que Poker Face) — 49→50... en fait porté à 49 (Artificier ajouté après le compte de 49, voir doc badges).

## Discussion de fond : à quoi servent les spéciaux ?

Le user a soulevé un vrai doute économique : les spéciaux sont dilués dans le deck (tirage aléatoire, jamais au bon moment) et n'ont souvent aucun bénéfice de score — un joueur rationnel achète plutôt Badges/Partitions/Dés à coudre. Piste explorée en profondeur : un "levier casino" au-dessus de la grille (payer des mouches pour lâcher un spécial au hasard dans une colonne au hasard, en dehors du shop/deck) — bonne idée pour injecter du chaos/fun (constat que le jeu en manque), mais finalement **mise de côté** au profit d'une solution plus simple et plus cohérente avec l'identité "outil ciblé" déjà en place :

**Concept "mangeur/scoreur"** — Cavalier, Frog et Liane (voir vague 2 ci-dessous) mangent et scorent (valeur brute, sans multiplicateur, comme la Bombe/le Pétard) le contenu des cases occupées sur lesquelles ils atterrissent/poussent, au lieu de le décaler. Ça leur donne une vraie raison d'être achetés et positionnés délibérément (dégager un coin précis tout en marquant des points), sans venir concurrencer le vrai moteur de score du jeu (les Partitions, qui passent par toute la chaîne de multiplicateurs — un mangeur ne rivalisera jamais avec un Ring bien équipé, et ce n'est pas le but). Crow et Underground restent de purs "déménageurs", jamais de score.

Sous-discussion notable : le user a observé en playtest que la grille est rarement vraiment engorgée, ce qui affaiblit l'argument "les déménageurs servent à désengorger" — mais renforce celui des mangeurs, qui n'ont pas besoin d'un scénario d'urgence pour être utiles (ils grignotent sur une grille normale aussi). Pistes de tuning évoquées pour faire monter la pression : `ENTITY_DROP_INTERVAL` (le user l'a lui-même passé de 6 à 5 en cours de session — les entity-skulls sont le seul obstacle vraiment permanent du jeu de base, contrairement aux Rocks qui disparaissent au Dernier Souffle). Idée notée pour plus tard : un countdown visible à l'écran avant le prochain drop de skull (télégraphage, cohérent avec le reste du jeu — pas encore codé).

Idées notées pour une session future (pas construites) : synergies badges dédiées aux mangeurs (multiplicateur sur leur score, +1 déplacement, scaling permanent), nouveaux spéciaux scoreurs (Siphon fixe qui draine sa colonne, Comète qui traverse toute une diagonale en un coup, Ver qui ne mange que sa propre famille), et des combos "spécial rencontre Rock" (ex: Frog + Rock → crée un Pétard à mèche) — jugé "inhérent au caractère du spécial" plutôt que badge, pour que ce soit vécu à chaque run sans dépendre d'un tirage.

## Spéciaux — vague 2 : Cavalier, Frog, Liane, Crow, Underground, Hypercube

Le user a fourni les 6 images restantes. Revue une par une avant codage (plusieurs mécaniques ambiguës sur la simple description Sheet) : déplacement en L façon échecs pour Cavalier, saut diagonal pour Frog, croissance à droite pour Liane (fane après 3 tours), vol d'un jeton de sa ligne pour Crow, creusement vers le bas pour Underground (clarifié ensuite : se pose visiblement au fond un tour avant de disparaître, pas de fusion instantanée du dernier échange), et Hypercube réactif au score dans ses 8 cases voisines — le plus lourd des 6, câblé directement dans `CascadeResolver.resolve()` (pas juste un tick GridManager comme les autres) pour dupliquer un jeton scoré et l'ajouter au pool, même mécanisme que la légendaire Last Trick (généralisation de `EventType.TRANSFORM` pour porter une valeur variable plutôt que toujours `LAST_TRICK_VALUE`).

Règle globale validée par le user pour tous les mobiles : ils peuvent atterrir sur une case occupée (le contenu est décalé plus haut dans sa colonne — sauf Crow qui "redépose" en drop normal). Countdown/compteur de déplacement réutilise le champ générique `.countdown`.

**Bugs trouvés et corrigés** :
- Liane bloquait le jeu entièrement au drop (`notify_special_effect_done()` s'était retrouvée piégée dans la mauvaise fonction lors d'un edit précédent mal ciblé — tous les spéciaux étaient en fait affectés, pas juste Liane).
- Frog "disparaissait" en se déplaçant : `sync_sprites()` ne réconcilie jamais un sprite déjà existant dont le contenu logique a changé sans passer par créer/détruire — nouveau signal `mobile_specials_ticked` déclenchant un rebuild complet, corrige Cavalier/Liane/Crow/Underground au passage (même cause).
- Prévisualisation (hover) cassée pour tous les spéciaux ajoutés depuis Bombe/Fantôme/Marée : le hover dupliquait une liste de textures en dur au lieu de réutiliser `TokenVisual`, simplifié.
- Hypercube affichait un 9 (`LAST_TRICK_VALUE`) au lieu de la vraie valeur dupliquée : la logique était corrigée mais pas l'animation visuelle (`_animate_transform`), qui ignorait la clé "value" de l'event et utilisait toujours la constante de Last Trick.

**Rework mangeur/scoreur** (voir discussion ci-dessus) implémenté en fin de session : `_eat_cell` (helper partagé), `move_cavalier`/`move_frog` retournent maintenant `{dest, score}`, `grow_liane` retourne un score — accumulé sur tout le tick et remonté par un nouveau signal `mobile_specials_scored` (un seul message à l'écran même si plusieurs mangeurs mangent le même tour). `insert_into_column` (le helper de décalage) supprimé, devenu mort. Prix des 3 mangeurs remonté de 2 à 3 mouches.

## Rééquilibrages ciblés (fin de session)

- **Prime** — `PRIME_SEQUENCE` étendu à `[2, 3, 5, 7, 11]` (un Valet est premier). N'abaisse pas le plancher de difficulté (2,3,5 seul déclenche toujours), juste une fenêtre haute optionnelle rare, même principe que les fenêtres hautes de Fibonacci.
- **Cairn** — deux corrections successives du user en playtest : (1) doit compter les Rocks à **chaque manche gagnée**, pas seulement aux 4 manches boss (le trigger `on_round_end` existait déjà, juste un `if round % ROUNDS_PER_ZONE` en trop à retirer) ; (2) le calcul en "tous les 10 Rocks, +0.1" sous-évaluait complètement le badge une fois le vrai volume de Rocks calculé (~x1.8 en fin de run, jugé "nul" pour un badge de scaling) — retravaillé en "+0.1 **par** Rock", ce qui le met au même ordre de grandeur qu'Escalade musicale (~x8-x9 en fin de run) ; rareté/prix remontés en conséquence, Rare/6 → **Epic/8**.
- **ENTITY_DROP_INTERVAL** — 6 → 5, changé directement par le user (un skull tous les 5 coups au lieu de 6), pour faire monter la pression de clog en cours de manche.

## Note process

Aucune remarque de process cette session — enchaînement fluide entre discussion de design et implémentation, plusieurs allers-retours de playtest→bug→fix qui ont bien fonctionné.
