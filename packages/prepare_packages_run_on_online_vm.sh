#!/bin/bash
set -e

[ "$(whoami)" = "root" ] || (echo "error: you cannot run this script unless you are root" && false)

trap 'rm -rf /tmp/prepare_packages/' EXIT

rm -rf /tmp/prepare_packages/
mkdir /tmp/prepare_packages/ -m 777

/bin/echo -e '\033[1;32m==>\033[0;1m Prepare apt for installing packages\033[m'
sed -i 's/^deb cdrom/# deb cdrom/' /etc/apt/sources.list
apt update

/bin/echo -e '\033[1;32m==>\033[0;1m Download apt-offline\033[m'
apt remove apt-offline -y
apt autoremove -y
apt clean -y
apt --download-only install apt-offline -y
mkdir /tmp/prepare_packages/apt-offline-prepare/
find /var/cache/apt/archives/ | grep -P '\.deb$' | while read archive; do
    cp $archive /tmp/prepare_packages/apt-offline-prepare/
done
mv /tmp/prepare_packages/apt-offline-prepare/ /tmp/prepare_packages/apt-offline/

/bin/echo -e '\033[1;32m==>\033[0;1m Install apt-offline\033[m'
apt install apt-offline -y

/bin/echo -e '\033[1;32m==>\033[0;1m Wait for update.sig\033[m'
until test -e /tmp/prepare_packages/update-sig-ready; do sleep 0.1; done

/bin/echo -e '\033[1;32m==>\033[0;1m Process update.sig\033[m'
apt-offline get /tmp/prepare_packages/update.sig --bundle /tmp/prepare_packages/update.zip -t 8 || true
touch /tmp/prepare_packages/update-zip-ready

/bin/echo -e '\033[1;32m==>\033[0;1m Wait for upgrade.sig\033[m'
until test -e /tmp/prepare_packages/upgrade-sig-ready; do sleep 0.1; done

/bin/echo -e '\033[1;32m==>\033[0;1m Process upgrade.sig\033[m'
apt-offline get /tmp/prepare_packages/upgrade.sig --bundle /tmp/prepare_packages/upgrade.zip -t 8 || true
test -s /tmp/prepare_packages/upgrade.zip || echo UEsFBgAAAAAAAAAAAAAAAAAAAAAAAA== | openssl enc -d -base64 > /tmp/prepare_packages/upgrade.zip
touch /tmp/prepare_packages/upgrade-zip-ready

/bin/echo -e '\033[1;32m==>\033[0;1m Install git and meson\033[m'
apt install git meson -y

/bin/echo -e '\033[1;32m==>\033[0;1m Clone sim repo\033[m'
git clone --recursive https://github.com/varqox/sim -b develop /tmp/prepare_packages/camp_sim
(cd /tmp/prepare_packages/camp_sim/ && meson subprojects download)
(cd /tmp/prepare_packages/ && tar -czvf camp_sim.tgz camp_sim)
touch /tmp/prepare_packages/camp-sim-tgz-ready

/bin/echo -e '\033[1;32m==>\033[0;1m Wait for "done" signal\033[m'
until test -e /tmp/prepare_packages/done; do sleep 0.1; done

/bin/echo -e '\033[1;32m==>\033[0;1m Finished successfully\033[m'
