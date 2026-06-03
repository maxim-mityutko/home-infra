# Agent Guide

This repository is a GitOps home infrastructure repo. Treat changes as production
cluster changes unless they are clearly documentation-only.

## Pull Requests

- Keep PRs focused on one service, feature, fix, or maintenance task.
- Use the PR title format from `.github/pull_request_template.md`:
  `[feature|bugfix|chore] Short description of the change`.
- Fill out the PR template with enough context for review:
  - what changed
  - why it changed
  - whether the change is a bug fix, new feature, or chore
  - any operational impact, migration, or follow-up needed
- For a new service, update `README.md` with the service name, short
  description, repository/docs links, and Docker or Helm links.
- If a new user-facing service should appear on the Homer dashboard, update
  `kubernetes/cluster/default/homer/config/config.yml`.
- Mention validation performed in the PR description. At minimum, inspect the
  generated or edited manifests and run the relevant checks available locally.
- Never include plaintext secrets. If a secret is required, create a placeholder
  and communicate the need for secret to the user.

## Repository Layout

- ArgoCD application manifests live in `kubernetes/argocd/<tier>/`.
- Kubernetes workload manifests live in `kubernetes/cluster/<area>/<service>/`.
- Shared resources use `x-<area>-shared` directories.
- Service directories usually include a `kustomization.yaml` plus separate files
  for the workload, ingress, volumes, scaler, secrets, dashboards, or scrapers as
  needed.

## Manifest Style

Prefer following existing manifests over inventing a new style. Good examples:

- `kubernetes/cluster/extras/code-server/`
- `kubernetes/cluster/privacy/filebrowser/`
- `kubernetes/argocd/07_extras/code-server.yaml`
- `kubernetes/cluster/monitoring/victoria-metrics/kustomization.yaml` for
  Kustomize-managed Helm charts with inline values

Use these conventions unless a nearby service has a stronger local pattern:

- Use `app.kubernetes.io/name: <service-name>` consistently for labels and
  selectors.
- Keep Kubernetes resource names, file names, directory names, container names,
  PVC names, and secret/config names in lowercase kebab-case.
- Put `namespace` in `metadata` and in the service `kustomization.yaml`.
- Keep one main workload file named after the service, for example
  `code-server.yaml` or `filebrowser.yaml`.
- Split supporting concerns into clear files such as `ingress.yaml`,
  `volumes.yaml`, `secret.yaml`, `scaler.yaml`, `service-scrape.yaml`, and
  `dns-endpoint.yaml`.
- Manage service-specific Grafana dashboards in the owning service directory
  with a `dashboards/kustomization.yaml` ConfigMap generator, following
  `kubernetes/cluster/default/cloudnative-pg/dashboards/`, instead of placing
  service dashboards in the Victoria Metrics kustomization.
- Use `revisionHistoryLimit: 1` for Deployments unless there is a reason not to.
- Use explicit resource requests. Add limits where the existing service pattern
  or workload risk calls for them.
- Use probes and security context where the application supports them, following
  `filebrowser` as a stronger example.
- Keep Kustomize resource lists sorted in a readable, intentional order rather
  than alphabetizing at the expense of clarity.

## Naming

- Area names match the existing top-level cluster folders, such as `default`,
  `monitoring`, `smart-home`, `privacy`, `media`, `backup`, `extras`, and `ai`.
- Service slugs are lowercase kebab-case and should match across:
  - `kubernetes/cluster/<area>/<service>/`
  - `kubernetes/argocd/<tier>/<service>.yaml`
  - `metadata.name`
  - `app.kubernetes.io/name`
  - container, service, PVC, secret, and config names where practical
- Hostnames generally use the public service name under `brhd.io`. Reuse nearby
  ingress patterns for annotations and authentication.

## Editing Rules

- Read nearby examples before changing manifests.
- Preserve existing user changes in the working tree.
- Keep unrelated refactors out of service PRs.
- Prefer small, reviewable YAML changes.
- If a change adds or updates an image, chart, or version, make sure the source
  link in `README.md` still points to the correct project.
