# Session 10 — Refonte GDD modulaire + specials one-shot

**Date** : 2026-04-20
**Theme** : Restructuration du GDD en fichiers modulaires par concept + refactor des specials en one-shot avec toggle debug

---

## Contexte

Deux chantiers distincts :

1. **GDD devenait difficile a naviguer** : 10 chapitres gros, mélange de concepts, difficile de retrouver une info. Passage a une structure modulaire — un fichier par concept, regroupe en dossiers thematiques.
2. **Ecart entre implementation et design** : les specials etaient permanents dans le code mais le design (HOB-13) les voulait one-shot. Refactor minimal pour corriger ca, avec un toggle debug au passage.

---

## GDD — refonte modulaire (pas commitee, docs/ gitignored)

### Nouvelle arborescence

10 chapitres → **45 fichiers modulaires** regroupes en 10 dossiers thematiques :

```
docs/gdd/
  00-index.md                    carte de navigation
  univers/                       pitch, ton, DA, personnages (garçon, entity, grenouilles)
  grille/                        format, gravite, modifiers
  jetons/                        boutons, rocks, specials, entity-skull, etats-reserve
  partitions/                    principe, formes, axes, scoring, level-up, catalogue
  manche/                        deck, stream-hold, deroulement, score-cible, dernier-souffle
  echoes/                        principe, triggers, cartes, rarete, feedback-visuel
  shop/                          offre-mixte, packs, reroll, economie, generation
  progression/                   structure-run, sources-scaling, monnaies, defaite
  shore/                         principe, unlocks, boucle-narrative
  meta/                          questions-ouvertes, decisions-tranchees
```

**Règle** : un fichier = un concept qui tient en 1-2 minutes de lecture. Backlinks partout (markdown standard) pour connecter les concepts transversaux.

### Decisions actees pendant la refonte

- **3 familles = Bone / Wood / Brass** (IDs code `FAMILY_BONE/WOOD/BRASS`) — matieres de boutons historiques, thematique "tailleur ancien"
- **Spéciaux = jetons du deck** (pas items consommables) — garde l'ADN puzzle-drop "tout tombe". Le hold slot porte la tension du timing tactique.
- **Vocabulaire thématique** partout : Partitions (ex-Pattern Tags), Cartes d'Echoes (ex-Echoes), Boutons (ex-jetons de base). "The Shore" conserve comme placeholder.

### Autres livrables

- **`docs/simple-concept.md`** — pitch Discord-style du jeu, sert de baromètre de complexité (si le pitch ne tient plus, c'est que le jeu a gonflé)
- **`docs/content/*.csv`** — 3 CSV (echoes / specials / partitions) pre-rempli avec les items implémentés + idées du brainstorm, importable dans Google Sheets pour bdd de contenu
- **Suppression `brainstorm-identite.md`** — obsolète depuis le pivot univers (maritime écarté). `brainstorm-univers.md` fait désormais autorité sur l'identité.

---

## Specials one-shot + debug toggle (commit)

### Ecart corrige

Avant : `_deck_composition["bombe_count"] += 1` hardcode dans `init_run()`, counters jamais décrémentés → specials permanents dans le deck pendant toute la run. Contraire au design HOB-13 qui les veut **one-shot** (consommés à chaque manche).

### Changements

- **`SpecialItem.gd`** : nouveau champ `@export var debug_always_in_deck: bool = false` — toggle par special pour l'auto-ajouter au deck a chaque manche (pratique dev)
- **`resources/specials/special_bombe.tres`** : créé (bombe n'avait pas de .tres, c'était une erreur). `debug_always_in_deck: true` par defaut pour conserver l'experience actuelle "1 bombe au démarrage".
- **`ShopManager.SPECIAL_PATHS`** : bombe ajoutée → elle devient achetable au shop
- **`RunManager`** :
  - Hardcode `"bombe_count": 1` vire, remplace par appel a `_apply_debug_specials_to_deck()` qui itere les .tres et applique les flags
  - Nouvelle `reset_specials_counts()` : reset dict a 0 + re-applique les flags debug
  - Helpers `_apply_debug_specials_to_deck()` et `_increment_special_count()` pour factoriser
- **`game_scene._on_round_won()`** : appel a `reset_specials_counts()` en premier, avant la transition shop/end-screen

### Flow resultant

1. Init run → dict reset + flags debug appliques → dict = `{bombe: 1}` (via bombe.tres toggle)
2. Manche 1 se joue
3. Round won → reset + re-applique debug → dict = `{bombe: 1}`
4. Shop : achat d'1 fantome → dict = `{bombe: 1, fantome: 1}`
5. Manche 2 : 1 bombe + 1 fantome
6. Round won → reset → dict = `{bombe: 1}`

Pour tester le vrai one-shot sans debug : décocher `debug_always_in_deck` sur bombe.tres et voir que les specials achetés sont bien consommés.

---

## Tickets Linear crees aujourd'hui

- **HOB-14** — Items consommables — système séparé des spéciaux (futur). Piste pour plus tard : ajouter un 2e type d'outil (inventaire séparé, crafté au Shore, activable à volonté) pour enrichir les décisions tactiques en cours de manche.

---

## Prochaine etape

**Session 11 — content** : creer 3-4 nouveaux echoes ciblant les triggers inutilisés (`on_token_drop`, `on_last_breath`, `on_turn_resolved`) + 2-3 nouveaux specials (piochés dans `docs/content/specials.csv`). Pool de contenu a grossir pour que le shop v2 (HOB-13) ait de quoi proposer des choix varies.
