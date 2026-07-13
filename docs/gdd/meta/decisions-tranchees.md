# Décisions tranchées — source de vérité

Le registre des décisions de design qui ne sont plus à rediscuter, sauf à l'expliciter.

## Univers

| Question | Décision | Raison |
|---|---|---|
| **Pitch** | ["Un garçon se retrouve malgré lui dans un monde halluciné"](../univers/pitch.md) | Justifie la boucle et le bizarre, laisse ouvert le qui/pourquoi/quoi |
| Direction artistique | [Univers d'auteur, ton conte bizarre, hand-drawn](../univers/direction-artistique.md) | Différenciateur + signature d'auteur |
| [Ton](../univers/ton.md) | Cute-dérangeant, double lecture enfant/adulte | Déjà dans l'ADN Thomas (Licky's Escape) |
| [Boucle narrative](../shore/boucle-narrative.md) | Le run raté fait partie de l'histoire (modèle Hades) | Structure roguelite justifiée narrativement |

## Jetons

| Question | Décision | Raison |
|---|---|---|
| [Jetons de base](../jetons/boutons.md) | **Boutons** | Familier dans un monde qui ne l'est pas, double lecture |
| [Familles](../jetons/boutons.md) | **4 familles** en code (`CORAL/SHELL/RUST/INK`, la 4e ajoutée session 12). Nommage thématique Bone/Wood/Brass toujours pas appliqué au code | Passé de 3 à 4 pour que le matching famille-seule (voir "Résolution par valeur" ci-dessous) ne soit pas trivial |
| [Résolution par valeur](../partitions/axes-de-regles.md) | **Désactivée** (session 12) — seules famille et rock résolvent des patterns, la valeur est un pur levier de score | Lisibilité (scan couleur plutôt que lecture de chiffres) + a mécaniquement augmenté la fréquence des cascades |
| [Persistance](../grille/gravite-resolution.md) | Disparaissent après résolution | Plus dynamique, la grille vit |
| [Spéciaux](../jetons/specials.md) | **Achat persistant** — reste dans le deck manche après manche tant qu'il n'est pas réellement joué, seul le shop en remet (révisé session 15 : consommés uniquement à la manche suivante à l'origine, corrigé après qu'un Marée acheté ait disparu du hold sans avoir été joué) | Accessibles, le joueur en prend 2-3 pour une manche chaude |
| [Spéciaux — format](../jetons/specials.md) | **Jetons du deck** (pas items consommables) | Garde l'ADN puzzle-drop "tout tombe". Hold slot porte la tension du timing tactique |
| [Rocks](../jetons/rocks.md) | Explosent au Dernier Souffle | Placement stratégique pour fin de manche |
| [États de jetons](../jetons/etats-reserve.md) | **Réserve** — déprioritisé | Risque de lisibilité avant d'avoir testé les autres couches |
| [Pool de boutons de départ](../jetons/boutons.md) | **Structuré** (session 13) — 2 exemplaires de chaque (famille, valeur), 40 boutons au total, pas de tirage aléatoire | Un mauvais tirage random pouvait saboter une Partition équipée sans faute du joueur — contraire au principe "pas de RNG punitif" |

## Grille et partitions

