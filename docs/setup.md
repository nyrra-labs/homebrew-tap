# Setup

## Temporary Mode

Use this first.

1. Create the GitHub repository as `nyrra-labs/homebrew-tap`.
2. Push this repo.
3. In `Settings -> Actions -> General`:
   - set workflow permissions to `Read and write`
   - enable `Allow GitHub Actions to create and approve pull requests`
4. Attach the org-level `NYRRA_GH_TOKEN` secret to `homebrew-tap` if you want private NYRRA formulae to update automatically.
5. Run the `version-bumps` workflow manually.

Result:

- branch and PR creation use the repo `GITHUB_TOKEN`
- private NYRRA formula refreshes work only if the repo can read `NYRRA_GH_TOKEN`
- there is no separate publish workflow because the tap repo itself is the distribution surface

## Org-Level Secret

This org secret already exists:

```bash
NYRRA_GH_TOKEN
```

Attach it to the tap repo with:

```bash
gh secret set NYRRA_GH_TOKEN \
  --org nyrra-labs \
  --repos homebrew-tap \
  --body "$(gh auth token)"
```

## Local Operator Flow

If you are logged into GitHub locally with `gh auth login`, you can run:

```bash
./scripts/update-formulae.sh all
./scripts/validate-formulae.sh
```

That uses your local GitHub CLI session for private release access.

## Current Limitation

The first formula, `nyrra-foundry-cli`, can be generated and maintained automatically, but private Homebrew install auth is still an internal-only story until it is validated end-to-end on macOS.

## Recommended Follow-Up

1. Attach `NYRRA_GH_TOKEN` to this repo once it exists.
2. Validate a real `brew install nyrra-labs/tap/nyrra-foundry-cli` flow on macOS with a user who has access to the private upstream repo.
3. Add `nyrra-signals` once the darwin release artifacts exist.
