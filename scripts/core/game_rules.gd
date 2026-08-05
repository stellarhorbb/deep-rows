class_name GameRules

# Grille
const COLS: int = 7
const ROWS: int = 7

## Profondeur maximale de la persistance entre manches (voir
## GridManager.get_top_base_tokens) -- 1 par defaut, 2 avec le Sortilège
## "Deux étages". Layout fixe (toujours COLS * CARRYOVER_MAX_DEPTH, meme si
## le Sortilège n'est pas equipe) pour que l'encodage/decodage entre la fin
## d'une manche (_on_round_won) et le debut de la suivante (_play_carryover_
## intro) ne desynchronise jamais si le Sortilège est achete/vendu entre les
## deux (au shop).
const CARRYOVER_MAX_DEPTH: int = 2

# Patterns — taille minimum
const MIN_MATCH_SIZE: int = 3

# Garde-fou de securite (pas une valeur de balancing) : nombre max de passes
# de cascade dans une seule resolution (CascadeResolver.resolve). Chaque passe
# retire normalement au moins une cellule, donc COLS*ROWS suffirait en theorie —
# largement au-dessus pour ne jamais gener un cas legitime, coupe seulement un
# vrai bug de boucle infinie (freeze total signale en session 25) au lieu de
# geler le jeu.
const MAX_CASCADE_PASSES: int = 200

# Chevauchement de figures dans un meme tour (CascadeResolver.resolve) : deux
# groupes qui partagent au moins une cellule sans que l'un soit entierement
# inclus dans l'autre sont un "Double Partition" delibere — les deux scorent
# et leur total combine est multiplie par ce facteur. Si l'un des deux groupes
# est un sous-ensemble strict de l'autre (ex: T contenu dans Plus, memes
# jetons), ce n'est pas un combo : seule la mieux payee compte, comme avant.
const PATTERN_COMBO_MULTIPLIER: float = 2.0

# Cascade — x2 par niveau (pow(2, cascade_level))
const CASCADE_MULTIPLIER_BASE: float = 2.0

# Deck
const DECK_ROCK_COUNT: int = 4

# Malus de boss "Pluie de cailloux" — rocks supplementaires injectes dans le
# deck pour la manche, en plus de DECK_ROCK_COUNT (voir BossMalusManager).
const BOSS_MALUS_ROCK_COUNT: int = 4

# Malus de boss "Mèche courte" — countdown de depart d'un entity-skull avant
# qu'il explose (voir GridManager.tick_entity_countdowns).
const MECHE_COURTE_START_COUNTDOWN: int = 5

# Famille des explosifs a retardement (session 25 : Bombe/Armageddon
# rejoignent Petard a meche, avant elle seule a scorer) — countdown de depart
# avant explosion, croissant avec la taille de la zone d'impact (voir
# GridManager.tick_special_countdowns/_explosive_offsets). Plus la zone est
# grande, plus la grille a le temps de bouger dessous avant que ça parte —
# c'est le "gamble" propre a cette famille (contrairement aux mobiles
# Cavalier/Frog, dont le gamble porte sur la destination, pas le temps).
const PETARD_A_MECHE_START_COUNTDOWN: int = 3  # 2 cases (gauche/droite), Uncommon
const BOMBE_START_COUNTDOWN: int = 5           # 4 cases (haut/bas/gauche/droite), Rare
const ARMAGEDDON_START_COUNTDOWN: int = 8      # 8 cases (carre 3x3 autour), Epic

## Multiplicateurs de la famille "Décuple Pétard/Quintuple Bombe/Triple
## Armageddon" (session "Vague 1") -- chaque Sortilège ne boost que le score
## d'un seul type d'explosif, voir GridManager.tick_special_countdowns.
const DECUPLE_PETARD_MULT: float = 10.0
const QUINTUPLE_BOMBE_MULT: float = 5.0
const TRIPLE_ARMAGEDDON_MULT: float = 3.0

# Speciaux mobiles (session 22) — nombre de deplacements/croissances avant
# disparition (voir GridManager.tick_mobile_specials).
const CAVALIER_MOVES: int = 3
const FROG_MOVES: int = 5

## Siphon (session "Vague 3") : plafond fixe de bouchees (cases mangees
## au-dessus/en-dessous), capture une fois a la pose -- empeche de le
## nourrir indefiniment en re-droppant dans sa colonne. Voir SpecialEffects.
## siphon_eat / GridManager.tick_mobile_specials.
const SIPHON_MAX_EATS: int = 5
const LIANE_GROWTH_TICKS: int = 3
const CROW_IDLE_TICKS: int = 1

## Multiplicateur de valeur (retour playtest session 25) applique au score
## brut de Cavalier/Frog quand ils mangent effectivement quelque chose — voir
## SpecialEffects.move_cavalier/move_frog. Compense le seul vrai "gamble" du
## jeu chez les speciaux : leur destination est tiree au hasard parmi
## plusieurs cases valides (contrairement a Bombe/Petard/Liane/Underground,
## toujours visees ou deterministes), donc un coup rate ne rapporte
## strictement rien — contrairement a la famille Bombe, dont la zone
## d'impact garantit toujours au moins sa base. Premier jet, a ajuster au
## ressenti.
const MOBILE_EATER_GAMBLE_MULT: float = 1.5

# "Grille cabossee" — trous generes au debut de chaque manche. Un jeton qui
# tombe les traverse sans pouvoir s'y arreter — different d'un Rock, qui
# bloque et sert d'appui.

