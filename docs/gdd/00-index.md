# Deep Rows — Game Design Document

**Genre** : Roguelite puzzle-drop
**Moteur** : Godot 4.6
**Cible** : Steam PC
**Statut** : Pré-production

---

## Pitch

> **Un garçon se retrouve malgré lui dans un monde halluciné.**

Un roguelite où le joueur drop des boutons dans une grille verticale (style puissance 4). Chaque drop déclenche des interactions immédiates — cascades, explosions, disparitions. Score en temps réel. Shop tenu par des grenouilles orchestre. Game over = retour au Shore pour meta-progression.

**Feeling** : input simple → spectacle automatique → chiffres qui explosent → encore.

**Positionnement** : tempo Balatro × geste Candy Crush × profondeur de build Diecast × univers d'auteur (OTGW / Gravity Falls / Cuphead).

---

## Carte du GDD

### [Univers](univers/)
- [Pitch](univers/pitch.md) — la phrase, la descente, la boucle
- [Ton](univers/ton.md) — cute-dérangeant, double lecture
- [Direction artistique](univers/direction-artistique.md) — hand-drawn, lumière, UI
- **Personnages**
  - [Le garçon](univers/personnages/garcon.md) — le joueur
  - [L'Entity](univers/personnages/entity.md) — villain de conte, perturbateur
  - [Grenouilles orchestre](univers/personnages/grenouilles-orchestre.md) — tenancières du shop

### [Grille](grille/)
- [Format](grille/format.md) — 7×7, choix de grille en début de run (pas encore implémenté)
- [Grille cabossée](grille/trous.md) — trous aléatoires par manche (session 12)
- [Gravité et résolution](grille/gravite-resolution.md) — cascades, chaîne d'événements
- [Modifiers de cellules](grille/modifiers-cellules.md) — HALF / BOOST / DOUBLE / TRIPLE

### [Jetons](jetons/)
- [Boutons](jetons/boutons.md) — 4 familles en code, valeur = pur levier de score depuis la session 12, deck persistant, fusion gatée
- [Rocks](jetons/rocks.md) — scaffold, explosent au Dernier Souffle
- [Spéciaux](jetons/specials.md) — outils one-shot
- [Entity-skull](jetons/entity-skull.md) — jeton lâché par l'Entity
- [États de jetons](jetons/etats-reserve.md) — réserve, déprioritisé

### [Partitions](partitions/) (ex "Pattern Tags")
- [Principe](partitions/principe.md) — règle fondamentale, slots
- [Formes](partitions/formes.md) — ligne / carré / losange
- [Axes de règles](partitions/axes-de-regles.md) — famille / chiffre / suite / mixte
- [Scoring](partitions/scoring.md) — multi direction, cascade, modifiers, rule
- [Level up](partitions/level-up.md) — Pianissimo → Maestro
- [Catalogue implémenté](partitions/catalogue-implemente.md) — 6 actives (famille/rock), 4 dormantes (chiffre)

### [Manche](manche/)
- [Deck](manche/deck.md) — composition, persistant sur la run, pas de reshuffle
- [Stream + Hold](manche/stream-hold.md) — pioche continue, 1 slot
- [Inspecteur de deck](manche/inspecteur-deck.md) — voir ce qu'il reste à tirer
- [Déroulement](manche/deroulement.md) — les étapes d'un tour
- [Score cible](manche/score-cible.md) — courbe de pression
- [Dernier Souffle](manche/dernier-souffle.md) — explosion rocks, cascade surprise

### [Badges](badges/)
- [Principe](badges/principe.md) — 5 slots, passifs permanents
- [Triggers](badges/triggers.md) — les 5 triggers et leurs events
- [Badges implémentés](badges/badges-implementes.md) — 10 actifs, 1 dormant
- [Rareté](badges/rarete.md) — common → epic
- [Feedback visuel](badges/feedback-visuel.md) — à faire (HOB-12)

### [Shop](shop/)
- [Offre mixte](shop/offre-mixte.md) — 2 packs fixes + 2 unitaires rerollables (implémenté session 12)
- [Packs](shop/packs.md) — un seul contenant générique
- [Reroll](shop/reroll.md) — prix croissant, ne touche que les unitaires
- [Économie](shop/economie.md) — hiérarchie des prix
- [Génération de l'offre](shop/generation-offre.md) — règles de curation

### [Progression](progression/)
- [Structure du run](progression/structure-run.md) — 4 zones × 3 manches
- [Sources de scaling](progression/sources-scaling.md) — les 7 leviers
- [Monnaies](progression/monnaies.md) — mouches + tickets
- [Défaite](progression/defaite.md) — conditions, game over

### [Shore](shore/)
- [Principe](shore/principe.md) — hub de meta-progression
- [Unlocks](shore/unlocks.md) — ce qui se débloque
- [Boucle narrative](shore/boucle-narrative.md) — retour, mystères

### [Meta](meta/)
- [Questions ouvertes](meta/questions-ouvertes.md) — ce qui reste à trancher
- [Décisions tranchées](meta/decisions-tranchees.md) — la grande table, source de vérité

---

## Ressources connexes

- **Brainstorms** (bacs à sable, dans `docs/brainstorms/`)
  - `brainstorm-univers.md` — source de vérité sur l'univers et le ton
  - `brainstorm-pattern-tags.md` — pool de partitions à piocher
  - `brainstorm-badges.md` — triggers × effets pour le catalogue
- **Base de contenu** (dans `docs/content/`) — CSV pour Google Sheets : `badges.csv`, `specials.csv`, `partitions.csv`
- **Pitch Discord** — `docs/simple-concept.md` (baromètre de complexité)
- **Logs de sessions** — `docs/logs/`
