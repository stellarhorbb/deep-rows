# Session 23 — File d'apparition du shop, taux Legendary fixe + 4 nouveaux Badges, recalibrage Maestro, hover sur les jetons

**Date** : 2026-07-22
**Thème** : Session longue en plusieurs vagues, partie balance (nettoyage post-session 22, Maestro recalibré) puis gros chantier shop (file d'apparition façon Balatro, taux Legendary fixe, 4 nouveaux Badges Legendary co-brainstormés) puis une fonctionnalité UI (hover sur les jetons) qui a exposé trois bugs distincts en cascade, dont un vrai blocage de tour.

---

## Nettoyage post-session 22 et bug Minima/Maxima

- **Pétard à mèche visible sur une case déjà occupée par un skull** — bug confirmé et non retenu comme prioritaire ce jour-là (reporté, pas corrigé dans cette session).
- **Minima/Maxima scoraient un jeton hors seuil** — bug réel trouvé dans `SheetMatcher.find_lines` : le jeton de **départ** d'une ligne n'était jamais vérifié contre `MINIMA_MAX_VALUE`/`MAXIMA_MIN_VALUE`, seuls les jetons ajoutés en cours de marche (`nxt`) l'étaient. Un 3 (ou un jeton sous le seuil Maxima) en tête de séquence, suivi de vrais jetons valides, se faisait inclure dans le match. Corrigé par un rejet du jeton de départ avant même la logique de dédup. Vérifié par test headless isolé (`[3,1,1]` ne matche plus, `[1,2,1]` toujours correct, `[5,8,8]` maxima corrigé pareil).
- **Discussion Minima/Maxima "somme sur 3 jetons" (proposition du user)** — explorée puis **différée** (pas tranchée) : une règle de somme casserait le côté "sans réfléchir" de Minima (tier Amorce), plafonnerait la taille du groupe à 3 exactement (perte du scaling ouvert actuel), et rendrait Maxima plus facile sans le vouloir (somme > 20 est plus permissif que "chaque jeton ≥ 8"). Alternative moins risquée notée dans les questions ouvertes si le besoin revient : remonter `MINIMA_MAX_VALUE` 2→3 et `MAXIMA_MIN_VALUE` 8→7, même algorithme.
- **Double Partition élargie au Dernier Souffle** — `CascadeResolver.resolve()` traitait le "0 chevauchement" comme deux figures indépendantes (aucun bonus combo). Retiré ce garde-fou : deux figures qui scorent dans la même passe comptent maintenant comme Double Partition, chevauchement ou pas. Le cas "0 chevauchement" ne peut mécaniquement se produire qu'au Dernier Souffle (un coup normal ne modifie qu'une seule colonne) — aucune exception codée en dur, conséquence naturelle de la règle généralisée. Le bonus scale déjà tout seul avec le nombre de figures simultanées (N figures → N× la somme des scores), formule inchangée.

## File d'apparition du shop façon Balatro

Point de départ : une discussion sur pourquoi Balatro semble moins répétitif que Deep Rows sur les items skippés-puis-revus au shop. Recherche web confirmant le vrai mécanisme Balatro (queues par source/rareté, seul un achat consomme un item, un skip fait juste avancer la file — pas un tirage indépendant à chaque fois comme actuellement chez nous).

