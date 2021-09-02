#!/bin/bash
set -e

packages="vim network-manager sudo git g++-multilib fpc mariadb-server libmariadb-dev libseccomp-dev libzip-dev libssl-dev pkgconf expect meson nginx cron"

[ "$(whoami)" = "root" ] || (echo "error: you cannot run this script unless you are root" && false)

trap 'rm -rf /tmp/prepare_packages/' EXIT

rm -rf /tmp/prepare_packages/
mkdir /tmp/prepare_packages/ -m 777

/bin/echo -e '\033[1;32m==>\033[0;1m Wait for sources.list and apt-offline packages\033[m'
until test -e /tmp/prepare_packages/apt-offline-is-present; do sleep 0.1; done

/bin/echo -e '\033[1;32m==>\033[0;1m Install sources.list\033[m'
cp /tmp/prepare_packages/sources.list /etc/apt/sources.list

/bin/echo -e '\033[1;32m==>\033[0;1m Install apt-offline\033[m'
PATH="$PATH:/usr/sbin" dpkg -i $(find /tmp/prepare_packages/apt-offline/ | grep -P '\.deb$')

/bin/echo -e '\033[1;32m==>\033[0;1m Prepare apt-offline update\033[m'
apt-offline set --update /tmp/prepare_packages/update.sig
touch /tmp/prepare_packages/update-sig-ready

/bin/echo -e '\033[1;32m==>\033[0;1m Wait for update.zip\033[m'
until test -e /tmp/prepare_packages/update-zip-ready; do sleep 0.1; done

/bin/echo -e '\033[1;32m==>\033[0;1m Install update.zip\033[m'
apt-offline install /tmp/prepare_packages/update.zip

/bin/echo -e '\033[1;32m==>\033[0;1m Prepare apt-offline upgrade\033[m'
apt-offline set --upgrade --upgrade-type dist-upgrade /tmp/prepare_packages/upgrade.sig --install-packages $packages
touch /tmp/prepare_packages/upgrade-sig-ready

/bin/echo -e '\033[1;32m==>\033[0;1m Wait for upgrade.zip\033[m'
until test -e /tmp/prepare_packages/upgrade-zip-ready; do sleep 0.1; done

/bin/echo -e '\033[1;32m==>\033[0;1m Install upgrade.zip\033[m'
apt-offline install /tmp/prepare_packages/upgrade.zip

/bin/echo -e '\033[1;32m==>\033[0;1m Run dist-upgrade\033[m'
apt dist-upgrade -y

/bin/echo -e '\033[1;32m==>\033[0;1m Run install packages\033[m'
apt install -y $packages

/bin/echo -e '\033[1;32m==>\033[0;1m Wait for "done" signal\033[m'
until test -e /tmp/prepare_packages/done; do sleep 0.1; done

/bin/echo -e '\033[1;32m==>\033[0;1m Finished successfully\033[m'
