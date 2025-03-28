#!/bin/bash

source ./params.sh
source ./utils/utils.sh
source ./load-tf-output.sh

# -------------------------------------------------------------------------------------
# Functions:

#
function rke2installmaster1
{
  Log "function rke2installmaster1: started.."

  # first instance
  NODENAME=${MASTER_NAME[1]}
  NODEIP=${MASTER_PUBLIC_IP[1]}
  PRIVATEIP=${MASTER_PRIVATE_IP[1]}
  NODEN=$(echo $NODENAME | cut -d. -f1)

  Log "\__Creating cluster rke2 config.yaml.."
  cat << EOF >./local/rke2-config.yaml
token: $RKE2_TOKEN
tls-san:
- $NODENAME
- $NODEIP
- ${MASTER_NAME[2]}
- ${MASTER_NAME[3]}
- ${MASTER_PUBLIC_IP[2]}
- ${MASTER_PUBLIC_IP[3]}
- rke.$DOMAINNAME
EOF
  ssh $SSH_OPTS ${SSH_USERNAME}@${NODEIP} "sudo mkdir -p /etc/rancher/rke2"
  scp $SSH_OPTS ./local/rke2-config.yaml ${SSH_USERNAME}@${NODEIP}:~/config.yaml
  ssh $SSH_OPTS ${SSH_USERNAME}@${NODEIP} "sudo cp config.yaml /etc/rancher/rke2/"

  Log "\__Installing RKE2 ($NODENAME).."
  ssh $SSH_OPTS ${SSH_USERNAME}@${NODEIP} "sudo bash -c 'curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=${RKE2_VERSION} sh - 2>&1 > /root/rke2-install.log 2>&1'"
  ssh $SSH_OPTS ${SSH_USERNAME}@${NODEIP} "sudo systemctl enable rke2-server.service"
  Log "\__Starting rke2-server.service.."
  ssh $SSH_OPTS ${SSH_USERNAME}@${NODEIP} "sudo systemctl start rke2-server.service"


  Log "\__Waiting for kubeconfig file to be created.."
  WAIT=30
  UP=false
  while ! $UP
  do
    ssh $SSH_OPTS ${SSH_USERNAME}@${NODEIP} "sudo test -e /etc/rancher/rke2/rke2.yaml && exit 10 </dev/null"
    if [ $? -eq 10 ]; then
      Log " \__Cluster is now configured."
      UP=true
    else
      sleep $WAIT
    fi
  done

  Log "\__Downloading kube admin.conf locally.."
  ssh $SSH_OPTS ${SSH_USERNAME}@${NODEIP} "sudo cp /etc/rancher/rke2/rke2.yaml ~/admin.conf"
  ssh $SSH_OPTS ${SSH_USERNAME}@${NODEIP} "sudo chown ${SSH_USERNAME}:users ~/admin.conf"
  ssh $SSH_OPTS ${SSH_USERNAME}@${NODEIP} "sudo chmod 600 ~/admin.conf"
  ssh $SSH_OPTS ${SSH_USERNAME}@${NODEIP} "echo export KUBECONFIG=~/admin.conf >> ~/.bashrc"

  # Local admin.conf
  mkdir -p ./local
  if [ -f ./local/admin.conf ] ; then rm ./local/admin.conf ; fi
  scp $SSH_OPTS ${SSH_USERNAME}@${NODEIP}:~/admin.conf ./local/admin.conf
  sed -i '' "s/127.0.0.1/rke.$DOMAINNAME/g" ./local/admin.conf
  chmod 600 ./local/admin.conf
  
  Log "\__adding kubectl link to bin.."
  KDIR=`ssh $SSH_OPTS ${SSH_USERNAME}@${NODEIP} "ls /var/lib/rancher/rke2/data/"`
  ssh $SSH_OPTS ${SSH_USERNAME}@${NODEIP} "cd /usr/local/bin ; sudo ln -s /var/lib/rancher/rke2/data/$KDIR/bin/kubectl kubectl"
  ssh $SSH_OPTS ${SSH_USERNAME}@${NODEIP} "sudo bash -c 'echo export KUBECONFIG=/etc/rancher/rke2/rke2.yaml >> /root/.bashrc'"
  ssh $SSH_OPTS ${SSH_USERNAME}@${NODEIP} "sudo bash -c 'echo alias k=kubectl >> /root/.bashrc'"

  LogElapsedDuration
}


#
function rke2joinmasterx
{
  NODENUM=$1

  Log "function rke2joinmasterx: for master$NODENUM"

  Log "\_Joining RKE2 master (${MASTER_PUBLIC_IP[${NODENUM}]}).."

  ANODEIP=${MASTER_PUBLIC_IP[$NODENUM]}
  ANODENAME=${MASTER_NAME[$NODENUM]}
  APRIVATEIP=${MASTER_PRIVATE_IP[$NODENUM]}
  ANODEN=$(echo $ANODENAME | cut -d. -f1)

  Log "\__Creating RKE2 join config.yaml.."

  cat << EOF >./local/rke2-join-config.yaml
server: https://${MASTER_PRIVATE_IP[1]}:9345
token: $RKE2_TOKEN
tls-san:
- ${MASTER_NAME[1]}
- ${MASTER_NAME[2]}
- ${MASTER_NAME[3]}
- ${MASTER_PUBLIC_IP[1]}
- ${MASTER_PUBLIC_IP[2]}
- ${MASTER_PUBLIC_IP[3]}
- rke.$DOMAINNAME
EOF

  scp $SSH_OPTS ./local/rke2-join-config.yaml ${SSH_USERNAME}@${ANODEIP}:~/config.yaml
  ssh $SSH_OPTS ${SSH_USERNAME}@${ANODEIP} "sudo mkdir -p /etc/rancher/rke2"
  ssh $SSH_OPTS ${SSH_USERNAME}@${ANODEIP} "sudo cp config.yaml /etc/rancher/rke2/"

  Log "\__Installing RKE2 (master$NODENUM).."
  ssh $SSH_OPTS ${SSH_USERNAME}@${ANODEIP} "sudo bash -c 'curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=${RKE2_VERSION} sh - 2>&1 > /root/rke2-install.log 2>&1'"
  ssh $SSH_OPTS ${SSH_USERNAME}@${ANODEIP} "sudo systemctl enable rke2-server.service"
  Log "\__Starting rke2-server.service.."
  ssh $SSH_OPTS ${SSH_USERNAME}@${ANODEIP} "sudo systemctl start rke2-server.service"
}


