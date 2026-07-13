# Monnaies

Deux monnaies distinctes, avec des rôles séparés.

## Mouches — monnaie du shop

Payée aux [grenouilles orchestre](../univers/personnages/grenouilles-orchestre.md) pour acheter des items au [shop](../shop/offre-mixte.md).

### Logique interne

Les grenouilles mangent des mouches. D'où viennent celles du garçon ? On ne répond pas. On paye, on continue.

### Sources

| Source | Montant |
|---|---|
| Manche réussie (base) | Fixe (`FLIES_PER_ROUND_WON` = 10 actuellement) |
| Jetons restants en fin de manche (session 16) | Palier exclusif selon `DeckManager.get_remaining()` au moment de la victoire : ≥20 restants = +5, ≥10 = +2, sinon rien (`GameRules.get_round_end_flies_bonus`) |
| Surplus de score | À designer (bonus selon score au-dessus de la cible ?) |
| [Badges](../badges/principe.md) | Ex : "Mouches en Cascade" → +3 par cascade secondaire. Depuis la session 16, les Badges `on_round_end` (ex : Pourboire) contribuent aussi à la recompense de fin de manche |

### Écran de récompense (YouWinUI, session 16)

En fin de manche (hors dernière manche du run), un écran dédié décompose la récompense — base, bonus jetons restants, bonus par Badge — avant un bouton **ENCAISSER** qui débloque la suite vers le shop. Le compteur de mouches affiché en jeu ne bouge visuellement qu'au clic sur ce bouton (la mutation réelle est immédiate, seul l'affichage est retardé, pour ne pas spoiler le total avant que le joueur ait vu le détail).

### Dépenses

Voir [Économie du shop](../shop/economie.md) pour la hiérarchie des prix.

## Tickets — monnaie de progression

Donnent accès aux **zones** suivantes. Monnaie différente des mouches — les tickets ne servent pas au shop.

**Attention, homonymie (session 13)** : l'UI affiche désormais "TICKETS" partout où le score/cible de manche apparaît (`TICKETS : 1234`, `TICKETS REQUIS : 100`) — pur habillage textuel décidé en session 13, le score reste le score, ça ne touche à aucune économie. Ce n'est **pas** la monnaie de progression décrite ci-dessous, qui reste un concept à mécanique non formalisée. Les deux partagent juste le même mot pour l'instant — à trancher si ça reste ambigu une fois la vraie économie de Tickets formalisée (peut-être un renommage de l'un des deux à ce moment-là).

### Statut

Concept validé dans `brainstorm-univers.md`, **mécanique exacte à formaliser** :
- Combien de tickets gagnés par manche / par zone ?
- Coût d'accès à une zone (fixe ? croissant ?)
- Les tickets non dépensés sont-ils conservés ?
- Conversion en ressource de meta-progression au [Shore](../shore/unlocks.md) ?

### Questions ouvertes

- **Mouches non dépensées en fin de run** — converties en tickets pour le Shore ? Perdues ?
- **Surplus de tickets** — utilité au Shore ou au cours du run suivant ?

## Liens

- [Structure du run](structure-run.md)
- [Shop — économie](../shop/economie.md)
- [Grenouilles orchestre](../univers/personnages/grenouilles-orchestre.md)
- [Shore — unlocks](../shore/unlocks.md)
