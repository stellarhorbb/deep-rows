# Session 04 — Clarification du modele Pattern Tags

**Date** : 2026-04-10
**Theme** : Refonte du modele de scoring via les Pattern Tags, introduction de la regle de resolution conditionnelle, lancement du brainstorm dedie

---

## Contexte

Session de discussion design. Le user avait plusieurs idees qui bouillonnaient (events entre zones, variete des patterns, formes exotiques, mobile comme cible potentielle) et voulait en parler avant de rien noter. Apres recadrage, on s'est concentre sur une clarification structurelle majeure du modele de scoring.

Feedback recu en cours de session : **discuter avant de noter dans le GDD**. Par defaut challenger les idees a l'oral, n'ecrire dans les docs que si le user le demande explicitement. Sauve en memoire long-terme (`feedback_discuss_before_writing.md`).

---

## Decision structurelle : le modele Pattern Tags

Avant cette session, le vocabulaire autour des "patterns" etait ambigu dans le GDD — le terme designait a la fois les formes geometriques (lignes 3+, 2x2) et les items de scoring achetes au shop. On a clarifie le modele complet.

### Le vrai modele

Un **Pattern Tag** est une etiquette de scoring que le joueur equipe dans un de ses 4 slots. Chaque Tag est un **bundle indivisible forme + regle** : "Ligne couleur", "2x2 chiffre", "Fibonacci", "Suite 3", "Parfait", etc. Il n'y a pas de "couche geometrique" separee — les formes valides (ligne 3+ h/v/diag, carre 2x2) sont le vocabulaire commun, mais c'est chaque Tag qui porte le bundle complet.

### La regle fondamentale (le point critique que Claude avait rate)

**Pour qu'une figure alignee sur la grille se resolve (disparition + score), elle doit correspondre a au moins un Pattern Tag equipe.** Sinon les jetons restent sur la grille et s'accumulent.

- Figure alignee + Tag correspondant equipe → resolution + score
- Figure alignee + aucun Tag correspondant → **rien ne se passe**, les jetons cloggent la grille

C'est le coeur du puzzle : le joueur ne choisit pas juste comment scorer, il choisit **quoi resoudre**. Les rocks sont la version permanente de cette logique (jetons sans Tag possible par nature). N'importe quel jeton peut devenir rock-like si le joueur n'a pas le bon Tag.

### Implications structurelles

- **Demarrage garanti jouable** : le pack de jetons (classe de run) livre **1 a 2 Tags pre-equipes** coherents avec ses jetons. Impossible de commencer un run ou rien ne se resout.
- **4 slots max** : le joueur a 4 slots de Pattern Tags actifs. Un mauvais loadout est volontairement punitif — c'est au joueur de faire ses choix au shop.
- **Dernier Souffle respecte les regles** : les cascades post-explosion ne se resolvent que si elles matchent un Tag equipe. Pas de magie qui casse le modele.
- **Pool cible : 20-30 Tags** dans le jeu pour assurer la rejouabilite. Chaque Tag a un impact comportemental fort (il change *ce que la grille accepte de liberer*), donc un pool plus petit qu'un Balatro suffit.
- **Regle implicite decouverte** : un jeton qui ne matche pas la regle d'un Tag n'est pas consomme meme s'il est geometriquement dans la forme. Seuls les jetons qui satisfont la regle disparaissent. A remonter dans `03-patterns.md` plus tard.

---

## Brainstorm Pattern Tags lance

Creation de `docs/gdd/brainstorm-pattern-tags.md` sur le meme modele que `brainstorm-echoes.md`. Bac a sable pour accumuler les idees de Tags sans les verrouiller.

Contenu :
- Rappel du modele et de la regle de resolution
- Axes de construction : formes possibles (avec contrainte gravite explicitee) et axes de regles
- Catalogue de propositions en 4 sections : lignes, 2x2, formes etendues, interactions mecaniques
- Questions ouvertes dont la principale : est-ce qu'on autorise les formes au-dela des lignes et 2x2
- Principes de selection pour le pool final

### Debat sur les formes etendues

Le user a propose d'explorer des formes exotiques (etoiles, 3x3 creux, pyramides). La decision verrouillee dans `CLAUDE.md` les interdit mais l'esprit de la regle visait les chaines libres (L, T, zigzag), pas les geometries specifiques et reconnaissables. Question laissee ouverte dans le brainstorm, pas tranchee.