## "Fond marin" (session 26, quatrieme jet) : plusieurs pics independants,
## chacun une pyramide en escalier (largeur de base 1/3/5 pour hauteur
## 1/2/3, retrecit de 2 cases par row en montant jusqu'a 1 case au sommet)
## ancree sur une colonne au hasard -- pas forcement centree, clippee aux
## bords si l'ancre est pres d'un cote (le pic "sort du champ", voulu). Les
## versions precedentes (marche aleatoire, tirage independant par colonne,
## pic unique + solitaires) ne rendaient jamais assez varie. Voir
## GridManager._generate_seafloor / _carve_peak.
const SEAFLOOR_PEAK_COUNT_MIN: int = 2
const SEAFLOOR_PEAK_COUNT_MAX: int = 4

## Taux fixe par hauteur (1/2/3), meme principe que MYSTERY_RARITY_RATES --
## index 0 = hauteur 1 (case simple), index 2 = hauteur 3 (gros pic).
const SEAFLOOR_PEAK_HEIGHT_RATES: Array[float] = [0.45, 0.35, 0.20]

## Aspiration des jetons persistes en fin de manche (session 26), juste avant
## l'ecran YOU WIN -- duree du vol + fondu (GridVisual.animate_pickup), plus
## une courte pause avant/apres pour laisser le geste se lire. Vise ~3
## secondes au total, demande par le user.
const CARRYOVER_PICKUP_DURATION: float = 1.8
const CARRYOVER_PICKUP_PRE_DELAY: float = 0.6
const CARRYOVER_PICKUP_POST_DELAY: float = 0.6

## Trous isoles en plus du fond marin, disperses au hasard sur toute la
## grille (jamais en row 0 -- le sol garde toujours au moins une case
## non-trouee sur ces colonnes-la). Premier jet, a ajuster au ressenti.
const ROUND_START_RED_HOLES_MIN: int = 2
const ROUND_START_RED_HOLES_MAX: int = 4

# Stream
const PREVIEW_SIZE: int = 3
const BASE_HOLD_SLOTS: int = 1

## Inventaire de speciaux (session 25, remplace le systeme "special = jeton du
## deck") -- le joueur achete un special au shop, il rejoint cet inventaire
## possede pour toute la run (pas remis a zero au round_start, contrairement
## au deck), joue a la demande a la place du coup normal (voir TurnController.
## play_special_from_inventory). Fixe pour l'instant, pas encore upgradable
## par Sortilège comme le Hold (BASE_HOLD_SLOTS) -- a etendre si le besoin se
## confirme au playtest.
const SPECIAL_INVENTORY_SLOTS: int = 3

## "Shake" -- bouton d'urgence qui remelange TOUT ce qui reste a jouer cette
## manche (current en main + hold + pioche), jamais la composition -- pas
## d'ajout/retrait/recuperation de jetons deja joues, donc aucune contradiction
## avec le "un seul passage, pas de reshuffle" du deck (voir docs/gdd/manche/
## deck.md). Completement aleatoire, peut ne rien ameliorer. Charge limitee
## PAR RUN (pas par manche) -- voir RunManager._shake_charges.
const SHAKE_CHARGES_DEFAULT: int = 2

## Score cible par manche (session 18, remplace l'ancien BASE_TARGET +
## TARGET_INCREMENT lineaire). Valeurs hardcodees pour faciliter le retuning
## manuel plutot qu'une formule live — derivees de :
##   f(n) = (n-1) + ACCEL * (n-1)^2        avec ACCEL = 0.01
##   target(n) = round_to_2_sig_figs(60 * GROWTH^f(n))  avec GROWTH = 2^(1/4)
##   (grain minimum 5 — 2 sig figs seul ne touche pas les nombres a 2 chiffres,
##   d'ou le 70 en manche 2 plutot que 71)
## (doublement tous les 4 manches + acceleration quadratique tardive, boss
## sans multiplicateur — le malus de boss porte deja la difficulte du tour).
## Index = manche - 1. Les paliers boss (5, 10, 15, 20) restent sur la meme
## courbe lissee, pas de spike. Voir docs/gdd/manche/score-cible.md.
const ROUND_TARGETS: Array[int] = [
	60, 70, 85, 100, 120,
	150, 180, 220, 270, 330,
	400, 500, 620, 770, 950,
	1200, 1500, 1900, 2400, 3000,
]

# Structure d'un run — 4 biomes de 5 manches (4 + 1 boss) = 20 manches
const ROUNDS_PER_ZONE: int = 5
const ZONES_PER_RUN: int = 4

## Noms placeholder des biomes (session 18) et fond pastel associe, un par
## zone + un pour le mode infini. Index = zone - 1 (voir GameScene._update_
## zone_display). Noms et couleurs a remplacer une fois la DA/l'univers
## des biomes tranches (voir questions-ouvertes.md).
const BIOME_NAMES: Array[String] = ["PLAGE", "FORET", "MARAIS", "REVES", "VIDE"]
const BIOME_BACKGROUND_COLORS: Array[Color] = [
	Color("b8ccd8"), # Plage — bleu
	Color("bfddc4"), # Foret — vert
	Color("d0c2e0"), # Marais — violet
	Color("e8c9d6"), # Reves — rose
	Color("d6d6da"), # Vide (mode infini) — gris
]

# Sheets
const MAX_SHEET_SLOTS: int = 4

# Vente de Partitions/Sortilèges — pourcentage du prix d'achat rembourse
const SELL_REFUND_RATIO: float = 0.5

