# Session 28 — Colonne Convoitée, refonte des cases mystère, tri des Sortilèges

**Date** : 2026-08-05
**Thème** : Suite directe du doute posé en session 27 (brainstorm-geste-central.md) — refonte complète de l'axe casino (roulette + skull ambiant) en un seul système greffé au geste, puis application du même principe aux cases mystère, au bouton Shake, et un tri du catalogue de Sortilèges. Session de dev pur, beaucoup d'itérations testées en direct par le user entre deux passes de code.

---

## Colonne Convoitée — remplace roulette + skull-ailleurs (session 25/26)

Diagnostic de départ (repris de la fin de session 27) : la roulette (jauge/seuil 21/Multiplicateur-Boost) et le skull ambiant (chance croissante, colonne aléatoire) étaient deux systèmes **parallèles** au geste — le joueur devait les suivre en tête en plus de regarder la grille. Objectif : un seul mécanisme, greffé directement sur le drop.

**Premier jet** : chance de corruption roulée sur CHAQUE drop du joueur (n'importe quelle colonne), remplace le jeton par un skull sans le consommer (swap, pas perte — le jeton reste en tête de stream). Une "Colonne Convoitée" signalée, re-tirée à chaque tour, avec un risque plus élevé mais des récompenses (Multiplicateur/Boost, repris du pool roulette) ciblées sur le jeton dropé.

**Retour playtest, deux fois de suite** :
1. *"Le skull tombe TOUJOURS pile où je construis, c'est trop punitif"* — corrigé en scindant les deux couches : la corruption ambiante redevient un événement post-tour totalement séparé du geste (formule d'avant session 27, colonne aléatoire, comme l'ancien système), seule la Colonne Convoitée (pari délibéré et visible) touche directement le geste. Le compteur de dread reste partagé entre les deux sources.
2. *"La roulette au seuil 21 me manque un peu"* — accepté comme trade-off assumé (rythme garanti vs pari actif), pas retouché.

**Contrepoids risque/récompense** : le palier Légendaire (jackpot) scale maintenant avec le risque affiché — multiplicatif, ×1 à risque nul jusqu'à ×4 à 100% (`GameRules.CURSED_COLUMN_JACKPOT_MULTIPLIER_MAX`). Bug trouvé par le user en le testant : la chance ABSOLUE de jackpot chutait mécaniquement vers 0 à haut risque (moins d'espace de récompense total), donnant l'impression fausse que le risque payait moins. Fix : affichage en conditionnel ("si ça passe") plutôt qu'absolu — le tirage réel n'a jamais eu le bug, seul le tooltip trompait.

**Hover sur le %** : `GridHoverUI` (déjà utilisé pour les tooltips de jetons) étendu à la case du haut de la Colonne Convoitée — détail Skull/Bonus/Jackpot au survol, sans nouvelle UI.

