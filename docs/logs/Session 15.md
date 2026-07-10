# Session 15 — Balancing post-playtest, Double Partition, refonte Diamond Rock

**Date** : 2026-07-10
**Thème** : Le user a joué plusieurs parties entre deux sessions et est revenu avec une liste de notes balancing/bugs, puis deux nouvelles mécaniques nées de la discussion (Double Partition, roll casino sur Diamond Rock).

---

## Balancing (notes de playtest)

- **Pourboire** : +5 → +3 mouches (`effect_pourboire.gd`, `badge_pourboire.tres`)
- **Vertige** : +8 → +5 mouches sur cascade. Au passage, le commentaire du script disait "niveau 2+" alors que le code checkait bien niveau 1+ (une vraie cascade, pas juste le match initial) — c'est le commentaire qui était faux, corrigé, le code ne bougeait pas
- **Diamond Rainbow** : ×3.5 → ×2.0, aligné sur Square Rainbow (déjà nerfé pour la même raison en session 14 : plafonné à 4 familles, trop facile). Prix/rareté baissés en cohérence (14/RARE → 12/UNCOMMON) pour ne pas devenir un piège plus cher que Square Rainbow pour la même force. Reste en dessous de Diamond Family (×2.5) comme demandé
- **Seuils de level up des Partitions** : `[150, 400, 800, 1500]` → `[150, 500, 1100, 2200]` — le niveau 2 reste rapide, les niveaux 3-5 repoussés pour éviter d'atteindre "Forte" dès la manche 6
- **Trop de modificateurs colonnes (4 badges = grille trop forte)** : décision du user de ne rien toucher pour l'instant, réévaluer après les autres nerfs

## Grid modifiers : stacking multiplicatif

Root cause commune à deux signalements du user (Cellule Triple qui disparaît, Tranchée+Bord à Bord qui ne se calculent pas ensemble) : `_grid_modifiers` était un dict `case → un seul type`, le dernier badge appliqué écrasait le précédent.

Changé en `case → Array[StringName]`, tous les types empilés multiplient le score (`CascadeResolver._modifier_multiplier`), le rendu dessine des anneaux concentriques au lieu d'un seul contour (`GridVisual._draw`). Résout les deux problèmes avec un seul système cohérent : Tranchée+Bord à Bord sur une colonne extérieure donne bien ×0.5×1.5, et Cellule Triple ne se fait plus jamais écraser.

## Bugs de shop

- **Fusion au-delà de 10** : le clamp `min(somme, MAX_BUTTON_VALUE)` existait déjà côté backend (session 12) mais sans retour visuel. Ajout d'une désactivation des candidats de fusion dont la somme dépasserait 10, dès qu'un premier bouton est sélectionné (`ShopUI._update_fusion_candidate_availability`)
- **Badge choisi via pack même slots pleins** : l'achat unitaire vérifiait déjà `can_purchase` (bouton grisé), mais le choix dans un pack (`ShopManager.choose_from_pack`) n'a jamais vérifié les slots — `equip_badge()` échouait silencieusement en interne sans que rien dans la chaîne UI ne relaie l'échec. Fix : nouveau `ShopManager.can_equip_slot` partagé, `PackPanelUI.open_with` grise maintenant les candidats sans slot dispo, `choose_from_pack` revalide en filet de sécurité (`purchase_failed` émis si jamais)

## Diamond : le centre ne doit pas toujours disparaître

Bug signalé par le user : former un Diamond (Family/Rainbow, pas Rock) effaçait aussi le jeton central alors qu'il n'entre jamais dans le match ni dans le score pour ces règles. `CascadeResolver.resolve` ajoutait le centre à `cells_to_remove` pour **toute** forme à centre indifférent (diamond, ring), peu importe la rule. Fix : seul `rule == "rock"` retire le centre désormais — Family/Rainbow (et Ring) laissent le centre en place, il tombe normalement à la gravité qui suit.

## Double Partition (nouvelle mécanique)

Discussion partie d'un cas concret du user (Square Rainbow + Brelan qui se chevauchent sur 2 cellules) : l'ancienne règle `PATTERN_SHARED_CELL_TOLERANCE` (1 cellule commune = combo, au-delà = seule la mieux payée compte, posée en session 13) écrasait ce vrai combo puisqu'il partageait 2 cellules. Remplacée par un critère structurel :

- **Inclusion totale** d'un groupe dans l'autre (mêmes jetons, ex T dans Plus) → seule la mieux payée compte, comme avant
- **Chevauchement partiel** (≥1 cellule commune, aucune inclusion totale) → **Double Partition** : les deux scorent, total combiné ×`GameRules.PATTERN_COMBO_MULTIPLIER` (2.0), bannière dédiée "DOUBLE PARTITION ×2 !" (`ResolutionBanner.play_combo_announcement`) jouée après le détail des deux groupes

`PATTERN_SHARED_CELL_TOLERANCE` supprimé (plus aucune référence). Bug trouvé en playtest juste après : la bannière restait bloquée à l'écran — `play_cascade_announcement`/`play_combo_announcement` ne repassaient jamais `visible = false` (ça passait inaperçu avant parce que la cascade était toujours suivie du détail des groupes qui s'en chargeait ; Double Partition est maintenant potentiellement le dernier appel de la séquence). Corrigé sur les deux fonctions.

## Symbole × remplacé par x

La police du jeu ne supporte pas `×`. Remplacé partout où il traînait : `resolution_banner.gd`, commentaires de `grid_visual.gd`, description de 7 Badges en `.tres`.

## Spéciaux : persistance jusqu'à l'utilisation réelle

