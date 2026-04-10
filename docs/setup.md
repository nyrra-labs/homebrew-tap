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

For local `brew install nyrra-labs/tap/nyrra-signals`, the formula uses the same auth path:

- it first checks `HOMEBREW_GITHUB_API_TOKEN`, `GH_TOKEN`, `GITHUB_TOKEN`, and `NYRRA_GH_TOKEN`
- if none are set, it falls back to `gh auth token`
- in headless environments, prefer `HOMEBREW_GITHUB_API_TOKEN="$(gh auth token)" brew install ...`

## Package-Manager Install Behavior

Both private formulae now use install-side GitHub auth:

- they check `HOMEBREW_GITHUB_API_TOKEN`, `GH_TOKEN`, `GITHUB_TOKEN`, and `NYRRA_GH_TOKEN`
- if no token env var is present, they fall back to `gh auth token`

Package-manager installs still intentionally avoid mutating your shell config:

- `nyrra-foundry-cli` does not create a standalone `npc` binary; use the printed caveats to add the `npc` shell alias and completion snippet yourself
- `nyrra-signals` does not auto-open its first-run TUI; run `nyrra-signals setup` from a real terminal after install

`nyrra-signals` remains arm64-only on macOS for now.

## Recommended Follow-Up

1. Attach `NYRRA_GH_TOKEN` to this repo once it exists.
2. Validate real `brew install nyrra-labs/tap/nyrra-foundry-cli` and `brew install nyrra-labs/tap/nyrra-signals` flows on macOS with a user who has access to the private upstream repos.
3. Keep the package-manager caveats aligned with the upstream installers when shorthand or setup UX changes.