# Sortilèges
const MAX_SPELL_SLOTS: int = 5

## Bonus de slots de Sortilège le plus genereux qu'un pack de demarrage puisse
## accorder (Le Collectionneur, +1, voir resources/starter_packs/) — sert
## uniquement a dimensionner a l'avance les slots UI de SpellsUI, crees avant
## qu'un pack ne soit choisi (voir SpellsUI._create_sell_buttons). A remonter
## si un futur pack accorde plus.
const STARTER_PACK_MAX_SPELL_SLOT_BONUS: int = 1

# Recompense par manche gagnee (fixe pour l'instant)
const FLIES_PER_ROUND_WON: int = 8

# Bonus de mouches en fin de manche si le deck restant est encore confortable
# au moment de la victoire (session 18, retune equilibrage).
const FLIES_BONUS_REMAINING_THRESHOLD: int = 10
const FLIES_BONUS_REMAINING: int = 2

# Delai avant transition en fin de manche (shop / victoire / defaite) pour
# laisser le temps d'integrer le dernier coup.
const ROUND_END_DELAY: float = 2.0


static func get_round_end_flies_bonus(remaining: int) -> int:
	if remaining >= FLIES_BONUS_REMAINING_THRESHOLD:
		return FLIES_BONUS_REMAINING
	return 0

# Modificateurs de cellules
# Cle stockee dans le dict grid_modifiers : Vector2i -> Array[StringName]
# (plusieurs types peuvent s'empiler sur une meme case, voir RunManager.add_grid_modifier)
const MODIFIER_HALF: StringName = &"half"
const MODIFIER_BOOST: StringName = &"boost"
const MODIFIER_DOUBLE: StringName = &"double"
const MODIFIER_TRIPLE: StringName = &"triple"
const MODIFIER_HALF_MULT: float = 0.5
const MODIFIER_BOOST_MULT: float = 1.5
const MODIFIER_DOUBLE_MULT: float = 2.0
const MODIFIER_TRIPLE_MULT: float = 3.0

## Special "Amplificateur" (session "Vague 2", revise) : double le score d'un
## groupe qui touche une de ses 4 cases orthogonales -- reactif comme
## Hypercube, pas un modifier de cellule plante a la pose (voir
## CascadeResolver._adjacent_amplificateurs). Usage unique, se retire du jeu
## des qu'il declenche.
const AMPLIFICATEUR_MULT: float = 2.0

# Modifiers exclusifs aux cases mystere (effet MULTI, voir MysteryCellEffects) —
# jamais poses par un Sortilège, paliers au-dessus de MODIFIER_TRIPLE pour garder
# un vrai "wow" propre a la surprise.
const MODIFIER_MYSTERY_X2: StringName = &"mystery_x2"
const MODIFIER_MYSTERY_X5: StringName = &"mystery_x5"
const MODIFIER_MYSTERY_X10: StringName = &"mystery_x10"
const MODIFIER_MYSTERY_X2_MULT: float = 2.0
const MODIFIER_MYSTERY_X5_MULT: float = 5.0
const MODIFIER_MYSTERY_X10_MULT: float = 10.0

# Modifier exclusif au Sortilège "Bord a Bord" (session 25, retune equilibrage) --
# MODIFIER_BOOST est partage avec Ecume/Colonne Chanceuse/Trench (voir
# scripts/spells/effect_*.gd) : le retoucher directement aurait aussi nerf
# ces trois-la sans que ce soit demande. Valeur dediee pour ne changer que
# Bord a Bord.
const MODIFIER_BORD_A_BORD: StringName = &"bord_a_bord"
const MODIFIER_BORD_A_BORD_MULT: float = 1.2

# Cases mystere (session 24, axe casino) — quelques cases par manche, visibles
# mais au contenu inconnu jusqu'a ce qu'un jeton/rock/special y atterrisse
# (voir GridManager.generate_random_mystery_cells, MysteryCellEffects).
# Retour a 2-4 en session 25 apres un aller-retour a 1-2 : la roulette a
# d'abord ajoute des cases en plus (Planter), puis ce pont a ete retire pour
# garder les deux systemes casino totalement independants (voir
# docs/gdd/manche/roulette-casino.md) — les cases mystere redeviennent donc
# la seule source, retour au chiffre valide fun en session 24.
const ROUND_START_MYSTERY_MIN: int = 2
const ROUND_START_MYSTERY_MAX: int = 4

## QoL (retour user) : les "?" de round-start apparaissent en escalier
## gauche a droite plutot que toutes en meme temps, meme langage visuel que
## GameScene._play_carryover_intro (jetons persistes). Delai entre chaque
## colonne concernee, pas entre chaque case individuelle.
const MYSTERY_REVEAL_STAGGER: float = 0.12

## Taux fixe par palier (Commun/Rare/Jackpot), meme principe que
## SPELL_RARITY_RATES : le taux se fixe par palier, pas par item — avoir plus
## d'items en Rare rend juste ce palier plus varie, pas plus frequent.
const MYSTERY_RARITY_RATES: Array[float] = [0.55, 0.40, 0.05]

## Catalogue recentre sur la grille/le jeton (session 27, retire les effets
## purement economiques -- mouches/cible -- voir docs/brainstorms/brainstorm-
## geste-central.md). Valeur+/Valeur- : delta applique au jeton qui declenche
## la case, voir MysteryCellEffects/GridManager.nudge_token_value.
const MYSTERY_VALUE_DELTA: int = 1

