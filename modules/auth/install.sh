#!/bin/bash

echo "Compiling auth module"
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOTDIR="/srv/mox"

SYSTEM_PACKAGES=$(cat "$DIR/SYSTEM_DEPENDENCIES")
for package in "${SYSTEM_PACKAGES[@]}"; do
	sudo apt-get -y install $package
done

pushd "$DIR"
mvn package
popd

ln -sf "$DIR/auth.sh" "$ROOTDIR/auth.sh"

