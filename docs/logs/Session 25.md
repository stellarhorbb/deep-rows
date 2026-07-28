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

## Troisième bug, playtest prolongé

Freeze après un score normal (Small T) avec plusieurs Frogs déjà vivants sur la grille — cette fois pas dans le code de la roulette, mais un défaut préexistant dans le pipeline d'animation de base (`GridVisual`). Quatre fonctions (`_animate_match` shake, `_animate_gravity`, `_animate_upgrade`, `_animate_remove`) créaient un `Tween` sans condition puis n'y ajoutaient des `tween_property` que pour les cases ayant encore un sprite à ce moment précis — si un Frog avait mangé/déplacé un jeton entre-temps, une case scorée pouvait se retrouver sans sprite, Tween vide, même crash que le premier bug. Bug dormant depuis longtemps dans le jeu, jamais déclenché avant parce qu'avoir plusieurs specials mobiles vivants simultanément était rarissime en jeu normal (il faut acheter et poser chaque Frog un par un) — la roulette (5 Frogs d'un coup au palier Légendaire) l'a rendu courant. Les 4 fonctions filtrent maintenant les cases valides avant de créer le Tween.

## Retunes d'équilibrage (playtest prolongé, même jour)

Six ajustements demandés par le user après plusieurs manches jouées :

- **Bord à Bord** (Badge) : x1.5 → x1.2. Modifier dédié créé (`MODIFIER_BORD_A_BORD`) plutôt que retoucher `MODIFIER_BOOST_MULT` partagé avec Écume/Colonne Chanceuse/Trench, qui auraient été nerfés sans que ce soit demandé.
- **Frog roulette attendait un tour de trop** avant son premier déplacement, comparé à un Frog acheté normalement — cause : `just_placed` (protection anti-mouvement sur le même battement que la pose) ne se consomme que via `tick_mobile_specials`, jamais appelé pendant `drop_bonus_token` puisque les Frogs de la roulette sont posés hors d'un tour normal. Fix : `just_placed` remis à `false` explicitement dans `drop_bonus_token`, rien à protéger pour un cadeau posé entre deux tours.
- **Description de Last Trick non conforme** — `SheetData.describe()` affichait "Multiplicateur variable (légendaire)" pour toutes les Sheets légendaires sans distinction, alors que Last Trick a un multiplicateur fixe (x2.5, contrairement à Royal Square/Lost Corners qui sont réellement variables). Distinction faite sur `score_multiplier > 1.0`.
- **Jauge de roulette remise à zéro entre les manches**, plutôt que de courir sur toute la run — revient sur la décision initiale documentée ("seuil fixe pour toute la run"), voir doc dédié pour le détail.
- **Multiplicateur de la roulette : 3 drops de couverture au lieu d'1** — un seul drop jugé "trop chaud à caler" en jeu réel. `_multi_active` (bool) remplacé par un compteur de drops restants (`GameRules.ROULETTE_MULTI_DROPS = 3`).
- **Piège à mouches : -5 → -2**, sans toucher Trésor de mouches (+5) — les deux effets partageaient `MYSTERY_FLIES_BIG`, séparé en `MYSTERY_FLIES_BIG_GAIN`/`MYSTERY_FLIES_BIG_LOSS`.

## Famille de spéciaux réactifs

Après avoir écarté un système d'états de jetons généralisé (trop coûteux à maintenir/comprendre, cf. [États de jetons — réserve](../gdd/jetons/etats-reserve.md)), la discussion a convergé vers une poignée de spéciaux ciblés qui amplifient une résolution de Partition sans jamais devenir eux-mêmes une figure — extension du type **Réactif** déjà amorcé par Hypercube. Détail complet et raisons des idées écartées : [Spéciaux — famille réactive](../gdd/jetons/specials.md#spéciaux-réactifs--famille-identifiée-session-25).

Retenus : **Électrique**, **Cristal**, **Diamant**, **Amplificateur**. Deux autres idées apportées par le user depuis le Google Sheet, **Comète** et **Siphon**, rejoignent en fait des familles déjà existantes (Instantané et Mangeur) plutôt que la nouvelle famille Réactif — bonne diversité d'archétypes plutôt que des variations d'une seule idée.

