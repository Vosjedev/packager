#!/usr/bin/bash

cd "$(dirname "$0")"
src="$(pwd)"

echo -n "loading... "
function err {
    trap "trap.err" ERR
}
function unerr {
    trap "trap.ncerr" ERR
}
function trap.err {
    echo -e "\nOOPS! something went wrong. cleaning up..."
    rm -rf "$HOME/.vosjedev/packager"
    exit 1
} 
function trap.ncerr {
    echo "error!"
}
trap "trap.err" SIGINT

while :
do
[ "$HOME" > /dev/null ] || read -p "enter your home directory:" -e HOME
[ "$HOME" > /dev/null ] && break
done
echo "done"

echo "running git pull..."
git pull
echo "done."

err
echo -n "making filesystem... "
cd "$HOME"
[ -d .vosjedev ] || mkdir .vosjedev
cd .vosjedev
dest="$(pwd)/packager"

echo "done."
cd "$src"
echo "copying files..."
cp -r ./ "$dest"
echo "done."