## Pierre libérée (voir GridManager.free_adjacent_rock) : valeur du jeton de
## base qui remplace le Rock adjacent converti -- basse par design, c'est
## l'espace regagne qui est la vraie recompense, pas la valeur du jeton.
const MYSTERY_ROCK_FREED_VALUE: int = 1

# Entity
## Drop de skull (session 26, remplace l'ancien intervalle fixe) : chance qui
## grimpe de ENTITY_DROP_INCREMENT chaque tour depuis le dernier drop,
## plafonnee naturellement a 100% (un pourcentage ne peut pas depasser 100 --
## pas besoin d'un "forced" code a part). Premier jet a 20%+10% juge trop
## frequent au playtest (moyenne ~3 tours) ; retune a 5%+10% par tour ->
## moyenne simulee ~5.3 tours, quasiment identique a l'ancien intervalle
## fixe de 5. Le plafond naturel ne tombe que tres tard (tour 20) mais
## n'est quasiment jamais atteint en pratique (~93% des cas deja resolus
## avant le tour 9). Remplace le comptage exact ("je sais qu'un skull tombe
## dans exactement N tours") par une vraie incertitude, bornee et simple a
## presenter (un pourcentage, pas une regle arbitraire).
const ENTITY_DROP_BASE_CHANCE: float = 0.05
const ENTITY_DROP_INCREMENT: float = 0.05

## Colonne Convoitée (remplace l'axe casino "roulette" de session 25, nom
## placeholder) -- bonus AJOUTE a la chance ambiante du moment (pas un taux
## fixe independant, voir EntityManager.corruption_chance) quand le joueur
## choisit de droper dans la colonne signalee par EntityManager.
## reroll_cursed_column -- sinon un ambiant deja monte haut (longue serie
## sans skull) finirait par depasser le risque affiche sur la colonne, qui
## doit pourtant rester la pire option. Le risque total est affiche
## (contrairement au risque ambiant, qui reste cache) puisque c'est un pari
## delibere, pas une menace de fond -- voir docs/brainstorms/brainstorm-geste-
## central.md. Multiplie par EntityManager.drop_chance_multiplier comme
## l'ambiant (malus de boss GRANDE FAIM), plafonne a 100%. Au niveau de base
## (ambiant 5%), ca retombe sur 35% -- meme premiere impression qu'avant.
const CURSED_COLUMN_SKULL_BONUS: float = 0.30

## Pool de recompenses de la Colonne Convoitée quand le drop echappe a la
## corruption (deux familles seulement, Multiplicateur / Boost -- meme
## catalogue que l'ancienne roulette, juste retarget sur le geste). Meme
## principe a taux fixe par palier que MYSTERY_RARITY_RATES -- voir
## CursedColumnRewards.
const CURSED_COLUMN_RARITY_RATES: Array[float] = [0.55, 0.40, 0.05]  # Commun/Rare/Legendaire

## Contrepoids au risque (session 27, retour user) : plus le % de corruption
## affiche sur la Colonne Convoitée est haut, plus le palier Legendaire est
## probable en retour -- voir CursedColumnRewards.roll_tier/_scaled_rates.
## Multiplicatif sur le taux de base (5%) : x1 a risque nul, jusqu'a x4 (20%)
## a 100% de risque. A 80% de risque (exemple concret du user), ca donne
## ~x3.4 -- proche du "3x" evoque a l'oral. Sans ca, une colonne a haut risque
## n'offre aucune contrepartie et devient juste une case a fuir des qu'elle
## depasse un seuil de confort personnel.
const CURSED_COLUMN_JACKPOT_MULTIPLIER_MAX: float = 4.0

## Multiplicateur applique aux prochains drops apres le declenchement (jamais
## celui qui declenche) -- voir EntityManager. Fixe, pas de roll dans une
## fourchette : "ce sera memorable" (choix du user pour le palier Legendaire).
const CURSED_COLUMN_MULTI_VALUES: Array[float] = [1.2, 3.0, 10.0]  # index = palier

## Delai MAXIMUM (en drops) pour se servir du multiplicateur avant qu'il
## n'expire -- pas une duree garantie, voir EntityManager.tick_multi : des
## qu'un tour scoré en profite, il s'efface immediatement. 1 seul drop en
## premier jet (session 25), remonte a 3 apres retour de playtest ("un coup
## c'est trop chaud a caler") : trop dur a timer precisement sur un coup unique.
const CURSED_COLUMN_MULTI_DROPS: int = 3

## Fenetre etendue (Sortilège "Fenêtre Longue") -- remplace CURSED_COLUMN_
## MULTI_DROPS quand equipe, pour laisser plus de temps a un Multiplicateur
## d'etre reellement rentabilise.
const CURSED_COLUMN_MULTI_DROPS_EXTENDED: int = 5

## Boost (session 25, remplace Frog dans le pool a l'epoque de la roulette) --
## augmente directement la valeur du jeton que le joueur vient de droper dans
## la Colonne Convoitée (mutation immediate, meme langage visuel que Pile ou
## Face -- voir TurnController.play_current_to). Cible desormais TOUJOURS ce
## jeton precis, jamais un jeton aleatoire ailleurs sur la grille (ancien
## defaut de la roulette identifie en session 27). L'ampleur varie par palier
## -- meme forme que CURSED_COLUMN_MULTI_VALUES (1.2/3/10) pour rester
## coherent visuellement dans le pool. Plafonne a MAX_BUTTON_VALUE (10) :
## les figures restent exclusivement accessibles par le score reel, jamais
## offertes gratuitement -- +10 sur le palier Legendaire revient donc
## toujours a fixer la valeur pile a 10, peu importe le point de depart.
const CURSED_COLUMN_BOOST_VALUES: Array[int] = [1, 3, 10]  # Commun/Rare/Legendaire

