#!/bin/sh
#
# Restart the Multus DaemonSet on a daily schedule. Requires the CronJob service
# account to be allowed to restart daemonsets in kube-system.

kubectl rollout restart daemonset/multus
