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

# ----------------------------
# milvus OSS
#  https://milvus.io/docs/install_cluster-helm.md

Log "\_Installing milvus OSS database.."

Log " \_Adding milvus OSS helm repo.."
helm repo add milvus https://zilliztech.github.io/milvus-helm/

Log " \_Installing milvus OSS database.."
helm upgrade --kubeconfig=./local/admin.conf \
  --install milvus milvus/milvus \
  -n suse-ai \
  -f ./dev/milvus-oss-values.yaml \
  --set ignore-formatted=true \
  --timeout=10m

# --------------------------------------------------------------------

LogCompleted "Done."

# tidy up
exit 0
