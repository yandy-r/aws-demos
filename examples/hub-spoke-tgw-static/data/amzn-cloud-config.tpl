#!/bin/bash -xe
set -o xtrace

hostname "${hostname}"
echo "${hostname}" >/etc/hostname

# for amazon linux
cat <<EOF >>/home/ec2-user/.ssh/ssh-key
${ssh_key}
EOF
chmod 600 /home/ec2-user/.ssh/ssh-key
chown ec2-user /home/ec2-user/.ssh/ssh-key
chgrp ec2-user /home/ec2-user/.ssh/ssh-key
