# Monnaies

Deux monnaies distinctes, avec des rôles séparés.

## Mouches — monnaie du shop

Payée aux [grenouilles orchestre](../univers/personnages/grenouilles-orchestre.md) pour acheter des items au [shop](../shop/offre-mixte.md).

### Logique interne

Les grenouilles mangent des mouches. D'où viennent celles du garçon ? On ne répond pas. On paye, on continue.

### Sources

| Source | Montant |
|---|---|
| Manche réussie | Fixe de base (`FLIES_PER_ROUND_WON` = 10 actuellement) |
| Surplus de score | À designer (bonus selon score au-dessus de la cible ?) |
| [Badges](../badges/principe.md) | Ex : "Mouches en Cascade" → +3 par cascade secondaire |

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