# Valeurs des jetons de base
const TOKEN_MIN_VALUE: int = 1
const TOKEN_MAX_VALUE: int = 5
const FAMILY_COUNT: int = 4

## Suite Fibonacci de reference pour la Partition "Fibonacci" (session 14,
## etendue session 19) — n'importe quelle fenetre de FIBONACCI_WINDOW_SIZE
## valeurs consecutives de cette suite matche (1,1,2,3 / 1,2,3,5 / 2,3,5,8),
## pas seulement les 4 premiers termes. Dans un sens ou dans l'autre le long
## de la ligne (voir SheetMatcher.find_fibonacci).
const FIBONACCI_SEQUENCE: Array[int] = [1, 1, 2, 3, 5, 8]
const FIBONACCI_WINDOW_SIZE: int = 4

## Valeur plafond/plancher pour les Partitions "Minima"/"Maxima" (session 19,
## axe casino) — tous les jetons alignes doivent respecter le seuil (strict,
## "< 3" et "> 7" cote Sheet), peu importe la famille. Maxima (valeurs >= 8)
## demande plusieurs Fusions (le tirage de base plafonne a TOKEN_MAX_VALUE =
## 5), pas juste un tirage chanceux — d'ou son mult plus eleve que Minima.
const MINIMA_MAX_VALUE: int = 2
const MAXIMA_MIN_VALUE: int = 8

## Suite de nombres premiers de reference pour la Partition "Nombres premiers"
## (session 19) — meme mecanique que FIBONACCI_SEQUENCE (n'importe quelle
## fenetre valide de la suite matche), mais fenetre MINIMALE plutot que fixe :
## au moins PRIME_MIN_WINDOW consecutifs, jusqu'a la sequence entiere (2,3,5 /
## 3,5,7 / 5,7,11 / 2,3,5,7,11...). 11 etendu en session 22 : un Valet (voir
## GameRules.FACE_CARD_VALUES) est premier — fenetre haute optionnelle, ne
## baisse pas le plancher de difficulte (2,3,5 seul declenche toujours),
## meme principe que les fenetres hautes de Fibonacci (valeurs obtenues par
## Fusion/promotion, rares).
const PRIME_SEQUENCE: Array[int] = [2, 3, 5, 7, 11]
const PRIME_MIN_WINDOW: int = 3

## Tiroir rare/signature (session 14/19, "Vague 1") — meme mecanique que
## FIBONACCI_SEQUENCE/PRIME_SEQUENCE (SheetMatcher._find_sequence_matches),
## mais une fenetre fixe unique de valeur repetee plutot qu'une suite. 777
## demande 3 Fusions vers 7, 9999 en demande 4 vers 9 (proche du plafond
## MAX_BUTTON_VALUE = 10) — signature de fin de run.
const JACKPOT_777_SEQUENCE: Array[int] = [7, 7, 7]
const JACKPOT_9999_SEQUENCE: Array[int] = [9, 9, 9, 9]

## Roll casino ajoute a la valeur du centre d'un Diamond Rock (session 15) —
## avec seulement DECK_ROCK_COUNT rocks dans tout le deck, ce pattern ne se
## declenche quasiment qu'une fois par run : le roll garantit un plancher
## correct independamment de la valeur (chanceuse ou non) du jeton central,
## et ajoute un moment casino avant que le multiplicateur du sheet s'applique.
const DIAMOND_ROCK_ROLL_MIN: int = 1
const DIAMOND_ROCK_ROLL_MAX: int = 5

## Partitions legendaires (session 20) — petit pool a part de 3 ressources
## (Lost Corners, Royal Square, Last Trick), jamais dans le tirage uniforme
## normal (voir ShopManager.LEGENDARY_SHEET_PATHS). Chance independante par
## slot "sheet" (unitaire ou candidat de pack) qu'il s'agisse d'une legendaire
## plutot qu'un tirage normal — additif, ne retire jamais de chances au pool
## de base. Effets codes en dur par sheet_name dans CascadeResolver/
## SheetMatcher, pas de systeme d'effets generique (voir SheetData.is_legendary).
## 0.05 -> 0.03 (session 22) : a 5%, ~7-10% de chance de tomber sur les 3
## legendaires en une seule run (calcul sur ~19 tirages de Partition/run avec
## CATEGORY_WEIGHTS actuels) — trop frequent pour rester "legendaire". A 3%,
## la probabilite du grand chelem tombe a ~2%.
const LEGENDARY_SHEET_CHANCE: float = 0.03

## Royal Square (Carre 2x2 famille) : le multiplicateur EST le roll, pas un
## bonus ajoute a autre chose (contrairement au roll de Diamond Rock) — flat,
## ne level up jamais. Declencheur identique a Square Family (facile a
## provoquer volontairement), donc beaucoup de tentatives possibles par run —
## 20 -> 12 (session 22) apres 3 manches de suite explosees par un roll
## moyen/haut combine a une cellule doublee. Plage reduite mais toujours
## uniforme (pas de ponderation) : un roll reste un vrai jet de des, pas
## truque, meme si la plage est plus resserree.
const ROYAL_SQUARE_ROLL_MIN: int = 1
const ROYAL_SQUARE_ROLL_MAX: int = 12

