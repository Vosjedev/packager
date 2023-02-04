#!/usr/bin/bash

set +x
# shellcheck disable=SC2164
cd "$(dirname "$0")"
src="$(pwd)"

echo -n "loading... "
function err {
    trap "trap.err" ERR
}
function unerr {
    trap "trap.ncerr" ERR
}
# shellcheck disable=SC2317
function trap.err {
    echo -e "\nOOPS! something went wrong. cleaning up..."
    rm -rf "$HOME/.vosjedev/packager"
    exit 1
}
# shellcheck disable=SC2317
function trap.ncerr {
    echo "error!"
}
trap "trap.err" SIGINT

while :
do
# shellcheck disable=SC2162
[[ "$HOME" > /dev/null ]] || read -p "enter your home directory:" -i "/home/$(logname)" -e HOME
[[ "$HOME" > /dev/null ]] && break
done
echo "done"

echo "running git pull..."
#git pull
echo "done."

err
echo -n "making filesystem... "
cd "$HOME" || {
    echo "error while cd into \$HOME which becomes '$HOME'. please set it using the command"
    echo "> HOME='/path/to/home' '$0'"
    exit 1
}
[ -d .vosjedev ] || mkdir .vosjedev
# shellcheck disable=SC2164
cd .vosjedev
[ -d packager ] && {
    echo packager already installed. removing it...
    rm -rf packager
}
dest="$(pwd)/packager"
mkdir "$dest"

echo "done."
cd "$src" || echo err || exit 1
echo "copying files..."
for file in *
do
    if [[ "$file" == "."* ]] || [[ "$file" == repo ]]
    then echo "skipped $file"
    else cp -r "$file" "$dest/$file"
    fi
done
mkdir "$dest/repo"
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
        # shellcheck disable=SC2162
        read -s -p "press enter when done."
    fi
done

function mkshortcut {
    [ -d "$HOME/.local/" ] || mkdir "$HOME/.local"
    [ -d "$HOME/.local/bin" ] || mkdir "$HOME/.local/bin"
    ln -s "$dest/run.sh" "$HOME/.local/bin/vpm"
   [[ "$PATH" == *"$HOME/.local/bin"* ]] || echo "your current \$PATH is '$PATH' we could not find $HOME/.local/bin in there. please consider adding it to your path to be able to use vpm."
    echo "you can use now use vpm to run vosje's package manager."
}
while :
do
    # shellcheck disable=SC2034,SC2162
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

cd "$dest" || exit
echo "making a vpmfile"
echo "protected = true
type    = program
name    = vpm
id      = packager
url     = https://github.com/vosjedev/packager
format  = git
install = ./install.sh
info    = a packager
readme  = README.md
" >> info.vpmfile
echo "done"
echo "refreshing repolist"
echo " > ./run.sh -R"
./run.sh -R
echo "\> ./run.sh -R"
echo "done."
echo "      .__
 \  / |__) |\ /|
  \/  |    | | |"

exit 0
