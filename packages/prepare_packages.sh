#!/bin/bash
set -e

script_dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)

online_host=$1 # e.g. a qemu VM ssh alias
offline_host=$2 # e.g. a qemu VM ssh alias
[ -z "$offline_host" ] && echo "Usage: $0 <online_host> <offline_host>" && false

/bin/echo -e '\033[1;32m==>\033[0;1m Wait for prepare_packages_run_on_online_vm.sh to prepare apt-offline\033[m'
ssh "$online_host" 'until test -d /tmp/prepare_packages/apt-offline/; do sleep 0.1; done'

/bin/echo -e '\033[1;32m==>\033[0;1m Copy apt-offline\033[m'
rm -rf "$script_dir/apt-offline/"
scp -r "$online_host":/tmp/prepare_packages/apt-offline/ "$script_dir/"

/bin/echo -e '\033[1;32m==>\033[0;1m Copy apt sources\033[m'
scp "$online_host:/etc/apt/sources.list" "$script_dir/"

/bin/echo -e '\033[1;32m==>\033[0;1m Wait for prepare_packages_run_on_offline_vm.sh to prepare /tmp/prepare_packages/\033[m'
ssh "$offline_host" 'until test -d /tmp/prepare_packages/; do sleep 0.1; done'

/bin/echo -e '\033[1;32m==>\033[0;1m Copy apt-offline packages to offline host\033[m'
scp "$script_dir/sources.list" "$offline_host":/tmp/prepare_packages/
scp -r "$script_dir/apt-offline/" "$offline_host":/tmp/prepare_packages/
ssh "$offline_host" 'touch /tmp/prepare_packages/apt-offline-is-present'

/bin/echo -e '\033[1;32m==>\033[0;1m Wait for offline host to prepare update.sig\033[m'
ssh "$offline_host" 'until test -e /tmp/prepare_packages/update-sig-ready; do sleep 0.1; done'

/bin/echo -e '\033[1;32m==>\033[0;1m Receive update.sig\033[m'
scp "$offline_host":/tmp/prepare_packages/update.sig "$script_dir/"

/bin/echo -e '\033[1;32m==>\033[0;1m Copy update.sig to online host\033[m'
scp "$script_dir/update.sig" "$online_host":/tmp/prepare_packages/
ssh "$online_host" 'touch /tmp/prepare_packages/update-sig-ready'

/bin/echo -e '\033[1;32m==>\033[0;1m Wait for online host to prepare update.zip\033[m'
ssh "$online_host" 'until test -e /tmp/prepare_packages/update-zip-ready; do sleep 0.1; done'

/bin/echo -e '\033[1;32m==>\033[0;1m Receive update.zip\033[m'
scp "$online_host":/tmp/prepare_packages/update.zip "$script_dir/"

/bin/echo -e '\033[1;32m==>\033[0;1m Copy update.zip to offline host\033[m'
scp "$script_dir/update.zip" "$offline_host":/tmp/prepare_packages/
ssh "$offline_host" 'touch /tmp/prepare_packages/update-zip-ready'

/bin/echo -e '\033[1;32m==>\033[0;1m Wait for offline host to prepare upgrade.sig\033[m'
ssh "$offline_host" 'until test -e /tmp/prepare_packages/upgrade-sig-ready; do sleep 0.1; done'

/bin/echo -e '\033[1;32m==>\033[0;1m Receive upgrade.sig\033[m'
scp "$offline_host":/tmp/prepare_packages/upgrade.sig "$script_dir/"

/bin/echo -e '\033[1;32m==>\033[0;1m Copy upgrade.sig to online host\033[m'
scp "$script_dir/upgrade.sig" "$online_host":/tmp/prepare_packages/
ssh "$online_host" 'touch /tmp/prepare_packages/upgrade-sig-ready'

/bin/echo -e '\033[1;32m==>\033[0;1m Wait for online host to prepare upgrade.zip\033[m'
ssh "$online_host" 'until test -e /tmp/prepare_packages/upgrade-zip-ready; do sleep 0.1; done'

/bin/echo -e '\033[1;32m==>\033[0;1m Receive upgrade.zip\033[m'
scp "$online_host":/tmp/prepare_packages/upgrade.zip "$script_dir/"

/bin/echo -e '\033[1;32m==>\033[0;1m Copy upgrade.zip to offline host\033[m'
scp "$script_dir/upgrade.zip" "$offline_host":/tmp/prepare_packages/
ssh "$offline_host" 'touch /tmp/prepare_packages/upgrade-zip-ready'

/bin/echo -e '\033[1;32m==>\033[0;1m Wait for online host to prepare sim repo\033[m'
ssh "$online_host" 'until test -e /tmp/prepare_packages/camp-sim-tgz-ready; do sleep 0.1; done'

/bin/echo -e '\033[1;32m==>\033[0;1m Receive camp_sim\033[m'
scp "$online_host":/tmp/prepare_packages/camp_sim.tgz "$script_dir/"

/bin/echo -e '\033[1;32m==>\033[0;1m Tell online and offline scripts that we are done\033[m'
ssh "$online_host" 'touch /tmp/prepare_packages/done'
ssh "$offline_host" 'touch /tmp/prepare_packages/done'

/bin/echo -e '\033[1;32m==>\033[0;1m Finished successfully\033[m'
