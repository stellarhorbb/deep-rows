# Feedback visuel des Sortilèges

**À faire — pas implémenté.** Tracé dans [HOB-12](https://linear.app/hobbes-game/issue/HOB-12).

## Problème actuel

Les Sortilèges s'appliquent **silencieusement**. Le joueur ne sait pas quand un Sortilège triggere ni ce qu'il a fait. Difficile de sentir la synergie quand on ne la voit pas.

## À travailler

- **Déclenchement visible** : flash/glow sur le slot du Sortilège dans l'UI au moment du trigger
- **Effet lisible** : pop-up ou indicateur quand le Sortilège génère des mouches, ajoute un modifier, boost un score
- **Particulier à chaque trigger** :
  - `on_round_start` : animation au démarrage de manche quand les mods sont posés
  - `on_cascade_step` : popup "+3" près du slot à chaque cascade secondaire
  - `on_turn_resolved` : plus discret, post-manche
- **Lisibilité chaîne** : si plusieurs Sortilèges se déclenchent en même temps, éviter le bordel visuel

## À faire quand

Après validation du fun mécanique. Pas de polish avant que la boucle soit jugée solide.

## Liens

- [Principe](principe.md)
- [Triggers](triggers.md)
- [Sortilèges implémentés](sortileges-implementes.md)
