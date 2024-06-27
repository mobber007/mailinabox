#!/bin/bash
#########################################################
# This script is intended to be run like this:
#
#   export PRIMARY_HOSTNAME=mailinabox.local && curl -H 'Cache-Control: no-cache, no-store' -H 'Content-Type: application/x-sh' -s https://raw.githubusercontent.com/mobber007/mailinabox/master/setup.sh | sudo -E bash
#
#########################################################


# Allow 22.04.1
UBUNTU_VERSION=$( lsb_release -d | sed 's/.*:\s*//' | sed 's/\([0-9]*\.[0-9]*\)\.[0-9]/\1/' )
if [ "$UBUNTU_VERSION" == "Ubuntu 22.04 LTS" ]; then
    echo "Machine running Ubuntu 22.04."
    TAG=v68
else
	echo "This script may be used only on a machine running Ubuntu 22.04."
	exit 1
fi

# Are we running as root?
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root. Did you leave out sudo?"
	exit 1
fi

hostnamectl set-hostname $PRIMARY_HOSTNAME
hostnamectl set-hostname $PRIMARY_HOSTNAME --pretty
hostname $PRIMARY_HOSTNAME
sysctl -w net.ipv6.conf.default.disable_ipv6=0
sysctl -w net.ipv6.conf.all.disable_ipv6=0

cat >/etc/init.d/wonready <<EOF
#!/usr/bin/env bash
sleep 10s
sysctl -w net.ipv6.conf.default.disable_ipv6=0
sysctl -w net.ipv6.conf.all.disable_ipv6=0
service nsd stop || true
service nsd start || true
EOF
chmod a+x /etc/init.d/wonready
ln -s /etc/init.d/wonready /etc/rc5.d/S99wonready

# Clone the Mail-in-a-Box repository if it doesn't exist.
if [ ! -d "$HOME/mailinabox" ]; then
	if [ ! -f /usr/bin/git ]; then
		echo "Installing git . . ."
		apt-get -q -q update
		DEBIAN_FRONTEND=noninteractive apt-get -q -q install -y git < /dev/null
		echo
	fi

	if [ "$SOURCE" == "" ]; then
		SOURCE=https://github.com/mobber007/mailinabox
	fi
 
	echo "Cloning Mail-in-a-Box . . ."
	git clone $SOURCE -b $TAG --depth 1
    cd mailinabox
    cd ..
	echo
 
fi

# Change directory to it.
cd "$HOME/mailinabox" || exit

# Update it.
if [ "$TAG" != "$(git describe --always)" ]; then
	echo "Updating Mail-in-a-Box to $TAG . . ."
	git fetch --depth 1 --force --prune origin tag "$TAG"
	if ! git checkout -q "$TAG"; then
		echo "Update failed. Did you modify something in $PWD?"
		exit 1
	fi
	echo
fi

# Start setup script.
setup/start.sh

