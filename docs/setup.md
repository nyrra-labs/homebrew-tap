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
- upstream `nyrra-signals` and `nyrra-foundry-cli` release workflows can also trigger this workflow automatically with `gh workflow run version-bumps.yml`, but that depends on `NYRRA_WORKFLOW_DISPATCH_TOKEN` being configured in those producer repos

## GitHub UI Links

- create PAT: <https://github.com/settings/personal-access-tokens>
- review active org PATs: <https://github.com/organizations/nyrra-labs/settings/personal-access-tokens/active>
- manage org Actions secrets: <https://github.com/organizations/nyrra-labs/settings/secrets/actions>

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

## NYRRA_WORKFLOW_DISPATCH_TOKEN

Create a fine-grained PAT that can trigger workflow dispatches in:

- `nyrra-labs/homebrew-tap`
- `nyrra-labs/pkgbuilds`

Store that PAT as the GitHub org secret `NYRRA_WORKFLOW_DISPATCH_TOKEN` with `selected` visibility for these producer repos:

- `nyrra-labs/nyrra-foundry-cli`
- `nyrra-labs/nyrra-signals`

Those producer release workflows run in Depot CI, so GitHub org secrets are not enough on their own. Mirror the same secret into Depot for each producer repo with one of these paths:

```bash
cd /home/anandpant/Development/nyrra/nyrra-foundry-cli
depot ci migrate secrets-and-vars -y

cd /home/anandpant/Development/nyrra/nyrra-signals
depot ci migrate secrets-and-vars -y
```

Or add the Depot secrets directly:

```bash
depot ci secrets add NYRRA_WORKFLOW_DISPATCH_TOKEN --repo nyrra-labs/nyrra-foundry-cli
depot ci secrets add NYRRA_WORKFLOW_DISPATCH_TOKEN --repo nyrra-labs/nyrra-signals
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

- `foundry-cli` installs the renamed CLI binary and prints completion setup snippets only
- `nyrra-foundry-cli` does not create a standalone `npc` binary; use the printed caveats to add the `npc` shell alias and completion snippet yourself
- `nyrra-signals` does not auto-open its first-run TUI; run `nyrra-signals setup` from a real terminal after install

`nyrra-signals` remains arm64-only on macOS for now.

## Recommended Follow-Up

1. Attach `NYRRA_GH_TOKEN` to this repo once it exists.
2. Validate real `brew install nyrra-labs/tap/nyrra-foundry-cli` and `brew install nyrra-labs/tap/nyrra-signals` flows on macOS with a user who has access to the private upstream repos.
3. Keep the package-manager caveats aligned with the upstream installers when shorthand or setup UX changes.
