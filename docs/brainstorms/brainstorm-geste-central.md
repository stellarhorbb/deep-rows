# Brainstorm — Remettre en question le geste central

**Statut** : bac a sable, rien de tranche. Session 27 (2026-08-04), longue exploration a chaud qui part d'un doute reel en cours de run et qui teste concretement une piste de refonte du coeur du jeu. Conclusion : la piste testee ne marche pas, mais le diagnostic qui y mene est solide et vaut la peine d'etre garde.

---

## Le declencheur : une vraie run, pas une intuition abstraite

Contrairement au doute de session 26 (resurgi apres quelques jours sans dev), celui-ci est ne en jouant reellement une run avec **Le Prévoyant** (tour des starters restants, voir memoire `project_starters_testing_progress`). Perdue a la Forêt manche 5/5 (manche 10 globale, boss de zone 2), a court de score.

Diagnostic de la defaite, precis : le joueur "spammait" **Diamond (Family)** faute d'alternative — ni 777 ni Royal Wedding n'ont jamais ete completes de toute la run — et le loadout de Sortilèges tires ce run-la etait "que des trucs qui scalent pas ou utilitaires". Diamond (Family) scale bien via le level-up generique des Sheets (x1.0 -> x2.0), mais son plafond ne suffit pas seul face a une cible qui grimpe, sans aucun Sortilège scalant en soutien.

Ca a ouvert une discussion plus large : le joueur s'habitue au pattern de son starter et scanne la grille avec CE pattern en tete — difficile de "voir" les 3 autres Tags equipes une fois l'habitude engagee. Question posee frontalement : **le systeme de Partitions (resolution conditionnelle aux Tags) est-il un defaut du core, pas juste un probleme de balance ?**

## Le ressenti, precise en 4 points

Demande de nommer precisement ce qui semble plat (pas accepter le mot "plat" tel quel) :
1. **Chaque coup individuel ne fait rien ressentir.**
2. **Impression de refaire la meme run**, peu importe le starter.
3. **Aucun moment "wow"** en plusieurs runs de test.
4. **"A quoi bon continuer, pourquoi jouer"** — au bout d'un moment.

## Le signal objectif : le jeu a depasse son propre barometre

`docs/simple-concept.md` (le doc designe explicitement comme garde-fou anti-complexite, voir memoire `feedback_simple_concept_check`) ne mentionne **ni la roulette, ni les cases mystere, ni les des a coudre, ni les malus de boss, ni la persistance entre manches, ni les Legendary Sheets** — rien de ce qui a ete construit ces ~10 dernieres sessions. Le contrat "reste pitchable en Discord" est rompu en silence, personne ne s'en etait rendu compte parce que chaque ajout individuel semblait raisonnable sur le moment.

## Comparaison marche : 3 references, meme formule a deux volets

Reprise du framework de session 26 (Cursed Words, CloverPit, Dogpile, Bills Must Be Paid), plus deux references creusees cette session :

**Sol Cesto** (steam/app/2738490, ~200k ventes, 89% avis tres positifs) : tu choisis une ligne parmi 4 (ton controle), tu atterris au hasard sur 1 des 4 cases de cette ligne (l'incertitude reelle — combat/tresor/piege, "tu vis ou tu meurs", pas un flavor bonus discret). Les "dents" (upgrades) modifient uniquement CETTE MEME action — jamais un nouveau systeme a cote.

**Bills Must Be Paid** (jouee en direct par le user pendant la session) : le geste (taper au marteau) reste identique du debut a la fin d'une run — toute la progression (plus vite, plus fort, plus d'endurance, les cochons lachent plus de pieces) amplifie CE MEME geste. Le "joyeux bordel" de fin de run est un geste simple empile de bonus, pas 15 mecaniques qui coexistent.

**Formule commune aux deux, et aux 4 references de session 26** :
1. Le geste de base paie **toujours** quelque chose, sans condition.
2. La progression amplifie CE geste, elle n'en ajoute jamais un nouveau a cote.

Deep Rows echoue aux deux points : le drop est conditionnel/differe (gate par Tag + besoin de 3-4 jetons assembles), et la quasi-totalite des ajouts recents (roulette, cases mystere, malus de boss, des a coudre) sont des **systemes paralleles** poses a cote du geste plutot que des amplificateurs de ce geste.

Lien direct avec le sentiment de patchwork exprime par le user avant meme la comparaison marche : "j'ai l'impression d'avoir accumule les petits bouts de ficelle... pour essayer de pallier a des soucis de game design" — chaque systeme recent existe **parce que** le coeur ne payait pas assez, pas malgre un coeur qui marche.

## Le prototype teste : `proto/fusion-lines.html`

Proto HTML autonome (meme pattern que `proto/index.html`), construit et itere en direct pendant la session, sans toucher au jeu Godot. Zero risque, zero DA — juste le geste nu.

