# Session 07 — Direction artistique, univers et piliers narratifs

**Date** : 2026-04-13
**Theme** : Remise en question du theme marin, definition de la direction creative du jeu

---

## Contexte

Le proto Godot est jouable et juice. La mecanique est validee. La question qui se pose : est-ce que le jeu a une ame ?

---

## Le declencheur

Thomas a eu l'idee d'un jeton special Grenouille — un jeton vivant qui saute aleatoirement a gauche ou a droite a chaque tour. Super mecanique, mais "ca colle pas au theme marin". Le theme bride l'imagination au lieu de la nourrir.

---

## Direction artistique validee

**Univers d'auteur, ton conte bizarre.**

References cles :
- **Over the Garden Wall** — feerique, lugubre, drole, inquietant
- **Gravity Falls** — mysteres, humour, couche sombre dessous
- **Nightmare Before Christmas** — creatures bizarres traitees comme normales
- **Cuphead** — DA hand-drawn comme argument commercial, style reconnaissable en une image
- **Sol Cesto** — 2 dev francais, DA unique, histoire simple ("le soleil a disparu"), l'univers porte le jeu

Le liant n'est pas un theme mais un **ton** : bizarre, enfantin, un peu off, hand-drawn. Le jeu doit plaire aux enfants de Thomas (5 et 10 ans) sans etre "un jeu pour enfants" — meme posture qu'OTGW : les enfants accrochent sur le charme, les adultes sur la profondeur.

**Ecarte** : theme marin pur (generique, vocabulaire ferme). Certains mots (Shore, Salt, Echoes) peuvent survivre dans un contexte metaphorique.

---

## Thematique du seuil

Fil conducteur qui emerge : **l'entre-deux**. Un personnage qui est quelque part ou il ne devrait pas etre, entre deux etats.

Pistes d'imaginaire en exploration :
- Monde de migraine — distorsions, auras, le monde se deforme (vecu personnel de Thomas)
- Enfant perdu a la Chihiro — piege dans un lieu de transition
- Bord du monde des morts a la OTGW
- Seuil entre normalite et depression/folie (reference Berserk monde astral, vecu personnel)

Tous ces fils ont un **enfant qui traverse** (posture, pas forcement litteral) et un monde **presque normal mais pas tout a fait**.

---

## Boucle narrative

La structure roguelite doit etre justifiee par l'histoire (modele Hades). Le personnage est coince dans un entre-deux, il essaie de traverser, n'y arrive pas, revient, repart. Chaque tentative il comprend un peu mieux le monde.

- The Shore = point de retour, change subtilement entre les runs
- L'Entity sait que le joueur revient, commente, evolue
- Les mysteres se revelent run apres run
- La "vraie fin" demande des dizaines de runs

---

## Mysteres et secrets

Le jeu doit avoir des couches cachees (modele Gravity Falls / Fez / Tunic / Inscryption). Objectif : que les joueurs theorisent, postent, creusent.

- Symboles recurrents dans les decors
- Evenements rares lies a des conditions specifiques
- Details sur The Shore qui changent apres N runs
- Entity presente dans les marges avant qu'on sache qui elle est

---

## L'Entity — direction

Villain de conte, pas boss de jeu video. Reference dominante : Bill Cipher.
- Forme simple et iconique
- Drole et terrifiant a la fois
- Parle peu, marque beaucoup
- Conscient de la boucle

---

## Scope realiste (dev solo)

Discussion importante sur le realisme des ambitions :
- Narration minimaliste — pas de cinematiques, peu de dialogues. Modele Sol Cesto, pas Hades.
- Mysteres visuels, pas scenariques — placement intentionnel, pas arbres narratifs
- Entity qui parle peu mais marque — une phrase par run suffit
- Shore qui evolue via quelques flags, pas 500 evenements scriptes
- Hand-drawn simple — illustrations statiques + juice en code (deja en place)
- 4-5 zones visuellement distinctes
- Une dizaine de secrets/mysteres planques

---

## Fichiers modifies

- `docs/gdd/00-index.md` — pitch enrichi (boucle narrative, seuil, mysteres)
- `docs/gdd/07-entity.md` — ajout ton et personnalite (Bill Cipher, conscience de la boucle)
- `docs/gdd/09-shore.md` — ajout boucle narrative, evolution entre les runs
- `docs/gdd/10-questions.md` — section Theme/Univers majeure (seuil, boucle, mysteres, scope, questions ouvertes restructurees), nouvelles decisions tranchees (style graphique, boucle narrative, mysteres), technique mise a jour

---

## Prochaine etape cle

Trouver **la phrase** — le pitch univers en un souffle. Tout le reste (personnage, zones, creatures, jetons, Entity, nom du jeu) en decoule. Thomas laisse infuser, dessine, laisse venir.