## Sortilège "Echo" (session 27) : chance qu'un groupe qui score se retrigger
## (score double) -- voir RunContext.has_echo/CascadeResolver.
## _apply_score_gambles.
const ECHO_RETRIGGER_CHANCE: float = 0.15

## Sortilège "Quitte ou Double" (session 27) : chaque groupe qui score joue ce
## coin-flip -- double si <, remis a zero sinon. Toujours 50/50 par design
## (voir Sheet), constante quand meme pour respecter "zero magic number".
const QUITTE_OU_DOUBLE_CHANCE: float = 0.5

## Skull Line 4 (tiroir rare/signature, session "Vague 3") : les 4 cellules
## sont des entity-skulls, sans valeur reelle -- tirage a palier (meme
## principe que CURSED_COLUMN_RARITY_RATES/MYSTERY_RARITY_RATES) plutot qu'une
## plage lineaire, pour un vrai coup de jackpot plutot qu'un chiffre plat.
## 120 calcule contre CURSED_COLUMN_BOOST_VALUES (ratio x3/x3.3) plutot qu'a
## l'instinct — verifie au jugement du user contre un scenario reel
## (4 skulls du pattern + 3 autres sur la grille = x7, donc jusqu'a 840 sur
## le palier legendaire, reste sous la cible manche 20 ~3000).
const SKULL_LINE_VALUE_RATES: Array[float] = [0.55, 0.40, 0.05]
const SKULL_LINE_VALUES: Array[int] = [12, 36, 120]

## Last Trick (Losange famille) : le centre (jamais requis par le match, voir
## SheetMatcher.find_diamonds) se transforme en jeton de cette valeur, AJOUTE
## DEFINITIVEMENT au pool possede (voir RunManager.add_button, appele par
## TurnController sur EventType.TRANSFORM) — un vrai moteur de deck-building,
## pas juste un coup de pouce pour la manche en cours. Plafonne a 9, pas
## MAX_BUTTON_VALUE (10) : le vrai plafond du jeu reste un objectif merite via
## les Des a coudre (Augmenter/Fusionner), pas court-circuite gratuitement.
## Vu la frequence de Diamond+famille en jeu, LAST_TRICK_TRIGGER_CHANCE limite
## l'effet a une manche sur N plutot qu'un tirage a chaque match (retour de
## playtest session 20 : sans ca, un moteur permanent qui se declenche a
## chaque fois est too much).
const LAST_TRICK_VALUE: int = 9
const LAST_TRICK_TRIGGER_CHANCE: float = 0.25

## Sortilège "Dernier dernier Souffle" (Va-tout, session "Vague 2") : au
## Dernier Souffle, une fois le score final connu, tirage all-in sur tout le
## score de la manche. Voir TurnController._on_resolution_complete.
const VA_TOUT_WIN_CHANCE: float = 0.2

## Poids de tirage par rarete au shop (unitaires + packs), par item — plus il
## y a d'items dans un palier, plus ce palier occupe de place au total. Utilise
## par DeckToolData et SpecialItem (rarete ajoutee en session 23) via
## ShopManager._weighted_pick. Les Sortilèges n'utilisent PLUS ce systeme depuis la
## session 23 (voir SPELL_RARITY_RATES ci-dessous) — Boutons et Partitions
## n'ont toujours pas de champ rarity, tires uniformement (Partitions retirees
## du systeme en session 19, voir Decisions tranchees : gater par rarete la
## mecanique de resolution elle-meme allait a l'encontre du principe "pas de
## RNG punitif", contrairement aux Sortilèges/Speciaux/Des a coudre qui restent un
## bonus optionnel).
const RARITY_WEIGHTS: Array[float] = [10.0, 5.0, 2.0, 1.0, 0.1]

## Taux de tirage FIXE par palier pour les Sortilèges (session 23, inspire de
## Balatro) — contrairement a RARITY_WEIGHTS ci-dessus, ce n'est PAS un poids
## par item : chaque palier a une probabilite constante, peu importe combien
## de Sortilèges y vivent. Ajouter un Sortilège Epic ne rend donc pas le palier Epic
## plus frequent, juste chaque Epic individuel un peu plus rare a l'interieur
## d'un palier dont la frequence globale ne bouge pas. Somme = 1.0. Si un
## palier n'a aucun Sortilège disponible (tous equipes, ou vide), il est retire du
## tirage et les autres se renormalisent automatiquement (voir ShopManager.
## _draw_spell_queued) — meme principe que le "resample" de Balatro.
## Legendary a 1% assume un seul Sortilège dedans pour l'instant (Poker Face) —
## a se sentir plus "chasse variee" une fois d'autres Sortilèges Legendary ajoutes.
const SPELL_RARITY_RATES: Array[float] = [0.50, 0.30, 0.13, 0.06, 0.01]

## Couleurs et noms par rarete, pour le sortilège colore affiche dans les tooltips
## (voir RarityTooltip). Meme indexation que RARITY_WEIGHTS.
const RARITY_COLORS: Array[Color] = [
	Color("9a9a9a"), # COMMON
	Color("4caf7d"), # UNCOMMON
	Color("4a90d9"), # RARE
	Color("b06fd9"), # EPIC
	Color("e8b923"), # LEGENDARY
]
const RARITY_NAMES: Array[String] = ["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY"]