**Cases mystère et skulls** : un skull qui atterrit sur une case mystère non révélée la **désamorce** au lieu de la déclencher (évite qu'une corruption distribue accidentellement un bonus) — annonce dédiée qui révèle ce qui a été raté, pour donner du poids à la perte sans info exploitable.

**Bug de freeze trouvé en playtest** : `GridManager.place_token()` ne gérait jamais `Kind.ENTITY` (seul `place_token_direct` le faisait avant cette session) — le skull de corruption, routé par le nouveau pipeline animé, ne déclenchait jamais `token_placed`, donc `await drop_animated` restait bloqué pour toujours. Corrigé en ajoutant ENTITY à la branche BASE/ROCK de `place_token`.

**Leçon méthodologique** : le check `godot --headless --quit` sur la scène de boot ne compile QUE ce qui est chargé au démarrage — `game_scene.gd` n'est atteint qu'en lançant une vraie manche, donc une erreur de syntaxe dedans (bug trouvé plus tard dans la session : fonction insérée en plein milieu d'un `match`) passait complètement inaperçue. Un script de vérification dédié (`check_all_scripts.gd`, charge tous les `.gd` du projet via `load()`) a été ajouté au scratchpad et utilisé pour le reste de la session — bien plus fiable, malgré quelques faux positifs inévitables sur les scripts qui référencent des autoloads (RunService/SceneRouter/MetaProgression, absents en mode `--script` isolé).

## Cases mystère — catalogue recentré

Même diagnostic appliqué : sur les 13 effets d'origine, une bonne moitié (cible ±10%, mouches ±1/2/5/20) étaient purement économiques, détachés de la grille/du jeton. Nouveau catalogue de 11 effets, ratio ~70% bonus / 30% malus pondéré par palier :

- **Bonus** : Valeur +1, Trou rebouché, Verrou (protège contre mutation future), Fusion spontanée (fusionne avec un voisin adjacent), Pierre libérée (convertit un Rock adjacent), Multiplicateur ×2/×5/×10 (Jackpot).
- **Malus** : Valeur -1, Pétrification, Modifier ×0.5.

Mutation de famille et Téléportation retirées du pool — retour direct du user, jamais appréciées en jouant : elles "reviennent sur une décision déjà prise" (le jeton posé est changé/déplacé après coup) plutôt que d'ajouter un obstacle avec lequel composer. Pétrification a été précisée en discussion : un Rock apparaît **sous** le jeton posé, qui remonte d'une case — le jeton lui-même n'est jamais muté, cohérent avec le même principe.

Nettoyage en cascade : `add_random_hole()` (HOLE_ADD supprimé du pool) et `ScoreManager.adjust_target` (SCORE_UP/DOWN supprimés) sont devenus du code mort, supprimés.

## Shake — shuffle de grille au lieu du remélange de stream

Retour du user : jamais utilisé, "rien de spectaculaire". L'ancien effet (remélangeait current + pioche, invisible) remplacé par un shuffle physique de tous les jetons de base non verrouillés actuellement sur la grille (même empreinte de cellules, aucune gravité à retasser). Rocks/entity-skulls/jetons verrouillés restent fixes — même logique de protection que Fixer contre le Boost. `DeckManager.shake()` (devenu orphelin) supprimé.

## Sortilèges — deux audits + tri

Deux passes d'audit (agents dédiés, catalogue de 53 Sortilèges) :
1. **Mini-systèmes à part** : seuls Régularité et Un Pour Tous tiennent un compteur caché à suivre sur plusieurs tours (déjà connus comme "illisibles" par le projet — seuls Sortilèges avec un `get_progress_text()` de secours). Pas de refonte tranchée, juste confirmé comme le seul vrai cas.
2. **Générique/Balatro vs spécifique à Deep Rows** : 5 candidats génériques identifiés (Pourboire, Mouche dorée, Économe, Rescapé, Dernier Carré). Discussion : le vrai problème n'est pas "emprunté à Balatro" mais le patron "bonus de mouches plat/conditionnel sans moment fort". Décision finale : pas de retouche — ces Sortilèges servent de pièces de synergie pour des builds qui scalent sur les mouches (ex: Mouche dorée), un rôle légitime même sans être excitants seuls.

**Retirés (obsolètes, orphelins de la refonte roulette→Colonne Convoitée)** : Bon départ (head-start sur une jauge qui n'existe plus), Jamais 1 sans 2 (doublait le Boost sur un 2e jeton aléatoire — le nouveau Boost cible déjà un seul jeton précis).

**Ajoutés (specs venues du Google Sheet)** :
- **Echo** — 15% de chance qu'une Partition qui score se résolve une deuxième fois (retrigger).
- **Quitte ou Double** — une Partition qui score joue un pile ou face : 50% double, 50% remet à zéro.

Les deux réutilisent le pattern "flag simple sur RunContext" déjà en place pour Dresseur Fou/Pierre de Famille (pas de canal par source, un seul exemplaire équipable), branchés sur les deux points de calcul final de `CascadeResolver._score_group` (nouvelle fonction `_apply_score_gambles`, Quitte ou Double appliqué avant Echo). Pas encore d'annonce dédiée dans la bannière de résolution quand ça déclenche — le score reflète juste le résultat, silencieusement.

## Reste ouvert (partie 1)

- Annonce visuelle dédiée pour Echo/Quitte ou Double (actuellement silencieux).
- Miroir (déjà implémenté, copie le Sortilège à gauche) occupe en fait la case que le brainstorm de session 15 réservait au concept "Echo" — le nouvel Echo de cette session est un mécanisme totalement différent (probabiliste, retrigger de score). Pas de conflit en pratique (le Sheet a tranché), mais `brainstorm-sortileges.md` garde l'ancienne proposition à nettoyer si on y retourne.
- Tuning à l'oeil pour l'instant : `CURSED_COLUMN_JACKPOT_MULTIPLIER_MAX` (×4), ratio bonus/malus des cases mystère (70/30), rareté/prix d'Echo et Quitte ou Double (Epic/7, pas précisé par le Sheet).

---

## Partie 2 — Bug de persistance du Boost, puis consolidation de la Colonne Convoitée

Suite directe dans la même journée, après un premier retour user sur la Colonne Convoitée fraîchement codée.

### Bug trouvé en playtest : un jeton boosté "redevient" sa valeur de base

Rapporté par le user : un 10 de bâtons obtenu via Boost n'a plus aucune trace au deck de la manche suivante. Deux fausses pistes explorées et rejetées par le user avant la vraie cause (voir mémoire `feedback_trace_before_speculating`) :
1. Verrouiller (`token.locked`) le jeton boosté — rejeté : ça bloque aussi les futures évolutions légitimes (promotion en figure, autres boosts), pas juste la perte de valeur.
2. Réinjecter dans le pool possédé les jetons boostés qui finissent couverts en fin de manche — rejeté violemment ("tu fais n'importe quoi") : le user précise que ça n'a jamais été un problème de position/couverture.

**Vraie cause**, trouvée après capture d'écran fournie par le user (jeton à 10 visiblement enterré sous des Rocks, mais ce n'était pas le sujet) : `DeckManager.build_deck()` fait des **copies fraîches** des jetons du pool possédé à chaque manche (`deck_manager.gd:57`). Le Boost mutait uniquement la copie éphémère sur la grille, jamais l'entrée d'origine dans le pool — exactement le même bug que l'ancien Boost roulette, déjà corrigé en session 25 via `RunManager.boost_random_button`, et réintroduit par la refonte session 27 (qui cible désormais LE jeton précis plutôt qu'un jeton aléatoire du pool, donc ne pouvait plus réutiliser cette fonction telle quelle).

**Fix** : nouvelle fonction `RunManager.bank_column_boost` — retrouve dans le pool l'entrée exacte correspondant au jeton (même famille + même valeur avant boost) et la met à jour, au lieu d'un candidat aléatoire. Fonctionne aussi bien pour un jeton frais que pour un jeton revenu par carryover (la réconciliation pool/grille se fait par famille+valeur, pas par identité d'objet).

### Annonce de récompense simplifiée

Retour user : le double défilement type roulette (palier Bonus/Jackpot puis famille Multi/Boost) est "trop long". Remplacé par un affichage direct — `JACKPOT` en titre uniquement pour le palier Légendaire, Commun/Rare vont droit au gain. Nettoyage en cascade : `play_prize_spin_announcement` (grid_visual + resolution_banner) et `CursedColumnRewards.tier_label`/`TIER_LABELS` devenus du code mort, supprimés.

### Brainstorm : rendre le geste encore plus "Sol Cesto"

Retour à la formule identifiée en session 27 (voir `brainstorm-geste-central.md`) : le geste de base doit toujours payer quelque chose, et la progression doit amplifier CE geste plutôt que d'en ajouter un nouveau à côté. Le user précise vouloir consolider l'existant, pas de nouveau système parallèle — les Sortilèges jouent le rôle des "dents" de Sol Cesto (upgrades qui ne modifient jamais que la même action).

Piste explicitement écartée : rendre la Colonne Convoitée fixe jusqu'à résolution au lieu de re-tirée à chaque tour — le user aime le côté aléatoire actuel, "ça force le côté agile et dynamique du jeu".

Piste retenue : le swap-sans-perte de la corruption dilue trop le risque ("pas grave, je tente ailleurs") — le vrai "tu vis ou tu meurs" de Sol Cesto vient du poids ressenti, pas juste du taux affiché.

### Retune de la Colonne Convoitée

- **Corruption consomme vraiment le jeton** — `TurnController.play_current_to` appelle désormais `deck_manager.consume_current()` dans la branche corruption. Le jeton disparaît sans avoir scoré pour cette manche, mais reste dans le pool possédé (jamais touché par ce qui se joue en manche) — revient normalement au deck de la manche suivante.
- **Boost Légendaire devient multiplicatif** (`GameRules.CURSED_COLUMN_JACKPOT_VALUE_MULTIPLIER`, ×2) au lieu d'un ancien +10 plat qui fixait n'importe quel jeton pile à `MAX_BUTTON_VALUE` — l'ancien système favorisait TOUJOURS le fodder (un +10 sur un jeton à 1 valait bien plus, en relatif, qu'un +10 sur un jeton à 8 déjà proche du plafond). Le ×2 rend le risque proportionnel à l'enjeu : un "5" qui double tombe pile sur 10, le vrai sweet spot. Commun/Rare restent additifs et plats (+1/+2, `GameRules.CURSED_COLUMN_BOOST_VALUES`).

### 4 nouveaux Sortilèges, tous scopés à la Colonne Convoitée

Brainstorm en plusieurs passes : d'abord des idées génériques (choix de famille, plancher garanti, colonnes jumelles), puis affiné vers des mécaniques plus originales une fois que le user a demandé "des trucs auxquels on n'aurait pas pensé". Un premier jet ("Emprise", multiplicateur global +10%/skull) rejeté par le user comme "simpliste" et redondant avec un autre jet ("Tribut", mouches/skull) — le vrai defaut identifié : les deux étaient un pur compteur ambiant, sans lien avec le placement. Résolu en recentrant sur l'adjacence (une vraie décision spatiale) plutôt qu'un total global.

- **RENAISSANCE** (Rare, 5 mouches) — 1 jeton corrompu sur 3 revient à une place aléatoire du stream de LA MÊME manche (`DeckManager.insert_random`), au lieu d'attendre la manche suivante.
- **CONSOLATION** (Uncommon, 3 mouches) — +2 mouches à chaque corruption, compense la perte sans l'annuler.
- **ADJACENCE SOMBRE** (Rare, 5 mouches) — +20% de score, mais LOCAL (pas un `global_multiplier` qui touche tout comme Emprise) : par skull adjacent orthogonalement à la Partition qui score, même canal que l'Amplificateur (`grid_mult`). Naturellement plafonné à 4 skulls adjacents.
- **ACCOUTUMANCE** (Rare, 5 mouches) — le risque affiché/réel de la Colonne Convoitée baisse de 3% par skull présent sur la grille (`GridManager.count_entity_skulls`, branché dans `EntityManager._cursed_column_chance`, donc cohérent sur le tirage réel ET l'affichage ET le calcul du palier Légendaire). Contrairement à Emprise/Tribut, reboucle directement sur le système retravaillé toute la session plutôt que d'être un bonus déconnecté.

## Reste ouvert (partie 2)

- Tout ce qui a été codé dans cette partie 2 (retune Boost/corruption, 4 nouveaux Sortilèges) n'a pas encore été testé en run réel par le user — calibrage à revoir avec de vraies données, pas à l'instinct.
- `CURSED_COLUMN_SKULL_BONUS` (0.30) — potentiellement à revoir maintenant que la corruption coûte vraiment un jeton (avant, elle ne coûtait qu'un tour). Pas de décision a priori.
- Piste identifiée mais pas creusée cette session : transformer les skulls en avantage au-delà d'Adjacence Sombre/Accoutumance — jokers de famille (comme Pierre de Famille pour les Rocks), "moisson" (retirer un skull ciblé contre récompense).

---

## Partie 3 — Nettoyage du catalogue de Sortilèges, vocabulaire multi/proba, audit complet

Suite directe : le user remarque tomber très souvent sur les mêmes Sortilèges Communs en début de run (Économe, Petit Point, Jetons Sacrés) — diagnostic RNG plutôt qu'un vrai chantier au départ, qui a fini par ouvrir tout le catalogue.

### RNG des Sortilèges — rien de cassé, mais Commun structurellement mince

`SPELL_RARITY_RATES` (50/30/13/6/1, taux fixe par palier peu importe le nombre d'items) explique tout : avec seulement 13 Communs à l'époque, chacun sortait ~3,85%/tirage contre ~1,58% pour un Uncommon — pas un bug, littéralement le système qui pousse les Communs en avant. Confirmé : aucune restriction par manche/zone sur les Sortilèges, tout le pool est ouvert dès la manche 1.

### Passe Google Sheet — synchronisation et découvertes

Sheet "spells" lue intégralement (contournement du bug `read_file_content` qui ne renvoie que le premier onglet : export xlsx complet + unzip + parse XML). Plusieurs allers-retours de correction :
- Tous les noms retrouvés pour les lignes encore numérotées (matching par description contre les `.tres` du repo) — **Petit Point et Jetons Sacrés étaient déjà dans la Sheet**, juste jamais renommés (correction d'une erreur précédente qui les disait absents).
- 3 vrais écarts corrigés dans le code (pas juste la Sheet) : **Petites Mains** (0.1→0.5 au multi, le code ne suivait même pas son propre commentaire), **Bord à Bord** (×1.2→×1.5), **Artificier** confirmé bon (25%, c'est la Sheet qui avait 33% de trop).
- **Couronne**/**Diadème** vérifiés avant tout changement : "+1.0"/"+3.0" et "×2"/"×4" décrivaient déjà la même chose (le canal `add_value_bonus_multiplier` part de 1.0 et additionne — un seul Roi = 1+1 = ×2). Changer les constantes à la valeur "x" littérale aurait cassé le sort.
- 2 raretés corrigées pour matcher la Sheet : **Cairn** (Epic→Rare) et **Regain** (Uncommon→Rare), prix réalignés à 5 (médiane du tier Rare).
- **Tickets Printanier/Estival/Automnal/Hivernal renommés** en **Tickets de Bâtons/Coupes/Épées/Deniers** (fichiers, id, label, description, catalogue shop) — la Sheet avait abandonné le thème saisonnier pour un nom plus direct.

### Refonte du vocabulaire multi/probabilité

Le user trouvait le mélange décimales/% confus pour tout ce qui touche au "multi". Comparaison avec Balatro (screenshots à l'appui) pour trouver une vraie doctrine :
1. **Premier essai rejeté** : rebaser en "+Mult" façon Balatro (×10, base 10 au lieu de 1.0) — jugé confus par le user, abandonné avant d'être appliqué.
2. **Contre-exemple trouvé par le user** (Steel Joker, "X0.2 Mult... Currently X1") : Balatro utilise bien des décimales, mais uniquement sur le canal "X" (multiplicatif à taux variable), jamais sur le "+Mult" plat.
3. **Décision finale** : gardé le **%** (déjà une convention connue du genre, Diablo/PoE) pour la famille "bonus additif par occurrence" (Couronne, Diadème, Petites Mains, Sacre) plutôt que d'importer le vocabulaire Balatro tel quel — leur "+Mult" marche seulement parce que tous les jokers alimentent un seul pool partagé, pas notre cas. Clause "(cumulatif : 2 X = +Y%)" proposée puis **retirée** après retour du user : ça recontaminait la distinction qu'on venait de poser ("cumule" = scaling permanent uniquement), et "Chaque X qui score ajoute +Y%" se lit déjà sans ambiguïté tout seul.
4. **"1 chance sur N"** adopté pour toute la famille probabiliste (Poker Face, Quitte ou Double, Pile ou Face, Artificier) — Echo (15%) reste en %, pas de fraction propre.
5. Famille "scaling permanent" (Jetons Sacrés, Cairn, Escalade Musicale, Rescapé) : décimales → % dans la description ET dans `get_progress_text()` (le tooltip live en jeu), pour rester cohérent pendant la partie et pas seulement au shop.

**Deux vraies découvertes de mécanique en cours de route, pas juste du vocabulaire :**
- **Refrain** n'est pas un multiplicateur — le user pensait "+10% au multi", mais le code (et son historique) montre que c'était **délibérément retravaillé en session 23** après un exploit playtest (spammer une seule Partition faisait exploser le multi) vers un bonus de points plats. Le comportement actuel est le bon, seule la Sheet n'avait jamais suivi.
- **Sacre** réécrit de fond en comble : l'intention du user ("chaque figure qui score, n'importe où, cumule +10% pendant toute la run") ne correspondait pas du tout à l'implémentation existante (bonus local recalculé par groupe, jamais permanent). Migré vers le canal `scaling_mult_bonus` (même famille que Jetons Sacrés/Cairn), nouveau trigger `on_turn_resolved`, scan du timeline comme Refrain/Artificier.

**Gourmand scindé en deux Sortilèges distincts** (le user avait gardé les deux idées d'une session précédente) :
- **AVIDITÉ** (reprend l'ancien Gourmand tel quel : jeton ajouté au deck) — fichiers renommés `spell_avidite.tres`/`effect_avidite.gd`.
- **GOURMAND** (nouveau : spécial qui mange quelque chose) — a nécessité de créer un chemin de trigger qui n'existait pas (`GridManager.tick_mobile_specials` ne remontait jamais le nombre de bouchées réelles, même le booléen "ate" de Liane était calculé puis jeté) : nouveau signal `TurnController.special_ate`, nouveau trigger générique `on_special_ate` dans `SpellManager`.

### Audit complet du catalogue (72 Sortilèges)

Dashboard généré et vérifié champ par champ contre la Sheet mise à jour par le user (desc/rareté/type/scaling tous alignés, sauf formulations cosmétiques volontairement non synchronisées mot pour mot). Chiffres clés :
- Rareté : Commun 13 (18,1%), Uncommon 19 (26,4%), Rare 25 (34,7%), Epic 8 (11,1%), Legendary 7 (9,7%).
- Type (nouvelle taxonomie à 7 catégories, remplace l'ancien "specials" fourre-tout) : Score direct 22, Multiplicateur 18, Grille 10, Mouches 7, Colonne Convoitée 6, Jetons spéciaux 5, Deck/Pool 4.
- **Découverte** : Rare a grossi au point de devenir le plus gros tier (34,7% du catalogue) sans que son taux de tirage suive (13% fixe) — un Rare individuel sort maintenant *moins* souvent (~0,52%) qu'un Epic (~0,75%).
- Confusion corrigée en cours de route : le "63/72 implémentés" affiché au départ venait de la colonne `status` de la Sheet (suivi QA perso du user), pas d'un vrai statut de build — vérifié que les 72 sont bien enregistrés dans `shop_manager.gd` et présents comme `.tres`, donc 100% en jeu.

Piste de rééquilibrage discutée (Commun toujours mince, zéro Grille/CC/Spéciaux dedans ; Rare sur-provisionné) : redescendre Cellule Double/Écume/Colonne Chanceuse en Commun et Cellule Triple en Uncommon — **proposé mais pas exécuté**, le user est parti se reposer avant de trancher ("travail de fourmi").

## Reste ouvert (partie 3)

- Rééquilibrage des paliers de rareté — voir `questions-ouvertes.md`, rien d'exécuté.
- `sortileges-implementes.md` n'a pas suivi les retunes de cette session (Couronne/Diadème en decimales, Refrain/Sacre/Gourmand désynchronisés, Numérologie listée à tort comme "Dormant") — prévoir une vraie passe de resynchro plutôt que des patchs.
- Aucun des changements de cette partie 3 n'a encore été testé en run réelle.
