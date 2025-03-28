#!/usr/bin/bash

echo "==========> Started userdata script.."

# user shell
echo "alias l='ls -latFrh'" >> /home/ec2-user/.bashrc
echo "alias vi=vim"         >> /home/ec2-user/.bashrc
echo "set background=dark"  >> /home/ec2-user/.vimrc
echo "syntax on"            >> /home/ec2-user/.vimrc
chown ec2-user users /home/ec2-user/.*
echo "alias l='ls -latFrh'" >> /root/.bashrc
echo "alias vi=vim"         >> /root/.bashrc
echo "set background=dark"  >> /root/.vimrc
echo "syntax on"            >> /root/.vimrc

# repos and packages
zypper refresh
zypper --non-interactive install git bind-utils mlocate lvm2 jq nfs-client cryptsetup open-iscsi

# enable for longhorn
systemctl enable iscsid --now

