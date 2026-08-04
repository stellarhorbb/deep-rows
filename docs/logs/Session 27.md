# Session 27 — Corrections de bugs, puis long doute sur le core en pleine run

**Date** : 2026-08-04
**Thème** : Session qui commence en correction de bugs classique, puis bascule en cours de route sur un doute profond sur le geste central, declenche par une vraie run perdue. Voir le [brainstorm dedie](../brainstorms/brainstorm-geste-central.md) pour le detail complet de l'exploration design — ce log se concentre sur les fixes concrets livres.

---

## Bugs corriges

**Pile ou Face n'affichait jamais son +5 de valeur** — le trigger fonctionnait (confirme par le user pour la branche Rock), mais rien ne rendait visible la branche +5 valeur. `TurnController.dropped_token_mutated` emettait avant la fin de l'animation de chute et ne portait pas la cellule concernee ; `GameScene` faisait un `rebuild_sprites()` generique sans feedback dedie. Corrige : le signal porte maintenant `(col, row)` et s'emet apres `drop_animated`, et le cas "valeur augmentee" reutilise le flash dore de `GridVisual.animate_boost` (meme langage visuel que le Boost de la roulette) plutot qu'un simple `replace_sprite`.

**Cases mystere SCORE_UP/SCORE_DOWN calculaient sur le score actuel** — donc souvent 0% de rien quand la case se declenche tot en manche. Change pour deplacer la **cible** de score plutot (+10% pour le malus, -10% pour le bonus) — `ScoreManager.adjust_target()` ajoute, plancher a 1. Effet de bord positif : si un bonus fait tomber la cible sous le score deja acquis, la manche se termine gagnee au prochain check, sans cablage supplementaire.

**Étau bloquait 2 colonnes aleatoires** — change pour toujours les deux colonnes exterieures (`[0, COLS-1]`), plus fidele au nom (l'etau serre depuis les bords). `_pick_distinct_columns` retiree (plus utilisee).

**Bourrasque visait le stream** — change pour viser le premier slot de Hold non vide a la place (`DeckManager.take_first_held`). Silencieux si rien n'est tenu ou si la colonne est pleine (le jeton reste en Hold, aucune perte) — prefere a un comportement hybride avec fallback sur le stream, juge source de confusion ("pourquoi ca a fait ca cette fois et pas la derniere").

**Bug de concurrence dans `ResolutionBanner`** — toutes les annonces (breakdown/cascade/combo/roll/mystere/roulette) partagent le meme Label sans aucune synchronisation. Le cas precis : le dernier jeton d'une Partition qui atterrit sur une case mystere declenchait les deux annonces en parallele, et le `visible = false` differe de la premiere ecrasait la seconde en plein milieu de sa sequence (invisible). Corrige par un verrou cooperatif simple (`_acquire_lock`/`_release_lock`) autour des 6 fonctions publiques — desormais serialisees, plus jamais simultanees.

**QoL cases mystere** — reveal en escalier gauche-a-droite au round-start (au lieu de toutes en meme temps) et glyphe "?" agrandi pour rester lisible sur une grille chargee.

**Fixer generalise a toute valeur** — limite jusque-la aux figures (Valet+). Etendu a n'importe quel jeton de base, et `RunManager.boost_random_button`/`GridManager.boost_random_token` (Boost de la roulette) respectent desormais `token.locked`. Repond a une vraie frustration remontee en jouant : un 7 patiemment amene via les Des a coudre pour completer 777 pouvait se faire muter par un Boost aleatoire, ruinant le travail sans aucun recours. Renomme `FIX_FIGURE` -> `FIX_VALUE`.

## Le reste de la session

Discussion longue sur une possible refonte du geste central (fusion/lignes plutot que Partitions), avec un prototype teste en direct (`proto/fusion-lines.html`). Verdict : la piste testee ne tient pas, mais le diagnostic qui y mene (le geste doit toujours payer, la progression doit amplifier UN geste plutot que d'empiler des systemes paralleles) est solide. Detail complet dans le [brainstorm dedie](../brainstorms/brainstorm-geste-central.md).

## Reste ouvert

- Question ouverte posee en fin de brainstorm : a quoi ressemblerait un enjeu reel (pas un flavor bonus) sur chaque case/drop, sans recreer le probleme d'illisibilite deja rejete deux fois cette session. A reprendre a tete reposee, pas en fin de session fatiguee.
- Tour des starters (voir memoire `project_starters_testing_progress`) : Le Prévoyant tente, perdu Forêt 5/5 — pas encore une run complete/gagnee avec ce starter.
