# Session 20 — Carrousel de démarrage, renommage Sheet, Partitions légendaires

**Date** : 2026-07-19
**Thème** : Session en trois temps. D'abord une série de petites features/fixes issus du playtest (carrousel de packs de démarrage, affichage du bonus mouches du Généreux, pondération des catégories du shop, consultation du deck hors-manche). Puis un renommage complet du vocabulaire "Pattern Tag"/"tag" en "Sheet" dans tout le code. Enfin un gros chantier de design + implémentation : la recherche du ressenti "jackpot" (envie d'ouvrir un pack même avec un bon build), aboutissant à un système de Partitions légendaires (Lost Corners, Royal Square, Last Trick), retravaillé plusieurs fois en cours de playtest.

---

## Carrousel de sélection du pack de démarrage

Écran remplacé : grille des 4 packs côte à côte → carrousel une carte à la fois avec flèches gauche/droite. Anticipe la dizaine de starters prévus à terme, chacun avec illustration + univers propre, plus un futur système de handicaps façon stakes Balatro — une grille ne tiendrait plus à l'écran et les cartes seront visuellement plus lourdes. Sélection = carte affichée, plus de clic de sélection séparé. `StarterPackSelectUI`/`starter_pack_select.tscn` réécrits.

## Bonus de mouches du pack de démarrage affiché à part

Le bonus permanent du Généreux (+mouches/manche) était fondu dans la ligne "BASE" de l'écran de fin de manche, invisible en tant que tel. Séparé en sa propre ligne bonus (`YouWinUI.show_reward` prend maintenant `starter_pack_name`/`starter_bonus` en plus). Point de vigilance noté (pas bloquant) : seulement 4 emplacements de ligne bonus (`BonusLabel1-4`) — pack + jetons restants + plusieurs badges à mouches simultanément pourrait déborder visuellement (le total resterait juste).

## Pondération des catégories du shop

Retour de playtest : les packs de Partitions revenaient trop souvent alors que déjà au niveau max, et les packs de jetons simples rendaient le deck trop facile (plus de coups). Remplace le shuffle uniforme (`ShopManager._regenerate_packs/_regenerate_unitaires`) par un tirage pondéré sans remise (`GameRules.CATEGORY_WEIGHTS`) : Partitions et Boutons à 0.5 (2x plus rares), Spéciaux à 2.0 (2x plus fréquents), Badges/Dés à coudre inchangés à 1.0. **Tranche la question ouverte "Pondération des catégories par progression du run" (session 19)** — piste Balatro (plus de rareté en début de run, courbe qui évolue) explicitement écartée après discussion : introduirait une supposition subjective du designer sur "ce que le joueur veut à ce stade", contrairement à l'ante-gating de Balatro qui est une règle objective et déterministe. Poids gardés fixes et identiques à tout moment de la run.

## Consultation du deck hors-manche

Le bouton DECK n'était actif que pendant une manche active (`DeckManager` recréé à chaque manche, n'existe pas pendant le shop). Ajouté : `RunManager.build_next_round_deck_preview()` construit un `DeckManager` jetable à partir de la composition possédée pour prévisualiser le contenu de la prochaine manche ; `DeckInspectorUI` retombe dessus quand aucune manche n'est active. Bouton actif en permanence dès qu'une run existe, y compris pendant l'ouverture d'un pack au shop.

## Renommage "Pattern Tag" / "tag" → "Sheet"

Demande du user : le vocabulaire interne ne collait plus au terme "Partition" et mélangeait "tag"/"pattern" de façon incohérente. Renommage complet, code en anglais :
- Classes : `PatternData`→`SheetData`, `PatternManager`→`SheetManager`, `PatternMatcher`→`SheetMatcher`, `TagsUI`→`SheetsUI`
- Fichiers renommés (`git mv`) : `pattern_data.gd`→`sheet_data.gd`, `pattern_manager.gd`→`sheet_manager.gd`, `pattern_matcher.gd`→`sheet_matcher.gd`, `tags_ui.gd`→`sheets_ui.gd`, `resources/patterns/`→`resources/sheets/` (21 fichiers)
- Signaux, méthodes, constantes, champs de données renommés en cohérence (`sheets_changed`, `equip_sheet`, `MAX_SHEET_SLOTS`, `SHEET_PATHS`, `sheet_name`...)
- Mots génériques ("pattern" = figure matchée, hors nom de la classe/du système) laissés tels quels dans les commentaires — hors périmètre de la demande

## Recherche du ressenti "jackpot"

