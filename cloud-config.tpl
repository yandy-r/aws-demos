#!/bin/bash -xe
set -o xtrace

sudo hostname ${hostname}
sudo echo ${hostname} > /etc/hostname