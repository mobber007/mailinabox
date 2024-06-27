#!/bin/bash
#########################################################
# This script is intended to be run like this:
#
#   export PRIMARY_HOSTNAME=mailinabox.local && curl -H 'Cache-Control: no-cache, no-store' -H 'Content-Type: application/x-sh' -s https://raw.githubusercontent.com/mobber007/mailinabox/master/setup.sh | sudo -E bash
#
#########################################################

if [ -z "$TAG" ]; then
	# If a version to install isn't explicitly given as an environment
	# variable, then install the latest version. But the latest version
	# depends on the machine's version of Ubuntu. Existing users need to
	# be able to upgrade to the latest version available for that version
	# of Ubuntu to satisfy the migration requirements.
	#
	# Also, the system status checks read this script for TAG = (without the
	# space, but if we put it in a comment it would confuse the status checks!)
	# to get the latest version, so the first such line must be the one that we
	# want to display in status checks.
	#
	# Allow point-release versions of the major releases, e.g. 22.04.1 is OK.
	UBUNTU_VERSION=$( lsb_release -d | sed 's/.*:\s*//' | sed 's/\([0-9]*\.[0-9]*\)\.[0-9]/\1/' )
	if [ "$UBUNTU_VERSION" == "Ubuntu 22.04 LTS" ]; then
		# This machine is running Ubuntu 22.04, which is supported by
		# Mail-in-a-Box versions 68 and later.
		TAG=v68
	else
		echo "This script may be used only on a machine running Ubuntu 14.04, 18.04, or 22.04."
		exit 1
	fi
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

	echo "Downloading Mail-in-a-Box $TAG. . ."
	git clone $SOURCE
    cd mailinabox
    git checkout $TAG
    cd ..
	echo
fi

# Change directory to it.
cd "$HOME/mailinabox" || exit

# Start setup script.
setup/start.sh