| Question | Décision | Raison |
|---|---|---|
| [Pattern Tags](../partitions/principe.md) | **Partitions musicales** (nom thématique) | Vendues par les grenouilles, géométrie dessinée |
| [Level up Partitions](../partitions/level-up.md) | **Pianissimo → Piano → Forte → Fortissimo → Maestro**, puis des "dan" sans plafond au-delà de Maestro (session 16, formule des incréments pas encore tranchée) | Cohérent avec grenouilles orchestre. Le plafond dur à Maestro payait mal un investissement proche du budget de score d'un run entier ; les dan donnent une vraie destination au [mode infini](../progression/structure-run.md#mode-infini) |
| Minimum pour scorer | 3 connectés | Les paires sont trop faciles |
| Slots de Partitions | 4 max | Force à choisir quoi résoudre |
| [Scoring lignes](../partitions/scoring.md) | **Révisé session 16** : multiplicateur fixe par Partition (implémenté, `cascade_resolver.gd` + `.tres`), remplace l'ancien multi par direction (v=x1, h=x1.5, d=x2) | L'axe directionnel en plus de cascade/modifiers/rule/level up/global/value bonus rendait la formule illisible et compliquait le balancing (calibrer un mult sur 3 valeurs au lieu d'une) |
| [Scoring autres formes](../partitions/scoring.md) | Multi fixe sur la Partition | Chaque forme a son ratio risque/récompense |
| [Modifiers de cellules](../grille/modifiers-cellules.md) | 4 types (HALF, BOOST, DOUBLE, TRIPLE), plusieurs sources prévues | Couche séparée, extensible. HOB-11 pour l'override |
| Jeton scorant plusieurs Partitions | **Oui**, un même jeton peut valider plusieurs formes simultanément | Encourage les placements malins, cœur du plaisir |
| Feedback figure non résolue (pas de Partition équipée) | **Pas de highlight** — l'absence de résolution est le signal | Ajouter un highlight pollue la lecture de la grille |
| Taille de grille | **7×7** actuellement (`COLS`/`ROWS`), pas encore de choix de classe | Passée de 6×8 à 7×7 en session 12 pour équilibrer la densité de la grille cabossée |
| [Grille cabossée](../grille/trous.md) | 5-8 trous aléatoires par manche, jamais en row 0, transparents à la gravité (contrairement à un Rock) | Casse la routine sans réintroduire un plateau plein façon Candy Crush (piste testée et abandonnée en session 12) |
| [Sélection de Partition de départ](../partitions/principe.md) | 3 tirées au hasard dans tout le catalogue, le joueur en choisit **2, gratuites** | 1 seule s'est révélée trop punitive au playtest (entrée en jeu ruinée si elle ne matche jamais) |
| [Vente de Partitions/Badges](../partitions/principe.md) | À tout moment, 50% du prix remboursé, aucun plancher | Respec toujours possible, façon Balatro |
| [Formes de Partitions](../partitions/formes.md) | 7 primitives (session 13 : +Plus, +Cross, +Ring, +T — le veto initial sur le T levé) | Le T avait été banni faute d'identité visuelle claire ; retenu une fois qu'un vrai usage (tétromino, orientation libre) s'est dégagé |
| [Chevauchement de figures — Double Partition](../partitions/scoring.md) | Inclusion totale d'un groupe dans l'autre (mêmes jetons, ex: T entièrement contenu dans Plus) → seule la mieux payée compte. Chevauchement partiel sans inclusion (au moins 1 cellule commune, ex: Square Rainbow + Brelan) → les deux scorent, total combiné x`GameRules.PATTERN_COMBO_MULTIPLIER` (2 actuellement), bannière dédiée "DOUBLE PARTITION" | session 13 : 1 cellule commune = deux figures distinctes qui convergent sur le jeton qu'on vient de poser (combo délibéré, à récompenser) ; révisé session 15 après un cas réel (Square Rainbow + Brelan, 2 cellules communes) où le simple compte de cellules partagées écrasait un vrai combo — le critère devient structurel (inclusion vs chevauchement partiel) plutôt qu'un seuil numérique, et le combo gagne un vrai bonus au lieu d'une simple addition silencieuse |
| [Anti-synergie de Partitions imbriquées](../partitions/catalogue-implemente.md) | **Pas de règle d'exclusivité** — équiper à la fois une petite forme et une forme qui la contient entièrement (T + Plus, Ligne 3 + Ligne 4...) rend la petite quasi-inévitable et la grande quasi-inatteignable (résolution immédiate à chaque tour, verrouillée) ; au joueur de le repérer et de vendre au besoin | Cohérent avec "base simple, pas de règles empilées" — la vente à tout moment existe déjà et suffit à corriger le choix |
| [Extension du catalogue Partitions (session 14)](../partitions/axes-de-regles.md) | **Rainbow** ajouté à l'axe famille, plafonné aux formes de taille 4 (Square/Diamond/Line 4 — 4 familles max, pas plus). **Duo/Alternance écartés** (pas de template visuel unique sans logique de matching dédiée par forme). **Axe chiffre réactivé** sous vocabulaire casino (Suite/Brelan/Carré/Fibonacci) confiné à la Ligne uniquement — jamais sur Carré/Losange/Plus/Cross/Ring/T. **Fibonacci fixé à 1,1,2,3** (pas générique). Tiroir "rare/signature" ouvert (9999/Jackpot, paires de familles figées) hors pool régulier | Le catalogue de formes (7 primitives) était épuisé pour créer de nouvelles Partitions ; le vrai levier restant est l'axe de règle, pas la géométrie. Confiner le chiffre à la Ligne évite de rouvrir le problème de lisibilité de la session 12 (family-only) tout en gardant les deux vocabulaires (forme géométrique vs poker) mentalement séparés pour le joueur |
| [Diamond Rock ne consomme que le centre (session 15)](../jetons/rocks.md) | Seul le jeton central est retiré de la grille et scoré. Les 4 rocks du losange ne sont jamais supprimés — ils restent en jeu comme des rocks normaux | Les rocks régénèrent à chaque manche (`DECK_ROCK_COUNT`), mais doivent aussi rester disponibles pour exploser au [Dernier Souffle](../manche/dernier-souffle.md) — les détruire à chaque récolte les priverait de ce rôle. Correction d'un design initial erroné qui supprimait les 4 rocks à chaque récolte |
| [Roll casino sur Diamond Rock (session 15)](../jetons/rocks.md) | Score = (valeur du centre + roll 1-5) × multiplicateur du tag, roll révélé par une animation de roulette dédiée. Scopé à Diamond Rock uniquement pour l'instant, pas de système générique | Diamond Rock demande un vrai effort de placement (4 rocks + un centre de valeur alignés) et, une fois la récolte faite, la gravité rend quasi impossible de la refaire immédiatement sur les mêmes rocks — un score qui dépend entièrement de la valeur (1-5) du jeton central serait une pure loterie sur un coup déjà difficile à mettre en place. Le roll garantit un plancher correct tout en gardant un moment casino excitant. Généralisation à d'autres Partitions volontairement différée — voir [Questions ouvertes](questions-ouvertes.md) |

## Manche et deck

| Question | Décision | Raison |
|---|---|---|
| [Reshuffle](../manche/deck.md) | **Non**, un seul passage par manche | Sinon on peut jamais perdre |
| [Défausse](../manche/deck.md) | **Non** (sauf Badge rare) | Serait spammée pour chercher les spéciaux |
| [Pioche](../manche/stream-hold.md) | Stream jeton-par-jeton + 1 slot de hold | Colle à l'ADN cascade. Slot upgradable via Badge |
| [Condition de défaite](../progression/defaite.md) | Deck vide + score pas atteint = game over | Simple, brutal, clair |
| [Persistance du pool de boutons](../manche/deck.md) | Le pool suit le joueur toute la run, pas de régénération aléatoire par manche | Donne un sens durable à l'achat et à la fusion |
| [Fusion de boutons](../jetons/boutons.md) | 2 boutons, famille libre → 1 ; valeur = somme (**plafonnée à 10**), famille = random entre les deux entrées | Levier "slim" opposé à l'achat ; le plafond évite la fuite en avant maintenant que la valeur est un pur levier de score |
| [Sélection de fusion](../jetons/boutons.md) | Tirage random de 8-10 boutons du pool, pas accès libre à tout le deck | Cohérent avec le shop RNG-forward ; évite que la fusion devienne un calcul d'optimisation |
| [Accès à la fusion](../jetons/boutons.md) | **Gaté** derrière l'achat d'un item "Dés à coudre", une fusion par achat | Sans plafond, la fusion était trop facile à spammer pour gonfler les chiffres sans limite |
| [Outils de deck (session 16)](../jetons/boutons.md) | Le Dés à coudre généralise la Fusion en 9 actions pondérées par rareté (Augmenter/Réduire, 4× Changer de famille, Scinder, Fusionner, Suppression) — 3 tirées, actions et 8 cibles affichées ensemble, sélectionner des boutons active/désactive les actions, cliquer une action l'applique direct | Comble un trou repéré en remplissant la Sheet des Badges (rien ne touchait au deck/aux jetons) ; voir [Brainstorm](../../brainstorms/brainstorm-outils-deck.md) |
| [Suppression et Scinder (session 16)](../jetons/boutons.md) | Suppression = Rare (le plus fort, vu le sans-reshuffle qui améliore les probas de tout le tirage restant). Scinder = uniquement les valeurs paires, split exact moitié-moitié | Suppression casse la logique "no RNG punitif" dans l'autre sens (avantage le joueur au lieu de le pénaliser), d'où sa rareté ; Scinder pair-only évite une répartition arbitraire sur les valeurs impaires |
| [Inspecteur de deck](../manche/inspecteur-deck.md) | Comptes agrégés visibles, ordre de tirage caché | Le seul-passage-sans-reshuffle serait punitif sans lui ; révéler l'ordre tuerait la tension du stream |

## Badges

| Question | Décision | Raison |
|---|---|---|
| [Nom thématique](../badges/principe.md) | **Badges** (objet physique) | Collectionnable, thématique forte |
| Slots max | 5 | Assez pour synergies, pas trop pour lisibilité |
| [Archi](../badges/principe.md) | Option B — un script par badge | Extensible sans toucher au core |
| [État persistant des Badges](../badges/triggers.md) | `RunManager.get_badge_state`/`set_badge_state` (clé libre par badge, reset chaque manche) | Débloque les Badges à compteur (Régularité, Un Pour Tous) malgré `BadgeEffect` instancié à neuf à chaque dispatch |
| [Indicateur de progression](../badges/badges-implementes.md) | `BadgeEffect.get_progress_text()`, virtuelle, affichée au survol dans `BadgesUI` | Un Badge à compteur illisible sans savoir où on en est |
| [Trigger `on_round_end` (session 16)](../badges/triggers.md) | Nouveau 6e trigger, branché sur `TurnController.round_won`. `BadgeManager._dispatch` retourne le detail des mouches ajoutées par badge (diff avant/après chaque effet) | Premier consommateur : Pourboire, deplacé de `on_round_start` pour apparaître sur l'écran de récompense de fin de manche (YouWinUI) plutôt qu'en silence au début |

## Shop

| Question | Décision | Raison |
|---|---|---|
| [Tenanciers](../univers/personnages/grenouilles-orchestre.md) | **Grenouilles orchestre** | Constante du monde, logique interne (elles mangent des mouches) |
| [Monnaie shop](../progression/monnaies.md) | **Mouches** | Logique interne avec les grenouilles |
| [Monnaie progression](../progression/monnaies.md) | **Tickets** | Donne accès aux zones |
| [Shop v2](../shop/offre-mixte.md) | **Implémenté** (session 12, ex-HOB-13) — 2 packs fixes + 2 unitaires "en vitrine" rerollables | Doser RNG et agence, éviter l'inflation de choix ; les packs ne rerollent jamais (comme Balatro) |
| [Contenants de packs](../shop/packs.md) | **Un seul contenant générique** pour toutes les catégories (pas 4 objets/gestes distincts) | Pas de DA à valider avant que la boucle mécanique soit jugée solide — habillage distinct reportable sans toucher aux données |
| [Taille des packs](../shop/packs.md) | 3 choix, **exception boutons : 5 choix** | Boutons plus nombreux et moins déterminants individuellement |

## Structure run

| Question | Décision | Raison |
|---|---|---|
| [Entity](../univers/personnages/entity.md) | [Jeton entity-skull](../jetons/entity-skull.md) tous les 6 tours | Perturbe sans jouer, brise le stacking pur |
| Manches par zone | 3 aujourd'hui, **chantier session 16** (probablement plus, avec une manche boss incluse) | Bon rythme au proto, mais l'ajout d'un boss par zone remet ce chiffre en question |
| Zones par run | 4, deviennent des **biomes** à forte identité (session 16) | 12 manches totales au format actuel, run complet en ~30-40 min — chiffre pas figé, voir ligne ci-dessus |
| [Ordre des biomes](../progression/structure-run.md#biomes) | **Fixe**, jamais aléatoire (session 16) | Cohérent avec le pilier narratif "la descente" (zone 1 familière → zone finale totalement étrangère) — n'a de sens que si la position dans la séquence est stable. Modèle Hades : ordre macro fixe, contenu randomisé à l'intérieur |
| [Boss de zone](../progression/structure-run.md#boss-de-zone) | Manche qui referme chaque biome, contrainte tirée d'un **pool global et aléatoire** (pas spécifique au biome), façon Balatro (session 16) | Garde la surprise "chaque run est différente" ; justifié narrativement par l'Entity, persistante sur toute la run et pas rattachée à un biome |
| [Grille](../grille/format.md) | Liée au **biome** traversé, pas un choix de départ (session 16, revient sur la vision d'origine "grille = classe") | Le rôle de "classe" façon Balatro est repris par le pack de boutons ; la grille sert l'identité de lieu, découverte en progressant |
| Pack de boutons | Fixe pour le run, améliorable. Devient le **vrai choix de départ façon "deck" Balatro** (session 16), choisi parmi les packs débloqués au Shore | Comme une classe, garde son identité — résout l'ancienne question ouverte "decks de départ façon Balatro" |
| [Mode infini](../progression/structure-run.md#mode-infini) | Optionnel, proposé après le boss de la zone 4 ("you win" → continuer), difficulté croissante jusqu'au game over inévitable (session 16) | Donne une vraie destination aux systèmes sans plafond (dan de level up, courbe de score cible exponentielle) qui servent peu dans une campagne à durée bornée |
| [The Shore](../shore/principe.md) | Meta-progression (unlocks), nom placeholder | Plus simple que du craft pendant le run |
| [Contenu débloqué par biome](../shore/unlocks.md) | Trois niveaux d'accès — générique (dispo dès le départ), thématique/biome (débloqué en atteignant le biome, permanent ensuite), achievement/découverte (débloqué par un exploit, permanent ensuite) (session 16) | Prolonge le pilier "Découvertes" déjà envisagé pour le Shore ; donne un sens à la progression dans les biomes au-delà du pur score |

## Liens

- [Questions ouvertes](questions-ouvertes.md)
- [Tickets Linear HOB-*](https://linear.app/hobbes-game/team/HOB)
