# Session 18 — Courbe de score, biomes tarot, refonte scoring, système de figures

**Date** : 2026-07-16
**Thème** : Session dense, en plusieurs vagues. D'abord de l'équilibrage réactif au playtest (économie, deck, Rainbow, Écume), puis deux vrais chantiers de fond posés le même jour : la courbe de score cible (exponentielle, hardcodée) et le renommage complet des familles sur le vocabulaire tarot — qui ouvre à son tour un système de figures (Valet/Chevalier/Reine/Roi) entièrement neuf. Deux bugs de scoring trouvés et corrigés en direct (empilement de modificateurs de cellule, détection de Suite en pic). Finit par un refactor architectural du pipeline de scoring (RunContext) pour nettoyer 3 patterns incohérents accumulés depuis la session 15.

---

## Courbe du score cible — figée

Le linéaire (`BASE_TARGET + TARGET_INCREMENT × manche`) devenait trivial dès qu'un build multiplicatif prenait (637/390 en session 17). Discussion complète sur une courbe exponentielle à accélération quadratique tardive (doublement tous les 4 manches + terme `ACCEL × (n-1)²`), calibrée en plusieurs passes avec le user (biome 3/4 jugés trop faibles au premier jet, boss finalement laissés **sans spike de cible** — le malus de boss doit porter la difficulté, pas la cible, pour ne pas punir deux fois).

