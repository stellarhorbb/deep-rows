# Session 24 — Cases mystère sur la grille, réflexion sur le geste de placement, épiphanie narrative

**Date** : 2026-07-24
**Thème** : Session de playtest suivie d'un chantier de fond né en cours de route — le geste de placement ressenti comme plat après plusieurs runs consécutives, comparé à Sol Cesto, qui a débouché sur un nouveau système (cases mystère "?") conçu, implémenté et validé fun dans la même session. Plus tard le même jour, une session courte de game design/narration pure (pas de code) où le user a partagé une épiphanie eue en faisant du vélo : le sens caché de toute l'histoire du jeu, qui a été noté dans le GDD.

---

## Le geste de placement ressenti "plat"

Après plusieurs runs d'affilée (4 starters, chasse aux bugs/balance), le user a remis en question le geste central — choisir une colonne — plutôt que la variété de contenu (déjà riche : 6 pools existants). Piste initiale évoquée : des jetons avec **états** (ex: un jeton normal qui gagne un statut mobile façon Frog). Discutée puis **écartée** : ferait perdre le contrôle sur un pattern patiemment construit sur plusieurs tours, retour de frustration comparable au risque déjà identifié avec les jetons mobiles.

**Référence externe clé : Sol Cesto** (roguelite Steam, ~test Gamekult partagé par le user). Geste aussi mince que le nôtre sur le papier (choisir 1 ligne parmi 4, atterrir au hasard sur 1 des 4 cases : monstre/coffre/piège), mais jamais déterministe — contrairement à notre drop, où le jeton est toujours connu (famille/valeur visibles) avant de jouer. Le déclic : injecter l'incertitude sur le **terrain** (où on tombe) plutôt que sur **ce qu'on pose** (le jeton), pour garder le puzzle de pattern-building intact.

## Cases mystère ("?") — conception

