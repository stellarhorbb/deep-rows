# Session 17 — 22 nouveaux Badges, fondations de scoring, refonte de la bannière de résolution

**Date** : 2026-07-15
**Thème** : Grosse session de contenu Badges (10 → 37 actifs), avec deux vraies fondations techniques posées au passage (bonus flat au value_sum, scaling permanent), un chantier de lisibilité déclenché par le playtest en direct (bannière de résolution, tilt des Badges), et un refacto de gameplay (hold multi-slots). Premier run complet gagné avec le nouveau setup.

---

## Remplissage de la Sheet et choix du focus

Reprise après la session 16 (mult des Partitions, structure du run) : le user teste en continu depuis, sans nouveau sujet précis. Face au choix entre plus de Badges/Spéciaux ou la structure biome/boss/mode infini, discussion courte pour clarifier : ce n'est pas le **nombre** de Badges qui manque (16 vs 18 Partitions, écart resserré) mais leur **nature** — aucun Badge par famille, aucun Badge qui scale sur toute la run. Le user remplit la Google Sheet en conséquence avec ~21 nouvelles idées, en tâchant de clarifier le vocabulaire ("Cumule" = scaling, "Ajoute" = ponctuel).

Plusieurs clarifications à l'oral avant de coder :
- **"Tickets"** dans la Sheet = nom poétique pour "points de score", pas une vraie monnaie — les 8 Badges qui "ajoutent des tickets" ajoutent en fait des points, comme la valeur d'un jeton.
- **"Retrigger"** (Vingt-trois, Saint Pair, Impair profane) = le jeton recompte sa propre valeur une deuxième fois dans le score.
- **Gourmand** = compte les jetons ajoutés au deck (achat shop ou scission), pas juste achetés.
- **Poker Face** = mute réellement un jeton du deck (même effet qu'"Augmenter" des Dés à coudre), pas un bonus ponctuel — nécessite que le proc ait lieu pendant la résolution, avant que le jeton disparaisse, pour pouvoir l'animer.
- **Legendary** : nouveau palier de rareté voulu pour 5-10 Badges très puissants, débloqués via le Shore + tirage shop quasi nul.

## Fondation 1 — bonus flat au value_sum

Canal parallèle à `value_bonus_multipliers` existant : au lieu de multiplier, ajoute directement à `value_sum` avant la chaîne de multiplicateurs (traité comme si le jeton valait plus cher). `CascadeResolver._value_sum_bonus`, alimenté par 4 champs `RunContext` cumulatifs entre Badges (contrairement au bug connu de `set_rule_multiplier`) : retrigger par valeur, bonus de famille, bonus de paire, bonus rangée du haut.

9 Badges livrés d'un coup : Vingt-trois, Saint Pair, Impair profane (retrigger), Y'en a pas deux, Sommet, Encrée, Rouillée, Nacrée, Coraillée (points fixes).

## Fondation 2 — scaling permanent

Nouveau `RunManager.get_run_badge_state`/`set_run_badge_state`, jamais remis à zéro en cours de run (contrairement à `_badge_state`) — comble le trou technique identifié depuis la session 15 pour les Badges qui grossissent sur toute la run. Deux nouveaux facteurs de formule (`scaling_mult_bonus`, `flat_score_bonus`), volontairement séparés de `global_multiplier`/`value_bonus_multiplier` existants pour ne pas entrer en collision avec leur bug d'écrasement connu.

3 Badges : Jetons sacrés (+0.1 mult/spécial joué), Quatre quart (+5 points/pattern de 4, nerfé à +1 après playtest — +20 en une manche), Poker Face (upgrade en direct, voir plus bas).

**Legendary** ajouté à `BadgeData.Rarity` (poids de tirage 0.1 vs 10 pour Common).

## Poker Face — upgrade animé en direct

Retour de playtest : 25% de proc trop fort (+6 jetons upgradés en une manche) → nerfé à 10%. Deuxième demande : montrer visuellement le jeton monter d'un cran *avant* de disparaître, pas juste un texte au survol. A nécessité de déplacer le tirage à l'intérieur de `CascadeResolver.resolve()` (nouveau `EventType.UPGRADE` dans la timeline, entre MATCH et REMOVE) plutôt qu'après coup dans le Badge — `CascadeResolver` reste de la logique pure (pas de référence à `RunManager`), c'est `TurnController` qui applique la mutation réelle du pool en lisant l'événement. Poker Face lui-même redevient tout simple (`on_round_start`, pose juste une chance). Ralenti ensuite (0.15s → 0.6s de hold + fondu) suite à un nouveau retour : trop rapide pour le voir venir.

## Bug fix — pack de Badges/Partitions figé

Repéré en testant : vendre un Badge/Partition pendant qu'un pack est ouvert ne redonnait pas les slots libérés — `PackPanelUI` calculait `disabled` une seule fois à l'ouverture, sans écouter `badges_changed`/`tags_changed`. Corrigé en connectant le panel à ces deux signaux (`is_connected` pour éviter les doublons).

## Quick wins (5 Badges sans dépendance)

Mouche cubique (+1 mouche/3 scoré), Mouche dorée (+points = mouches actuelles, lecture live), Visionnaire (+1 preview stream). Et un vrai chantier : **Bénédiction** (+1 slot de hold) a demandé de refactorer `DeckManager._hold` d'une variable unique en tableau de slots (`hold_capacity`), avec clic ciblé sur un slot précis dans `StreamUI`.

## Récif vivant — deux essais

Premier jet mal compris de ma part : "+4 rocks dans le deck". Le user a corrigé — c'est "quand une Partition score, un jeton *parmi ceux qui viennent de scorer* laisse place à un rock" (généralisation de l'idée brainstorm "carré 2x2 scoré laisse un rock"). Repris directement dans `CascadeResolver.resolve()` : au moment de collecter les cellules à supprimer, une cellule du groupe est tirée au sort et exclue — nouveau `EventType.ROCKIFY` joué juste après le REMOVE du reste du groupe.

