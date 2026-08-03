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
- [Format](grille/format.md) — 7×7, liée au biome traversé plutôt qu'un choix de départ (pas encore implémenté, revu session 16)
- [Grille cabossée](grille/trous.md) — fond marin (pics variables) + trous rouges par manche (session 12, revu session 26)
- [Gravité et résolution](grille/gravite-resolution.md) — cascades, chaîne d'événements
- [Modifiers de cellules](grille/modifiers-cellules.md) — HALF / BOOST / DOUBLE / TRIPLE

### [Jetons](jetons/)
- [Boutons](jetons/boutons.md) — 4 familles vocabulaire tarot (session 18), valeur = pur levier de score depuis la session 12, deck persistant, fusion gatée, [figures](jetons/boutons.md#figures-arcanes-mineurs) Valet→Roi (session 18)
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
- [Catalogue implémenté](partitions/catalogue-implemente.md) — 20 actives, 1 dormante, classées par tier de difficulté (session 16, rééquilibré session 18, +Minima/Maxima/Prime session 19)

### [Manche](manche/)
- [Deck](manche/deck.md) — composition, persistant sur la run, pas de reshuffle
- [Stream + Hold](manche/stream-hold.md) — pioche continue, 1 slot
- [Inspecteur de deck](manche/inspecteur-deck.md) — voir ce qu'il reste à tirer
- [Déroulement](manche/deroulement.md) — les étapes d'un tour
- [Score cible](manche/score-cible.md) — courbe exponentielle, figée session 18
- [Dernier Souffle](manche/dernier-souffle.md) — explosion rocks, cascade surprise
- [Persistance entre manches](manche/persistance-entre-manches.md) — le bouton le plus haut de chaque colonne survit à la manche suivante (session 26)
- [Axe casino — roulette et cases mystère](manche/roulette-casino.md) — jauge, seuil fixe 21, spéciaux réactifs (session 25 ; jauge + seuil + Planter codés, reste à faire : UI dédiée, Récolter, les autres prix, les spéciaux réactifs)

### [Sortilèges](sortileges/)
- [Principe](sortileges/principe.md) — 5 slots, passifs permanents
- [Triggers](sortileges/triggers.md) — les 12 triggers et leurs events
- [Sortilèges implémentés](sortileges/sortileges-implementes.md) — 49 actifs, 1 dormant
- [Rareté](sortileges/rarete.md) — common → legendary
- [Feedback visuel](sortileges/feedback-visuel.md) — à faire (HOB-12)

### [Shop](shop/)
- [Offre mixte](shop/offre-mixte.md) — 2 packs fixes + 2 unitaires rerollables (implémenté session 12)
- [Packs](shop/packs.md) — un seul contenant générique
- [Reroll](shop/reroll.md) — prix croissant, ne touche que les unitaires
- [Économie](shop/economie.md) — hiérarchie des prix
- [Génération de l'offre](shop/generation-offre.md) — règles de curation

### [Progression](progression/)
- [Structure du run](progression/structure-run.md) — biomes fixes, boss de zone, mode infini — 20 manches, figé session 18. Choix de départ : pack de démarrage déterministe acté session 19, remplace le draft de Partitions actuel
- [Sources de scaling](progression/sources-scaling.md) — les 7 leviers
- [Monnaies](progression/monnaies.md) — mouches + tickets
- [Défaite](progression/defaite.md) — conditions, game over

### [Shore](shore/)
- [Principe](shore/principe.md) — hub de meta-progression
- [Unlocks](shore/unlocks.md) — ce qui se débloque, dont les packs de démarrage (session 19, sa première vraie fonction)
- [Boucle narrative](shore/boucle-narrative.md) — retour, mystères

### [Meta](meta/)
- [Questions ouvertes](meta/questions-ouvertes.md) — ce qui reste à trancher
- [Décisions tranchées](meta/decisions-tranchees.md) — la grande table, source de vérité

---

## Ressources connexes

- **Brainstorms** (bacs à sable, dans `docs/brainstorms/`)
  - `brainstorm-univers.md` — source de vérité sur l'univers et le ton
  - `brainstorm-pattern-tags.md` — pool de partitions à piocher
  - `brainstorm-sortileges.md` — triggers × effets pour le catalogue
  - `brainstorm-outils-deck.md` — généralisation de la Fusion en rubrique "Dés à coudre" (session 16)
  - `brainstorm-starter-packs.md` — packs de démarrage déterministes, roster candidat (session 19)
- **Base de contenu** — [Google Sheet](https://docs.google.com/spreadsheets/d/1JMEQf2W6H8fMZ24D63-jRQrJKz5424kR7Exyo4xvM_0/edit) (onglets partitions/sortileges/boss/deck-control/specials/progression), source de vérité pour les données catalogue depuis le 2026-07-10 — le `.tres` doit suivre en cas de divergence
- **Pitch Discord** — `docs/simple-concept.md` (baromètre de complexité)
- **Logs de sessions** — `docs/logs/`