- **Visibles-mais-inconnues**, jamais totalement invisibles — garde l'agentivité du joueur (il choisit de risquer ou d'éviter), contrairement à un pur hasard subi.
- **Déclenchées par n'importe quoi qui atterrit dessus** — jeton normal, Rock, Special, et même un skull de l'Entity (tranché : cohérent avec son rôle perturbateur, "la grille reste l'espace du joueur" mais l'Entity peut y semer le chaos comme le reste).
- **Effet caché révélé au contact**, jamais avant.
- Interaction gratuite découverte en discussion : un Rock qui atterrit sur une case mystère la révèle mais neutralise son effet pour de bon (un Rock ne score jamais) — vrai dilemme "je sacrifie un Rock pour désamorcer, ou je le pose ailleurs et garde le mystère intact".

### Inquiétude sur l'empilement de systèmes

Discussion à part entière sur le nombre de pools déjà existants (Partitions, Badges, Specials, Boss Malus, Starters, Dés à coudre) — le user craignait d'ajouter une 7e couche. Diagnostic posé : pas de doublon réel entre les systèmes existants (chacun répond à un axe distinct), mais le **layer terrain** (Rocks/Trous/Modifiers/Mystère) commence à empiler des vocabulaires visuels différents sur la même grille — risque de lisibilité à traiter au moment de la DA (grammaire visuelle unifiée), pas un problème de règles. Correction au passage : le Boss Malus n'est **pas** une pool à contenu manquant comme affirmé par erreur en cours de discussion — les 12 malus sont déjà implémentés et testés (`BossMalusManager`), ligne périmée de `questions-ouvertes.md` retirée.

Décision finale sur le scope : réutiliser au maximum l'existant plutôt qu'inventer — le système de Modifiers de cellule (HALF/BOOST/DOUBLE/TRIPLE) sert de base aux effets "Multi", le taux de rareté par palier (Commun/Rare/Jackpot) reprend le principe de `BADGE_RARITY_RATES`.

## Implémentation

Pool final : 15 effets (14 implémentés + "Fixe le jeton" volontairement mis de côté — seul effet qui toucherait `GravitySystem`, à réévaluer si le concept continue d'accrocher). Insta-win la manche discuté puis retiré (jugé trop fort, viderait le sens de jouer la manche).

- **`scripts/systems/mystery_cell_effects.gd`** (nouveau) — catalogue (enum + LABELS + DESCRIPTIONS + taux fixe par palier `GameRules.MYSTERY_RARITY_RATES` = [0.55, 0.40, 0.05], même principe à deux temps que `ShopManager._draw_badge_queued`).
- **`GridManager`** — placement caché en début de manche (`generate_random_mystery_cells`, même timing que les trous), détection au moment de l'atterrissage (`place_token`, `_place_persistent_special`, `place_token_direct` pour l'Entity), helpers dédiés (ajoute/comble un trou, mute une famille, téléporte une colonne en gérant la gravité proprement).
- **`ScoreManager.subtract_score`** — n'existait pas, le score ne pouvait que monter avant les effets malus.
- **`RunManager.add_grid_modifier`** — **vrai bug latent corrigé** : les modifiers de cellule n'étaient jusque-là posés qu'au tout début de manche, avant que `RunContext` (snapshot figé) ne soit construit. Un Multi x2/x5/x10 posé en cours de manche par une case mystère aurait été visible à l'écran mais totalement ignoré par `CascadeResolver` sans la correction (push vers `_active_context.grid_modifiers`, même principe que les autres champs déjà mutables en cours de manche comme `_scaling_mult_bonuses`).
- **`TurnController._on_mystery_cell_triggered`** — dispatch des 13 effets vers Score/RunManager/GridManager.
- **UI** — marqueur "?" minimal (violet, pas de juice, cohérent avec "pas de DA avant validation du fun"). Itéré deux fois sur le retour visuel après premier test : d'abord un simple message discret (`MessageDisplay`, jugé pas assez visible), puis une vraie bannière centrale dédiée (`ResolutionBanner.play_mystery_announcement`, même style que CASCADE/DOUBLE PARTITION), puis ajout d'un sous-titre descriptif en plus petit sous le titre (nouveau node `Subtitle` dans `game.tscn`).

Vérifié par boot headless Godot propre (zéro erreur de parsing) à chaque étape — pas de test manuel en éditeur possible depuis cet environnement, joué et confirmé par le user directement.

## Retour de playtest

- **Confirmé fun** : *"ça crée une espèce de défi dans le défi d'aller chercher les cases '?', c'est fun"* — validation directe de l'hypothèse de départ.
- **Densité (2-4 cases/manche)** laissée telle quelle pour l'instant — pas de contrainte de distance minimale entre cases, jugée superflue vu le faible risque de clustering à cette densité sur une grille 7×7. À ressortir si le ressenti change sur plusieurs runs.
- **Une manche mauvaise croisée** : chasse risquée des "?" qui n'a rapporté que des malus, cumulée à des skulls de l'Entity ayant détruit des patterns en construction. Diagnostiqué comme deux malchances indépendantes superposées (variance normale d'un système ~50/50 bonus/malus + comportement pré-existant de l'Entity, sans lien de cause à effet) plutôt qu'un vrai défaut — confirmé par le user, rien retouché.

## Réflexion DA/UI (courte, en fin de session)

Le user s'est demandé si le proto approchait du moment de basculer vers l'UI/DA. Lecture posée : bon signal (geste de placement validé après itération, 6 pools de contenu déjà éprouvés), mais un vrai trou structurel identifié avant d'y aller à fond — **la sauvegarde/Shore n'existe pas du tout** (aucune persistance entre les runs, alors que les unlocks conditionnels sont tranchés sur le papier depuis le 22/07), ainsi que 6 des 10 packs de démarrage encore à faire. Le layer terrain (Rocks/Trous/Modifiers/Mystère) noté comme premier candidat à une vraie grammaire visuelle unifiée plutôt qu'une DA ajoutée couche par couche.

## Épiphanie narrative — le sens caché du jeu

Deuxième partie de la session, pure discussion de design/narration (aucun code touché) : le user, en faisant du vélo le matin, a eu un déclic sur le fil narratif global qui manquait encore au jeu.

**L'idée** : au-delà du "garçon perdu dans un monde halluciné" générique, le jeu devient un conglomérat de tout ce que le user est et aime (puzzles, systèmes, tarot, mystique, références OTGW/COTL/contes sombres) *et* un moyen d'exprimer, sans jamais le nommer, son propre vécu — imagination et émotions débordantes longtemps refoulées, blessures familiales, migraines avec aura qui basculent dans un espace-temps halluciné, refuge historique dans les livres/jeux/histoires.

Trois pièces qui s'emboîtent, chacune répondant à une question ouverte séparée jusque-là :
- **L'Entity** se relit comme la peur / la folie / la mort — celle qui veut que le garçon reste perdu dans le monde plutôt que d'en sortir.
- **Les packs de démarrage** sont chacun un trait de personnalité du garçon (le peureux, le chasseur, l'anxieux, le téméraire, le créatif...) — un joueur qui ne creuse pas voit juste des archétypes, celui qui creuse comprend.
- **Condition de fin de jeu** (genre déjà tranché session 23, façon Cult of the Lamb) : finir une run avec chaque starter débloque progressivement un **starter final**, le plus proche de qui est le garçon. Le finir à son tour propose une courte scène de fin ambiguë — le jeu continue après, pas d'arrêt.

**Règle non-négociable, insistée plusieurs fois par le user** : rien de tout ça ne doit être nommé ou montré frontalement en jeu (pas de personnage explicitement anxieux, pas de pathos) — uniquement suggéré par la narration environnementale déjà en place (objets, phrases courtes, indices), exactement le même geste que le choix des familles de jetons calées sur les 4 suites du tarot plutôt que sur un vocabulaire explicatif. Comparaison également posée avec Celeste et Hyper Light Drifter : le sens personnel fonctionne tant qu'il reste en sous-texte, jamais un argument affiché avant que le jeu soit jugé pour lui-même — sans quoi le risque de vanity project devient réel.

**GDD mis à jour** (voir Liens ci-dessous) : nouvelle section dans `pitch.md` ("Le sens caché"), lecture profonde ajoutée à `entity.md`, nouvelle section "Fin de run — le starter final" dans `structure-run.md`, deux nouvelles lignes dans `decisions-tranchees.md` (le sens caché du monde ; le genre + la condition de fin de jeu), `questions-ouvertes.md` mis à jour (Entity et habillage narratif des packs partiellement résolus, nouvelle question sur les détails précis du trigger de fin de jeu — gagner ou juste finir chaque starter, ordre, seuil).

## Liens

- [Questions ouvertes](../gdd/meta/questions-ouvertes.md) (ligne Boss Malus périmée retirée cette session ; section Univers mise à jour en fin de session)
- [Modifiers de cellules](../gdd/grille/modifiers-cellules.md)
- [Grille cabossée (trous)](../gdd/grille/trous.md)
- [Rocks](../gdd/jetons/rocks.md)
- [Forme du Shore](../gdd/shore/unlocks.md)
- [Pitch — le sens caché](../gdd/univers/pitch.md#le-sens-caché-privé--jamais-montré-en-jeu)
- [L'Entity — lecture profonde](../gdd/univers/personnages/entity.md#lecture-profonde-privée-session-24)
- [Structure du run — fin de run](../gdd/progression/structure-run.md#fin-de-run--le-starter-final)
- [Décisions tranchées](../gdd/meta/decisions-tranchees.md)
