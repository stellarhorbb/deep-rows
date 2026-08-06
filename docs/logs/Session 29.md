# Session 29 — Brainstorm structure de run, catalogue d'events entre manches

**Date** : 2026-08-06
**Thème** : Session de pure réflexion, sans code — le user joue toujours en continu (rien de spécifique remonté sur le build de session 28) et ouvre une question de fond sur la forme globale de la progression du run.

---

## Le doute de départ : Balatro vs StS2/Sol Cesto/Mewgenics/Cursed Words

Le modèle de référence pour la structure du run a toujours été Balatro (séquence linéaire de manches, cible qui grossit, zéro enjeu de décision sur le squelette lui-même). Le user se demande si un modèle plus proche de Slay the Spire 2, Sol Cesto ou Mewgenics (mini-arbre de décisions, rencontres à bonus/malus, roll de risque) ne servirait pas mieux le jeu.

Clarification en plusieurs passes :
- Pas une vraie carte à naviguer façon StS — explicitement écarté ("j'imaginais pas une full carte de malade").
- Le contenu à l'intérieur de la structure (starters, packs, Sortilèges, cases mystère, Colonne Convoitée...) varie déjà énormément — ce n'est pas la source du problème.
- Le vrai reproche : le **squelette** du run (`ROUND_TARGETS`, boss à 5/10/15/20, ordre des zones) est identique à 100% d'un run à l'autre, indépendamment des choix du joueur.
- Piste retenue : garder la structure linéaire actuelle telle quelle, mais glisser occasionnellement des **décisions binaires/ternaires** aux points de transition existants (avant/après un shop), façon écrans "Choose your opponent" / "Upgrade" de Cursed Words (captures d'écran fournies par le user).
- Piste explicitement écartée : changer l'ordre des zones/biomes — "on perd le fil cognitif et narratif de progression" (Plage→Forêt→Marais→Rêves reste fixe).

## Catalogue d'events — brainstorm puis passe sur le Google Sheet

Construction itérative en plusieurs vagues, resserrée à chaque fois par le user :

1. Neuf premières idées, classées par le user en **5 familles** : **Paris** (mise + résultat incertain), **Trocs** (échange immédiat certain), **Épreuves** (manche entière plus dure contre récompense garantie, refusable), **Cadeaux** (rien à donner, rare), **Choix** (options mutuellement exclusives, pas de coût commun). Complété à 22 idées (3-5 par famille) sur demande du user.
2. **Contrainte de timing corrigée** : plusieurs events référençaient des interactions en pleine manche (stream, cases live) — recadrés pour que toute décision se prenne au gate du shop (avant ou après), l'effet portant sur la manche qui vient de finir ou sur la mise en place de la manche à venir, jamais une interaction mid-round.
3. **Deux erreurs de design pointées par le user, corrigées** :
   - Un Sortilège ne level up pas — c'est la **Partition** (Pattern Tag) qui level up par score cumulé (`SHEET_LEVEL_THRESHOLDS`). Deux events renommés/recentrés en conséquence ("Pari de Sortilège" → "Pari de Partition", "Level-up gratuit" recentré sur Partition).
   - "Le Spécial est perdu si tu perds la manche" n'a pas de sens : perdre une manche = game over immédiat (deck vide + cible pas atteinte), donc décrire une perte distincte sur l'échec est redondant. Reformulé en coût immédiat au moment de la mise (le Spécial sort de l'inventaire pour la manche à venir), pas de branche d'échec à part.

Le user a ensuite créé un **7e onglet "events"** sur le Google Sheet (deep-rows) pour centraliser et itérer dessus directement, avec des colonnes `type / event / trigger / effect / resolution / notes`. Plusieurs allers-retours de tri :
- Coupé de 22 à 17 puis 14 events (retirés : Vision anticipée, Libération anticipée, Deck resserré, Colonne verrouillée, Ordre de deck, Pari de Tickets — résolution jamais tranchée, restée "?" — et Post Boss — "j'ai rien de bien qui me vient à l'esprit en rewards qui a du sens après un boss").
- **Pari de Partition** retravaillé pour avoir un vrai coût immédiat : désigne une Partition équipée et la **désactive** pour la manche à venir (au lieu d'un pari sans downside réel), gagne un level immédiat si la manche suivante est réussie.
- **Pacte de l'Entity** retravaillé en décision spatiale plutôt qu'en malus passif ambigu : boost ×2 le prochain jeton du deck (plafonné à 10, la valeur max des jetons), MAIS skull garanti à 100% seulement **si le joueur choisit lui-même** de le dropper dans la Colonne Convoitée — sinon le jeton est safe partout ailleurs. Validé comme une bonne évolution : transforme un flag RNG passif en vrai dilemme de placement (la CC est souvent la case la plus tentante à jouer un bon jeton dessus, à cause du Bonus/Jackpot possible). Point de vigilance identifié : il faudra un marqueur visuel clair sur ce jeton précis pour éviter une punition-piège.
- **Don empoisonné de Rock** précisé : Rock ×2 ajouté au deck contre +2 charges de Shake.
- **Boss Malus** et **Case Mystère** confirmés sans récompense associée — le choix lui-même est la valeur, pas de bonus en plus.

## Raretés — 3 paliers, même moule que les Sortilèges

Système de tirage pondéré demandé par le user : **Commun (60) / Rare (30) / Légendaire (10)**, réutilisant le principe de `SPELL_RARITY_RATES` (poids fixe par palier). Répartition proposée et validée sur les 14 events finaux (2 Légendaire, 4 Rare, 8 Commun) :
- **Légendaire** : Level-up gratuit (zéro risque, zéro coût, la récompense la plus forte du lot), Pari de Partition (même récompense mais gated par le pari, tag déjà posé par le user).
- **Rare** : Manche Élite, Handicap de grille, Pacte de l'Entity, Pari d'un Spécial.
- **Commun** : les 8 restants (Pari des Mouches, Don empoisonné de Rock, Aubaine de hold, Spécial pur cadeau, Mouches pures offertes, Jeton bonus offert, Boss Malus, Case Mystère).

## Lot pilote scopé (info seulement, rien codé)

Le chantier touche quasiment tous les Managers à la fois (DeckManager, RunManager, GridManager, EntityManager, ShopManager) plus un nouvel écran de décision et un tirage pondéré — jugé trop gros pour être codé d'un coup sans validation préalable, cohérent avec la philosophie proto-avant-contenu du projet. Lot pilote proposé (1 event par famille, choisis pour demander le moins de plomberie nouvelle) :

- Pari des Mouches (bets)
- Don empoisonné de Rock (trocs)
- Aubaine de hold (trials)
- Mouches pures offertes (gifts)
- Case Mystère (choices)

Infrastructure commune nécessaire une seule fois, peu importe lequel des 14 events suit : tirage pondéré par rareté au gate du shop, écran d'event générique (accepter/refuser ou choisir), état de "pari en attente" pour les résolutions différées.

Rien n'a été codé cette session — banque de design pour une prochaine session.

## Reste ouvert

- Le lot pilote lui-même n'est pas construit — reste à décider quand s'y attaquer.
- **Boss Malus** reste bloqué par un vrai manque de contenu : aucun malus de boss concret n'existe encore (question ouverte depuis la session 27/28, voir `questions-ouvertes.md`).
- Cas limite non tranché sur Level-up gratuit / Pari de Partition : que se passe-t-il si la Partition ciblée est déjà au niveau max (Maestro) ?
- Rien de cette session n'a été validé en jeu — c'est un chantier de design pur, à confronter au playtest une fois codé.
