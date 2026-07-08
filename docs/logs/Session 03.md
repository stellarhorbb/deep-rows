# Session 03 — Stream, Rocks, Specials & Iteration au Proto

**Date** : 2026-04-10
**Theme** : Remise en question de la pioche, ajout des rocks, geometrie des patterns, et iterations rapides au proto HTML

---

## Decisions de design verrouillees

### Pioche : stream + hold (au lieu de main de jetons)
- Les jetons arrivent **un par un** depuis le deck (stream avec preview de 2-3)
- **1 slot de hold** unique : peut accueillir n'importe quel jeton (basique ou special)
- Slot upgradable via Echo (+1 supplementaire)
- Raison : une "main" ne filtrait rien (tout part sur la grille de toute facon), elle ne faisait qu'ordonner. Le stream colle a l'ADN cascade et le hold preserve un levier tactique.

### Rocks dans le deck de base
- 6 jetons "rock" sans famille ni valeur, qui ne scorent pas et **restent permanents** sur la grille
- Apportent du relief, du puzzle de placement, et un terrain dedie pour les Echoes
- La facon de les retirer (collateral ? rock pattern ? Echo specifique ?) est laissee en question ouverte
- Valides au proto comme creant une vraie texture sans clogger trop vite

### Patterns : lignes droites + carres 2x2 uniquement
- **Lignes droites de 3+** (horizontale, verticale, diagonale)
- **Carres 2x2 plein**
- Pas de L, T, zigzag (contrairement a ce qu'on avait dit en 03-patterns avant)
- Raison : le user a teste au proto et a senti que la regle "chaine connectee" rendait tout trop facile et illisible. Les lignes + 2x2 forcent une vraie geometrie.

---

## Iterations au proto HTML

Le proto a ete refondu integralement pour coller au nouveau design, puis itere plusieurs fois pour trouver le bon feeling.

### Refonte complete
- Stream + hold (touche **H** ou clic sur le slot)
- Rocks dans le deck (rendu carre gris, pas de chiffre)
- Pattern detection reecrite : `findLines()` (4 axes) + `findSquares()` (2x2)
- Multiplicateurs : 3=x1, 4=x2, 5=x3, 6+=x5 pour les lignes ; carre 2x2 = x3 fixe

### Ajout des jetons speciaux (du catalogue 02-jetons)
- **Fantome ×2** : push colonne vers le haut, top detruit si pleine, residue au row 0 (anchor non-scorable, visuellement distinct du rock)
- **Bombe ×3** : explose 3x3 autour du point d'atterissage, score = somme des bases × 2
- **Marée ×1** : vague qui ecarte la ligne autour du clic (gauche shift gauche, droite shift droite, cellule cliquee preservee, 2 trous crees)
- Hover preview contextuel selon le type de current

### Iteration sur les dimensions de grille
- 7×6 (initial) → 9×8 → **6×8** (final)
- L'intuition du user etait juste : grille trop large = pression de placement faible (on peut "parker" sur les bords)
- Cell size : 70 → 64 → 80 → **60** (ajuste pour eviter le scroll)
- Deck final : 50 base + 8 rocks + 6 specials = **64 jetons**
- Cible base : 100

### Bug fix
- La cascade ne tournait que si elle detectait des patterns. Une Bombe/Marée qui creait des trous sans former de pattern direct laissait des jetons flottants.
- Fix : passe de gravite initiale en debut de `resolveAll`, avec skip du delai si rien n'a bouge (`applyGravity` retourne maintenant un bool)

---

## Decouverte : l'espace de design est immense

Le user a brainstorme spontanement une bibliotheque de **triggers d'Echoes** (etat de grille, position, drop, resolution, compteurs, negatifs) et a observe que Deep Rows offre **bien plus de possibilites** que les deux iterations precedentes (Salt House, Bag Battler).

C'est structurel : le pivot puzzle-drop ajoute 4 ingredients multiplicatifs par rapport aux jeux precedents :
1. **Dimension spatiale** (chaque case est une variable, chaque adjacence une relation)
2. **Persistance** (l'etat s'accumule, decisions compounding)
3. **Geometrie** (lignes/diagonales/carres = leviers strategiques empilables)
4. **Cascades** (complexite emergente, ce qui fait Tetris/Puyo/Bejeweled)

Sauvegarde dans la memoire long-terme du projet pour proteger ces 4 ingredients dans les futures sessions.

---

## Fichiers crees / modifies

### GDD
- `02-jetons.md` — section "Rocks — le scaffold" ajoutee
- `03-patterns.md` — regles de base reecrites (lignes + carres 2x2)
- `04-manche.md` — deroulement reecrit (stream + hold)
- `05-echoes.md` — exemples mis a jour pour refleter le hold et le stream
- `07-entity.md` — perturbation "Main reduite" remplacee par "Hold verrouille"
- `00-index.md` — description chapitre 04 mise a jour
- `10-questions.md` — question taille de main retiree, decisions verrouillees ajoutees, question rocks ajoutee
- `brainstorm-echoes.md` (**nouveau**) — bac a sable pour les triggers et effets d'Echoes

### CLAUDE.md
- 3 nouvelles decisions verrouillees ajoutees : stream/hold, rocks, lignes/2x2

### Proto
- `proto/index.html` — refonte complete + iterations (premier ajout au repo Git)

---

## Questions ouvertes (a tester / trancher plus tard)

- Faut-il un moyen de retirer les rocks (collateral cascade ? rock pattern ? Echo dedie ?)
- Taille de la preview du stream : 2 ou 3 ?
- Est-ce que 6 colonnes est le bon equilibre ou faut descendre a 5 ?
- L'overlap entre rocks (deck) et "jetons parasites" (perturbation Entity) : differencier ou fusionner ?
- Multiplicateur Bombe (actuellement x2) : trop fort, trop faible ?
- 6 specials sur 64 jetons (~9% du deck) : bonne frequence ?

---

## Prochaines etapes

1. **Phase 1 Godot** (toujours en attente) : Resource scripts (`TokenData`, `PatternData`, `GridData`, `PackData`, `EchoData`, `TokenStateData`) + `game_rules.gd`
2. Continuer a iterer le proto si on veut tester d'autres mecaniques avant Godot (ex : un premier Echo cable en dur, une regle de retrait des rocks, le Dernier Souffle)
