# Session 08 — Anti-exploit, Entity, 3 familles, modificateurs de cellules, nettoyage resources

**Date** : 2026-04-17
**Theme** : Corriger la faille du stacking vertical + ajout de profondeur de run + nettoyage structure resources

---

## Contexte

Le proto est jouable, la mecanique de base tient. En jouant, une faille emergente est identifiee : empiler les memes jetons en colonne permet d'atteindre le score cible trop facilement (lines verticales infinies). Il faut corriger ca sans casser la lisibilite du jeu.

---

## Decisions de design

### Multiplicateurs directionnels sur les lignes
Les lignes ne sont pas egales : la direction change leur valeur. Recompense l'horizontale et la diagonale, penalise le stacking vertical pur.

| Direction | Multiplicateur |
|---|---|
| Verticale | x1 |
| Horizontale | x1.5 |
| Diagonale | x2 |

Chemin explore et abandonne : les Pattern Tags eux-memes etaient d'abord restreints par direction (ex: un tag "Ligne Horizontale" qui ne matchait que l'horizontal). Trop contre-intuitif au jeu — le cerveau cherche les combos dans tous les sens. Solution retenue : tags libres de direction, multiplier applique au moment du match.

Les formes non-lineaires (carre, losange, suite) gardent leur multiplicateur fixe dans leur `.tres`.

### L'Entity — jeton obstacle
L'Entity place un jeton-skull dans une colonne aleatoire non pleine, tous les 6 tours joueur. Le jeton reste sur la grille, ne participe a aucun pattern, survit au Dernier Souffle. Perturbation previsible (pas de RNG punitif), efficace pour briser le stacking de colonnes.

### 3 familles (INK supprimee)
4 familles = trop de dispersion sur la grille, moins lisible. INK (la plus sombre) supprimee. Familles retenues : Coral, Shell, Rust.

### Dernier Souffle elargi
Le Dernier Souffle se declenche desormais meme sans jetons speciaux : les Rocks explosent egalement lors de la phase finale. Chaque run se termine par une resolution spectaculaire, pas un ecran vide si le joueur n'a pas achete de speciaux.

### Modificateurs de cellules — architecture multi-vecteurs
Idee : la grille elle-meme evolue pendant le run. Des cellules peuvent etre DOUBLE, TRIPLE, HALF, TRAP, VOID etc. Plusieurs vecteurs d'injection (aucun ne doit etre la seule source) :
- **Shop** — acheter un mod, le placer librement
- **Pool de zone** — a chaque fin de zone, choisir 1 mod parmi 2-3 proposes
- **Echoes** — passifs qui generent des mods recurrents
- **Speciaux** — effets secondaires qui laissent un mod sur la grille
- **Layout de zone** — certaines zones demarrent avec des mods pre-places

Architecture technique : `GridModifiers: Dictionary` (Vector2i → modificateur) dans RunManager, passe via RunContext, lu par CascadeResolver. Couche separee des tokens. Design valide, implementation future.

---

## Nouveaux Pattern Tags

4 nouveaux tags ajoutes au catalogue du shop :

| Tag | Forme | Multiplicateur |
|---|---|---|
| Line Family 3 Diagonal | Ligne 3 diag, meme famille | x1.5 |
| Line Number 4 Horizontal | Ligne 4 horiz, meme chiffre | x1.5 |
| Square Number | Carre 2x2, meme chiffre | x2.5 |
| Suite 3 Diagonal | Suite 3 consecutifs en diag | x2.0 |

---

## Systemes implementes

- **EntityManager** — compte les tours, retourne une colonne de drop tous les N tours
- **ShopManager** — catalogue hardcode, logique d'achat (can_purchase, purchase)
- **RunManager + RunContext** — source de verite du run (flies, tags equipes, speciaux)
- **RunService + SceneRouter** — gestion des transitions manche → shop → manche
- Direction multipliers dans `GameRules.get_direction_multiplier()`
- `PatternData` enrichi : `direction: StringName`, `score_multiplier: float`
- `CascadeResolver._score_group` : branch lines (direction mult) vs shapes (tag mult)

