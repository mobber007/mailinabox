#!/bin/bash
# If there aren't any mail users yet, create one.
if [ -z "$(management/cli.py user)" ]; then

	# Use me@PRIMARY_HOSTNAME
	EMAIL_ADDR=me@$PRIMARY_HOSTNAME
	EMAIL_PW=$(date +%s | sha256sum | base64 | head -c 32)
	echo
	echo "Creating a new administrative mail account for $EMAIL_ADDR with password $EMAIL_PW."
	echo

	# Create the user's mail account. This will ask for a password if none was given above.
	management/cli.py user add "$EMAIL_ADDR" "${EMAIL_PW:-}"

	# Make it an admin.
	hide_output management/cli.py user make-admin "$EMAIL_ADDR"

	# Create an alias to which we'll direct all automatically-created administrative aliases.
	management/cli.py alias add "administrator@$PRIMARY_HOSTNAME" "$EMAIL_ADDR" > /dev/null
fi
