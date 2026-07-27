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
5. Cohabitation avec les cases mystère : le quota de départ de manche (déjà codé session 24) est conservé plutôt que remplacé — la roulette vient s'ajouter via un duo **Planter** (pose une case mystère, pari différé) / **Récolter** (résout une case mystère existante, immédiat) plutôt que de dupliquer le système de cases mystère à l'intérieur de la roulette (première version, jugée confuse — une surprise qui en déclenche une autre en différé).

## Famille de spéciaux réactifs

Après avoir écarté un système d'états de jetons généralisé (trop coûteux à maintenir/comprendre, cf. [États de jetons — réserve](../gdd/jetons/etats-reserve.md)), la discussion a convergé vers une poignée de spéciaux ciblés qui amplifient une résolution de Partition sans jamais devenir eux-mêmes une figure — extension du type **Réactif** déjà amorcé par Hypercube. Détail complet et raisons des idées écartées : [Spéciaux — famille réactive](../gdd/jetons/specials.md#spéciaux-réactifs--famille-identifiée-session-25).

Retenus : **Électrique**, **Cristal**, **Diamant**, **Amplificateur**. Deux autres idées apportées par le user depuis le Google Sheet, **Comète** et **Siphon**, rejoignent en fait des familles déjà existantes (Instantané et Mangeur) plutôt que la nouvelle famille Réactif — bonne diversité d'archétypes plutôt que des variations d'une seule idée.

Écartés en cours de route : **Rouille** (négatif pur = contenu mort dans un pool achetable), **Domino** (redondant avec ce que `CascadeResolver` fait déjà), **Résine** (deux versions tentées, deux angles morts différents — pas de gain réel de cascade, puis pas de contrôle joueur sur le placement).

## Prochaines étapes

Rien d'implémenté cette session (pure réflexion). À faire quand on attaque le code :
- Jauge + seuil 21 + hook UI (`GameRules`, probablement un nouveau manager ou extension de `RunManager`)
- Les 4 spéciaux réactifs (nouveaux `SpecialType`, hooks dans `CascadeResolver`/`GridManager`)
- Chiffrer précisément : forfait de remplissage des Spéciaux, formule dépassement→palier de prix, prix/rareté définitifs des 4 nouveaux spéciaux (déjà esquissés dans la Sheet)