# Deck de depart structure : x copies de chaque (famille, valeur) possible,
# plutot qu'un tirage purement aleatoire — garantit une repartition egale
# entre les 4 familles a chaque run (voir RunManager._generate_starter_buttons).
# Reduit de 2 a 1 en session 18 (40+4 -> 20+4) : le deck de base etait trop
# genereux, la pression "deck vide" arrivait trop tard. Mais 20+4 s'est
# revele trop juste au playtest (44 -> 24 coups/manche, cible inchangee) —
# second pass session 18 : une copie supplementaire, mais seulement pour les
# valeurs basses (1-2), pour ne pas regonfler la rarete des valeurs hautes
# (3-5), qui doivent rester precieuses a placer. Total 28+4 = 32.
const STARTER_COPIES_PER_VALUE: int = 1
const STARTER_LOW_VALUE_EXTRA_COPY_MAX: int = 2 # valeurs <= ce seuil recoivent 1 copie de plus
const DECK_BASE_COUNT: int = (
	FAMILY_COUNT * (TOKEN_MAX_VALUE - TOKEN_MIN_VALUE + 1) * STARTER_COPIES_PER_VALUE
	+ FAMILY_COUNT * (STARTER_LOW_VALUE_EXTRA_COPY_MAX - TOKEN_MIN_VALUE + 1)
)

## Plafond de valeur apres fusion (voir RunManager.fuse_buttons) — la valeur
## ne sert plus a resoudre des patterns (seule la famille compte pour ca),
## juste a amplifier le score une fois un match resolu. Sans plafond elle
## scale sans limite au fil des fusions.
const MAX_BUTTON_VALUE: int = 10

## Valeur du jeton cree par Cristal/Diamant en convertissant un Rock (voir
## SpecialEffects.execute_cristal_diamant) -- 9 et pas MAX_BUTTON_VALUE (10),
## meme logique que Last Trick : un plafond volontairement sous le vrai max
## merite par la Fusion.
const CRISTAL_VALUE: int = 1
const DIAMANT_VALUE: int = 9

## Chance qu'un bouton achete au shop (unitaire ou pack, voir ShopManager.
## _random_button) sorte directement a MAX_BUTTON_VALUE au lieu du tirage
## normal 1-5 — un petit frisson jackpot a l'achat, qui saute juste le grind
## de Fusion. Les figures (Valet+) restent exclusivement accessibles par le
## score, jamais par le shop (session 18) : voir FACE_CARD_VALUES ci-dessous.
const SHOP_BUTTON_RARE_VALUE_CHANCE: float = 0.01

## Poids de tirage des valeurs 1-5 en boutique (hors jackpot ci-dessus) —
## plus une valeur est haute, plus elle est rare. Index 0 = TOKEN_MIN_VALUE.
## 25/25/25/15/10 : 1, 2 et 3 a poids egal, 4 et 5 degressifs.
const SHOP_BUTTON_VALUE_WEIGHTS: Array[float] = [25.0, 25.0, 25.0, 15.0, 10.0]

## Suite des figures (arcanes mineurs, session 18) : un jeton de base deja a
## MAX_BUTTON_VALUE qui score avance automatiquement d'un cran dans cette
## suite jusqu'a Roi (plafond definitif) — voir RunManager.promote_matching_
## button et CascadeResolver._roll_face_promotions. Chemin EXCLUSIVEMENT
## accessible par le score : Fusion/Augmenter/Poker Face restent plafonnes a
## MAX_BUTTON_VALUE (voir fuse_buttons, increase_button_value), sinon on
## pourrait acheter une figure sans jamais avoir a la jouer.
const FACE_CARD_VALUES: Array[int] = [11, 12, 15, 20] # Valet, Chevalier, Reine, Roi
const FACE_CARD_LABELS: Array[String] = ["J", "C", "Q", "K"] # Valet, Chevalier, Reine, Roi

## A appeler uniquement pour value >= MAX_BUTTON_VALUE (garanti par les deux
## call sites). Retourne la meme valeur si deja au Roi.
static func next_face_value(value: int) -> int:
	if value == MAX_BUTTON_VALUE:
		return FACE_CARD_VALUES[0]
	var idx: int = FACE_CARD_VALUES.find(value)
	if idx < 0 or idx >= FACE_CARD_VALUES.size() - 1:
		return value
	return FACE_CARD_VALUES[idx + 1]

## Valeur affichee sur les jetons (grille + stream) — redevient pertinente
## maintenant qu'elle sert de levier de score, pas juste de bruit visuel.
const DEBUG_SHOW_TOKEN_VALUE: bool = true

# Shop — offre curatee par visite (v2). Deux rangees separees, a la Balatro :
# - Packs : nombre fixe, categorie aleatoire, JAMAIS regeneres par le reroll
#   (fixes pour toute la visite).
# - Unitaires : nombre fixe, categorie aleatoire (incluant Des a coudre),
#   regeneres a chaque reroll.
const SHOP_PACK_SLOT_COUNT: int = 2
const SHOP_UNITAIRE_SLOT_COUNT: int = 2

# Poids de tirage par categorie de slot (session 20) — remplace le shuffle
# uniforme (chaque categorie avait les memes chances). Retour de playtest :
# Partitions et Packs de jetons simples revenaient trop souvent (Partitions
# deja au max niveau, Boutons supplementaires rendent le deck trop facile a
# vider) — rendus 2x plus rares que la base, Speciaux 2x plus frequents.
# Meme mecanisme que RARITY_WEIGHTS mais applique aux categories de slot.
const CATEGORY_WEIGHTS: Dictionary = {
	"sheet": 0.5,
	"spell": 1.0,
	"special": 2.0,
	"button": 0.5,
	"des_a_coudre": 1.0,
}

