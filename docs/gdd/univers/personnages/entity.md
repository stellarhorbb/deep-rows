# L'Entity

L'adversaire invisible. Un **villain de conte**, pas un boss de jeu vidéo. Références : Bill Cipher (Gravity Falls), la Bête (Over the Garden Wall).

Elle ne joue pas (ne score pas, ne cherche pas à gagner) — elle **perturbe**.

## Personnalité

- **Forme simple et iconique** — reconnaissable en un coup d'œil, dessinable en 3 secondes
- **Drôle et terrifiante à la fois** — inoffensive en apparence, glaçante quand elle devient sérieuse
- **Peu de screen time** — parle rarement, mais chaque apparition marque. La rareté la rend mémorable.
- **Consciente de la boucle** — elle sait que le joueur revient. Elle commente, s'amuse, s'agace. Sa relation avec le joueur évolue au fil des runs.
- **Présente dans les détails** — apparaît dans les marges, les arrière-plans, avant même qu'on comprenne qui elle est

Scope réaliste : une poignée de lignes marquantes, pas des centaines de dialogues.

## Mécanique — lâcher de jeton

L'Entity place un [jeton entity-skull](../../jetons/entity-skull.md) dans une colonne aléatoire non pleine, **tous les 6 tours joueur** (`ENTITY_DROP_INTERVAL` dans `game_rules.gd`). Pas un jeton du deck — il arrive de l'extérieur.

## Perturbations futures

L'Entity est le vecteur principal des perturbations qui montent en pression en zones avancées. **Annoncées en début de manche** — le joueur peut s'adapter, c'est un obstacle prévisible.

### Via la couche modifiers
La plupart des perturbations passeront par les [modifiers de cellules](../../grille/modifiers-cellules.md) — l'Entity devient une source qui peuple `grid_modifiers` en début de manche (cases HALF, cases piégées, etc.).

### Hors modifiers (spécifiques Entity)
- Gravité modifiée sur une colonne (inversée, latérale)
- Hold verrouillé pour une manche
- Pattern interdit : une Partition équipée ne score pas cette manche
- Jetons parasites : boutons de valeur 0 injectés dans le deck
- Score cible augmenté pour cette manche

## Escalade par zone

| Zone | Perturbations |
|---|---|
| 1 | 0-1 perturbation simple par manche |
| 2 | 1 perturbation par manche |
| 3 | 1-2 perturbations, début des combos |
| 4 | 2+ perturbations, combos complexes |

## Design intent

- Le joueur doit sentir que c'est **sa faute** quand il perd — les perturbations sont annoncées, l'adaptation est possible
- Pas de RNG punitif (pas de "l'Entity cible ton meilleur jeton")
- Forcer la **flexibilité** — un build trop spécialisé peut être mis en difficulté par la bonne perturbation
- Les [Sortilèges](../../sortileges/principe.md) peuvent contrer certaines perturbations

## Lecture profonde (privée, session 24)

L'Entity se relit comme la peur / la folie / la mort — celle qui veut que le garçon reste perdu dans le monde plutôt que d'en sortir. Jamais nommé ni montré ainsi en jeu, voir [Pitch — le sens caché](../pitch.md#le-sens-caché-privé--jamais-montré-en-jeu).

## Liens

- [Jeton entity-skull](../../jetons/entity-skull.md)
- [Modifiers de cellules](../../grille/modifiers-cellules.md)
- [Le garçon](garcon.md)
- [Pitch — le sens caché](../pitch.md#le-sens-caché-privé--jamais-montré-en-jeu)
- [HOB-11 — règles d'override des modifiers](https://linear.app/hobbes-game/issue/HOB-11)