Écartés en cours de route : **Rouille** (négatif pur = contenu mort dans un pool achetable), **Domino** (redondant avec ce que `CascadeResolver` fait déjà), **Résine** (deux versions tentées, deux angles morts différents — pas de gain réel de cascade, puis pas de contrôle joueur sur le placement).

## Frog remplacé par Boost (playtest prolongé, même jour)

Après plusieurs manches jouées avec le pool Multiplicateur/Frog, retour du user : Frog "casse souvent la grille qu'on a mis plusieurs drops à créer pour préparer le terrain de ses partitions" — le double tranchant assumé au moment du design (Frog mange ce qu'il traverse) s'est révélé trop pénalisant en pratique, pas juste un wildcard occasionnel.

Cheminement pour trouver le remplacement (plusieurs fausses pistes, comme pour le reste de la roulette) :

1. **Résoudre des jetons "isolés"** — évoqué en premier, mais définir "isolé" s'est avéré plus dur que prévu : par famille seule, angle mort sur les Partitions à base de valeur (Suite/Fibonacci/Minima/Maxima/Prime) qui n'ont pas besoin de voisins de même famille ; par isolement total (zéro voisin), sûr à 100% mais quasi inexistant en fin de manche — pile quand la roulette se déclenche le plus. Le user a lui-même coupé court : "quitte à mettre plein de règles comme ça, autant limiter le rendre en random pur."
2. **Sommer la valeur de N jetons piochés sans les retirer** — repartant de zéro sur "sans pénaliser les joueurs". Séduisant, recalculé avec les vrais chiffres (`ROUND_TARGETS`) : ~25% de la cible en manche 1, mais ~2,5% seulement en manche 20 — les valeurs de jetons plafonnent trop bas face à l'explosion du score via les multiplicateurs. Palliatif (réutiliser `ROULETTE_MULTI_VALUES` comme multiplicateur sur la somme) rejeté par le user : "ça piétine un peu sur l'autre côté de la roulette qui utilise les multi."
3. **Version finale, née d'une vraie observation de playtest** : le user a remarqué qu'il est en pratique très difficile de scaler son deck en cours de run (les achats au shop vont surtout vers Spéciaux/Badges, rarement les Dés à coudre) — "j'ai à peine une figure en fin de run, et quelques jetons à 6 ou 8." D'où **Boost** : augmenter la valeur d'UN jeton de base au hasard sur la grille (plafonné à 10), sans jamais le retirer ni le déplacer. Comble directement ce manque plutôt que d'ajouter un système à côté, scale naturellement avec la run (les valeurs de jetons grossissent tout du long), et crée une petite boucle de rétroaction avec la jauge elle-même (jeton boosté → jauge se remplit plus vite au prochain passage → plus de déclenchements).

Risque résiduel assumé, plus étroit que celui de Frog : Boost pourrait techniquement perturber une Partition de valeur en cours si le mauvais jeton est touché, mais ces Partitions restent une minorité du catalogue (la majorité tourne sur la famille, jamais affectée) — et ne toucher qu'UN seul jeton (plutôt que plusieurs, contrairement à l'ancienne structure "nombre scale par palier") réduit encore les chances de tomber sur le mauvais candidat. Rareté = l'ampleur de l'incrément (+1/+3/+10) plutôt que le nombre de jetons touchés (toujours 1) — inversion délibérée par rapport au reste du pool, proposée par le user lui-même.

## Spéciaux : du deck à l'inventaire possédé

Après plusieurs runs jouées jusqu'en manche 20, le user a remonté un vrai problème stratégique : les spéciaux achetés ne servent presque jamais en pratique. Noyés dans le stream, ils tombent rarement au bon moment (zéro contrôle du timing) et le Hold slot — seul levier de contrôle existant — est de toute façon toujours réquisitionné pour préserver un jeton de score plutôt qu'un spécial ("il m'est arrivé plein de fois de jeter mon special n'importe où juste pour gagner une place"). Sur demande explicite ("prend un peu de hauteur et imagine comment les spéciaux auraient le meilleur intérêt stratégique/fun"), reformulation proposée : les spéciaux deviennent une **soupape de secours** qu'on déclenche volontairement, pas un aléa du tirage.

