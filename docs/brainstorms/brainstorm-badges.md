# Brainstorm — Badges & Triggers

**Statut** : bac a sable. Rien ici n'est tranche. C'est un dump d'idees pour ne pas les perdre, a piocher quand on construira le catalogue officiel de Badges.

Format libre. On ajoute, on rature, on regroupe au fil des sessions.

---

## Pourquoi ce fichier

Une fois qu'on pense **trigger** comme une variable independante de l'**effet**, le produit cartesien Trigger × Effet explose. C'est exactement la richesse qu'on cherche pour un roguelite : peu de mecaniques de base + beaucoup de modificateurs combinables = profondeur par les permutations, pas par l'empilement de regles.

Donc on liste les **triggers** (les conditions de declenchement) d'un cote, les **effets** de l'autre, et on melange.

---

## Triggers — categories en vrac

### Etat de la grille
- Grille pleine
- Grille vide / quasi-vide (< X jetons)
- Une colonne pleine
- Une ligne horizontale complete (style Tetris : tous les jetons d'une rangee sont remplis)
- N rocks sur la grille
- Aucune diagonale possible (tous les diags sont casses)
- Symetrie parfaite gauche/droite
- Une colonne entiere d'une seule famille
- Le jeton du haut d'une colonne est de famille X

### Position du jeton qui vient d'arriver
- Sur la derniere rangee (top de la grille)
- Sur la premiere rangee (bottom)
- Dans un coin
- Isole (aucun voisin)
- Entoure des 4 cotes
- A cote d'un rock
- A cote d'un Fantome residue
- Sur une cellule "speciale" (case marquee — pas encore dans le jeu)

### Au moment du drop
- Premier drop de la manche
- Dernier drop du deck
- Drop apres un Hold
- Sur une colonne deja remplie a moitie
- Sur la meme colonne 3 fois de suite
- Drop sur une colonne entierement vide
- Drop d'un jeton de meme famille que le precedent

### Pendant la resolution
- 3+ patterns dans la meme cascade
- Cascade de niveau 3+
- Pattern qui inclut un jeton de valeur 9
- Pattern qui touche un rock
- Pattern qui ne touche aucun bord
- Resolution sans toucher la rangee du bas
- Resolution qui touche les 4 familles
- Carre 2x2 score

### Compteurs / etat run
- N patterns scores ce run
- Aucun pattern famille de toute la manche (build "value pure")
- Aucun pattern value de toute la manche (build "famille pure")
- Score multiple de 100
- Cible atteinte avec exactement le score requis (perfect)
- Cible atteinte avec X drops restants
- Manche reussie sans utiliser de special
- N manches reussies d'affilee
- Sortie de zone (transition zone N → N+1)

### Negatifs / risque-recompense
- Trigger seulement si tu finis la manche avec moins de X drops restants
- Trigger seulement si tu n'as utilise aucun special
- Trigger seulement si tu as au moins 3 rocks sur la grille
- Trigger seulement si la grille est a plus de 80% pleine
- Trigger seulement si tu n'as pas hold ce tour

---

## Effets possibles (a etoffer)

### Score / multi
- +X au score
- +X au multiplicateur du prochain pattern
- Double le prochain pattern
- Tous les patterns scorent +1 cette manche

### Transformation
- Transforme un jeton en un autre
- Transforme tous les jetons d'une famille
- Convertit un rock en jeton aleatoire
- Convertit un Fantome residue en X

### Generation
- Genere un jeton special
- Genere un jeton de base
- Ajoute un rock (negatif)
- Ajoute une cellule speciale sur la grille

### Modification de regles
- Les diagonales scorent x2
- Les patterns horizontaux scorent x2
- Les carres 2x2 scorent x4 au lieu de x3
- Le minimum pour scorer passe a 2 (juste cette manche)
- Les rocks comptent dans les patterns famille
- Les jetons de valeur 1 sont wildcards

### Action
- Debloque une defausse pour cette manche
- Debloque un slot de hold supplementaire
- Permet de relancer un drop
- Permet de choisir le prochain jeton du stream

### Shop / hors-manche (nouvelle categorie, pas encore cablee)
Avec la [fusion de boutons](../gdd/jetons/boutons.md), le shop devient un moment ou des Badges pourraient se declencher aussi — necessiterait un trigger `on_fusion` distinct des 5 triggers actuels (tous bases sur `TurnController`, donc en-manche uniquement). A explorer si ce genre d'idee prend :
- Au moment d'une fusion
- A l'ouverture d'un bocal/recueil/malle/paquet
- Au reroll

### Cascade / chain
- Si cascade x2+, gagne X
- Chaque cascade ajoute un jeton bonus au deck pour la manche suivante
- Une cascade qui n'aurait rien donne genere un Badge numerique gratuit

---

## Idees de Badges complets (trigger + effet)

A remplir au fur et a mesure. Quelques exemples pour amorcer :

- **"Marée Haute"** : si tu remplis une ligne horizontale entiere → toute la ligne score comme un quatuor famille bonus
- **"Souffle court"** : a chaque manche reussie avec moins de 5 drops restants → +1 slot de hold pour la prochaine manche
- **"Patience"** : si tu hold le meme jeton 3 tours → quand tu le drop, il score x3
- **"Recif vivant"** : chaque carre 2x2 scoree laisse un rock a la place
- **"Ecume"** : tous les patterns qui touchent la rangee du bas scorent x1.5
- **"Vertige"** : si un pattern atteint la rangee du top, +50 au score
- **"Solitude"** : un jeton isole (aucun voisin) au moment du drop suivant declenche un mini-pattern (score sa valeur x3)
- **"Erosion"** : a chaque resolution, un rock adjacent au pattern est detruit
- **"Perfectionniste"** : finir une manche avec exactement le score cible → recompense doublee en Salt
- **"Choix du tailleur"** (trigger `on_fusion`, a cabler) : lors d'une fusion, la famille du resultat n'est plus random — elle prend toujours celle du bouton de valeur la plus haute (ou la plus basse, variante a departager)

---

## Piste — build "Dernier Souffle" (session 13)

`on_last_breath` est le seul des 5 triggers actuels sans aucun Badge qui le consomme — terrain vierge. Discuté après avoir traité le softlock "grille pleine" (qui bascule maintenant sur le Dernier Souffle, comme le deck vide) : ça ouvre la porte à un vrai archétype de build autour de la cascade finale plutôt que de la subir comme un filet de sécurité.

- **Multi dedie au Dernier Souffle** : un Badge qui pose un `global_multiplier` (meme mecanisme que Dernier Carre/Regularite) actif uniquement sur `on_last_breath` — transforme la cascade finale en vrai climax recherche plutot qu'un fallback
- **Plus de Rocks dans le deck** : un Badge qui ajoute des Rocks supplementaires — plus de matiere pour l'explosion du Dernier Souffle, synergise avec Diamond Rock / Collectionneur
- **"Bombe a retardement"** (deja notee comme idee reportee ailleurs dans le GDD) : les Bombes n'explosent plus a l'impact, elles attendent le Dernier Souffle — rejoint directement cette piste
- **Recompenser le softlock volontaire** : un Badge qui bonifie le fait de finir par "grille pleine" plutot que "deck vide" — inciterait a saturer la grille exprès comme strategie de fin de manche plutot que comme accident a eviter

Objectif de sensation vise par le user : un build "stressant dans le bon sens", ou le joueur construit consciemment vers ce moment plutot que de le craindre.

---

## Notes / questions ouvertes

- Combien de triggers actifs en meme temps un Badge peut-il avoir ? (Un seul ? Plusieurs ANDes ?)
- Faut-il un systeme de "cooldown" sur certains triggers pour eviter le spam ?
- Faut-il que certains Badges interagissent entre eux (chains de Badges) ou rester independants ?
- Comment communiquer visuellement quand un Badge se declenche ? (Pulse, popup, son)
- L'equilibrage : un Badge a trigger commun + petit effet, ou trigger rare + gros effet ?
