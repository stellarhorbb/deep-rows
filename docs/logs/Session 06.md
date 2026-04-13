# Session 06 — Juice proto

**Date** : 2026-04-13
**Theme** : Ajout de juice visuel au proto Godot pour rendre le gameplay plus dynamique

---

## Contexte

Le proto Godot est jouable depuis la session 05. Objectif de cette session : ajouter du juice (feedback visuel) pour que chaque action du joueur ait un retour satisfaisant. Pas de nouvelles mecaniques, que du polish de sensation.

---

## Features implementees

### Hover preview
Fantome semi-transparent (35% opacite) du jeton courant qui suit la colonne survolee et se positionne a la landing row. Gere le cas special du Ghost qui atterrit en row 0. Se clear automatiquement pendant les animations, au clic, et hors de la grille.

### Pattern label de resolution
Label punchy qui pop au centre du groupe resolu avec le nom du pattern : "FAMILY LINE x3", "NUMBER SQUARE", "FAMILY LINE x4", etc. Fade in rapide, monte de 40px, puis fade out. Affiche en bleu fonce (#3d3d5c) pour etre lisible sur le fond clair.

### Cascade shake (grille)
Tremblement de la grille entiere au moment de chaque match. Intensite de 5px (resolution simple) a 5+3n px (cascades). Sequence de 4 micro-tweens qui s'attenuent.

### Flash blanc au match
Les jetons matches flashent en blanc surexpose (modulate 3x) pendant ~2 frames avant le shake. Donne un effet d'impact au moment de la connexion.

### Shake des jetons matches
Remplacement du pulse (scale 1.15) par un shake lateral rapide sur les jetons matches : 3 oscillations qui s'attenuent (4px → 2.4px → 1.4px) puis retour.

### Double bounce au drop
Le bounce d'atterrissage passe de 1 rebond (4px) a 2 rebonds (12px puis 4px). Sensation de jeton solide qui claque sur la surface.

### Bounce post-gravite
Les jetons qui retombent apres une resolution font un rebond de 6px a l'atterrissage. Meme sensation que le drop initial, en plus leger.

### Score counter anime
Le label de score roule vers la nouvelle valeur en 0.4s (ease out cubic) au lieu de sauter. Suivi d'un scale bump 1.12x centre (pivot_offset) qui se resorbe en 0.15s.

---

## Fichiers modifies

- `scripts/ui/grid_visual.gd` — hover preview, shake grille, flash blanc, shake jetons, pattern labels, bounce gravite, build_pattern_text
- `scripts/ui/input_handler.gd` — tracking InputEventMouseMotion, _handle_hover()
- `scripts/core/game_scene.gd` — score counter anime (_animate_score_to), clear hover sur resolution

---

## Observations de design

- Thomas note que les 4 familles (Coral, Shell, Ink, Rust) forment deux axes exploitables : chaud/froid et clair/fonce. Paires naturelles pour des mecaniques futures (patterns "opposes", effets visuels par temperature de couleur).
- Le squash & stretch a ete ecarte volontairement : les jetons sont des objets rigides, pas des blobs maleables. Le bounce et le shake sont plus coherents avec l'identite visuelle.

---

## Prochaines etapes

Le proto a maintenant un bon niveau de juice pour valider le gameplay. Priorites possibles :
1. Pattern Tags comme vrai systeme (slots, .tres, resolution conditionnelle visible)
2. Flow de manche complet (deck → jouer → score cible → transition)
3. Shop entre les manches
4. Juice supplementaire si besoin (particules a la disparition, son, stream slide-in)