Décision finale : **valeurs hardcodées** dans `GameRules.ROUND_TARGETS` (plus simple à retuner qu'une formule live), arrondies à 2 chiffres significatifs avec un grain minimum de 5. `ROUNDS_PER_ZONE` passe de 3 à 5 (4 manches + boss), soit **20 manches/run** au lieu de 12. `BASE_TARGET`/`TARGET_INCREMENT` supprimés.

## Biomes — noms placeholder + fond pastel

Plage → Forêt → Marais → Rêves, puis Vide pour le mode infini (remplace l'ancien "Cosmos"). `GameRules.BIOME_NAMES`/`BIOME_BACKGROUND_COLORS` (5 pastels), branchés dans `GameScene._update_zone_display` — le fond change à chaque nouvelle manche.

## Équilibrage réactif (plusieurs passes de playtest)

- **Mouches** : `FLIES_PER_ROUND_WON` 10→8, bonus fin de manche simplifié à un seul palier (+2 si >10 boutons restants)
- **Deck de départ** : `STARTER_COPIES_PER_VALUE` 2→1 (40→20+4) jugé trop généreux au premier test, puis **trop juste** au second (44→24 coups/manche, rocks passés de 9% à 17% du deck) — deuxième passe : copie additionnelle uniquement pour les valeurs basses (1-2), donnant **28+4 = 32**, avec les valeurs hautes (3-5) qui restent rares. `STARTER_LOW_VALUE_EXTRA_COPY_MAX` nouveau
- **Rainbow** : confirmé mathématiquement OP (4 familles → "tout différent" 6× plus probable que "tout pareil"). Line 4 Rainbow et Square Rainbow ×2→×1, Diamond Rainbow ×2.5→×2
- **Écume** : ciblait la row 0 fixe (la plus stable de la grille par construction de la gravité) → passe à une **rangée aléatoire par manche**, aligné sur Cellule Triple/Double/Colonne chanceuse
- **Petites Mains** : +0.5→+0.25 (renforcé sans le vouloir par le deck rebalancing ci-dessus)
- **Bouton unitaire au shop** : prix 3→5 (était le moins cher de tout le shop, achat par défaut trop facile)
- **Shop jackpot** : 1% de chance qu'un bouton acheté sorte direct à 10 (`SHOP_BUTTON_RARE_VALUE_CHANCE`) — pas de chemin d'achat direct vers une figure, volontairement écarté après discussion (casserait la règle "figure = uniquement par le score")

## Bug — softlock du hold multi-slots

Avec Bénédiction (2 slots de hold), enchaîner deux holds pendant que le deck se vide pouvait laisser `current` à null avec des jetons en hold inaccessibles — `do_hold()` refusait tout clic (y compris récupérer un jeton déjà en hold) dès que `current` était vide. Corrigé : le refus ne s'applique qu'à "stocker dans un slot vide" (rien à stocker sans `current`), pas à "récupérer depuis un slot plein".

## Bug — empilement de modificateurs de cellule

Une Partition entièrement posée dans une colonne boostée (Bord à Bord, Écume, Cellule Triple...) empilait le même coefficient une fois par cellule (`x1.5^5` sur une Line 5 au lieu de `x1.5`). `CascadeResolver._modifier_multiplier` (renommé `_grid_modifier_multiplier`) dédupliqué par **type** sur tout le groupe — toucher une case suffit à activer le multi, plusieurs cases du même type ne le cumulent plus. Les types différents sur des cases différentes restent cumulatifs entre eux.

## Bug — détection de Suite en "pic" de valeurs

Repéré par le user sur un vrai playtest (screenshot) : une colonne 2,3,4,3,rock,2 avec Suite équipée ne scorait pas. `PatternMatcher.find_lines` a une optimisation "dedup" qui saute une cellule de départ si son prédécesseur peut déjà l'étendre — valide pour Family/Value (égalité, pas de sens), **invalide pour Suite** qui peut changer de sens (un pic à 4 coupe la chaîne descendante 4→3→2, jamais redécouverte car la cellule de départ était sautée). Exclu la règle "suite" de cette optimisation ; les doublons résultants sont déjà gérés par la résolution en aval (sous-ensemble strict rejeté, chevauchement réel = Double Partition).

## Renommage complet des familles — vocabulaire tarot

`CORAL/SHELL/RUST/INK` → `BATONS/COUPES/EPEES/DENIERS` (arcanes mineurs), en remplacement définitif du projet Bone/Wood/Brass (session 10, jamais appliqué). Déclenché par une réflexion sur la lisibilité cognitive des familles, où le user a évité l'écueil "copie Balatro" (couleurs de cartes françaises) en proposant les couleurs latines/tarot à la place — bien plus cohérent avec le ton "monde halluciné" (mystique, pas casino-Vegas), et connecté à un fil déjà ouvert depuis la session 12 (idée d'"Effets Tarot" sur les boutons). Chaque famille garde sa correspondance élémentaire/saisonnière/astro traditionnelle (Bâtons/Feu/Printemps, Coupes/Eau/Été, Épées/Air/Automne, Deniers/Terre/Hiver) comme réservoir de sens pour la suite — volontairement gardé comme lexique à piocher, pas un nouveau système.

Portée du rename : enum `TokenData.Family`, sprites (`token_visual.gd`, nouveaux assets fournis par le user dans `assets/tokens/tarot/`, anciens sprites morts supprimés), 4 Badges par famille renommés en cohérence (Coraillée/Nacrée/Rouillée/Encrée → **Tickets Printanier/Estival/Automnal/Hivernal**), 4 outils Dés à coudre renommés (`change_batons/coupes/epees/deniers.tres`), doc GDD synchronisée.

Découverte annexe : "Rainbow un peu OP" (session, plus haut) et le vocabulaire `_format_tag_label` affichaient "VALUE" pour l'axe casino — renommé "CASINO" en cohérence avec le reste du vocabulaire poker (Brelan/Carré/Suite).

## Système de figures (arcanes mineurs) — nouveau

Discussion en plusieurs étapes (voir ci-dessous) aboutissant à : un jeton de base déjà à `MAX_BUTTON_VALUE` (10) qui **score** avance automatiquement d'un cran dans la suite **Valet(11) → Chevalier(12) → Reine(15) → Roi(20)**, plafond définitif. Affiché en jeu comme **J/C/Q/K**. Chemin exclusivement accessible par le score — Fusion/Augmenter/Poker Face restent plafonnés à 10, sinon une figure serait achetable sans jamais être jouée (décision explicite après discussion : casserait le partage shop=acquérir / jeu=faire grandir qui structure déjà le level up des Partitions).

Implémentation : `GameRules.FACE_CARD_VALUES/next_face_value`, `TokenData.value_label`, `RunManager.promote_matching_button` (chemin parallèle à `upgrade_matching_button`/Poker Face), `CascadeResolver._roll_face_promotions` (roll déterministe, fusionné avec le roll probabiliste de Poker Face). `decrease_button_value` refuse une figure (ne se perd pas via le shop).

**Action "Fixer" (Dés à coudre, rare)** : verrouille une figure contre toute promotion future, même si elle rescore — répond à la demande du user d'un levier de contrôle sur le *timing* de la progression (pas sur la nécessité de scorer, qu'il apprécie). Nouveau champ `TokenData.locked`, propagé explicitement pool→deck à chaque manche (`make_base` ne le porte pas par défaut).