Décision (revient sur ["Spéciaux — format"](../gdd/meta/decisions-tranchees.md), voir aussi [Spéciaux](../gdd/jetons/specials.md)) : un spécial acheté rejoint un **inventaire possédé de 3 slots**, séparé du deck/stream, avec une UI dédiée verticale sur le côté droit de l'écran. Le joueur sélectionne un slot puis clique une colonne pour le jouer à la place de son coup normal — garde l'ADN "tout tombe dans une colonne" (pas un item qu'on clique dans le vide). Retenu plutôt qu'un système "1 gratuit par passage au shop" : rester payable en mouches garde une vraie tension économique, le vrai problème n'était pas le prix mais l'absence de contrôle du timing.

Implémenté de bout en bout :
- `RunManager` : `_deck_composition` (dict de comptes, mélangé au deck) remplacé par `_special_inventory` (Array[SpecialType]) + `add_special()`/`remove_special_from_inventory()`/`get_special_inventory_capacity()` (`GameRules.SPECIAL_INVENTORY_SLOTS = 3`), signal renommé `special_inventory_changed`
- `DeckManager.build_deck()` simplifié — ne génère plus jamais de spéciaux, le deck ne contient plus que boutons + rocks
- `TurnController` : logique de résolution du tour extraite dans `_resolve_turn()`, partagée entre un tour normal (`play_current_to`, tire du stream) et un tour spécial (`play_special_from_inventory`, ne tire rien) — flag `_current_turn_from_stream` pour sauter la queue deck-spécifique (`advance_stream`, check de fin de deck) quand le tour vient de l'inventaire
- `ShopManager.can_equip_slot()` : achat bloqué si l'inventaire de 3 slots est déjà plein, même pattern que les slots de Sheets/Badges
- Nouvelle UI `SpecialInventoryUI` (`scripts/ui/special_inventory_ui.gd`) : même squelette que `StreamUI` (`Control` + `_draw()`, `TokenVisual.get_texture()`) mais empilée verticalement ; câblée dans `game.tscn`/`game_scene.gd` comme `StreamUI` (nœud propre à la manche, pas au Shell persistant, puisque jouer un spécial n'a de sens que pendant une manche) ; `InputHandler._handle_click()` route maintenant vers `play_special_from_inventory` si un slot est sélectionné, sinon comportement inchangé
- Nettoyage : `debug_always_in_deck` (champ mort de `SpecialItem`, plus rien ne le lit) et le bloc d'affichage des comptes de spéciaux dans `DeckInspectorUI` (toujours vide depuis le refactor) supprimés

Point de vigilance signalé au user : le refactor du cœur de boucle de tour (`_resolve_turn`/`_current_turn_from_stream`) est plus délicat que le reste des changements de cette session puisqu'il touche la boucle de jeu principale — pas encore testé en jeu réel au moment d'écrire cette ligne, à valider en priorité à la prochaine session.

## Spéciaux : inventaire déplacé dans le Shell + vente

Retour user après le premier jet : l'inventaire vivait dans `game.tscn`, donc invisible dès qu'on quittait la manche (shop, etc.), contrairement aux Partitions/Badges qui restent toujours affichés. Demande : même traitement — toujours visible, vendable depuis n'importe quel écran.

- `SpecialInventoryUI` déplacé de `game.tscn` vers `shell.tscn`, câblé une seule fois dans `Shell._ready()` (même pattern que `sheets_ui`/`badges_ui`) au lieu d'à chaque manche dans `GameScene._wire_references()`. `GameScene` le récupère désormais via `SceneRouter.shell.special_inventory_ui`, comme pour `sheets_ui`/`badges_ui`/`deck_button`/`deck_inspector_ui`
- Bouton **VENDRE** par slot, même pattern que `BadgesUI` (bouton créé une fois par slot max, positionné/affiché à chaque `_draw()` selon l'état du slot) : `RunManager.sell_special(index, price)` rembourse `SELL_REFUND_RATIO` du prix — le prix est résolu côté UI via `ShopManager.get_special_item()` (l'inventaire ne stocke qu'un `SpecialType`, pas un prix, pour ne pas faire dépendre `RunManager` de `ShopManager`)
- `Shell.load_content()` (appelé à chaque changement d'écran) désélectionne le slot actif — évite qu'une sélection faite en manche reste visuellement active en arrivant au shop, où jouer un spécial n'a pas de sens

## Prochaines étapes

- **Tester en jeu réel le nouveau système de spéciaux** (inventaire, UI, routing du clic, `_resolve_turn`) — rien n'a encore été joué depuis le refactor
- Les 4 spéciaux réactifs (Électrique/Cristal/Diamant/Amplificateur) restent à coder — nouveaux `SpecialType`, hooks dans `CascadeResolver`/`GridManager`
- Calibrage fin des chiffres de la roulette (seuil, valeurs multi, ampleur du Boost) au playtest prolongé
- Passe UI/juice plus poussée sur la roulette (voir questions ouvertes du GDD) — le premier jet fonctionne mais reste visuellement plat
- Synergies Badges/Boss malus sur la roulette et les cases mystère, pas encore spécifiées
- Trouver un lien narratif pour Boost (celui de Frog, "cadeau des grenouilles", ne s'applique plus) — pas bloquant

## Bug : "Lambda capture at index 0 was freed" en rafale

Signalé en jeu réel (plusieurs occurrences d'un coup). Cause : `_setup_countdown_sprite` (blink rouge/noir partagé par l'entity-skull Mèche Courte et le Pétard à mèche) créait son `Tween` de clignotement sur `self` (GridVisual, jamais libéré) tout en capturant dans ses `tween_callback` un `sprite` enfant, lui, libéré normalement (explosion, retrait de la grille). Le Tween continuait de tourner après la mort du sprite qu'il ciblait, jusqu'à ce qu'un garde `is_instance_valid` s'en aperçoive et se tue lui-même — mais Godot logue une erreur au niveau moteur avant même d'exécuter ce garde, dès que le lambda capture un objet déjà libéré. Fix : `Tween` créé sur `sprite.create_tween()` au lieu de `create_tween()` — Godot tue alors le Tween automatiquement au même instant que le sprite, plus de capture qui traîne. Même famille de bug que les crashs Tween déjà corrigés cette session (mobiles/countdown + roulette rendent ces cas courants, avant rares).

## Bug : Boost de la roulette ne persistait jamais

Signalé en playtest : *"j'avais eu un tour de roulette qui a mis 10 sur un de mes jetons, je l'ai scoré donc il est passé en J, mais je ne le vois plus dans mon deck sur la manche d'après."* Diagnostic confirmé : `GridManager.boost_random_token()` (appelé par `RouletteManager._apply_boost`) mutait un jeton **sur la grille** — une copie éphémère créée par `DeckManager.build_deck()` en tout début de manche, jamais reliée au pool possédé (`RunManager._button_pool`, celui qui persiste réellement d'une manche à l'autre). Résultat : que le jeton boosté score (disparaît, pilier du jeu) ou survive sans scorer jusqu'à la fin de la manche, le "+10" était perdu dans les deux cas — la manche suivante repartait toujours d'une copie neuve et non boostée. Contredisait directement la raison d'être de Boost telle qu'on l'avait posée en le choisissant à la place de Frog ("scale naturellement avec la run", voir plus haut).

Fix : nouvelle méthode `RunManager.boost_random_button(amount)`, même pattern que `increase_button_value`/`upgrade_matching_button` — pioche un bouton de base au hasard **dans le pool possédé** et l'y remplace par une version boostée (plafonnée à `MAX_BUTTON_VALUE`), avec `button_pool_changed.emit()`. Appelée par `RouletteManager._apply_boost` en plus du (et indépendamment du) tirage sur la grille, qui reste comme highlight visuel immédiat + petit bonus de score pour la manche en cours. Les deux tirages ne ciblent pas forcément le même jeton (aucune traçabilité entre une copie de grille et son origine dans le pool, complexité jugée non justifiée) — mais l'effet qui compte pour la suite de la run est bien acquis maintenant.

## Balance : Rescapé retravaillé de +2.0 à +1.0

Question soulevée en playtest : *"le rescapé est très fort, il ajoute vraiment +2 au multi global ? Il double le multi global ? J'ai l'impression qu'il fait plus ?"* Vérification du calcul (`scaling_mult = 1.0 + scaling_mult_bonus`, `effect_rescape.gd` cumule `+2.0 × nombre de boss survécus`) : dès le premier boss (manche 5), le multi passait déjà de ×1 à **×3** — puis ×5, ×7, ×9 aux boss suivants (manches 10/15/20). Comparé à **Cairn** (autre Epic du même canal, ~×8.6 en fin de run mais en accumulation lisse, +0.4/manche), le total final n'était pas hors normes, mais l'arrivée en 4 paliers brutaux — le premier triplant tout le score d'un coup dès la manche 5 — donnait une impression de force disproportionnée par rapport à son propre libellé ("+2").

Décision : `BONUS_PER_BOSS` 2.0 → **1.0**. Nouvelle courbe : ×2 (manche 5), ×3 (10), ×4 (15), ×5 (20) — sous Cairn plutôt qu'au-dessus, palier d'entrée ramené à un simple doublement.

## Retunes après le run complet avec Le Généreux

Quatre retours après un run entier joué (premier run complet avec un des 3 starters restants, jugé "bien plus fun" — cases mystère + roulette apportent le rythme voulu) :

- **Small T : ×1.5 → ×2.0.** Le catalogue GDD (`catalogue-implemente.md`) indiquait déjà ×2 dans son tableau — dérive doc/code jamais rattrapée, `t_family.tres` recolle maintenant au doc.
- **Cavalier/Frog disparaissent dès leur première bouchée**, plutôt que d'attendre la fin de leur countdown (3/5 déplacements). Nouveau champ `ate: bool` sur le retour de `SpecialEffects.move_cavalier`/`move_frog` (et `_eat_cell`, qui distingue maintenant "case vide traversée" de "quelque chose y a été mangé, même un Rock à 0 point") — `GridManager.tick_mobile_specials` efface le special immédiatement si `ate` est vrai, sinon le countdown reste le filet de sécurité habituel (utile s'il ne mange jamais rien). But explicite : trop de tours d'incertitude après une bouchée, alors qu'un même drop peut déjà cumuler score de Partition + case mystère + déclenchement de roulette — besoin d'un ordre plus simple et prévisible.
- **Les spéciaux ne remplissent plus la jauge de roulette.** `ROULETTE_SPECIAL_GAUGE_VALUE` (forfait fixe de 5) datait du système où les spéciaux étaient piochés dans le stream ; devenu un abus gratuit maintenant qu'ils vivent dans l'inventaire et se jouent à la demande SANS consommer de tour de stream (voir plus haut, refonte spéciaux) — spammer un outil "sans valeur" remplissait la jauge pour rien. Constante supprimée de `GameRules`, `RouletteManager._gauge_value` retombe sur 0 pour tout ce qui n'est pas `Kind.BASE`.
- **Le Boost de la roulette ignore maintenant les jetons déjà à MAX_BUTTON_VALUE (10) ou les Figures.** Un Boost qui tombait sur un jeton déjà plafonné ne faisait rien de visible — frustrant, surtout côté pool où l'effet gaspillé serait perdu pour de bon (pas juste ce tour-ci). Filtre de candidat ajouté aux deux tirages indépendants (`GridManager.boost_random_token` et `RunManager.boost_random_button`).

## QoL : ordre d'affichage fixe (mystère → score → roulette)

Signalé : "collision entre les popups de roulette et quand on score, c'est pas agréable." Diagnostic : au niveau logique, l'ordre était déjà fixe (case mystère et déclenchement de roulette se résolvent tous les deux instantanément au moment où le jeton se pose, bien avant le scoring de Partition qui n'arrive qu'après l'animation) — le problème était purement visuel, l'annonce de la roulette (`_on_roulette_triggered`) se jouait immédiatement à son propre signal, sans attendre le score.

Discussion sur la bonne place : d'abord envisagé "roulette avant le score" pour que le joueur profite immédiatement du Multi/Boost gagné — mais ça aurait exigé de rendre le Multi rétroactif au drop qui déclenche la roulette, à l'inverse d'une décision déjà prise ("jamais celui qui déclenche — pas de bonus rétroactif", pensé comme un wildcard sur le prochain coup). Écarté aussi parce que 3 drops (`ROULETTE_MULTI_DROPS`) suffisent rarement à reconstruire une figure scorable après en avoir déjà complété une — le Multi arrive presque toujours trop tard de toute façon (noté dans questions-ouvertes.md pour un futur recalibrage). Le user a alors proposé l'inverse : **mystère → score → roulette**. Simple à justifier : montrer la roulette APRÈS le score retire toute impression fausse de lien causal, sans toucher à la mécanique "prochain drop" existante.

Fix : `GameScene._on_roulette_triggered` ne joue plus l'annonce tout de suite — le résultat est stocké (`_pending_roulette_announcement`) et affiché par `_on_turn_resolved`, juste après le score de ce drop (`_play_roulette_announcement`, extrait de l'ancien `_on_roulette_triggered`). Les cases mystère n'ont pas eu besoin d'un traitement équivalent : leur résolution est déjà synchrone au moment du drop, donc déjà réglée avant que le score n'apparaisse à l'écran. Effet de bord assumé : le popup de la roulette bloque maintenant la main du joueur jusqu'à sa fin (rien ne l'en empêchait explicitement avant) — voulu, pour qu'un deuxième drop ne vienne jamais mélanger sa propre séquence d'annonces avec celle encore en cours.

## Descriptions des Badges de scaling reformulées (Rescapé/Cairn/Escalade musicale)

Suite à la confusion sur "+2 = ×3" : le calcul (`scaling_mult = 1.0 + somme des contributions`, partagé entre tous les Badges de scaling pour qu'ils s'additionnent plutôt que se multiplier entre eux — sinon Rescapé + Cairn + Escalade musicale ensemble exploseraient bien plus vite) reste inchangé, mais les trois descriptions statiques (`.tres`, texte affiché au shop) précisent maintenant explicitement le socle "qui démarre à ×1", pour que "+1.0" se lise sans ambiguïté. Au passage, deux dérives documentaires corrigées : la description de Rescapé était restée sur l'ancien "+2.0" après le retune de cette session (oubliée dans le fix précédent), et le tableau GDD d'Escalade musicale affichait encore "+0.1" alors que le code est à +0.25 depuis le retune session 23.

## Gros chantier specials : gamble récompensé + famille Bombe à 3 paliers

Suite du grand playtest complet (Le Généreux). Deux retours, discutés en profondeur avant de coder (raisonnement complet dans la conversation, résumé ici) :

**1. Distinction "pratique" vs "erratique"** — l'axe qui compte vraiment n'est pas "scoring ou pas" mais la **prévisibilité de la destination**. Bombe/Pétard/Marée/Enclume/Liane/Underground visent ou vont toujours au même endroit connu d'avance ; Cavalier/Frog sautent vers une destination tirée au hasard parmi plusieurs candidats — un coup raté ne rapporte rien. Décision : `GameRules.MOBILE_EATER_GAMBLE_MULT` (×1.5, premier jet) sur la valeur brute mangée par Cavalier/Frog (`SpecialEffects._apply_gamble_mult`, appliqué dans `move_cavalier`/`move_frog`) — Liane exclue (croissance déterministe, pas un gamble).

**Crow reclassé "pratique"** — au lieu de voler un jeton scorable au hasard sur toute sa ligne, il vole désormais systématiquement le jeton **immédiatement à sa gauche** (`SpecialEffects.steal_row_token`, signature simplifiée). Objectif explicite du user : outil de repositionnement fiable ("récupérer stratégiquement un jeton mal placé"), plus un pari. Cas limite tranché : un Crow posé en colonne 0 (rien à sa gauche) ne fait rien et disparaît quand même — jamais de blocage indéfini sur la grille, même raisonnement que partout ailleurs dans le jeu (countdown toujours borné, un Crow qui attendrait indéfiniment resterait planté pour toujours s'il est posé colonne 0).

**2. Bombe scoring + famille à 3 paliers** — Bombe (Common, 3×3, purement instantanée, zéro score) sous-performait par rapport au reste du catalogue. Retravaillée en famille complète avec Pétard à mèche, toutes à retardement et scorantes désormais :

| Nom | Rareté | Countdown | Zone |
|---|---|---|---|
| Pétard à mèche | Uncommon | 3 | 2 cases (gauche/droite) — inchangé |
| Bombe (nerfée) | Rare | 5 | 4 cases (haut/bas/gauche/droite) |
| Armageddon (nouveau) | Epic | 8 | 8 cases (carré 3×3 — l'ancienne forme de Bombe) |

Countdown croissant avec la taille de zone, choisi comme le vrai "gamble" de cette famille (contrairement aux mobiles, dont le gamble porte sur la position) : plus la mèche est longue, plus la grille a le temps de changer sous l'explosif avant qu'il parte, donc plus l'issue réelle devient incertaine — pas besoin d'un bonus supplémentaire en plus de la zone qui grossit.

**Implémentation** : `ARMAGEDDON` ajouté en fin d'enum `TokenData.SpecialType` (jamais au milieu — les `.tres` référencent les index par entier brut, un décalage aurait rompu tout le catalogue existant). `GridManager` généralisé : offsets par forme (Pétard/Bombe/Armageddon) remplacent la logique dédiée à Pétard, `_detonate_petard` devient `_detonate_explosive(cell, offsets)`, `tick_special_countdowns`/`detonate_remaining_explosives` (renommé) couvrent toute la famille. Bombe quitte le bucket "instantané" de `execute_special` pour le bucket "à retardement" comme Pétard. Nettoyage : `SpecialEffects.execute_bombe` (mort), `TurnController._on_special_executed` (ne servait qu'à lire le score instantané de Bombe, mort), message de score générique "EXPLOSION +X" côté `GameScene._on_petard_scored` (plus de nom précis, le signal ne distingue pas quel membre de la famille a détoné, et plusieurs peuvent détoner le même tour).

**Bug trouvé en cours de route (statique)** : `SpecialEffects.can_play()` a un `match` exhaustif sans branche par défaut — sans y ajouter explicitement `ARMAGEDDON`, le joueur n'aurait jamais pu le poser nulle part (bloqué silencieusement par le check de jouabilité, avant même d'atteindre `execute_special`). Attrapé en auditant systématiquement tous les `match token.special_type` du projet après l'ajout du nouvel enum.

**Bug trouvé au playtest (crash)** : premier jet des offsets stocké dans un `const Dictionary` (type → `Array[Vector2i]`). Un `Array` écrit comme valeur littérale dans un `Dictionary` ne garde pas son typage élément par élément, et le caster ensuite via `as Array[Vector2i]` au moment de la lecture plante au runtime dès qu'il est passé à une fonction qui exige ce type strict (`_detonate_explosive`) — crash confirmé en jeu au premier Pétard qui détonait. Fix : dictionnaire remplacé par une fonction `_explosive_offsets(special_type) -> Array[Vector2i]` (un `match` qui `return` un littéral directement) — le typage de retour de fonction, contrairement au cast a posteriori sur une valeur de dictionnaire, coerce correctement. Retesté avec Bombe, confirmé stable.

**Asset** : le user a fourni `assets/special-tokens/arma.png` en cours de route — pas de placeholder à remplacer plus tard.

Catalogue de spéciaux et tableau de rareté mis à jour en conséquence — voir [Spéciaux](../gdd/jetons/specials.md).

## Où on en est (fin de session)

Run complet joué avec Le Généreux (2e des 4 starters testés à fond) — reste Le Simplet et un dernier avant d'avoir fait le tour des 4. Prochaines étapes actualisées :

- **Terminer le tour des starters restants** (Le Simplet + 1) — objectif explicite du user pour se faire une idée d'ensemble du jeu après tout ce chantier
- Les 4 spéciaux réactifs (Électrique/Cristal/Diamant/Amplificateur) restent à coder — toujours pas commencé
- Calibrage fin des chiffres de la roulette (seuil, valeurs multi, ampleur du Boost) — toujours au playtest
- Passe UI/juice plus poussée sur la roulette — toujours plate visuellement
- Synergies Badges/Boss malus sur la roulette et les cases mystère — évoquées en discussion mais volontairement laissées de côté ("on laisse mariner")
- Lien narratif pour Boost — pas bloquant
- Rien de tout ce chantier n'est encore commité — à faire en fin de session une fois ce dernier lot de retours validé