---

## GDD mis a jour

Tous les 10 chapitres relus et mis a jour :
- **02** : 3 familles, 4 rocks, token Entity, rocks explosent au Dernier Souffle, etats deprioritises
- **03** : systeme de scoring reecrit (direction pour les lignes, tag mult pour les formes)
- **04** : Dernier Souffle reecrit, comptage deck mis a jour
- **05** : 5 slots max confirme, Salt → Mouches, exemples corriges
- **06** : Salt → Mouches partout, etats retires des prix, modificateurs de cellules ajoutes
- **07** : comportement Entity implemente documente
- **08** : modificateurs de cellules comme 7e vecteur de scaling
- **10** : questions repondues integrees dans la table des decisions

---

## Nettoyage resources

Les ShopItem wrappers pour les tags etaient redondants (un `.tres` wrapper par pattern juste pour porter label + prix). Simplifie :

- `PatternData` porte desormais `label` et `price` directement
- `ShopItem` ne sert plus que pour les speciaux (pas de PatternData associe)
- `resources/shop/tags/` supprime (6 fichiers wrappers)
- `resources/shop/specials/` → `resources/specials/`
- `ShopManager` charge les tags depuis `resources/patterns/`, les speciaux depuis `resources/specials/`

Structure finale :
```
resources/
  patterns/    → 8 PatternData (avec label + price)
  specials/    → 2 ShopItem
```

---

## Fichiers modifies

Scripts : `game_rules.gd`, `game_scene.gd`, `pattern_data.gd`, `token_data.gd`, `pattern_matcher.gd`, `cascade_resolver.gd`, `grid_manager.gd`, `grid_visual.gd`, `tags_ui.gd`, `token_visual.gd`, `shop_manager.gd`, `shop_ui.gd`

Nouveaux scripts : `entity_manager.gd`, `run_manager.gd`, `run_context.gd`, `run_service.gd`, `scene_router.gd`, `shop_item.gd`

---

---

## Session du soir — end screen + modificateurs de cellules MVP

### Ecran de fin de run
Les fins de run (victoire / game over) basculaient sur un message inline + espace pour restart. Remplace par une vraie scene dediee.

- `RunService` porte `last_score` / `last_target` pour alimenter l'ecran
- `SceneRouter.go_to_end_screen()` + `scenes/end/end_screen.tscn` + `end_screen_ui.gd`
- Variante VICTOIRE / GAME OVER selon `RunService.game_flow`, bouton "Nouveau run"
- Handler espace/entree inline supprime dans `game_scene`

### Timing de transition
Les transitions entre fin de manche et ecran suivant etaient instantanees — pas le temps d'integrer le dernier coup. Ajout de `GameRules.ROUND_END_DELAY = 2.0` applique aux 3 sorties de manche : shop, victoire, defaite.

### Modificateurs de cellules — MVP
Premiere passe de la couche discutee en debut de session. Scope minimal :

- 1 seul type pour l'instant : **DOUBLE** (x2 sur le total du pattern, par cellule modifiee dans le groupe — si deux cellules modifiees dans un meme pattern, x4)
- Source unique : **1 cellule aleatoire a chaque debut de manche**. Pas de persistance run. Reset automatique au tirage suivant.
- Architecture : `grid_modifiers: Dictionary` (Vector2i → StringName) dans `RunContext`, stocke et tire par `RunManager` via `roll_round_modifiers()`, lu par `CascadeResolver._score_group`
- Feedback visuel : contour bleu fonce autour de la cellule dans `GridVisual._draw()`

Sources futures pour generer des modifiers (pas implementees) : echo passif, grille speciale, entity, shop, layout de zone.

---

## Prochaine etape

Le build tourne, la progression de run tient (4 zones x 3 manches x shop entre chaque), les ecrans de fin sont propres, les modificateurs posent leur premiere couche. La DA reste volontairement brute — on priorise la validation du fun mecanique avant toute passe visuelle. Prochains ajouts de profondeur : nouveaux types de modifiers (HALF, TRAP, VOID), sources d'injection variees (shop, echoes), et les Echoes eux-memes.