- **Badges** — nouvelle file par palier de rareté (`ShopManager._badge_queues`/`_badge_queue_pos`), mélangée une fois par run, avancée à chaque tirage, remélangée automatiquement une fois épuisée. `reset_run()` la remet à zéro, câblé dans `RunService.start_new_run()` (le `ShopManager` vit pour toute la session de jeu, pas juste une run).
- **Partitions** — même principe, sans pondération de rareté (elles n'en ont pas) : une file `&"generic"` pour le pool normal, une `&"legendary"` séparée pour le petit pool à part.
- **Spéciaux et Dés à coudre laissés en tirage indépendant, volontairement** — usage temporaire (on veut parfois retomber sur le même Spécial ou revoir toutes les actions du Dé à coudre selon le besoin du moment), contrairement aux Badges/Partitions qui sont des choix de build pesés.
- Testé en isolé : tous les Badges/Partitions d'un même pool sortent une fois chacun avant tout doublon ; un item équipé est sauté ; un pack ne contient jamais de doublon interne.

## Taux de rareté Legendary fixe

- **Constat** : le système par poids existant (`RARITY_WEIGHTS`, poids par item × nombre d'items dans le palier) fait que plus on ajoute de Badges à un palier, plus ce palier devient fréquent globalement — pas un vrai taux fixe par rareté.
- **Nouvelle constante `GameRules.BADGE_RARITY_RATES`** = `[0.50, 0.30, 0.13, 0.06, 0.01]`, taux fixe par palier pour les Badges uniquement (Spéciaux/Dés à coudre restent sur `RARITY_WEIGHTS`). Un palier sans aucun Badge disponible sort naturellement du tirage et les autres se renormalisent (même principe que le "resample" de Balatro, sans code dédié).
- Chiffres validés à 200 000 tirages simulés (résultats à moins de 0.2% des cibles) et vérifié qu'épuiser un palier entier (5 Epic équipés) ne le fait plus jamais tirer.
- Legendary à 1% assume qu'il y aura plusieurs Badges Legendary à terme — avec un seul (Poker Face) avant cette session, c'était surtout "tomber régulièrement sur Poker Face précisément" plutôt qu'une vraie chasse variée. D'où le chantier des 4 nouveaux Legendary ci-dessous.

## Quatre nouveaux Badges Legendary

Brainstorm inspiré des Jokers Legendary de Balatro (Canio, Triboulet, Yorick, Chicot, Perkeo), traduit dans le vocabulaire et les systèmes de Deep Rows. Plusieurs pistes écartées en cours de route : immunité totale aux malus de boss jugée trop forte (retire 20% du contenu du jeu en permanence, comparé à Chicot déjà controversé côté Balatro pour la même raison) ; "au-delà de Maestro" jugé trop de maths/paliers pour un seul badge ; une "vie en plus" jugée pas assez subtile.

Roster final, tous à 8 mouches (prix aligné sur les Epic existants — la rareté du tirage fait déjà le travail, pas besoin de gonfler le prix en plus) :

- **Souffle Obscur** — après un Dernier Souffle normal, une deuxième vague fait disparaître aussi les entity-skulls (seul obstacle normalement permanent du jeu), avec sa propre bannière et une vraie deuxième résolution.
- **Sacre** — +1.0 au multi de la Partition par figure (Valet/Chevalier/Dame/Roi) dans le groupe qui score. Capstone de l'archétype déjà entamé par Couronne/Diadème.
- **Virtuose** — les Partitions équipées démarrent directement au niveau Maestro. Passe par le **cumul** plutôt que le niveau directement (`force_sheet_max_level`), pour ne pas se faire écraser au premier vrai score gagné.
- **Dresseur Fou** — Cavalier/Frog/Liane/Underground ne disparaissent plus jamais (countdown gelé). Crow explicitement exclu : il s'autodétruit après une action unique, pas de countdown à geler comme les 4 autres.

Implémentation : `RunContext.mobiles_never_expire` (nouveau flag, alimenté depuis `has_badge` dans `build_context`) lu par `GridManager.tick_mobile_specials`. Underground n'ayant pas de countdown (sa fin est positionnelle), il reste inerte au fond plutôt que de continuer à agir. Souffle Obscur a demandé une vraie séquence de jeu (nouveau signal `entity_skulls_cleared`, `GridManager.clear_entity_skulls`, `TurnController._trigger_second_wave`) plutôt qu'un simple script d'effet.

## Retour de playtest et recalibrages

- **Maestro atteint trop tôt, encore** — donnée réelle : Diamond au niveau Maestro dès Marais 3/5 malgré un vrai usage de Suite/Cross en parallèle (pas juste du spam mono-Partition comme en session 22). Confirme que le problème n'était pas seulement le spam mais les seuils eux-mêmes. **`SHEET_LEVEL_THRESHOLDS` recalculé** : `[400, 1500, 4000, 12000]` (étaient `[150, 500, 1100, 2200]`, session 15), calés sur la somme cumulée de `ROUND_TARGETS` aux 4 manches boss (5/10/15/20), arrondis pour rester mémorisables. Referme la question ouverte des paliers "dan" au-delà de Maestro pour la run classique (reste utile en mode infini uniquement). Bonus comique : Virtuose (ci-dessus) saute maintenant un palier ×5.45 plus gros qu'avant.
- **Gourmand** +5→+2 par jeton ajouté au deck, jugé trop fort.
- **Escalade musicale** +0.5→+0.25 par level up, jugé trop fort (le commentaire du script, resté à "+0.1", corrigé au passage).
- **Shake ne remélange plus le Hold** — un Spécial mis de côté exprès s'y faisait perdre au hasard à chaque Shake (current + hold + pioche partaient dans le même sac). Seuls current + pioche sont remélangés maintenant ; le Hold reste intact, cohérent avec son rôle de stockage délibéré.
- **Généreux plus dur en début de run (hypothèse, pas confirmée)** — Fibonacci, bien qu'une Ligne facile à placer, demande une séquence de valeurs exactes bien plus étroite que les Sheets "faciles" des 3 autres starters (family, suite libre, nombres premiers). Le user va rejouer avec Généreux pour vérifier avant de retoucher quoi que ce soit.
- **Underground cassait un pattern déjà formé** — l'ordre de tick (pétards/mobiles avant `resolve()`, volontaire pour que leurs propres effets scorent dans le même tour) pouvait perturber un pattern déjà complet avant que la résolution n'ait la moindre chance de le voir. Résolu par une **résolution en deux temps** : une 1ère passe juste après le drop (avant tout tick), puis les ticks habituels, puis la résolution finale comme avant. `turn_resolved` ne sort qu'une fois par tour réel (jamais à la 1ère passe seule, sauf victoire immédiate) pour ne pas double-dispatcher les Badges `on_turn_resolved` ni le compteur de drop d'entity-skull.

## Hover sur les jetons — trois bugs en cascade

Fonctionnalité demandée après la découverte que les valeurs des jetons ne s'affichent nulle part en jeu normal (`GameRules.DEBUG_SHOW_TOKEN_VALUE` gate l'affichage permanent). Le hover reste toujours visible, lui, contrairement à ce flag.

- **`TokenTooltip.describe`** — helper statique partagé (famille+valeur pour un jeton normal, label+description pour un Spécial en réutilisant le texte déjà écrit pour le shop), utilisé par `StreamUI` (current/hold/preview) et le nouveau `GridHoverUI` (Control transparent superposé à la grille, qui est en Sprite2D/Node2D donc sans tooltip natif possible directement dessus).
- **Bug 1 — `StreamUI` trop petit.** Le `Control` faisait 100px de large en dur dans la scène, alors que `_draw()` peint jusqu'à 368px (Current + jusqu'à 3 slots de Hold avec Bénédiction + Le Prévoyant cumulés) sans se soucier des bornes du node. `_draw()` ignore ces bornes, le hover s'appuie dessus. Corrigé par un recalcul dynamique de `size.x` à chaque changement de stream (`_update_size`, basé sur `deck_manager.hold_capacity`).
- **Bug 2 — blocage de tour, bien plus grave.** La résolution en deux temps (ci-dessus) émettait `resolution_pass_done` de façon 100% synchrone dans le cas courant (rien à résoudre à la 1ère passe) — le signal partait avant même que `play_current_to` n'ait atteint son `await`, bloquant le jeu pour de bon dès le 1er drop. Corrigé en différant l'émission via `call_deferred`.
- **Bug 3 — la vraie cause du hover jamais visible.** `mouse_filter = IGNORE` sur le node `StreamUI`, réglé bien avant cette session (cohérent à l'époque : aucune interaction directe, les clics passent par `InputHandler._unhandled_input` qui contourne entièrement le système GUI). Passé à `PASS` (pas `STOP`, qui aurait bloqué les clics de `InputHandler`). Diagnostiqué via des `print()` temporaires (taille/rect réels, `mouse_entered`/`mouse_exited`, `_gui_input`) après plusieurs hypothèses fausses.
- Passage de `_get_tooltip(at_position)` à `_gui_input` + `tooltip_text` dynamique pour `StreamUI` en cours de route (plus standard/éprouvé) — `GridHoverUI`, lui, garde `_get_tooltip` (fonctionnait déjà correctement).
- Deux points de dette signalés par le user pour la suite : `GridHoverUI.cell_size`/`cell_gap` sont des copies des valeurs de `GridVisual`, pas une référence (risque de désync si retouché dans l'éditeur) ; la taille du node `GridHover` (672×672) est un chiffre figé, pas recalculé dynamiquement si la grille change un jour. Pas corrigés dans cette session (pas urgent), mais à faire avant que le user commence à intégrer ses propres illustrations.

## Note process

Session à très gros volume, avec un vrai fil rouge économie/rareté (Balatro comme référence structurante plutôt que juste esthétique) puis une fonctionnalité UI qui a demandé un vrai travail de diagnostic en aller-retour avec le user (trois bugs indépendants découverts un par un, dont un blocage de tour qui aurait pu passer inaperçu longtemps sans le hover pour le révéler). Bon exemple où une fonctionnalité "cosmétique" en apparence a servi de test d'intégration involontaire pour un changement plus profond (la résolution en deux temps).

## Liens

- [Questions ouvertes](../gdd/meta/questions-ouvertes.md)
- [Rareté des Badges](../gdd/badges/rarete.md)
- [Génération de l'offre](../gdd/shop/generation-offre.md)
- [Level up des Partitions](../gdd/partitions/level-up.md)
- [Badges implémentés](../gdd/badges/badges-implementes.md)
