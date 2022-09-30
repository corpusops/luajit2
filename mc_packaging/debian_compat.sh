#!/usr/bin/env bash
declare -A DHVERSIONS
DHVERSIONS[xenial]=9
DHVERSIONS[bionic]=11
DHVERSIONS[focal]=12
DHVERSIONS[jammy]=13
DHVERSIONS[kinetic]=13
cd "$(dirname "$(readlink -f "$0")")/.."
RELEASE=${RELEASE:-${1:-$(. /etc/os-release && echo $VERSION_CODENAME)}}
DHRELEASE="${DHVERSIONS[$RELEASE]}"
sed -i -re "s/ debhelper-compat( \(= 1.\))?,?/debhelper,/g" debian/control
echo "$DHRELEASE">debian/compat
# vim:set et sts=4 ts=4 tw=80:
