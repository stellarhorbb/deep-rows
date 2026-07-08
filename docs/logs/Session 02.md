# Session 02 — Setup Git

**Date** : 2026-04-09
**Theme** : Initialisation du repo Git et push sur GitHub

---

## Ce qui a ete fait

- Init du repo Git local + remote `origin` → `stellarhorbb/deep-rows`
- Premier commit : config Godot, .editorconfig, .gitattributes, .gitignore
- Ajout de `docs/` et `CLAUDE.md` au .gitignore (pas en clair sur le repo public)
- Purge de CLAUDE.md de l'historique Git (filter-branch + force push)

## Decisions

- **docs/ et CLAUDE.md restent locaux uniquement** — le repo GitHub est public, ces fichiers contiennent le GDD et les instructions internes.

## Prochaines etapes

1. **Phase 1** : Resource scripts (TokenData, PatternData, GridData, PackData, EchoData, TokenStateData) + game_rules.gd