**Regle de base finale** : deck presque uniquement des jetons de valeur 1 (4 familles). Tu drop (geste Puissance 4 inchange). Tout groupe de 2+ jetons adjacents meme famille + meme valeur fusionne automatiquement en valeur+1, cascade possible. Une ligne de 3+ meme valeur+famille est le gros lot. Rocks (~12% du deck, jamais de fusion) et trous fixes (fond marin, la gravite les ignore) ajoutent une contrainte de placement. Persistance entre paliers de score (comme le vrai jeu : le jeton le plus haut de chaque colonne survit a la purge, sauf si couvert par un Rock) pour eviter les colonnes mortes definitives.

**Iterations en cours de route** (chaque etape verifiee en direct dans le navigateur, pas juste ecrite) :
- Seuil de fusion : 2 -> teste a 3 (pire, plus "dur" sans etre plus interessant) -> remis a 2.
- Score : constante arbitraire (`valeur x 4`) -> tentative exponentielle (`2^valeur`, meme logique que 2048/Suika) rejetee car illisible ("2^5 = 32, c'est quoi ce symbole bizarre ?") -> **formule simple finale : nombre de jetons fusionnes x leur valeur**, calculable de tete. Le scaling doit venir des upgrades du shop (deja presentes dans le proto : Surtension, Chaine genereuse, Lignes courtes, Deck enrichi, Ligne doree, Familles libres), pas d'une formule de base compliquee.
- Feedback visuel : chute animee, petit "pop" sur fusion/ligne, **cascade etapee dans le temps** (pas tout instantane d'un coup) suite a un retour direct ("sans animation on comprend pas ce qui s'est passe").
- Placement du resultat de fusion : ancre sur la colonne du drop en cours plutot qu'une case arbitraire du groupe (retour : "je sais pas ou ca tombe").
- Bug trouve et corrige en testant : l'affichage du deck ne se mettait pas a jour quand un drop ne declenchait aucune fusion/ligne (`renderInfo()` jamais appele dans ce cas).
- Bug de concurrence trouve et corrige : rien n'empechait deux cascades de tourner en meme temps sur la meme grille si les clics arrivaient plus vite que la resolution ne se terminait (`isResolving` ajoute pour bloquer un nouveau drop pendant toute la sequence, pas juste la chute).

## Le verdict : pas fun, et pourquoi precisement

Une fois le systeme complet (fusion + lignes + rocks + trous + persistance + score simple) reellement joue : **"punaise c'est pas fun"**.

Diagnostic final du user, net : il n'y a **pas de vrai milieu interessant**. Soit tu joues "safe" (empiler la meme famille au meme endroit) — trivial, aucune decision reelle — soit ca clogue et t'as aucun recours. Rien entre les deux ou un bon geste se distingue d'un geste mediocre.

Cause identifiee : le prototype a supprime quasiment toute incertitude du geste central pour garantir "ca paie toujours" — aperçu du prochain jeton visible (corrige plus tot dans la session suite a un retour "je vois pas ce qui va tomber"), gravite deterministe, fusion automatique et previsible. Sol Cesto marche parce que tu choisis (controle) MAIS tu atterris au hasard avec de vrais enjeux (incertitude) — deux couches distinctes. Le proto n'a garde que le controle, jamais l'incertitude a vrais enjeux.

**Auto-correction notee en fin de session** : une derniere piste proposee ("chaque case a un petit effet cache, revele au drop") contredisait une conclusion posee PLUS TOT dans la meme session (option ecartee explicitement pour illisibilite/bordel visuel) et diluait Sol Cesto en le rendant "petit effet sympa" plutot que "tu vis ou tu meurs" — reconnu comme un signal de fatigue de session (cote assistant cette fois, pas juste cote user), pas une vraie piste a creuser a chaud. Session arretee la plutot que de forcer une 8e idee.

## Question ouverte pour la prochaine fois (a tete reposee)

**A quoi ressemblerait un enjeu reel (pas un flavor bonus discret) sur chaque case ou chaque drop, dans un geste vertical toujours lisible, sans recreer le probleme d'illisibilite deja identifie et rejete une fois ?**

Pistes explicitement écartées a ne pas re-proposer sans nouvel angle :
- Cases mystere generalisees a toute la grille (illisible, deja teste comme raisonnement et rejete deux fois dans la meme session).
- Score exponentiel sur la valeur (illisible, "c'est quoi ce symbole").
- Momentum/combo meter façon Bills Must Be Paid (mismatch de rythme : geste delibere un par un, pas de rafale).
- Entity adversariale façon vrai Puissance 4 (renverse un pilier narratif verrouille, deja rejete en session 26).

## Statut du prototype

`proto/fusion-lines.html` reste dans le repo, fonctionnel et verifie (fusion/lignes/rocks/trous/persistance/animations tous testes en direct, aucune erreur console a la fin de la session). Reutilisable comme scaffold technique si ce fil est repris — la mecanique de fusion+gravite+cascade-etapee en particulier est solide independamment du verdict "pas fun" du systeme global.
