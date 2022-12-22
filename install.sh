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
[ "$HOME" > /dev/null ] || read -p "enter your home directory:" -i "/home/$(logname)" -e HOME
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
for file in *
do
    if [[ "$file" == "."* ]]
    then echo "skipped $file"
    else cp -r "$file" "$HOME/.vosjedev/packager"
    fi
done
echo "done."
unerr

while :
do
    ifs="$IFS"
    IFS=":"
    for dir in $PATH
    do
        if [ -x "$dir/wget" ]
        then echo "wget found!"
            wgetfound=1
            break
        fi
    done
    IFS="$ifs"
    if [ "$wgetfound" == 1 ]
    then break
    else echo "no wget client found in PATH. please install wget as it is a dependency of vpm."
        read -s -p "press enter when done."
    fi
done

function mkshortcut {
    [ -d "$HOME/.local/" ] || mkdir "$HOME/.local"
    [ -d "$HOME/.local/bin" ] || mkdir "$HOME/.local/bin"
    ln -s "$dest/run.sh" "$HOME/.local/bin/vpm"
    [ "$PATH" == *"$HOME/.local/bin"* ] || echo "your current \$PATH is '$PATH' we could not find $HOME/.local/bin in there. please consider adding it to your path to be able to use vpm."
    echo "you can use now use vpm to run vosje's package manager."
}
while :
do
    read -p "do you want to make a symlink in '$HOME/.local/bin'? [y/n] " in over
    case $in in
        y | yes ) mkshortcut
                    break 
                    ;;
        n | no  ) echo "you wil not be able to use vpm using a simple command. use 'ln -s \"$dest/run.sh\" \"$HOME/.local/bin/vpm\"' to make a shortcut in $HOME/local/bin."
                    break
                    ;;
        *       ) echo "please enter y/yes to add vpm to the path or n/no to not add vpm to the path." ;;
    esac
done

exit 0