Discussion longue partant d'un constat du user : les Partitions/Badges/Spéciaux n'ont pas encore ce qui donne envie d'ouvrir un pack même avec un build déjà solide (contrairement à Balatro et son espoir de Legendary Joker). Pistes explorées et écartées en cours de route :
- Formes exotiques (Entity/skulls, trous de grille, coins) — rendent le **déclenchement** rare plutôt que l'**acquisition**, l'inverse de ce qui crée le frisson jackpot. Deux idées jugées bonnes quand même et notées au Google Sheet par le user pour plus tard : **Danse des ombres** (ligne alternée scorable/Entity) et un pattern simple impliquant les Entity.
- États/effets appliqués sur des Partitions équipées (façon Écho générique) — jugé comme une couche de complexité en trop par le user lui-même, en repensant à sa tendance à sur-complexifier (référence citée : *Sol Cesto*, jeu indé à 2 devs, système volontairement minimal, 200k ventes).

Conclusion actée : un petit pool de **Partitions légendaires** à part, rares à l'acquisition, faciles à déclencher une fois obtenues, à l'effet marquant plutôt qu'un simple gros chiffre — sans empiler de nouvelle couche générique d'options.

## Partitions légendaires (implémenté)

Infrastructure : `SheetData.is_legendary` (flag simple, pas de champ rareté générique sur tout le catalogue — respecte la décision session 19 de ne pas gater le catalogue de base). Pool séparé (`ShopManager.LEGENDARY_SHEET_PATHS`), jamais dans le tirage uniforme normal — chaque slot Partition (unitaire ou candidat de pack) a une chance indépendante (`GameRules.LEGENDARY_SHEET_CHANCE`, 5%) de piocher dedans à la place. Flat : ne level up jamais (exclues de `RunManager._sheet_progress`). Effets codés en dur par `sheet_name` dans `CascadeResolver`/`SheetMatcher`, pas de système d'effets générique — même esprit que Diamond Rock déjà en place.

- **Lost Corners** — nouvelle forme `corners` (2 coins inférieurs de la grille, même famille). Multiplicateur = somme des jetons scorables de toute la ligne du bas (dynamique, pas un chiffre fixe). Retour de playtest : jugé très fort mais finalement pas si problématique une fois les vrais chiffres posés (cibles de manche 60→3000, meilleur cas ~4000, et rare à obtenir + configurer) — **laissé sans plafond**, décision actée après calcul avec le user. Le fait qu'un skull de l'Entity puisse se poser dans un coin et bloquer la Partition pour le reste de la manche est gardé tel quel : vraie contrepartie au côté OP, donne un usage aux Spéciaux (Bombe...) pour débloquer la situation plutôt qu'un bug à corriger.
- **Royal Square** — Carré famille classique (même shape+rule que Square Family existant), multiplicateur = roll direct 1-20 (`GameRules.ROYAL_SQUARE_ROLL_MIN/MAX`), animation roulette réutilisée (celle-ci lit maintenant la plage dynamiquement depuis le breakdown au lieu d'être câblée en dur sur la plage de Diamond Rock).
- **Last Trick** — Diamond famille classique. Le centre (jamais requis par le match) se transforme en jeton valeur 9 **ajouté définitivement au pool possédé** (`RunManager.add_button`, vrai moteur de deck-building, pas juste un effet de manche) — plafonné à 9 et non 10 (`MAX_BUTTON_VALUE`) pour ne pas court-circuiter gratuitement l'économie des Dés à coudre. Gating à 25% de chance par match (`LAST_TRICK_TRIGGER_CHANCE`) ajouté après retour de playtest — Diamond+famille se déclenche trop souvent pour un moteur permanent systématique. Bug corrigé en cours de route : la famille du jeton transformé était prise sur le centre lui-même, qui vaut toujours `Family.BATONS` par défaut pour tout ce qui n'est pas `Kind.BASE` (Rock/Entity/Special/Résidu) — corrigé pour la prendre sur un des 4 bras, déjà garantis de la même famille par la règle elle-même.

Deux bugs transverses trouvés et corrigés en playtest :
- Quand une légendaire partage exactement le même shape+rule qu'une Partition de base déjà équipée (ex: Royal Square et Square Family, toutes deux carré+famille), seule la première dans l'ordre des slots équipés captait le match — les légendaires sont maintenant toujours prioritaires (`SheetMatcher.find_all`), peu importe l'ordre d'équipement.
- `SheetsUI` affichait un niveau/une progression même pour les légendaires (qui ne level up jamais) — corrigé, affiche "Légendaire — flat" à la place.

Ajouté au passage : `SheetData.debug_start_equipped` (même principe que `BadgeData`), pour équiper une Partition au démarrage d'une run sans attendre son tirage au shop.

## Notes diverses

- **Réordonner les Partitions équipées** — même souci déjà identifié pour les Badges ([Questions ouvertes](../gdd/meta/questions-ouvertes.md)), étendu aux Partitions cette session (l'ordre détermine qui capte un match en cas de shape+rule partagé, ex: Line 3 vs Line 4). Jugé accessoire pour l'instant par le user, pas construit.
