# Session 11 — Fusion de boutons, deck persistant, shop v2, level up des Partitions

**Date** : 2026-07-01
**Theme** : Reprise après ~2 mois de standby. Discussion de design sur le scaling (comparaison Balatro / Slay the Spire / Sol Cesto / Ball X Pit), qui a débouché sur une grosse session d'implémentation : deck de boutons persistant pour la run, fusion, shop refondu en 2 colonnes, inspecteur de deck, refonte visuelle des boutons, et enfin le level up des Partitions qu'on cherchait à valider depuis le départ.

---

## Discussion de design — scaling

Point de départ : est-ce que Partitions + Echoes + spéciaux suffisent à scaler une run entière ? Comparaison avec Balatro (Planet cards ≈ notre level-up, Jokers qui se multiplient entre eux), Slay the Spire (deck thinning comme leviers caché), Sol Cesto (les "dents" tordent les probabilités plutôt que le score brut), et Ball X Pit (3 échelles de temps de scaling en parallèle : fusion de boules, XP continue, passifs rares).

Constat qui a structuré toute la session : les Echoes actuels sont **4 îles isolées** — aucun ne lit l'état d'un autre système, et `set_rule_multiplier` écrase au lieu de cumuler (bug latent si deux Echoes visent la même rule un jour). Idées de contenu transversal notées dans `docs/brainstorms/brainstorm-echoes.md` (dont "Choix du tailleur", lié à un futur trigger `on_fusion`).

Deuxième axe identifié : les boutons ont des valeurs fixes (1-5), aucun levier pour les faire scaler. → discussion → **fusion de boutons** retenue comme mécanique (vs. système complet à la Tarot Balatro, jugé trop tôt vu que même la fusion seule n'était pas encore testée).

## Design de la fusion (voir GDD, déjà à jour)

- Deck de boutons **persistant pour toute la run** (plus de régénération aléatoire par manche)
- Achat au shop : unitaire (choix exact) ou bocal **5 choix** (exception à la règle des 3 des autres packs)
- Fusion : 2 boutons **de famille libre** → 1, valeur = somme, famille = tirée au hasard entre les deux entrées (déterministe si même famille au départ)
- Sélection de fusion : tirage random de **8-10** boutons du pool (pas accès libre à tout le deck) — élimine le risque de tirage sans paire valide
- Coût : **prix plat en mouches**, pas de prix croissant (le tirage random suffit comme frein anti-spam)

Tout ça est documenté dans `docs/gdd/jetons/boutons.md`, `docs/gdd/shop/`, `docs/gdd/meta/decisions-tranchees.md` et `questions-ouvertes.md` (montants exacts encore à tuner au playtest).

## Implémentation

**Deck persistant**
- `RunManager._button_pool` généré une fois à `init_run()`, `DeckManager.build_deck()` clone depuis ce pool au lieu de randomiser à chaque manche

**Shop v2 — deux colonnes**
- Colonne A : 3 Partitions+Echoes mélangés (hors déjà possédés)
- Colonne B : 2 boutons unitaires random + 2 spéciaux random + bloc Fusion
- `ShopManager.regenerate_offer()` roule une nouvelle offre à chaque visite
- Écran de fusion (overlay dans `shop.tscn`) : tirage frais à chaque ouverture (pas mis en cache par visite — tension connue avec le "pas d'anti-spam nécessaire", à surveiller au playtest)

**Inspecteur de deck**
- Bouton "DECK" en bas à droite + touche Tab, comptes agrégés (famille/valeur, rocks, spéciaux) du deck restant à tirer, ordre jamais révélé

**Boutons "nude" + valeur en texte**
- Sprites remplacés par des versions sans points (une par famille au lieu d'une par valeur)
- Valeur affichée en Londrina Solid blanc, par-dessus (grille, hover, stream UI). Piège évité : le label enfant du sprite est dimensionné dans l'espace local de la texture (pas de la cellule) pour être *downscalé* avec le sprite plutôt qu'*upscalé* depuis une police minuscule — sinon flou. `mouse_filter = IGNORE` obligatoire sur ces labels sinon ils cassent le clic sur les colonnes occupées.

**Hover simple (Partitions, Echoes, shop)**
- `PatternData.describe()` et `EchoData.description` réutilisés partout (jeu + shop) via `Control._gui_input` + `tooltip_text`
- Piège récurrent cette session : les `Control` custom-dessinés (`TagsUI`, `EchoesUI`) avaient `mouse_filter = IGNORE` pour ne pas bloquer les clics sous-jacents — il faut `PASS` (pas `STOP`) pour capter le hover sans intercepter les clics de la grille.

**Level up des Partitions**
- Score cumulé par Partition (`tag_name`), seuils génériques `[150, 400, 800, 1500]`, multiplicateurs `[1.0, 1.25, 1.5, 1.75, 2.0]`, vocabulaire musical (Pianissimo → Maestro)
- Le multiplicateur de niveau est snapshoté au `start_round` comme les `rule_multipliers` des Echoes — un level up en cours de manche ne s'applique qu'à la manche suivante
- Barre de progression directement dans le fond des slots `TagsUI` (bande `progress_fill_color` qui avance), mise à jour en temps réel à chaque gain de score

## Points techniques à garder en tête

- `TokenData.Family` est toujours `CORAL/SHELL/RUST` dans le code — pas encore renommé en `BONE/WOOD/BRASS` comme décidé en session 10
- Il existe des sprites `ink_1..5.png` orphelins (famille "Ink" jamais branchée dans l'enum) — reliquat, pas grave
- Nouveau 6e trigger d'Echo potentiel (`on_fusion`, shop/hors-manche) noté dans le brainstorm, pas câblé

## Prochaine étape

Playtester la boucle complète avec le level up actif — voir si la sensation de progression sur une run entière (le problème posé en tout début de session) est enfin au rendez-vous. Tuning à prévoir : seuils/multiplicateurs de level up, prix de fusion et du bocal de boutons, taille du tirage de fusion (8 vs 10).