### Discussion — tensions identifiées, non résolues

Plusieurs allers-retours ont fait émerger des tensions réelles, notées dans `questions-ouvertes.md` et `boutons.md#figures-arcanes-mineurs` :
- **Axe casino orphelin au-delà de Chevalier** : Reine/Roi n'ont aucun voisin à distance 1 (pas de Suite), Brelan demanderait 3 exemplaires de la même figure (quasi impossible). Seul l'axe famille reste ouvert. Piste retenue : un futur pattern **"Mariage"** (Roi+Reine assemblés, terme classique tarot/belote) comme débouché casino dédié aux figures — pas implémenté
- **Pas de population stable de figures** : toute figure qui score avance, jamais de "économie de Reines" à long terme — accepté comme cohérent avec l'esprit "voyage vers Roi", pas un défaut
- **Paradoxe valeur/difficulté** : stabiliser une Reine (Fixer + timing) coûte plus cher que laisser filer vers Roi, pour un jeton qui score pourtant moins (15 < 20) — résolu en pointant que Fixer n'a de sens qu'en vue d'un combo multi-jetons (Mariage), jamais en comparaison solo. **Fixer n'a donc aucun cas d'usage rationnel tant que Mariage n'existe pas** — pas un bug, mais un signal que Mariage n'est plus vraiment optionnel

Autres pistes évoquées et mises de côté pour plus tard, sans notes GDD dédiées (discussion orale uniquement) : bonus astro basé sur la date de naissance du joueur (easter egg de personnalisation, pas un levier de build), axe valeur étendu 1-10 + figures (Valet/Chevalier/Reine/Roi) façon vraies cartes à jouer, duo chaud/froid Bâtons+Deniers vs Coupes+Épées visible dans les sprites (couleurs) — potentiel pour un futur axe de Partition "Duo" ou Badge à synergie.

## Refactor — unification du pipeline de scoring (RunContext)

Question du user sur la lisibilité de la formule à 9 facteurs (`value_sum × shape_mult × cascade_mult × modifier_mult × rule_mult × level_mult × global_mult × value_bonus_mult × scaling_mult`) : clarifié que 5 des 9 sont des canaux Badge-conditionnels qui valent 1.0 (neutre) par défaut, pas des règles à apprendre d'emblée — mais l'audit a révélé 3 patterns différents pour "suivre les contributions d'un ou plusieurs Badges à un canal" :
- `rule_multipliers`/`global_multiplier` : écrasement pur (bug confirmé, connu depuis la session 15)
- `value_bonus_multipliers` : même bug, jamais repéré avant aujourd'hui
- `pair_score_bonus`/`top_row_score_bonus`/`family_score_bonus` : somme correcte mais attribution à une seule source (limite juste l'affichage, pas le score réel)

`RunContext` entièrement réécrit sur un seul pattern : chaque canal est un dictionnaire gardé par source (`Dictionary[badge_id]` ou `Dictionary[clé][badge_id]`), combiné par produit (multiplicateurs) ou somme (bonus plats) via des méthodes dédiées (`get_rule_multiplier`, `get_global_multiplier`, etc.). `CascadeResolver._mult_contributions` reconstruit l'attribution directement depuis ces dictionnaires. **Aucun des 37 Badges n'a eu besoin d'être modifié** — les signatures publiques de `RunManager` restent identiques, seul l'interne change. `_modifier_multiplier` renommé `_grid_modifier_multiplier` au passage (clarté du nom, demandée par le user).

## Statut

- Score cible et structure de run (20 manches) figés et implémentés
- Familles renommées de bout en bout, doc synchronisée
- Système de figures fonctionnel, playtesté avec succès (1 Roi + 1 Valet obtenus sur une run)
- Deux bugs de scoring réels corrigés (modificateurs de cellule, Suite en pic), un troisième bug historique (cumul de multiplicateurs) corrigé via le refactor RunContext
- **Prochaine priorité identifiée** : malus de boss (architecture actée — pool global aléatoire, contenu toujours à inventer, le user gère une nouvelle page Google Sheet dédiée) ; "Mariage" et contenu figure-spécifique en attente
