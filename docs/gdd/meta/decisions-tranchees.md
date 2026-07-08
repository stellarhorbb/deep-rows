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
| [Spéciaux](../jetons/specials.md) | **One-shot** — consommés à la manche suivante | Accessibles, le joueur en prend 2-3 pour une manche chaude |
| [Spéciaux — format](../jetons/specials.md) | **Jetons du deck** (pas items consommables) | Garde l'ADN puzzle-drop "tout tombe". Hold slot porte la tension du timing tactique |
| [Rocks](../jetons/rocks.md) | Explosent au Dernier Souffle | Placement stratégique pour fin de manche |
| [États de jetons](../jetons/etats-reserve.md) | **Réserve** — déprioritisé | Risque de lisibilité avant d'avoir testé les autres couches |
| [Pool de boutons de départ](../jetons/boutons.md) | **Structuré** (session 13) — 2 exemplaires de chaque (famille, valeur), 40 boutons au total, pas de tirage aléatoire | Un mauvais tirage random pouvait saboter une Partition équipée sans faute du joueur — contraire au principe "pas de RNG punitif" |

## Grille et partitions

| Question | Décision | Raison |
|---|---|---|
| [Pattern Tags](../partitions/principe.md) | **Partitions musicales** (nom thématique) | Vendues par les grenouilles, géométrie dessinée |
| [Level up Partitions](../partitions/level-up.md) | **Pianissimo → Piano → Forte → Fortissimo → Maestro** | Cohérent avec grenouilles orchestre |
| Minimum pour scorer | 3 connectés | Les paires sont trop faciles |
| Slots de Partitions | 4 max | Force à choisir quoi résoudre |
| [Scoring lignes](../partitions/scoring.md) | Multi par direction (v=x1, h=x1.5, d=x2) | Punit le stacking vertical sans l'interdire |
| [Scoring autres formes](../partitions/scoring.md) | Multi fixe sur la Partition | Chaque forme a son ratio risque/récompense |
| [Modifiers de cellules](../grille/modifiers-cellules.md) | 4 types (HALF, BOOST, DOUBLE, TRIPLE), plusieurs sources prévues | Couche séparée, extensible. HOB-11 pour l'override |
| Jeton scorant plusieurs Partitions | **Oui**, un même jeton peut valider plusieurs formes simultanément | Encourage les placements malins, cœur du plaisir |
| Feedback figure non résolue (pas de Partition équipée) | **Pas de highlight** — l'absence de résolution est le signal | Ajouter un highlight pollue la lecture de la grille |
| Taille de grille | **7×7** actuellement (`COLS`/`ROWS`), pas encore de choix de classe | Passée de 6×8 à 7×7 en session 12 pour équilibrer la densité de la grille cabossée |
| [Grille cabossée](../grille/trous.md) | 5-8 trous aléatoires par manche, jamais en row 0, transparents à la gravité (contrairement à un Rock) | Casse la routine sans réintroduire un plateau plein façon Candy Crush (piste testée et abandonnée en session 12) |
| [Sélection de Partition de départ](../partitions/principe.md) | 3 tirées au hasard dans tout le catalogue, le joueur en choisit **2, gratuites** | 1 seule s'est révélée trop punitive au playtest (entrée en jeu ruinée si elle ne matche jamais) |
| [Vente de Partitions/Badges](../partitions/principe.md) | À tout moment, 50% du prix remboursé, aucun plancher | Respec toujours possible, façon Balatro |
| [Formes de Partitions](../partitions/formes.md) | 7 primitives (session 13 : +Plus, +Cross, +Ring, +T — le veto initial sur le T levé) | Le T avait été banni faute d'identité visuelle claire ; retenu une fois qu'un vrai usage (tétromino, orientation libre) s'est dégagé |
| [Chevauchement de figures](../partitions/scoring.md) | Tolérance de `GameRules.PATTERN_SHARED_CELL_TOLERANCE` (1) cellule partagée entre deux groupes du même tour — au-delà, seule la mieux payée compte | 1 cellule commune = deux figures distinctes qui convergent sur le jeton qu'on vient de poser (combo délibéré, à récompenser) ; plus que ça = une figure qui en avale une autre (ex: T entièrement contenu dans Plus, Ligne 3 dans Ligne 4) — un simple doublon à ne pas sur-scorer |
| [Anti-synergie de Partitions imbriquées](../partitions/catalogue-implemente.md) | **Pas de règle d'exclusivité** — équiper à la fois une petite forme et une forme qui la contient entièrement (T + Plus, Ligne 3 + Ligne 4...) rend la petite quasi-inévitable et la grande quasi-inatteignable (résolution immédiate à chaque tour, verrouillée) ; au joueur de le repérer et de vendre au besoin | Cohérent avec "base simple, pas de règles empilées" — la vente à tout moment existe déjà et suffit à corriger le choix |

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
| [Inspecteur de deck](../manche/inspecteur-deck.md) | Comptes agrégés visibles, ordre de tirage caché | Le seul-passage-sans-reshuffle serait punitif sans lui ; révéler l'ordre tuerait la tension du stream |

## Badges

| Question | Décision | Raison |
|---|---|---|
| [Nom thématique](../badges/principe.md) | **Badges** (objet physique) | Collectionnable, thématique forte |
| Slots max | 5 | Assez pour synergies, pas trop pour lisibilité |
| [Archi](../badges/principe.md) | Option B — un script par badge | Extensible sans toucher au core |
| [État persistant des Badges](../badges/triggers.md) | `RunManager.get_badge_state`/`set_badge_state` (clé libre par badge, reset chaque manche) | Débloque les Badges à compteur (Régularité, Un Pour Tous) malgré `BadgeEffect` instancié à neuf à chaque dispatch |
| [Indicateur de progression](../badges/badges-implementes.md) | `BadgeEffect.get_progress_text()`, virtuelle, affichée au survol dans `BadgesUI` | Un Badge à compteur illisible sans savoir où on en est |

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
| Manches par zone | 3 | Bon rythme au proto |
| Zones par run | 4 | 12 manches totales, run complet en ~30-40 min |
| Pack de boutons | Fixe pour le run, améliorable | Comme une classe, garde son identité |
| [The Shore](../shore/principe.md) | Meta-progression (unlocks), nom placeholder | Plus simple que du craft pendant le run |

## Liens

- [Questions ouvertes](questions-ouvertes.md)
- [Tickets Linear HOB-*](https://linear.app/hobbes-game/team/HOB)
