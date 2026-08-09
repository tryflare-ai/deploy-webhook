# Flare Deploy Webhook

**Get an automatic security review after every deployment.**

Flare compares your cloud audit logs from *before* and *after* each deploy to catch IAM changes, new service accounts, permission escalations, and access pattern shifts. This GitHub Action triggers that comparison with a single step in your workflow.

## How it works

1. Your deployment completes
2. This action fires a webhook to Flare
3. Flare waits 60 minutes for post-deploy activity to accumulate
4. Flare fetches audit logs from before and after the deploy, compares them, and flags what changed
5. Results appear in your Flare dashboard with a "Post-deploy" badge

## Quick start

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # ... your deploy steps ...

      - name: Flare post-deploy security review
        uses: tryflare-ai/deploy-webhook@v1
        with:
          token: ${{ secrets.FLARE_WEBHOOK_TOKEN }}
```

## Setup

1. Sign up at [tryflare.ai](https://tryflare.ai/sign-up)
2. Connect your GCP project (OAuth, 60 seconds)
3. Go to **Connectors**, click **Generate webhook token** in the Deploy webhook section
4. Add the token as a repository secret: **Settings > Secrets > Actions > New repository secret** named `FLARE_WEBHOOK_TOKEN`
5. Add the step to your deploy workflow

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `token` | Yes | -- | Flare webhook token (starts with `flr_`). Generate from the Connectors page. |
| `commit-sha` | No | `${{ github.sha }}` | Git commit SHA of the deployment. |
| `branch` | No | `${{ github.ref_name }}` | Branch that was deployed. |
| `environment` | No | -- | Deployment environment (e.g., `production`, `staging`). |
| `api-url` | No | `https://www.tryflare.ai/api/webhooks/deploy` | Webhook endpoint. Override for self-hosted or staging. |

## Outputs

| Output | Description |
|--------|-------------|
| `analysis-at` | ISO timestamp when the post-deploy analysis will run. |
| `queued` | Whether the analysis was successfully queued (`true`/`false`). |

## Example: with environment

```yaml
- name: Flare post-deploy security review
  uses: tryflare-ai/deploy-webhook@v1
  with:
    token: ${{ secrets.FLARE_WEBHOOK_TOKEN }}
    environment: production
```

## Example: conditional (only on production deploys)

```yaml
- name: Flare post-deploy security review
  if: github.ref == 'refs/heads/main'
  uses: tryflare-ai/deploy-webhook@v1
  with:
    token: ${{ secrets.FLARE_WEBHOOK_TOKEN }}
    environment: production
```

## Example: use the output

```yaml
- name: Flare post-deploy security review
  id: flare
  uses: tryflare-ai/deploy-webhook@v1
  with:
    token: ${{ secrets.FLARE_WEBHOOK_TOKEN }}

- name: Print analysis time
  run: echo "Security review scheduled for ${{ steps.flare.outputs.analysis-at }}"
```

## What Flare detects

The post-deploy comparison focuses on what *changed* between the two windows:

- **New principals**: service accounts or users that only appear after the deploy
- **IAM mutations**: role bindings or policy changes introduced by the deploy
- **Permission escalations**: actions requiring higher privileges than pre-deploy activity
- **New IP addresses**: source IPs that appear only in the post-deploy window
- **Frequency shifts**: operations that existed before but now occur at different rates
- **Disappeared patterns**: regular activity that stops after the deploy

## Requirements

- A Flare account with a connected GCP connector ([sign up](https://tryflare.ai/sign-up))
- `jq` and `curl` available in the runner (included in all GitHub-hosted runners)

## Documentation

- [GCP Audit Log anomaly detection](https://tryflare.ai/gcp-audit-log-anomaly-detection)
- [Deploy Webhooks docs](https://docs.tryflare.ai/deploy-webhooks)
- [Flare documentation](https://docs.tryflare.ai)

## License

MIT