## Lisibilité de la bannière de résolution

Retour de playtest majeur : avec 2-3 Badges de cette session actifs sur la même résolution, l'ancien "BADGE x2.3" fondu ne permettait plus de voir qui avait fait quoi. Reconstruit en plusieurs passes de discussion :
1. D'abord : Badges résolus un par un, dans l'ordre des slots, mélangeant points et multis.
2. Puis correction : les Badges "points" doivent apparaître juste après les jetons bruts, avant tout multi (le user a réalisé que son intuition "réordonner pour optimiser" ne changerait rien au score réel — la formule reste `(value_sum + tous les flats) × (tous les multis)`, order-independent. Discuté explicitement de passer à un scoring séquentiel façon Balatro pour que l'ordre compte vraiment ; mis de côté volontairement, trop gros chantier vs. priorité "simplicité mécanique" du projet.

Séquence finale : Tickets bruts → Badges "points" (ordre des slots) → Multi intrinsèque → Badges "multi" (ordre des slots) → total. `CascadeResolver._attach_breakdown` construit `score_breakdown.badge_steps`, une liste ordonnée et taguée `flat`/`mult`, que la bannière parcourt en deux passes filtrées.

Au passage : tilt visuel étendu aux Badges "mouches" (Vertige, Pourboire, Un Pour Tous, Mouches en Cascade) qui n'en avaient aucun avant (réutilise le diff mouches avant/après déjà calculé dans `BadgeManager._dispatch` pour YouWinUI). Puis rendu plus fort/long sur demande : 0.4s → 0.7s, et une vraie bascule de rotation en plus du flash de couleur (deux Tween indépendants sur le même node, dessin via `draw_set_transform` par slot).

## Derniers 5 Badges — 2 nouveaux triggers

Exploration du code avant d'implémenter (agent dédié) pour cartographier où accrocher le level up et les hooks shop. Résultat :
- **`on_level_up`** — branché directement sur `RunManager.tag_leveled_up` (existait déjà, jamais exploité), protégé par `is_connected()` dans `bind_round` car ce signal vit sur `RunManager` (persistant toute la run), pas `TurnController` (recréé chaque manche). Consommateurs : Mouche mélomane (+5 mouches), Escalade musicale (+0.1 mult cumulé, constante remontée à 0.25 par le user en testant), Amélioration continue (+5 points cumulés).
- **`on_deck_grown`** — dérivé de `button_pool_changed` existant, filtré au delta de taille positif (achat/scission) pour ignorer les retraits (fusion/vente). Consommateur : Gourmand (+5 points cumulés/jeton ajouté).
- **Économe** (reroll gratuit au shop) : cas à part, aucun trigger de manche ne correspond à "le joueur ouvre le shop" — `ShopUI` vérifie directement `RunManager.has_badge(&"econome")` à l'ouverture, `apply()` du Badge ne fait rien.

Oubli corrigé ensuite : `get_progress_text` manquant sur Escalade musicale/Amélioration continue/Gourmand (présent sur Jetons sacrés/Quatre quart mais pas repris pour ce batch).

## Premier run complet gagné

637/390, avec Escalade musicale, Vingt-trois, Impair profane, Jetons sacrés, Colonne chanceuse équipés — bonne validation que tout le pipeline (level up, scaling, retrigger, deck grown) tourne sans accroc sur un run entier.

## GDD mis à jour

Beaucoup de docs touchés au fil de l'eau (`scoring.md`, `badges-implementes.md`, `triggers.md` réécrit — était resté à "5 triggers" alors qu'`on_round_end` avait déjà été ajouté en session 16 sans que le doc suive, `rarete.md`, `rocks.md`, `stream-hold.md`). Passe finale : `questions-ouvertes.md` (bug d'écrasement précisé aux seuls champs historiques, réordonnancement des Badges clarifié comme cosmétique, statut de balance des 22 nouveaux Badges), `decisions-tranchees.md` (2 nouvelles lignes : triggers session 17, ordre des Badges n'affecte pas le score), `00-index.md` (compteurs à jour).

## Prochaine étape

Playtest continu du user sur les 22 nouveaux Badges — aucun retour dédié pour l'instant sur la moitié d'entre eux (voir questions ouvertes). Pas de sujet précis convenu pour la prochaine session.
