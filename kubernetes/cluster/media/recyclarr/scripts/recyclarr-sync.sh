#!/bin/sh
#
# Run the scheduled Recyclarr sync against the configured Sonarr/Radarr
# instances. Requires the Recyclarr config ConfigMap and API token Secret.

/app/recyclarr/recyclarr sync
