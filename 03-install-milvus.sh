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
#Log "\_Creating cert-manager namespace.."
#kubectl --kubeconfig=./local/admin.conf create namespace cert-manager

#Log "\_Creating application-collection secret for cert-manager.."
#kubectl --kubeconfig=./local/admin.conf create secret docker-registry application-collection --docker-server=dp.apps.rancher.io --docker-username=$APPCOL_USER --docker-password=$APPCOL_TOKEN -n cert-manager

#Log "\_Installing cert-manager.."
#helm upgrade --kubeconfig=./local/admin.conf --install cert-manager \
#  oci://dp.apps.rancher.io/charts/cert-manager \
#  -n cert-manager \
#  --set crds.enabled=true \
#  --set 'global.imagePullSecrets[0].name'=application-collection

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
  messageQueue: rocksmq
  persistence:
    mountPath: "/var/lib/milvus"
    enabled: true
    persistentVolumeClaim:
      storageClass: longhorn
      size: 20Gi
etcd:
  replicaCount: 1
  persistence:
    storageClassName: longhorn
minio:
  mode: distributed
  replicas: 4
  rootUser: "admin"
  rootPassword: "adminminio"
  persistence:
    storageClass: longhorn
    size: 30Gi
  resources:
    requests:
      memory: 1024Mi
kafka:
  name: kafka
  enabled: false
MV1EOF

cat << MVEOF >./local/milvus-values.yaml
global:
  imagePullSecrets:
  - application-collection
cluster:
  enabled: true
standalone:
  messageQueue: kafka
  persistence:
    enabled: true
    mountPath: "/var/lib/milvus"
    persistentVolumeClaim:
      storageClass: longhorn
      size: 20Gi
etcd:
  replicaCount: 3
  persistence:
    storageClassName: longhorn
minio:
  mode: distributed
  replicas: 4
  rootUser: "admin"
  rootPassword: "adminminio"
  persistence:
    storageClass: longhorn
    size: 10Gi
  resources:
    requests:
      memory: 1024Mi
kafka:
  name: kafka
  enabled: true
  persistence:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 8Gi
    storageClassName: longhorn
MVEOF

Log " \_Installing milvus database.."
helm upgrade --kubeconfig=./local/admin.conf \
  --install milvus oci://dp.apps.rancher.io/charts/milvus \
  -n suse-ai \
  -f ./local/milvus-values-nokafka.yaml \
  --set ignore-formatted=true \
  --timeout=5m

# --------------------------------------------------------------------

LogCompleted "Done."

# tidy up
exit 0
