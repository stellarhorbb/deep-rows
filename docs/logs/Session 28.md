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

## Reste ouvert

- Annonce visuelle dédiée pour Echo/Quitte ou Double (actuellement silencieux).
- Miroir (déjà implémenté, copie le Sortilège à gauche) occupe en fait la case que le brainstorm de session 15 réservait au concept "Echo" — le nouvel Echo de cette session est un mécanisme totalement différent (probabiliste, retrigger de score). Pas de conflit en pratique (le Sheet a tranché), mais `brainstorm-sortileges.md` garde l'ancienne proposition à nettoyer si on y retourne.
- Tuning à l'oeil pour l'instant : `CURSED_COLUMN_SKULL_BONUS` (0.30), `CURSED_COLUMN_JACKPOT_MULTIPLIER_MAX` (×4), ratio bonus/malus des cases mystère (70/30), rareté/prix d'Echo et Quitte ou Double (Epic/7, pas précisé par le Sheet).
