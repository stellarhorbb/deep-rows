# Session 25 — Comparaison Raccoin, axe casino (roulette + jauge), famille de spéciaux réactifs

**Date** : 2026-07-27
**Thème** : Session de game design pure (pas de code), partie d'une conversation continue. Point de départ : le user a joué à Raccoin (coin-pusher roguelite) toute une journée en famille et s'est senti "pâle" en comparaison. La discussion a creusé pourquoi, a fini par isoler la vraie cause (fréquence des cascades, structurellement basse à cause du gating par Partition), a exploré puis écarté une réponse structurelle (états de jetons généralisés) au profit de deux réponses plus contenues : un système de jauge/roulette/cases mystère, et une nouvelle famille de spéciaux qui amplifient les résolutions de Partition.

---

## Pourquoi Raccoin "met la honte"

Comparaison posée point par point :

- **Onboarding et contenu** (150 pièces spéciales, 100 jokers) — pas un vrai signal de faiblesse, juste un delta de contenu : Deep Rows a volontairement limité à 4 starters day-one pour rester en proto (décision déjà actée). Pas comparable à ce stade.
- **Le vrai signal : les cascades**. Raccoin cascade parce que sa condition de match est universelle et quasi-inconditionnelle (toute la physique s'enchaîne librement). Deep Rows filtre chaque maillon d'une chaîne par les 4 [Partitions](../gdd/partitions/principe.md) équipées — la probabilité que deux alignements consécutifs matchent chacun un slot équipé est mécaniquement basse. Le user a fait une seule cascade en 4 semaines de playtest.
- Comparaison à Candy Crush : cascade parce que la règle de match est unique (3 pareils alignés, partout, toujours vrai) — contraire à la fragmentation des Partitions. Reproduire cette recette casserait le pilier de résolution conditionnelle (le cœur du puzzle) — écarté.
- Acceptation actée en cours de session : **Deep Rows sera plus un jeu de stratégie qu'un jeu-spectacle comme Raccoin/Balatro** — mais Balatro n'explose pas par fréquence de cascades, il explose par empilement de multiplicateurs sur une résolution unique (mécanique déjà en germe côté Badges/level up des Partitions).

## Axe casino — jauge, roulette, cases mystère

Voir le détail complet : [Axe casino — roulette et cases mystère](../gdd/manche/roulette-casino.md).

Cheminement de la conception (plusieurs fausses pistes avant la version retenue) :

1. Combo meter façon Raccoin évoqué en premier (jauge qui se charge, roulette de bonus à foison — cases mystère, pluie de spéciaux, tours de pièces).
2. Plusieurs mesures de remplissage testées et rejetées : nombre de résolutions (trop rare, 2-5/manche), nombre de jetons posés (linéaire, prévisible, "pas sexy"), vitesse de drop en temps réel (rejeté — aucune mécanique temps réel dans le jeu, irait contre l'identité stratégique tout juste actée).
3. Version retenue : **valeur brute du jeton posé**, sans plafond — lisible (la valeur affichée justifie l'effet) et permet le power-fantasy voulu (un bon build en fin de run spamme la roulette).
4. Seuil : d'abord envisagé comme un ratio de la valeur totale du deck de la manche (auto-scalant), rejeté par le user ("chiffre qui scale sur une décision arbitraire du dev", et ça amortirait justement le snowball recherché). Fixé à **21, pour toute la run** — garantit qu'aucun jeton seul (même un Roi = 20) ne déclenche à lui seul, clin d'œil discret à l'ADN blackjack du projet.
5. Cohabitation avec les cases mystère : plusieurs versions tentées (duo Planter/Récolter, chevauchement de contenu avec `MysteryCellEffects`), toutes jugées pas assez séparées cognitivement. **Tranché en fin de session : séparation totale**, aucun pont entre les deux systèmes — les cases mystère restent purement round-start (quota remonté à 2-4), la roulette n'a plus que ses deux familles propres (voir plus bas).
6. Pool de prix final, après plusieurs tentatives trop larges (Pièces/Capsules façon Raccoin, Récolter, Résolution forcée, accélérer un level up — toutes écartées pour des raisons précises, voir [doc dédié](../gdd/manche/roulette-casino.md#ce-qui-a-été-écarté)) : **deux familles seulement**, Multiplicateur (x1.2/x3/x10 selon palier, sur le prochain drop uniquement) et Frog (1/2-3/5 exemplaires du spécial Frog, "cadeau des grenouilles orchestre" — lien narratif léger, pas de DA). Rareté = uniquement l'ampleur, jamais la mécanique, inspiré de Raccoin ("pièces vs capsules, la rareté c'est juste le nombre") mais traduit dans le vocabulaire du jeu plutôt que copié.

## Implémentation (même session, même conversation)

Codé en une passe puis retouché après plusieurs bugs trouvés en playtest immédiat par le user :

- `RouletteManager` (nouveau, vit dans `RunService`) : jauge, seuil, tirage palier/famille (`RouletteRewards`, nouveau, même moule que `MysteryCellEffects`), signaux `roulette_triggered`/`gauge_changed`/`multi_status_changed`
- Le multiplicateur réutilise `RunManager.set_global_multiplier` (système déjà en place pour les Badges) plutôt que d'inventer un nouveau mécanisme
- UI : jauge + label dynamique (`RouletteGauge`/`RouletteGaugeLabel`), indicateur pulsant "heartbeat" du multiplicateur en attente (`RouletteMultiLabel`, disparaît si le drop suivant ne score pas), animation de défilement réutilisant la cadence du roll du Diamond Rock (`ResolutionBanner.play_prize_spin_announcement`)

**Deux bugs trouvés et corrigés en playtest, même famille de cause** — poser un jeton hors du pipeline normal du joueur est plus fragile qu'il n'y paraît :

1. **Blocage complet du jeu** (`Tween started with no Tweeners`) — les Frogs étaient posés en plein milieu du tour du joueur, avant que son propre pipeline d'animation soit terminé, collision directe. Fix : mettre les effets qui touchent la grille en attente plutôt que de les exécuter immédiatement.
2. **Frog invisible jusqu'au coup suivant** — même différé, le Frog "poppait" au lieu de tomber visuellement. Cause réelle : `GridManager.place_token` pour un Special n'écrit pas encore dans la grille, ça attend `execute_special`, censé arriver seulement après la fin de l'animation de chute — appeler les deux d'affilée désynchronisait la pose logique de l'animation. Fix : nouvelle méthode `TurnController.drop_bonus_token` qui réutilise le vrai pipeline animé dans le bon ordre, plutôt que d'appeler `GridManager` directement. Le déclenchement lui-même a aussi été déplacé de `turn_resolved` à `awaiting_input` (le premier sort avant que l'état ne soit vraiment stabilisé) puis affiné une troisième fois pour aussi attendre la fin du popup visuel avant de lâcher les Frogs (sinon spin et chute se chevauchent) — deux conditions indépendantes (`_turn_ready` et `_banner_ready`) doivent être réunies.

**Confirmé fun par le user immédiatement après** : "c'est fun ça redynamise bien le jeu depuis qu'on a ajouté les cellules mystère et la roulette !"

## Famille de spéciaux réactifs

Après avoir écarté un système d'états de jetons généralisé (trop coûteux à maintenir/comprendre, cf. [États de jetons — réserve](../gdd/jetons/etats-reserve.md)), la discussion a convergé vers une poignée de spéciaux ciblés qui amplifient une résolution de Partition sans jamais devenir eux-mêmes une figure — extension du type **Réactif** déjà amorcé par Hypercube. Détail complet et raisons des idées écartées : [Spéciaux — famille réactive](../gdd/jetons/specials.md#spéciaux-réactifs--famille-identifiée-session-25).

Retenus : **Électrique**, **Cristal**, **Diamant**, **Amplificateur**. Deux autres idées apportées par le user depuis le Google Sheet, **Comète** et **Siphon**, rejoignent en fait des familles déjà existantes (Instantané et Mangeur) plutôt que la nouvelle famille Réactif — bonne diversité d'archétypes plutôt que des variations d'une seule idée.

Écartés en cours de route : **Rouille** (négatif pur = contenu mort dans un pool achetable), **Domino** (redondant avec ce que `CascadeResolver` fait déjà), **Résine** (deux versions tentées, deux angles morts différents — pas de gain réel de cascade, puis pas de contrôle joueur sur le placement).

## Prochaines étapes

- Les 4 spéciaux réactifs (Électrique/Cristal/Diamant/Amplificateur) restent à coder — nouveaux `SpecialType`, hooks dans `CascadeResolver`/`GridManager`
- Calibrage fin des chiffres de la roulette (seuil, valeurs multi, nombre de Frogs) au playtest prolongé
- Passe UI/juice plus poussée sur la roulette (voir questions ouvertes du GDD) — le premier jet fonctionne mais reste visuellement plat
- Synergies Badges/Boss malus sur la roulette et les cases mystère, pas encore spécifiées
