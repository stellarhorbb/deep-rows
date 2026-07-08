# Session 01 — Naissance de Deep Rows

**Date** : 2026-04-09
**Theme** : Mise en place du projet, GDD complet, proto HTML, conventions

---

## Contexte

Deep Rows nait du pivot de Salt House (Session 24-25). Apres avoir explore et ecarte le Blackjack, Tide, et une douzaine d'autres pistes, le concept de grille verticale avec cascades s'est impose en une session de brainstorm.

Le proto HTML (`proto/index.html`) a valide le geste de base : drop + cascade = fun.

## Ce qui a ete fait

### GDD complet en 10 chapitres
- `docs/gdd/00-index.md` → pitch et sommaire
- `docs/gdd/01-grille.md` → terrain, gravite, cascades, choix de grille
- `docs/gdd/02-jetons.md` → base, speciaux, etats, catalogue
- `docs/gdd/03-patterns.md` → scoring, axes de match, level up par score cumule
- `docs/gdd/04-manche.md` → deck, deroulement, Dernier Souffle
- `docs/gdd/05-echoes.md` → passifs, synergies, exemples
- `docs/gdd/06-shop.md` → economie Salt, choix, reroll
- `docs/gdd/07-entity.md` → perturbations, escalade
- `docs/gdd/08-progression.md` → scaling, structure de run
- `docs/gdd/09-shore.md` → meta-progression, unlocks
- `docs/gdd/10-questions.md` → ouvertes + decisions tranchees

### Conventions et architecture
- `docs/project-conventions.md` — conventions Godot completes, adaptees au nouveau projet
- Architecture proposee : Managers, Systems (logique pure), Data (Resources), separation logique/visuel
- Resolution : 1920x1080

### CLAUDE.md
- Instructions pour les futures sessions Claude

### Projet Godot
- `project.godot` cree (vide)

## Decisions cles de cette session

Toutes documentees dans `docs/gdd/10-questions.md` section "Decisions tranchees".

## Prochaines etapes

1. **Phase 1** : poser les Resource scripts (TokenData, PatternData, GridData, PackData, EchoData, TokenStateData) + game_rules.gd
2. **Phase 2** : moteur logique (GridManager, PatternMatcher, CascadeResolver) testable sans visuel
3. **Phase 3** : minimum jouable (grille visuelle, main, drop, score)
4. **Phase 4** : boucle de run (manches, score cible, game over, Dernier Souffle)
5. **Phase 5** : shop + Echoes

---

**Pas de code Godot touche. Session 100% setup + design.**
