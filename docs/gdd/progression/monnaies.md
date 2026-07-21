# Monnaies

Deux monnaies distinctes, avec des rôles séparés.

## Mouches — monnaie du shop

Payée aux [grenouilles orchestre](../univers/personnages/grenouilles-orchestre.md) pour acheter des items au [shop](../shop/offre-mixte.md).

### Logique interne

Les grenouilles mangent des mouches. D'où viennent celles du garçon ? On ne répond pas. On paye, on continue.

### Sources

| Source | Montant |
|---|---|
| Manche réussie (base) | Fixe (`FLIES_PER_ROUND_WON` = 8) |
| Jetons restants en fin de manche | +`FLIES_BONUS_REMAINING` (2) si `DeckManager.get_remaining()` >= `FLIES_BONUS_REMAINING_THRESHOLD` (10) au moment de la victoire (`GameRules.get_round_end_flies_bonus`) — simplifié à un seul palier en session 18, remplace l'ancien double palier (≥20/≥10) de session 16 ; seuil rendu inclusif en session 19 |
| Surplus de score | À designer (bonus selon score au-dessus de la cible ?) |
| [Badges](../badges/principe.md) | Ex : "Mouches en Cascade" → +3 par cascade secondaire. Depuis la session 16, les Badges `on_round_end` (ex : Pourboire) contribuent aussi à la recompense de fin de manche |

### Écran de récompense (YouWinUI, session 16)

En fin de manche (hors dernière manche du run), un écran dédié décompose la récompense — base, bonus jetons restants, bonus par Badge — avant un bouton **ENCAISSER** qui débloque la suite vers le shop. Le compteur de mouches affiché en jeu ne bouge visuellement qu'au clic sur ce bouton (la mutation réelle est immédiate, seul l'affichage est retardé, pour ne pas spoiler le total avant que le joueur ait vu le détail).

### Dépenses

Voir [Économie du shop](../shop/economie.md) pour la hiérarchie des prix.

## Tickets — le score

Pas une monnaie séparée : "Tickets" est simplement le nom diégétique donné au score. Les jetons rapportent des tickets (modifiés par le multiplicateur de Sheet + Badges) quand une figure score, et atteindre le total de tickets requis sur une manche fait passer à la suivante — jusqu'au boss de zone, qui ouvre la zone suivante. C'est tout : pas de coût d'accès distinct, pas de solde à gérer entre les manches, rien à formaliser en plus de ce qui existe déjà (`ScoreManager`, `GameRules.ROUND_TARGETS`).

Ancienne piste abandonnée : une "vraie" monnaie de progression nommée Tickets, distincte du score, avait été envisagée dans `brainstorm-univers.md` puis renommée par-dessus le score en session 13 — les deux ont coexisté un temps sous le même nom (voir historique `Session 13.md`). Tranché le 2026-07-21 : il n'y a jamais eu qu'une seule chose.

## Liens

- [Structure du run](structure-run.md)
- [Shop — économie](../shop/economie.md)
- [Grenouilles orchestre](../univers/personnages/grenouilles-orchestre.md)
- [Shore — unlocks](../shore/unlocks.md)
