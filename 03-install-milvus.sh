#!/bin/bash

source ./params.sh
source ./utils/utils.sh

export KUBECONFIG=./local/admin.conf

# --------------------------------------------------------------------
# suse application collection auth
Log "\_Authenticating local helm cli to SUSE Application Collection registry.."
helm registry login dp.apps.rancher.io/charts -u $APPCOL_USER -p $APPCOL_TOKEN

# ----------------------------
# install cert manager 
Log "\_Creating cert-manager namespace.."
kubectl --kubeconfig=./local/admin.conf create namespace cert-manager

Log "\_Creating application-collection secret for cert-manager.."
kubectl --kubeconfig=./local/admin.conf create secret docker-registry application-collection --docker-server=dp.apps.rancher.io --docker-username=$APPCOL_USER --docker-password=$APPCOL_TOKEN -n cert-manager

Log "\_Installing cert-manager.."
helm upgrade --kubeconfig=./local/admin.conf --install cert-manager \
  oci://dp.apps.rancher.io/charts/cert-manager \
  -n cert-manager \
  --set crds.enabled=true \
  --set 'global.imagePullSecrets[0].name'=application-collection

# ----------------------------
Log "\_Creating suse-ai namespace.."
kubectl --kubeconfig=./local/admin.conf create namespace suse-ai

Log "\_Creating a application-collection secret for suse-ai.."
kubectl --kubeconfig=./local/admin.conf create secret docker-registry application-collection --docker-server=dp.apps.rancher.io --docker-username=$APPCOL_USER --docker-password=$APPCOL_TOKEN -n suse-ai

# ----------------------------
# milvus
#  https://documentation.suse.com/suse-ai/1.0/html/AI-deployment-intro/index.html#milvus-installing
#  https://github.com/milvus-io/milvus-helm/tree/master/charts/milvus

Log "\_Installing milvus database.."

Log " \_Creating milvus helm chart values.."
cat << MV1EOF >./local/milvus-values-nokafka.yaml
global:
  imagePullSecrets:
  - application-collection
cluster:
  enabled: false
standalone:
  persistence:
    persistentVolumeClaim:
      storageClass: longhorn
etcd:
  replicaCount: 1
  persistence:
    storageClassName: longhorn
minio:
  mode: distributed
  replicas: 2
  rootUser: "admin"
  rootPassword: "adminminio"
  persistence:
    storageClass: longhorn
    size: 30Gi
  resources:
    requests:
      memory: 1024Mi
kafka:
  enabled: false
  name: kafka
MV1EOF

cat << MVEOF >./local/milvus-values.yaml
global:
  imagePullSecrets:
  - application-collection
cluster:
  enabled: true
standalone:
  persistence:
    persistentVolumeClaim:
      storageClass: longhorn
etcd:
  replicaCount: 1
  persistence:
    storageClassName: longhorn
minio:
  mode: distributed
  replicas: 2
  rootUser: "admin"
  rootPassword: "adminminio"
  persistence:
    storageClass: longhorn
    size: 30Gi
  resources:
    requests:
      memory: 1024Mi
kafka:
  persistence:
    storageClassName: longhorn
MVEOF

Log " \_Installing milvus database.."
helm upgrade --kubeconfig=./local/admin.conf \
  --install milvus oci://dp.apps.rancher.io/charts/milvus \
  -n suse-ai \
  -f ./local/milvus-values.yaml \
  --timeout=10m

# --------------------------------------------------------------------

LogCompleted "Done."

# tidy up
exit 0
