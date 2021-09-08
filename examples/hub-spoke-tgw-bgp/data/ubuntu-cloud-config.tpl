#!/bin/bash -xe
set -o xtrace

hostname "${hostname}"
echo "${hostname}" >/etc/hostname

# for ubuntu linux
cat <<EOF >>/home/ubuntu/.ssh/ssh-key
${ssh_key}
EOF
chmod 600 /home/ubuntu/.ssh/ssh-key
chown ubuntu /home/ubuntu/.ssh/ssh-key
chgrp ubuntu /home/ubuntu/.ssh/ssh-key
