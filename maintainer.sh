#!/bin/bash

MACHINE="tester"
# Update the container. Sleeps are added just in case bringing network up is slow.
# Adjust to your needs.
lxc stop "${MACHINE}" || /bin/true
lxc start "${MACHINE}"
lxc exec "${MACHINE}" -- su -lc "(sleep 1 && cd ~/lxd-bin && git pull)"
lxc exec "${MACHINE}" -- su -lc "emerge --sync"
lxc exec "${MACHINE}" -- su -lc "emerge -uvDN --binpkg-changed-deps=y --keep-going @world"
lxc exec "${MACHINE}" -- su -lc "emerge -uvDN --depclean"
lxc exec "${MACHINE}" -- su -lc "eclean-kernel -n 1"
lxc exec "${MACHINE}" -- su -lc "(eselect news read && etc-update)"
lxc exec "${MACHINE}" -- su -lc "pfl"
lxc exec "${MACHINE}" -- su -lc "eclean packages --changed-deps"
lxc stop "${MACHINE}"

# Delete all old snapshots. Note that this will NOT delete active containers!
lxc list | awk '{print $2}' | grep tester-snap | xargs -I SNAP lxc delete SNAP

# For problems with inittab, use
#lxc exec tester -- poweroff

echo "All done."
echo