Gros point de vigilance : **la gravite filtre naturellement les formes possibles**. Plusieurs pyramides proposees initialement ("Pyramide 3" = base 2 + sommet 1, "Pyramide 6" = 3+2+1) sont **geometriquement impossibles dans une grille carree** — le sommet devrait etre centre entre les jetons de base, ce qui demande un demi-decalage qui n'existe qu'en grille hexagonale. Corrige dans le brainstorm avec un avertissement explicite.

Formes "pyramide" qui marchent vraiment en grille carree :
- **T pyramidal** (4 jetons : base 3 + sommet 1 centre au-dessus du jeton milieu)
- **Grande Pyramide** (9 jetons : base 5 + milieu 3 + sommet 1, tous centres sur la meme colonne)

### Clarification sur les formes creuses

Les formes avec un "trou" central (3x3 anneau, Plus, Diamant) sont impossibles avec la gravite si le centre est vide. Initialement propose comme "necessite un rock central". Le user a clarifie : **n'importe quel jeton qui ne participe pas a la regle du Tag fait l'affaire** — un rock (permanent, garanti), ou un jeton d'une autre famille / valeur. Le jeton du centre n'est pas consomme par la resolution, il reste apres coup.

Exemple : "Couronne" = 8 jetons meme famille en anneau 3x3. Le centre peut etre un rock ou un Abyssal "hors sujet". Les rocks restent interessants comme la version "sans risque" de ce remplissage. Les Tags signature autour de cette mecanique (Couronne, Orbite, Croisee) donneraient un role structurel aux rocks au-dela de la nuisance.

---

## Reflexion mobile (non-verrouille)

Le user a soulеvе l'hypothese que Deep Rows pourrait aussi performer sur mobile. Discussion honnete des implications (economie premium vs F2P, UI portrait, effort de dev ×1.5). **Decision : on reste sur Steam PC comme cible prioritaire, mais on infusera des choix UI tap-friendly quand c'est gratuit** (zones cliquables assez grosses, pas de hover exclusif, hierarchie visuelle claire). Zero cout sur le dev Steam, porte ouverte pour un port mobile eventuel plus tard.

---

## Fichiers crees / modifies

### CLAUDE.md
- Section "concept en bref" : entree "Patterns" remplacee par "Pattern Tags" avec la regle de resolution en une phrase
- Section "Decisions de design verrouillees" : 3 decisions ajoutees/reformulees (resolution conditionnelle, bundles forme+regle, 4 slots max + Tags pre-equipes, Dernier Souffle respecte les regles)

### GDD
- `03-patterns.md` — titre et sections "Principe" + "Regles de base" reecrites pour utiliser "Pattern Tags" et expliquer la regle de resolution ; catalogue et sections suivantes vocabulaire harmonise ; pool cible de 20-30 explicite ; section "Choix strategiques" enrichie du dilemme "quoi resoudre"
- `brainstorm-pattern-tags.md` (**nouveau**) — bac a sable complet, 30+ propositions de Tags, axes de regles, formes possibles avec contrainte gravite

### Memoire long-terme
- `feedback_discuss_before_writing.md` (**nouveau**) — par defaut discuter avant de noter dans le GDD, ecrire seulement sur demande explicite

---

## Questions ouvertes (ajoutees ou reformulees en session)

- **Formes etendues oui/non** : est-ce qu'on met a jour la decision verrouillee dans `CLAUDE.md` pour autoriser explicitement les formes specifiques et reconnaissables au-dela des lignes/2x2 (pyramides viables, 3x3 plein, rectangles, formes creuses autour d'un jeton non-matchant) ? L'esprit de la regle "anti-chaines" est preserve, mais la lettre est a reecrire.
- **Double matching** : un meme alignement peut-il trigger plusieurs Tags equipes simultanement ? Question deja dans `10-questions.md`, a tester au proto.
- **Taille minimum du pool de Tags** pour que la rejouabilite tienne : cible actuelle 20-30, impossible a trancher sans playtest.

---

## Prochaines etapes

1. **Session dediee Godot proto-parity** (prochaine session si possible) : creer la structure du vrai projet (managers, signals, resources) en reproduisant exactement ce que fait le proto HTML, sans ajouter de features. Garder simple. Le user a explicitement demande de rester simple et d'implementer le core gameplay avant de creuser la variete des Pattern Tags.
2. Ne **pas** enrichir le pool de Pattern Tags avant d'avoir Godot qui tourne. Le brainstorm est un reservoir d'idees, pas une todo de contenu.
3. Question "formes etendues oui/non" a trancher un jour, mais pas urgent.
