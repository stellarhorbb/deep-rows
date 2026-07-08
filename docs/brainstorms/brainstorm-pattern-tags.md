# Brainstorm — Pattern Tags

**Statut** : bac a sable. Rien ici n'est tranche. C'est un dump d'idees pour ne pas les perdre, a piocher quand on construira le catalogue officiel de Pattern Tags (`03-patterns.md`).

**Session 14** : direction retenue pour etendre le pool (Rainbow sur l'axe famille, axe chiffre "casino" confine a la Ligne, tiroir rare/signature) — voir [Axes de regles](../gdd/partitions/axes-de-regles.md). Les pistes ci-dessous qui recoupent position/contexte ont ete recadrees cote Badges, pas Partitions. Ce fichier reste la reserve pour tout le reste (formes etendues type pyramide/3x3, autres regles non retenues).

Format libre. On ajoute, on rature, on regroupe au fil des sessions.

---

## Rappel du modele (a ne pas perdre de vue)

Un **Pattern Tag** est un bundle indivisible **forme + regle**. Le joueur equipe jusqu'a 4 Tags dans ses slots. Le pack de jetons en livre 1-2 pre-equipes.

**Regle fondamentale** : une figure sur la grille ne se resout (disparition + score) **que si elle correspond a au moins un Tag equipe**. Sinon les jetons restent et cloggent. Les rocks sont la forme permanente de cette logique (jetons sans Tag possible par nature).

Pool cible : **20-30 Tags** pour assurer la rejouabilite. Chaque Tag doit avoir une identite claire — si deux Tags se ressentent pareil, l'un des deux est en trop.

---

## Axes de construction d'un Tag

Un Tag = **une forme** × **une regle**. Les deux axes peuvent etre explores independamment.

### Formes possibles

Le catalogue actuel utilise uniquement : ligne 3+, ligne 4+, ligne 5+, carre 2x2. On peut elargir — a condition de respecter la **contrainte de gravite** : les jetons tombent et se posent sur ce qu'il y a en dessous, donc aucun jeton ne peut etre "flottant" sauf s'il est soutenu.

**Formes compatibles avec la gravite** :
- Ligne horizontale, verticale, diagonale 3/4/5+ (au sol ou sur jetons/rocks)
- Carré 2x2
- Star 5 jetons en forme de plus
- Diamant 4 jetons en losange
- Rectangle 2x3 ou 3x2
- Carre 3x3 plein
- Couronne 3x3 creux
- Grande pyramide (base 5 + milieu 3 + sommet 1, tout centre sur la meme colonne) → 9 jetons, tres rare, tres spectaculaire

**⚠ Formes impossibles dans une grille carrée** (a ne pas proposer) :
- "Pyramide 3" (base 2 + sommet 1) et "Pyramide 6" (3+2+1) : le sommet devrait etre centre entre les jetons de la base, ce qui demande un demi-decalage qui n'existe pas dans une grille carrée. Ca n'existe qu'en grille hexagonale. Dans notre grille, ca retombe toujours sur un L, exactement ce qu'on a banni.

**Formes creuses — possibles si le centre est occupe par un jeton non-matchant**
Ces formes ont un "trou" central qui serait impossible avec la gravite s'il etait vide. Mais il suffit que le centre soit occupe par **un jeton qui ne participe pas a la regle du Tag** : un rock (permanent, garanti), ou n'importe quel jeton d'une autre famille / valeur qui ne matche pas la regle. Le jeton du centre n'est pas consomme par la resolution — seuls les jetons qui matchent la regle disparaissent.

- **3x3 creux** (anneau 8 jetons autour d'un jeton central non-matchant) → Tag signature potentiel, fonctionne avec rocks ou avec un jeton "hors sujet"
- **Plus (+)** : 5 jetons (centre + 4 voisins orthogonaux) avec le centre non-matchant
- **Diamant / losange** : 4 jetons (en diagonales autour d'un centre non-matchant)

Exemple concret : "Couronne" = 8 jetons meme famille en anneau 3x3. Si le centre est un rock → valide. Si le centre est un jeton d'une autre famille → valide aussi, ce jeton reste apres resolution. Les rocks sont juste la version "sans risque" de ce remplissage.

**Formes interdites** (deja decide, a garder) :
- L, T plat, zigzag, chaines libres → trop floues visuellement, pas d'identité

**Question ouverte** : est-ce qu'on autorise explicitement les formes spécifiques et reconnaissables au-dela des lignes/2x2 ? La decision verrouillée actuelle dans `CLAUDE.md` les interdit toutes. L'esprit de la regle visait les chaines libres, pas les geometries identifiables. A trancher si on veut developper cette piste.

### Axes de regles

**Par famille**
- Meme famille
- Exactement 2 familles differentes (duo oppose)
- 3+ familles differentes (rainbow)
- Toutes familles differentes (rainbow strict)
- Alternance stricte famille A / famille B

**Par chiffre identite**
- Meme chiffre
- Tous pairs
- Tous impairs
- Alternance pair / impair
- Tous ≤ N (minima)
- Tous ≥ N (couronne)
- Tous dans un intervalle [A, B]

**Par chiffre sequence**
- Suite consecutive (N, N+1, N+2)
- Suite decroissante
- Fibonacci
- Progression geometrique (×2)
- Nombres premiers
- Carres parfaits (1, 4, 9)

**Par chiffre arithmetique**
- Somme = cible (ex: 10, 15, 20)
- Produit = cible
- Moyenne = valeur mediane
- Difference constante (progression arithmetique)

**Par mixte**
- Meme famille ET meme chiffre (Parfait)
- Meme famille ET suite
- Rainbow ET suite

**Par position sur la grille**
- Sur la ligne du bas
- Sur la ligne du haut
- Touchant un bord lateral
- Dans un coin
- Touchant (adjacent a) un rock
- Touchant un autre jeton d'une famille specifique

**Par contexte de drop**
- Incluant un jeton qui vient du hold
- Pendant une cascade (niveau ≥ 2)
- Juste apres un autre Tag qui vient de se resoudre (chain Tag)
- Incluant le dernier jeton drope

**Par etat de jeton**
- Incluant un jeton dans un etat particulier (beni, maudit, charge...)
- Tous dans le meme etat

---

## Catalogue de propositions (en vrac)

### Reprises du catalogue officiel (pour reference)

Deja dans `03-patterns.md` : Trio couleur, Quatuor couleur, Maree haute, Recif (2x2 couleur), Badge numerique, Suite 3, Escalier 4, Parfait, Arc-en-ciel, Fibonacci.

### Nouvelles propositions — lignes

| Nom | Regle | Forme | Diff. | Notes |
|---|---|---|---|---|
| Pair force | 3+ alignes tous de chiffres pairs | Ligne 3+ | Moyen | Filet pour build "paire" |
| Impair mystique | 3+ alignes tous de chiffres impairs | Ligne 3+ | Moyen | Pendant thematique de Pair force |
| Alternance | 3+ alignes en alternance pair-impair | Ligne 3+ | Moyen | Force a penser l'ordre de drop |
| Dizaine | 3+ alignes dont somme = 10 | Ligne 3+ | Dur | Precision arithmetique |
| Duo oppose | 3+ alignes utilisant exactement 2 familles | Ligne 3+ | Moyen | Entre Ligne couleur et Arc-en-ciel |
| Minima | 3+ alignes tous ≤ 3 | Ligne 3+ | Facile | Tag de demarrage accessible, faible mult |
| Couronne | 3+ alignes tous ≥ 7 | Ligne 3+ | Dur | Rare, haute valeur, gros mult |
| Premier | 3+ alignes tous chiffres premiers (2, 3, 5, 7) | Ligne 3+ | Dur | Niche mathematique |
| Double Fibonacci | 4 alignes formant une suite Fibonacci | Ligne 4 | Tres dur | Upgrade du Fibonacci de base |
| Chaine couleur | 5+ meme famille sur ligne verticale | Ligne 5 verticale | Dur | Recompense la gestion de colonne |

### Nouvelles propositions — 2x2

Le catalogue officiel n'a qu'un seul Tag 2x2 (Recif). On peut clairement elargir.

| Nom | Regle | Forme | Diff. | Notes |
|---|---|---|---|---|
| Pile 2x2 | Carre 2x2 dont somme = 20 | 2x2 | Dur | Variante arithmetique |
| Eclats | Carre 2x2 de 4 familles toutes differentes | 2x2 | Dur | Rainbow 2x2 |
| Mosaique | Carre 2x2 de 2 familles en diagonale (damier) | 2x2 | Moyen | Pattern visuel fort |
| Quatuor | Carre 2x2 de 4 chiffres identiques | 2x2 | Tres dur | Rarete, gros mult |
| Echelle | Carre 2x2 de 4 chiffres consecutifs | 2x2 | Dur | Sequence compacte |

### Nouvelles propositions — formes etendues (si on autorise)

Requiert de mettre a jour la decision verrouillee dans `CLAUDE.md`. Toutes ces formes respectent la gravite sauf mention contraire.

| Nom | Regle | Forme | Diff. | Notes |
|---|---|---|---|---|
| Chapelle | 4 jetons meme famille en T pyramidal (base 3 + sommet central 1) | T pyramidal | Moyen | Seule "pyramide" viable a 4 jetons dans une grille carree |
| Grande Pyramide | 9 jetons meme famille (base 5 + milieu 3 + sommet 1, centres sur une meme colonne) | Pyramide large | Tres dur | Forme spectaculaire, tres gros investissement de placement |
| Bloc | Carre 3x3 plein meme famille | 3x3 plein | Tres dur | Gros investissement, gros mult |
| Bastion | Rectangle 2x3 plein meme famille | 2x3 | Moyen | Intermediaire entre 2x2 et 3x3 |
| Couronne | 8 jetons meme famille formant un anneau autour d'un jeton central non-matchant (rock ou jeton d'une autre famille) | 3x3 creux | Tres dur | Le centre peut etre un rock (garanti) ou tout jeton qui ne matche pas la regle. Forme signature qui donne un role structurel aux rocks. |
| Orbite | 4 jetons meme famille en losange autour d'un jeton central non-matchant | Diamant | Dur | Version compacte de Couronne |
| Croisee | 4 jetons meme famille en plus (+) autour d'un jeton central non-matchant | Plus 5 | Dur | 4 voisins orthogonaux d'un centre non-matchant |

### Nouvelles propositions — interaction avec les mecaniques

| Nom | Regle | Forme | Diff. | Notes |
|---|---|---|---|---|
| Racine | 3+ alignes dont au moins un jeton adjacent a un rock | Ligne 3+ | Moyen | Valorise les rocks sans les exiger |
| Ancre | 3+ alignes sur la ligne du bas | Ligne 3+ horizontale | Facile | Incite a remplir la base |
| Sommet | 3+ alignes sur la ligne du haut | Ligne 3+ horizontale | Dur | Prise de risque (proche du game over) |
| Hold Chain | 3+ alignes incluant le jeton qui vient de sortir du hold | Ligne 3+ | Moyen | Synergie avec le slot de hold |
| Cascade Master | 3+ alignes declenches pendant une cascade (niveau ≥ 2) | Ligne 3+ | Dur | Recompense les combos |
| Mur lateral | 3+ alignes touchant un bord lateral (gauche ou droit) | Ligne 3+ | Moyen | Jeu de placement en bordure |

---

## Questions ouvertes

- **Autorise-t-on les formes au-dela des lignes et 2x2 ?** La decision verrouillee dans `CLAUDE.md` les interdit toutes. L'esprit de la regle visait les chaines libres (L, T, zigzag) pour leur manque d'identite, pas les geometries specifiques et reconnaissables. A trancher si on veut developper les Pyramides, 3x3, etc.
- **Les formes creuses (3x3 anneau, Plus, Diamant) demandent un centre occupe par un jeton non-matchant.** Tranche : n'importe quel jeton qui ne participe pas a la regle du Tag fait l'affaire — rock (garanti) ou jeton d'une autre famille/valeur. Le centre n'est pas consomme par la resolution. Les rocks restent interessants parce qu'ils sont la version "sans risque" (permanents, toujours disponibles).
- **Combien de Tags par axe de regle ?** Si on decline chaque regle sur chaque forme (et sur chaque taille de ligne), le pool explose artificiellement et chaque Tag se ressent moins unique. Il faut probablement se limiter a 2-3 declinaisons par regle max.
- **Double matching** : un meme alignement peut-il trigger plusieurs Tags equipes simultanement ? Deja pose dans `03-patterns.md`, a tester au proto.
- **Tags "meta" qui modifient d'autres Tags** ? Ex : "Amplificateur — doubler le mult du prochain Tag declenche ce tour". Frontiere floue avec les Badges, probablement a garder cote Badges.
- **Taille minimum d'un pool jouable** : quel est le seuil en dessous duquel la rejouabilite devient plate ? 15 ? 20 ? Impossible a trancher sans playtest, mais utile a avoir en tete comme cible.

---

## Principes de design pour selectionner les Tags du pool final

Quand viendra le moment de choisir lesquels des Tags ci-dessus entrent dans le pool officiel, critere par critere :

1. **Identite claire** — on doit pouvoir decrire le Tag en une phrase et le reconnaitre sur la grille en un coup d'oeil
2. **Comportement distinct** — deux Tags qui produisent le meme feeling en jeu, on en coupe un
3. **Courbe de difficulte variee** — un bon pool a ses Tags faciles (filet de demarrage), moyens (cœur du jeu) et durs (recompenses de build avance)
4. **Synergies avec d'autres systemes** — un Tag qui interagit avec rocks, hold, cascades ou etats de jetons est plus precieux qu'un Tag isole
5. **Pas de doublons par declinaison** — eviter "Trio couleur", "Quatuor couleur", "Quintet couleur" comme 3 Tags separes. Si la progression en taille est interessante, c'est via le level up, pas via des Tags distincts.