#
function rke2joinagentx
{
  AGENTNUM=$1

  Log "function rke2joinagentx: for agent$AGENTNUM"

  AAGENTNAME=${AGENT_NAME[$AGENTNUM]}
  AAGENTIP=${AGENT_PUBLIC_IP[$AGENTNUM]}
  AAGENTN=$(echo $AAGENTNAME | cut -d. -f1)

  Log "\_Joining RKE2 agent$AAGENTN ($AAGENTIP).."

  Log "\__Creating agent config-agent.yaml.."
  cat << EOF >./local/rke2-config-agent.yaml
server: https://${MASTER_PRIVATE_IP[1]}:9345
token: $RKE2_TOKEN
EOF

  ssh $SSH_OPTS ${SSH_USERNAME}@${AAGENTIP} "sudo mkdir -p /etc/rancher/rke2"
  scp $SSH_OPTS ./local/rke2-config-agent.yaml ${SSH_USERNAME}@${AAGENTIP}:~/config.yaml
  ssh $SSH_OPTS ${SSH_USERNAME}@${AAGENTIP} "sudo cp config.yaml /etc/rancher/rke2/"

  Log "\__RKE2 join agent$AGENTNUM ($AAGENTN).."
  ssh $SSH_OPTS ${SSH_USERNAME}@${AAGENTIP} "sudo bash -c 'curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=${RKE2_VERSION} INSTALL_RKE2_TYPE=\"agent\" sh - 2>&1 > /root/rke2-install.log 2>&1'"

  Log "\__Starting rke2-agent.service.."
  ssh $SSH_OPTS ${SSH_USERNAME}@${AAGENTIP} "sudo systemctl enable rke2-agent.service"
  ssh $SSH_OPTS ${SSH_USERNAME}@${AAGENTIP} "sudo systemctl start rke2-agent.service"
}


#
function rke2nodewait
{
  NODENUM=$1
  PUBLIC_IP=$2

  Log "function rke2nodewait: for cluster node $NODENUM (IP: $PUBLIC_IP)"

  # wait until cluster nodes ready
  Log "\_Waiting for RKE2 cluster node $NODENUM ($PUBLIC_IP) to be Ready.."
  READY=false
  while ! $READY
  do
    NRC=`kubectl --kubeconfig=./local/admin.conf get nodes 2>&1 | egrep 'NotReady|connection refused|no such host' | wc -l`
    if [ $NRC -eq 0 ]; then
      echo -n 0
      echo
      Log " \__RKE2 cluster nodes are Ready:"
      kubectl --kubeconfig=./local/admin.conf get nodes
      READY=true
    else
      echo -n ${NRC}.
      sleep 10
    fi
  done

  # wait until cluster fully up
  Log "\_Waiting for RKE2 cluster to be fully initialised.."
  sleep 30
  READY=false
  while ! $READY
  do
    NRC=`kubectl --kubeconfig=./local/admin.conf get pods --all-namespaces 2>&1 | egrep -v 'Running|Completed|NAMESPACE' | wc -l`
    if [ $NRC -eq 0 ]; then
      echo -n 0
      echo
      Log " \__RKE2 new cluster node is now initialised."
      READY=true
    else
      echo -n ${NRC}.
      sleep 10
    fi
  done
}

# -------------------------------------------------------------------------------------

# Main
#

NODEN=$(echo ${MASTER_NAME[1]} | cut -d. -f1)

LogStarted "Installing initial RKE2 master$NODEN (HOST: ${MASTER_NAME[1]} IP: ${MASTER_PUBLIC_IP[1]} ${MASTER_PRIVATE_IP[1]}).."
rke2installmaster1

# wait until cluster nodes ready
rke2nodewait 1 ${MASTER_PUBLIC_IP[1]}
LogElapsedDuration

echo
Log "Installing other RKE2 master nodes.."
echo

# Join master 2
rke2joinmasterx 2
LogElapsedDuration

rke2nodewait 2 ${MASTER_PUBLIC_IP[2]}
LogElapsedDuration

# Join master 3
rke2joinmasterx 3
LogElapsedDuration

rke2nodewait 3 ${MASTER_PUBLIC_IP[3]}
LogElapsedDuration

----
echo
Log "Installing RKE2 agent nodes.."
for ((i=1; i<=$NUM_AGENTS; i++))
do
  rke2joinagentx $i
  LogElapsedDuration
done
for ((i=1; i<=$NUM_AGENTS; i++))
do
  rke2nodewait $i ${AGENT_PUBLIC_IP[$i]}
  LogElapsedDuration
done
echo

LogCompleted "Done."

# -------------------------------------------------------------------------------------

# tidy up
exit 0