# Taille des packs a l'ouverture (candidats reveles, le joueur en garde 1).
# Exception boutons (5) deja actee dans le GDD : plus nombreux, individuellement
# moins determinants qu'une Partition ou un Sortilège.
const PACK_SIZE_DEFAULT: int = 3
const PACK_SIZE_BUTTON: int = 5

# Prix des packs par categorie — plus cher qu'un unitaire equivalent mais
# meilleur ratio par item (voir docs/gdd/shop/economie.md). Premiers jets.
const PACK_PRICE_SHEET: int = 8
const PACK_PRICE_SPELL: int = 6
const PACK_PRICE_SPECIAL: int = 4
const PACK_PRICE_BUTTON: int = 4

# Shop — boutons a l'unite
const BUTTON_UNIT_PRICE: int = 5

# Outils de deck ("Des a coudre") — generalise l'ancienne Fusion seule
# (session 16, voir docs/brainstorms/brainstorm-outils-deck.md). Gate derriere
# l'achat d'un "Des a coudre" (slot au meme titre que les autres categories) :
# un achat = tirage de DECK_TOOL_ACTION_DRAW_SIZE actions distinctes ponderees
# par rarete (GameRules.RARITY_WEIGHTS), le joueur en choisit 1, puis cible
# DECK_TOOL_TARGET_DRAW_SIZE boutons tires du pool (meme principe RNG-forward
# que l'ancienne selection de fusion). Remplace l'ancien FUSION_PRICE (bouton
# permanent, spammable).
const DES_A_COUDRE_PRICE: int = 6
const DECK_TOOL_ACTION_DRAW_SIZE: int = 3
const DECK_TOOL_TARGET_DRAW_SIZE: int = 8

# Shop — reroll (prix croissant, reset a chaque nouvelle visite)
const REROLL_BASE_PRICE: int = 2
const REROLL_INCREMENT: int = 1

# Level up des Partitions — regles generiques, identiques pour toutes.
# Seuils de score cumule pour passer au niveau suivant (1->2, 2->3, 3->4, 4->5).
## Retunes session 23 (etaient [150, 500, 1100, 2200], session 15) : calibres
## sur la somme cumulee de ROUND_TARGETS aux 4 manches boss (5/10/15/20), pour
## que Maestro tombe naturellement au dernier boss plutot qu'a mi-run (donnee
## de playtest session 22/23 : Maestro atteint des la manche 11-13/20 avec
## l'ancien seuil, meme sans spam extreme). Arrondis a des valeurs faciles a
## memoriser plutot que les sommes exactes (435/1585/4825/14825).
const SHEET_LEVEL_THRESHOLDS: Array[int] = [400, 1500, 4000, 12000]
# Multiplicateur applique au score selon le niveau (index 0 = niveau 1).
const SHEET_LEVEL_MULTIPLIERS: Array[float] = [1.0, 1.25, 1.5, 1.75, 2.0]
const SHEET_LEVEL_NAMES: Array[String] = ["Pianissimo", "Piano", "Forte", "Fortissimo", "Maestro"]


## Calcule le niveau (1 a 5) a partir du score cumule sur une Partition.
static func compute_sheet_level(cumulative_score: int) -> int:
	var level: int = 1
	for threshold in SHEET_LEVEL_THRESHOLDS:
		if cumulative_score >= threshold:
			level += 1
	return level


static func get_sheet_level_multiplier(level: int) -> float:
	var idx: int = clampi(level - 1, 0, SHEET_LEVEL_MULTIPLIERS.size() - 1)
	return SHEET_LEVEL_MULTIPLIERS[idx]


static func get_sheet_level_name(level: int) -> String:
	var idx: int = clampi(level - 1, 0, SHEET_LEVEL_NAMES.size() - 1)
	return SHEET_LEVEL_NAMES[idx]


## Score cumule requis pour atteindre le PROCHAIN niveau. -1 si deja au max.
static func get_next_sheet_threshold(level: int) -> int:
	if level - 1 >= SHEET_LEVEL_THRESHOLDS.size():
		return -1
	return SHEET_LEVEL_THRESHOLDS[level - 1]


## Score cumule qui a fait passer au niveau ACTUEL (0 pour le niveau 1).
static func get_previous_sheet_threshold(level: int) -> int:
	if level <= 1:
		return 0
	return SHEET_LEVEL_THRESHOLDS[level - 2]


static func get_modifier_multiplier(type: StringName) -> float:
	match type:
		MODIFIER_HALF:   return MODIFIER_HALF_MULT
		MODIFIER_BOOST:  return MODIFIER_BOOST_MULT
		MODIFIER_DOUBLE: return MODIFIER_DOUBLE_MULT
		MODIFIER_TRIPLE: return MODIFIER_TRIPLE_MULT
		MODIFIER_MYSTERY_X2:  return MODIFIER_MYSTERY_X2_MULT
		MODIFIER_MYSTERY_X5:  return MODIFIER_MYSTERY_X5_MULT
		MODIFIER_MYSTERY_X10: return MODIFIER_MYSTERY_X10_MULT
		MODIFIER_BORD_A_BORD: return MODIFIER_BORD_A_BORD_MULT
		_:               return 1.0
