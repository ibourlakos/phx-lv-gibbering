# Git Policy

---

## Commit Messages — Conventional Commits

Format: `<type>(<scope>): <subject>`

- **type** and **scope** are lowercase
- **subject** is imperative, present tense ("add" not "added"), no trailing period
- Max 72 characters on the first line
- Body (optional) goes after a blank line — use it to explain *why*, not *what*

### Types

| Type | Use for |
|---|---|
| `feat` | New feature or behaviour |
| `fix` | Bug fix |
| `refactor` | Code change that is neither a fix nor a feature |
| `test` | Adding or updating tests |
| `docs` | Documentation only |
| `chore` | Maintenance — deps bump, config tweak, build change |
| `perf` | Performance improvement |
| `ci` | CI/CD pipeline changes |
| `revert` | Reverts a previous commit |

### Scopes (project-specific)

| Scope | Area |
|---|---|
| `engine` | Core game engine — State, GameServer, Rules |
| `rules` | Ruleset behaviour and DnD5e implementation |
| `pipeline` | SRD data ingestion and LegalGuard |
| `ui` | LiveView templates and components |
| `db` | Ecto schemas and migrations |
| `docker` | Compose, Dockerfile, container config |
| `legal` | Legal docs and compliance filter |
| `docs` | Documentation files under `docs/` |

Scope is optional but encouraged for anything non-trivial.

### Examples

```
feat(engine): add fog-of-war mask calculation to Rules module

fix(pipeline): handle missing modifier field in action damage parser

chore(docker): pin postgres image to 17.2-alpine

docs(legal): add GDPR section to legal reference

feat(rules): implement DnD5e attack roll resolution

refactor(engine): extract valid_moves into a pure function

test(pipeline): add legal_guard tests for forbidden lore variants

db: add source_license column to monsters and spells tables
```

---

## Branches

| Pattern | Use for |
|---|---|
| `main` | Stable, deployable state |
| `feat/<short-name>` | Feature development |
| `fix/<short-name>` | Bug fixes |
| `chore/<short-name>` | Maintenance, deps, config |
| `docs/<short-name>` | Documentation-only changes |

Branch names use kebab-case. Keep them short and descriptive.

```
feat/fog-of-war
fix/legal-guard-regex
chore/bump-phoenix-1.8
docs/architecture-ruleset
```

---

## Commit Hygiene

- **One logical change per commit.** Don't bundle a migration with a UI change.
- **Never commit directly to `main`.** All changes go through a branch + merge/PR.
- **No WIP or "fix" commits on long-lived branches.** Squash before merging.
- **No secrets, `.env` files, or generated files.** The `.gitignore` enforces this — if something slips through, remove it from history immediately (`git filter-repo`).

---

## Binary Assets & Git LFS

**Git LFS 3.0.2 is installed and required.** Binary files (sprites, tilesets, fonts, audio) are tracked via LFS — not as regular Git objects.

### Setup (one-time, per developer machine)

```bash
# Install git-lfs (Ubuntu/Debian)
sudo apt install git-lfs

# macOS
brew install git-lfs

# Activate for this repo (run once after cloning)
git lfs install
```

Tracked extensions are defined in `.gitattributes` (committed to the repo):

```
*.png  filter=lfs diff=lfs merge=lfs -text
*.jpg  filter=lfs diff=lfs merge=lfs -text
*.gif  filter=lfs diff=lfs merge=lfs -text
*.ttf  filter=lfs diff=lfs merge=lfs -text
*.otf  filter=lfs diff=lfs merge=lfs -text
*.wav  filter=lfs diff=lfs merge=lfs -text
*.ogg  filter=lfs diff=lfs merge=lfs -text
```

Do not add binary assets outside of these extensions without updating `.gitattributes` first.

---

## Legal Gate on Commits

Before committing any asset or data file:
1. Verify its license is acceptable per [docs/legal.md](legal.md)
2. Note the source and license in the commit body or in a companion `CREDITS` entry

When in doubt, do not commit — flag it for review.