Bug rapporté par le user : un Marée acheté et mis en hold sans être joué disparaissait à la manche suivante. Diagnostic : `_deck_composition` (compteurs de spéciaux) était remis à zéro à *chaque manche gagnée*, "qu'ils aient été joués ou non" — c'était littéralement dans le commentaire du code (feature "one-shot" posée en session 13, écrite noir sur blanc dans `decisions-tranchees.md`).

Fix : les spéciaux se comportent maintenant comme les boutons/Partitions/Badges — un bien persistant. `RunManager.consume_special` décrémente uniquement au moment où le spécial est réellement joué (`TurnController.play_current_to`), plus rien ne touche le compteur en fin de manche. `reset_specials_counts` renommé `apply_debug_specials` (ne fait plus que réappliquer les specials `debug_always_in_deck`).

Découverte annexe en creusant : Bombe et Fantôme avaient `debug_always_in_deck = true` resté actif dans les ressources — un outil de test oublié en prod, qui les rendait gratuits chaque manche (probablement pourquoi le user n'a remarqué le bug que sur Marée, seul spécial sans ce flag). Désactivé sur les deux.

GDD mis à jour (`specials.md`, `deck.md`, `decisions-tranchees.md`) pour refléter le nouveau principe — c'était une vraie décision documentée qu'on renverse, pas juste un bugfix silencieux.

## Refonte Diamond Rock

Trois allers-retours de discussion pour arriver à la bonne mécanique (voir transcript pour le détail du raisonnement — plusieurs corrections successives du user sur mes suppositions, notamment sur la gravité qui garantit que le centre est forcément déjà occupé dès que les 4 rocks sont en place, et sur le fait que les rocks se régénèrent à chaque manche, pas une fois pour toute la run).

**Score** : le user trouvait le score misérable (juste la valeur du centre 1-5, ×4) vu la difficulté du coup. Ajout d'un **roll casino entre 1 et 5** additionné à la valeur du centre avant application du multiplicateur (`GameRules.DIAMOND_ROCK_ROLL_MIN/MAX`), avec une animation de roulette dédiée qui ralentit avant de s'arrêter sur le résultat déjà calculé par le resolver (`ResolutionBanner.play_roll_announcement`, branché dans `GridVisual._animate_match` via `breakdown.has("roll")`). Premier essai d'une mécanique de roll sur le scoring, volontairement scopé à ce seul pattern.

**Centre non scorable (Entity, Rock, trou)** : bug trouvé par le user en jouant — `PatternMatcher.find_diamonds` ne vérifiait jamais ce qu'il y avait au centre avant de générer un candidat `rule=rock`, donc une Entity au centre déclenchait quand même le match, supprimant les 4 Rocks et le centre pour 0 point, sans aucun retour visuel. Fix : le candidat n'est généré que si le centre est scorable.

**Les 4 Rocks ne disparaissent plus** : correction du non-sens le plus important de la session — seul le jeton central doit être consommé/scoré, les 4 Rocks doivent rester en jeu (relief de grille, terrain de Badges, et surtout disponibles pour exploser au Dernier Souffle en fin de manche). Le code d'origine retirait pourtant les 4 cellules du losange comme toutes les autres formes. Fix dans `CascadeResolver.resolve` : les cellules d'un groupe `shape=diamond, rule=rock` ne sont jamais ajoutées à `cells_to_remove`, seul le centre l'est.

Chaque étape vérifiée par un test headless jetable (non versionné) : bornes du roll, cohérence score/breakdown, centre Entity/trou/Rock → aucun match, régression Diamond Family toujours intacte, identité d'objet des 4 Rocks confirmée après resolve.

## Outil debug : refresh sur la sélection de Partition de départ

Le user devait quitter/relancer pour retirer 3 Partitions de départ tant que Diamond Rock n'apparaissait pas dans le tirage. Ajout d'un bouton "REFRESH (DEBUG)" sur `PartitionSelectUI` qui retire un nouveau tirage sans relancer — marqué explicitement temporaire dans le code, à retirer une fois le besoin de test passé.

## Observation notée pour plus tard

Playtest avec le bouton refresh : réussir un Diamond Rock arrive généralement quand la grille est déjà très remplie (mécaniquement lié à la difficulté du placement), donc même un bon score "tombe à plat" en fin de manche. Direction évoquée par le user : viser beaucoup plus haut, un vrai coup rare et unique qui devrait quasiment suffire à faire passer la manche à lui seul — mais le score cible grimpe avec la manche (~100 en manche 1, ~430 en manche 12), donc il faudra un vrai mécanisme de scaling plutôt qu'une grosse constante fixe. Noté dans `questions-ouvertes.md`, à trancher avec la courbe du score cible elle-même.

## Points techniques à garder en tête

- Tous les tests de cette session étaient des scripts headless jetables dans le scratchpad, non versionnés
- Limite confirmée à nouveau : impossible de tester headless un script qui référence l'autoload `RunService` (compile error hors du flux `--editor` normal) — contourné en testant la logique pure (`RunManager`, `CascadeResolver`, `PatternMatcher`) directement, jamais les scripts UI/Scene qui touchent l'autoload
- Plusieurs `.tres` de Badges ont vu leurs UID Godot se faire injecter automatiquement (`uid://...`) pendant les runs headless de cette session, avec des champs égaux à leur valeur par défaut silencieusement omis à la resauvegarde (`price`, `rarity`, `trigger`) — vérifié un par un via diff contre HEAD, aucune vraie perte de donnée (les valeurs par défaut du script correspondent exactement à ce qui était écrit), mais bon réflexe à refaire si ça se reproduit

## Prochaine étape

Le user continue à jouer. Score de Diamond Rock à recalibrer avec la courbe du score cible (voir Questions ouvertes). Généralisation éventuelle du roll casino à d'autres Partitions rares (Ring, Cross ?) à revoir si l'essai est concluant.
