# NYRRA Homebrew Tap

Homebrew formulae for NYRRA command-line tools.

This repo is the tap source of truth. Formulae are updated by repo-owned scripts and CI, not pushed in from each source repo.

## Packages

| Formula | Upstream | Notes |
|---|---|---|
| `nyrra-foundry-cli` | `nyrra-labs/nyrra-foundry-cli` GitHub Releases | Private darwin release assets fetched through the GitHub Releases API. The formula reads `HOMEBREW_GITHUB_API_TOKEN`, `GH_TOKEN`, `GITHUB_TOKEN`, or `NYRRA_GH_TOKEN`, and falls back to `gh auth token` when available. The current release archive also omits `templates/README.md`, so the formula patches that sentinel file during install to keep `templates` commands working. |
| `nyrra-signals` | `nyrra-labs/nyrra-signals` GitHub Releases | Private darwin arm64 release asset fetched through the GitHub Releases API. The formula reads `HOMEBREW_GITHUB_API_TOKEN`, `GH_TOKEN`, `GITHUB_TOKEN`, or `NYRRA_GH_TOKEN`, and falls back to `gh auth token` when available. |

## Automation

- `.github/workflows/version-bumps.yml` runs on a schedule or manual dispatch, refreshes formula versions/checksums, and opens or updates a PR.
- `.github/workflows/validate.yml` checks Ruby syntax and verifies that the generated formulae are in sync with the updater scripts.

## Usage

Once the GitHub repo exists as `nyrra-labs/homebrew-tap`:

```bash
brew tap nyrra-labs/tap
brew install nyrra-labs/tap/nyrra-foundry-cli
brew install nyrra-labs/tap/nyrra-signals
```

If `gh` is not installed or not logged in locally, run installs with an explicit token:

```bash
HOMEBREW_GITHUB_API_TOKEN="$(gh auth token)" brew install nyrra-labs/tap/nyrra-foundry-cli
HOMEBREW_GITHUB_API_TOKEN="$(gh auth token)" brew install nyrra-labs/tap/nyrra-signals
```

## Current Limitation

- `nyrra-foundry-cli` is still a private release repo, so this tap is currently NYRRA-internal.
- Automation can read those releases with the org-level `NYRRA_GH_TOKEN`.
- `nyrra-foundry-cli` and `nyrra-signals` both use authenticated GitHub Releases API downloads for private assets, but the broader private-package story is still internal-only.
- `nyrra-signals` is currently macOS arm64 only.

## Local Usage

Update formulae:

```bash
./scripts/update-formulae.sh auto
```

Validate formulae:

```bash
./scripts/validate-formulae.sh
```

## Adding a New Formula

1. Create `Formula/<name>.rb`.
2. Add a dedicated updater script in `scripts/` if the formula should auto-track upstream releases.
3. Extend `./scripts/update-formulae.sh`.
4. Keep the tap README and setup docs aligned with whatever auth story the formula actually requires.
