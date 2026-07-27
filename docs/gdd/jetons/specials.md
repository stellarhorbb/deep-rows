# Les Jetons spéciaux

Les **outils** — coups d'éclat qu'on achète au shop et qu'on joue au bon moment.

**Usage unique à l'utilisation, achat persistant tant qu'il n'est pas joué** (session 15). Un spécial acheté reste dans le deck manche après manche jusqu'à être réellement posé sur la grille — il n'est jamais reperdu "gratuitement" à la fin d'une manche où le joueur ne l'a pas utilisé. La seule façon d'en obtenir un autre est d'en racheter au shop. Le joueur peut en acheter 2-3 pour une manche qu'il sent chaude — ils sont volontairement peu chers et jetables.

## Principes

- Pas de famille ni de chiffre — ils ne participent pas aux [patterns](../partitions/principe.md) (un spécial ne peut jamais lui-même faire partie d'une figure matchée par une Partition)
- Ce sont des **outils** qui modifient la grille ou le contexte
- **Nuance session 25** — certains spéciaux réactifs (voir plus bas) peuvent désormais scorer, mais uniquement en amplifiant une résolution de Partition déjà valide (déclenchée par une vraie figure ailleurs sur la grille) — jamais en devenant eux-mêmes une figure. Le pilier "sans Partition équipée, une figure ne se résout pas" reste intact
- Doivent être assez impactants pour justifier l'achat
- Le joueur les time — LE bon moment dans LA bonne manche

## Spéciaux implémentés (proto)

| Nom | Type | Effet |
|---|---|---|
| **Bombe** | Instantané | Détruit une zone 3×3 autour de sa cellule d'impact |
| **Fantôme** | Posé | Traverse toute la colonne, pousse les jetons vers le haut et laisse un résidu en row 0 |
| **Marée** | Instantané | Pousse la ligne autour du point d'impact vers la gauche et la droite |
| **Enclume** (session 22) | Instantané | Pousse le premier jeton sur lequel elle tombe (le sommet de la colonne) tout au fond de la grille |
| **Pétard à mèche** (session 22) | À retardement | Se pose sur la grille avec un countdown de 3 tours (sprite qui clignote rouge/noir, chiffre affiché — même traitement que l'entity-skull de Mèche Courte) ; explose en scorant (valeur brute, sans multiplicateur) les jetons scorables à gauche et à droite, puis disparaît. Explose aussi immédiatement au [Dernier Souffle](../manche/dernier-souffle.md) s'il n'a pas fini son countdown |
| **Cavalier** (session 22) | Mobile (mangeur) | Se déplace 3 fois en L (mouvement d'échecs), destination tirée au hasard parmi les cases valides ; case occupée = mange le jeton (score sa valeur brute, sans multiplicateur, si scorable) au lieu de le décaler ; case vide = rien à manger ce coup-là ; disparaît après 3 déplacements |
| **Frog** (session 22) | Mobile (mangeur) | Saute 5 fois en diagonale haut-gauche ou haut-droite (tirée au hasard) ; même règle de case occupée/mangée que Cavalier ; disparaît après 5 sauts |
| **Liane** (session 22) | Mobile (mangeur) | Grandit d'une case vers la droite à chaque tour pendant 3 tours (s'arrête si elle atteint le bord droit, mais le minuteur continue) ; mange et score la case sur laquelle elle pousse si occupée ; fane et disparaît entièrement (tête + segments) au bout des 3 tours |
| **Crow** (session 22) | Mobile (déménageur) | Ne fait rien le premier tour ; au tour suivant, vole un jeton scorable au hasard sur sa ligne et le redépose (drop normal, sans le scorer) au sommet de sa propre colonne, puis disparaît |
| **Underground** (session 22) | Mobile (déménageur) | Creuse d'une case vers le bas à chaque tour (échange de position avec la case juste en dessous, qui remonte, sans scorer) ; se pose visiblement au fond de la colonne un tour, puis disparaît au suivant |
| **Hypercube** (session 22) | Réactif | Si une Partition score en touchant au moins une de ses 8 cases voisines, duplique un jeton scoré au hasard à son propre emplacement (qui disparaît) — le duplicata rejoint aussi le pool de boutons pour toute la fin de la run (même mécanisme que la légendaire Last Trick) |

## Quatre types de comportement

- **Instantanés** — effet immédiat à l'impact, ne restent pas sur la grille
- **Posés** — effet persistant pour la manche, disparaissent au [Dernier Souffle](../manche/dernier-souffle.md) (bonus + explosion)
- **À retardement** (session 22) — le jeton lui-même reste sur la grille, décompte tour après tour, explose de lui-même à 0 (ou immédiatement au Dernier Souffle s'il n'a pas fini) — voir `GridManager.tick_special_countdowns`
- **Mobiles/réactifs** (session 22) — le jeton reste sur la grille et agit tour après tour (déplacement, croissance, vol) ou réagit au score d'une Partition à proximité, jusqu'à sa propre disparition — voir `GridManager.tick_mobile_specials`. Deux familles distinctes chez les mobiles : les **mangeurs** (Cavalier, Frog, Liane) mangent et scorent ce qu'ils traversent — un usage délibéré, on choisit où les poser pour dégager un coin précis tout en marquant des points — et les **déménageurs** (Crow, Underground) ne font que réarranger la grille, jamais de score. Disparaissent silencieusement (sans scoring) au Dernier Souffle s'ils sont encore actifs, y compris les mangeurs — pas de dernière bouchée gratuite

## Spéciaux réactifs — famille identifiée (session 25)

Extension du type **Réactif** déjà amorcé par Hypercube (voir tableau ci-dessus) : des spéciaux posés qui ne scorent jamais tout seuls, mais amplifient ou modifient ce qui se passe quand une **Partition score en les touchant**. Le déclencheur reste toujours "figure + [Partition équipée](../partitions/principe.md)" — inchangé, pilier intact — ces spéciaux ne font que démultiplier la conséquence d'une résolution déjà légitime. Nés d'une réflexion sur la rareté des cascades : un seul match qui balaie soudain une grosse portion de la grille (via un réseau Électrique ou Résine) maximise les chances qu'une nouvelle figure se reforme après la gravité, sans jamais court-circuiter le choix de Partitions du joueur.

Statut **idea** (Google Sheet, onglet Spéciaux) — rien d'implémenté.

| Nom | Rareté | Effet |
|---|---|---|
| **Électrique** | Rare | Propage un réseau électrique aux jetons de même famille à son contact (instantané). Si une Partition qui score touche un jeton du réseau, tout le réseau se résout avec — valeur brute ajoutée aux tickets |
| **Cristal** | Uncommon | S'il touche un Rock, le transforme en jeton de famille aléatoire, valeur 1, pour la manche |
| **Diamant** | Epic | Cousin du Cristal — transforme les Rocks touchés en jetons de famille aléatoire, valeur 9 (pas 10, même logique que [Last Trick](../partitions/catalogue-implemente.md) : un plafond volontairement sous le vrai max mérité par la Fusion) |
| **Amplificateur** | Uncommon | Surveille ses 4 cases orthogonales (haut/bas/gauche/droite) ; si une Partition qui score en touche une, double le score de cette résolution |
| **Comète** | Epic | Traverse toute une diagonale en une seule fois et score tout ce qu'elle croise — rejoint en fait la famille **Instantané** existante (Bombe/Marée/Enclume), pas les Réactifs : score direct à l'impact, sans passer par une Partition |
| **Siphon** | Rare | Aspire et score les jetons au-dessus et en-dessous à chaque drop, jusqu'à ce que la colonne soit vide — rejoint la famille **Mobile (mangeur)** existante (Cavalier/Frog/Liane). À surveiller : contrairement à ses cousins (limite fixe en nombre de coups), sa durée dépend entièrement du remplissage de la colonne au moment où il est posé — swing potentiellement plus fort qu'un "rare" habituel, à valider en playtest |

**Écartés en session 25** (raisons notées pour ne pas les rouvrir sans nouvel angle) :
- **Rouille** — variante négative de l'Électrique (retire de la valeur au lieu d'en ajouter). Un négatif pur dans un pool de spéciaux *achetables* est du contenu mort, personne ne le choisit jamais — contrairement aux cases mystère ou aux malus de boss, subis et non choisis
- **Domino** — censé "forcer un recheck de cascade" ; en fait redondant avec ce que `CascadeResolver` fait déjà automatiquement après toute résolution
- **Résine** — glu qui fige la gravité. Deux versions tentées, deux angles morts différents : (1) un tas qui tombe groupé n'a pas plus de chances de former une figure valide qu'un tas qui tombe étape par étape, zéro gain réel de cascade ; (2) une variante "gèle toute une ligne pour construire une figure sur mesure" s'est heurtée au fait que le joueur ne contrôle pas quel jeton atterrit sur quelle rangée (dépend de la hauteur de chaque colonne au moment du drop), donc inutilisable sans la bonne Partition équipée ET la bonne hauteur de grille au bon moment. Pas jeté définitivement — à reprendre si un angle qui évite ces deux pièges se présente

## Catalogue futur

Pistes brainstorm restantes : Transformateur, Gravité inversée, Abîme, Prisme, Ancre, Corrosif, Dualité, Cactus, Poudrière.

Catalogue complet (statut + idées + prix) dans le [Google Sheet](https://docs.google.com/spreadsheets/d/1JMEQf2W6H8fMZ24D63-jRQrJKz5424kR7Exyo4xvM_0/edit) (onglet Jetons spéciaux), source de vérité depuis le 2026-07-10.

## Achat au shop

Vendus par les [grenouilles orchestre](../univers/personnages/grenouilles-orchestre.md), dans le [contenant générique](../shop/packs.md) commun à toutes les catégories — à l'unité ou en pack (3 choix, tu en gardes 1). Très accessibles parce que jetables.

**Rareté (session 23)** — jusque-là tirés uniformément, les Spéciaux gagnent le même système de rareté pondérée que les Badges/Dés à coudre (`GameRules.RARITY_WEIGHTS`), pour que le prix reflète l'accessibilité plutôt que la seule puissance :

| Rareté | Poids | Prix | Spéciaux |
|---|---|---|---|
| Common | 10 | 2 | Bombe, Enclume, Fantôme, Marée |
| Uncommon | 5 | 2 | Underground, Pétard à mèche, Crow, Liane |
| Rare | 2 | 3 | Cavalier, Frog |
| Epic | 1 | 4 | Hypercube |

Hypercube (le plus lourd des spéciaux, seul à interagir en direct avec le scoring) descend de 5 à 4 mouches — sa rareté porte maintenant l'essentiel de son coût, pas son prix d'achat.

## Liens

- [Boutons](boutons.md)
- [Rocks](rocks.md)
- [Dernier Souffle](../manche/dernier-souffle.md)
- [Shop — packs](../shop/packs.md)
- [Shop — économie](../shop/economie.md)
