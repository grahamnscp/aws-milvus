#!/bin/bash

source ./params.sh
source ./utils/utils.sh

export KUBECONFIG=./local/admin.conf

# --------------------------------------------------------------------
# suse application collection auth
Log "\_Authenticating local helm cli to SUSE Application Collection registry.."
helm registry login dp.apps.rancher.io/charts -u $APPCOL_USER -p $APPCOL_TOKEN

# ----------------------------
Log "\_Creating suse-ai namespace.."
kubectl --kubeconfig=./local/admin.conf create namespace suse-ai

Log "\_Creating a application-collection secret for suse-ai.."
kubectl --kubeconfig=./local/admin.conf create secret docker-registry application-collection --docker-server=dp.apps.rancher.io --docker-username=$APPCOL_USER --docker-password=$APPCOL_TOKEN -n suse-ai

# ----------------------------
# kafka
Log " \_Creating kafka helm chart values.."
cat << KEOF >./local/kafka-values.yaml
global:
  imagePullSecrets:
  - application-collection

cluster:
  nodeCount:
    controller: 3
    broker: 3
    clusterIDKey: clusterID

persistence:
  enabled: true
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 8Gi
  storageClassName: longhorn
KEOF

Log " \_Installing kafka.."
helm upgrade --kubeconfig=./local/admin.conf \
  --install kafka oci://dp.apps.rancher.io/charts/apache-kafka \
  -n suse-ai \
  -f ./local/kafka-values.yaml \
  --timeout=5m

# --------------------------------------------------------------------

LogCompleted "Done."

# tidy up
exit 0
