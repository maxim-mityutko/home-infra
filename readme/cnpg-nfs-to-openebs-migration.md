# Migrating a CloudNativePG cluster from NFS to OpenEBS

This runbook migrates `cnpg-default` or `cnpg-vectorchord` from its existing
`nfs-subdir` PVC to a three-instance `openebs-hostpath` cluster. It is a
controlled maintenance operation, not an in-place StorageClass conversion.

## Why a cutover is required

Kubernetes does not move an existing PVC when `storageClass` changes. Scaling a
one-instance NFS cluster directly to three instances would leave the existing
primary on NFS, which does not meet the target state. The procedure below
recovers a replacement cluster from a fresh physical Barman backup and creates
all three data PVCs on OpenEBS.

The target manifests intentionally:

- create three instances with a PDB;
- use `openebs-hostpath` and the same control-plane/SSD node selection plus
  hostname and zone anti-affinity as `cnpg-ha`;
- retain the old Barman archive as the recovery source, but use a new archive
  server name (`<cluster>-openebs`) after the cutover; and
- enable CNPG's `-ro` service. Borgmatic uses that service for logical dumps,
  so it cannot load the primary.

`openebs-hostpath` is node-local storage. HA comes from PostgreSQL replication
and scheduling replicas on different nodes; it does not make an individual
volume portable if its node is permanently lost.

## Preconditions

1. Schedule a maintenance window. `cnpg-default` serves the *arr services and
   VictoriaMetrics; `cnpg-vectorchord` serves Immich.
2. Review and approve the corresponding final-state PR, but do **not** merge
   it yet. Argo CD reconciliation is paused immediately before that merge.
3. Confirm every target node is Ready and has the required SSD/control-plane
   labels. Three distinct matching nodes are required.
4. Confirm the current cluster and its most recent scheduled backup are
   healthy:

   ```bash
   CLUSTER=cnpg-default # or cnpg-vectorchord
   kubectl -n default get cluster "$CLUSTER"
   kubectl -n default get scheduledbackup "${CLUSTER}-backup" -o wide
   kubectl -n default get backup -l cnpg.io/cluster="$CLUSTER" -o wide
   ```

5. Take and verify a fresh Barman backup after write traffic is quiesced. Do
   not rely on the scheduled backup being recent enough for the maintenance
   window. The exact `Backup` object must report `completed` with no error
   before proceeding.

   ```bash
   CLUSTER=cnpg-default # or cnpg-vectorchord
   BACKUP="${CLUSTER}-pre-openebs-$(date -u +%Y%m%d%H%M%S)"
   kubectl -n default apply -f - <<EOF
   apiVersion: postgresql.cnpg.io/v1
   kind: Backup
   metadata:
     name: ${BACKUP}
   spec:
     cluster:
       name: ${CLUSTER}
     method: plugin
     pluginConfiguration:
       name: barman-cloud.cloudnative-pg.io
   EOF
   kubectl -n default wait --for=jsonpath='{.status.phase}'=completed \
     "backup/${BACKUP}" --timeout=2h
   kubectl -n default get "backup/${BACKUP}" -o yaml
   ```

## Cutover

Perform one cluster at a time. Keep the old NFS PV intact until post-cutover
validation has completed.

1. Stop or scale down every writer for the selected cluster. Confirm no active
   client sessions remain except the migration operator.
2. Prevent Argo CD from reconciling the target Application while the old
   cluster is being removed. This annotation is deliberately temporary:

   ```bash
   CLUSTER=cnpg-default # or cnpg-vectorchord
   kubectl -n argocd annotate application "$CLUSTER" \
     argocd.argoproj.io/skip-reconcile=true --overwrite
   kubectl -n argocd get application "$CLUSTER" -o yaml | \
     rg 'skip-reconcile|syncPolicy'
   ```

3. Ensure the final-state commit is on `main`, then render it locally and
   inspect the exact desired Cluster. It must show `instances: 3`,
   `openebs-hostpath`, `enablePDB: true`, `primaryUpdateMethod: switchover`,
   the two required anti-affinity rules, and only `r` in
   `disabledDefaultServices`.

   ```bash
   kubectl kustomize "kubernetes/cluster/default/${CLUSTER}" > "/tmp/${CLUSTER}.yaml"
   rg -n 'instances: 3|openebs-hostpath|enablePDB: true|primaryUpdateMethod: switchover|disabledDefaultServices|topologyKey' \
     "/tmp/${CLUSTER}.yaml"
   ```

4. Delete the old Cluster and **only its PVC**. The NFS StorageClass/PV uses a
   `Retain` policy, so do not delete the resulting PV. Confirm the names before
   each destructive command.

   ```bash
   kubectl -n default get cluster "$CLUSTER"
   kubectl -n default get pvc -o wide | rg "^${CLUSTER}-"
   kubectl -n default delete cluster "$CLUSTER" --wait=true
   kubectl -n default delete pvc "${CLUSTER}-1"
   kubectl get pv -o wide | rg "${CLUSTER}-1"
   ```

5. Apply the rendered final state. The external-cluster entry reads the old
   archive prefix, while the plugin writes new WAL/base backups to the distinct
   `<cluster>-openebs` prefix. Never set `skipEmptyWalArchiveCheck` to bypass
   this separation.

   ```bash
   kubectl apply -f "/tmp/${CLUSTER}.yaml"
   kubectl -n default wait --for=condition=Ready "cluster/${CLUSTER}" --timeout=2h
   ```

6. Verify all three data volumes and instances before resuming writers:

   ```bash
   kubectl -n default get cluster "$CLUSTER" -o wide
   kubectl -n default get pods -l "cnpg.io/cluster=${CLUSTER}" -o wide
   kubectl -n default get pvc -o wide | rg "^${CLUSTER}-"
   kubectl -n default get svc "${CLUSTER}-rw" "${CLUSTER}-ro"
   ```

   The three pods must be Ready, on distinct hostnames and zones, and all three
   PVCs must use `openebs-hostpath`. The `-ro` EndpointSlice must contain only
   replicas. Take a second successful CNPG backup to confirm the new archive
   prefix works.

7. Apply the Borgmatic Kustomization and run one on-demand Borgmatic database
   backup. Verify its PostgreSQL connection uses `<cluster>-ro` and the dump
   succeeds. It should fail rather than fall back to the leader if no replica
   is ready.
8. Resume application writers, then remove the Argo CD guard and confirm it
   reports `Synced` and `Healthy`:

   ```bash
   kubectl -n argocd annotate application "$CLUSTER" \
     argocd.argoproj.io/skip-reconcile-
   kubectl -n argocd get application "$CLUSTER"
   ```

## Rollback

Before writers resume, stop the failed replacement, retain its OpenEBS PVCs for
forensics, reapply the prior Git revision, and restore the retained NFS PV/PVC
only through an explicit Kubernetes PV reclaim procedure. Do not try to mount
the old NFS data directory into the new cluster. After any writer has resumed
on the replacement, use Barman recovery/PITR from the last verified backup
instead; rolling back to the old NFS copy would discard new writes.

## References

- [CloudNativePG service management](https://cloudnative-pg.io/docs/1.29/service_management/)
- [CloudNativePG recovery](https://cloudnative-pg.io/docs/1.26/recovery/)
- [Barman Cloud plugin restore workflow](https://cloudnative-pg.io/plugin-barman-cloud/docs/usage/)
