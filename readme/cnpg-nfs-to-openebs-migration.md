# Migrating a CloudNativePG cluster from NFS to OpenEBS

This runbook migrates `cnpg-default` or `cnpg-vectorchord` from its existing
`nfs-subdir` PVC to a three-instance `openebs-hostpath` cluster. It is a
controlled maintenance operation, not an in-place StorageClass conversion.

## Why a rolling storage recreation is required

Kubernetes does not move an existing PVC when `storageClass` changes. Scaling a
one-instance NFS cluster directly to three instances leaves the existing
primary on NFS, but causes CNPG to create the two *new* replicas with the new
OpenEBS StorageClass. The procedure below uses those healthy, caught-up
OpenEBS replicas to make a controlled switchover, then has CNPG replace the
remaining NFS-backed standby. This avoids a full restore/recovery cutover.

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

5. Take and verify a fresh Barman backup while the database remains online. Do
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

1. Keep application writers running while CNPG creates and catches up the two
   OpenEBS replicas. Confirm the applications retry database connections: a
   controlled switchover briefly disconnects existing sessions, but does not
   require a planned write outage or a restore.
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
   `storage.resizeInUseVolumes: false`, `openebs-hostpath`, `enablePDB: true`,
   `primaryUpdateMethod: switchover`, the two required anti-affinity rules, and
   only `r` in `disabledDefaultServices`.

   ```bash
   kubectl kustomize "kubernetes/cluster/default/${CLUSTER}" > "/tmp/${CLUSTER}.yaml"
   rg -n 'instances: 3|resizeInUseVolumes: false|openebs-hostpath|enablePDB: true|primaryUpdateMethod: switchover|disabledDefaultServices|topologyKey' \
     "/tmp/${CLUSTER}.yaml"
   ```

4. Apply the rendered desired state without deleting the Cluster. CNPG retains
   the existing NFS primary and creates two new replicas. Wait for both new
   instances to be Ready and fully caught up; verify that their PVCs use
   `openebs-hostpath`. Do not continue if either replica is lagging, not Ready,
   or on an unsuitable node.

   ```bash
   kubectl apply -f "/tmp/${CLUSTER}.yaml"
   kubectl -n default wait --for=condition=Ready "cluster/${CLUSTER}" --timeout=2h
   kubectl -n default get cluster "$CLUSTER" -o wide
   kubectl -n default get pods -l "cnpg.io/cluster=${CLUSTER}" -o wide
   kubectl -n default get pvc -o wide | rg "^${CLUSTER}-"
   ```

   Identify the two OpenEBS instances from the PVC StorageClass rather than
   assuming a numeric instance name. Confirm their recovery state and LSN
   position with the CNPG status output before proceeding.

5. Announce the brief connection-retry window, choose one verified OpenEBS
   replica, and make it primary with a controlled CNPG switchover. Confirm
   that the selected instance owns the `-rw` service afterwards. Do **not**
   delete a Pod to force promotion.

   ```bash
   OPENEBSP_PRIMARY=<verified-openebs-instance-name-or-number>
   kubectl cnpg promote "$CLUSTER" "$OPENEBSP_PRIMARY" -n default
   kubectl -n default wait --for=condition=Ready "cluster/${CLUSTER}" --timeout=15m
   kubectl -n default get cluster "$CLUSTER" -o wide
   kubectl -n default get pods -l "cnpg.io/cluster=${CLUSTER}" -o wide
   kubectl -n default get endpointslice -l kubernetes.io/service-name="${CLUSTER}-rw"
   ```

6. The former NFS primary is now a standby. Record its PVC/PV names and ensure
   its PV uses `Retain`. Remove that instance through CNPG, not by deleting its
   Pod or PVC directly. CNPG creates a new replica from the OpenEBS primary;
   wait for that replacement to become Ready before doing anything else.

   ```bash
   NFS_INSTANCE=<former-primary-instance-number>
   kubectl -n default get pvc "${CLUSTER}-${NFS_INSTANCE}" -o wide
   kubectl get pv -o wide | rg "${CLUSTER}-${NFS_INSTANCE}"
   kubectl cnpg destroy "$CLUSTER" "$NFS_INSTANCE" -n default
   kubectl -n default wait --for=condition=Ready "cluster/${CLUSTER}" --timeout=2h
   kubectl -n default get pods -l "cnpg.io/cluster=${CLUSTER}" -o wide
   kubectl -n default get pvc -o wide | rg "^${CLUSTER}-"
   ```

   Keep the released NFS PV intact as rollback evidence. If any other
   NFS-backed standby remains, repeat this step for one instance at a time,
   waiting for its OpenEBS replacement to be Ready before continuing.

7. Verify all three data volumes and instances while application writers have
   reconnected. The
   external-cluster entry must still read the old archive prefix, while the
   plugin writes new WAL/base backups to the distinct `<cluster>-openebs`
   prefix. Never set `skipEmptyWalArchiveCheck` to bypass this separation.

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

8. Apply the Borgmatic Kustomization and run one on-demand Borgmatic database
   backup. Verify its PostgreSQL connection uses `<cluster>-ro` and the dump
   succeeds. It should fail rather than fall back to the leader if no replica
   is ready.
9. Confirm application writers have reconnected successfully, then remove the
   Argo CD guard and confirm it reports `Synced` and `Healthy`:

   ```bash
   kubectl -n argocd annotate application "$CLUSTER" \
     argocd.argoproj.io/skip-reconcile-
   kubectl -n argocd get application "$CLUSTER"
   ```

## Rollback

Before promotion, stop the failed replacement and retain both the OpenEBS PVCs
and the released NFS PV for forensics. Reapply the prior Git revision and keep
the original NFS primary serving. After promotion, do not attempt to
re-promote the retained NFS data: recover/PITR from the last verified Barman
backup if the OpenEBS primary cannot continue. Reverting to the old NFS copy
after the switchover would discard writes already accepted by the OpenEBS
primary.

## References

- [CloudNativePG service management](https://cloudnative-pg.io/docs/1.29/service_management/)
- [CloudNativePG storage recreation](https://cloudnative-pg.io/docs/current/storage/)
- [CloudNativePG kubectl plugin](https://cloudnative-pg.io/docs/current/kubectl-plugin/)
- [CloudNativePG recovery](https://cloudnative-pg.io/docs/1.26/recovery/)
- [Barman Cloud plugin restore workflow](https://cloudnative-pg.io/plugin-barman-cloud/docs/usage/)
