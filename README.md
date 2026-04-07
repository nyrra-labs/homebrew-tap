# NYRRA Homebrew Tap

Homebrew formulae for NYRRA command-line tools.

This repo is the tap source of truth. Formulae are updated by repo-owned scripts and CI, not pushed in from each source repo.

## Packages

| Formula | Upstream | Notes |
|---|---|---|
| `nyrra-foundry-cli` | `nyrra-labs/nyrra-foundry-cli` GitHub Releases | Private darwin release assets. The current release archive also omits `templates/README.md`, so the formula patches that sentinel file during install to keep `templates` commands working. |
| `nyrra-signals` | `nyrra-labs/nyrra-signals` GitHub Releases | Private darwin arm64 release asset. Formula is macOS arm64 only for now. |

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

## Current Limitation

- `nyrra-foundry-cli` is still a private release repo, so this tap is currently NYRRA-internal.
- Automation can read those releases with the org-level `NYRRA_GH_TOKEN`.
- End-user Homebrew auth for private release downloads is not fully validated yet, so do not present the tap as a polished public install path until that is proven.
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
