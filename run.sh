#!/usr/bin/bash

loglevel=1
#  get data dir
file="$(which "$0")"
while :
do
    if [ -L "$file" ]
    then [[ $loglevel -ge 2 ]] && echo "Symlink! '$file'"
        file="$(readlink "$file")"
    elif [ -d "$file" ]
    then echo "error while finding data directory"; exit 1
    elif [ -f "$file" ]
    then [ "$loglevel" -ge 2 ] && echo "found orginal! '$file'"
        break
    fi
done
data="$(dirname "$file")"
cd "$data"
pwd

# set $COLUMNS if unset
if ! [ "$COLUMNS" > /dev/null ]
then COLUMNS="$(tput cols)"
fi

#       ___       __   _
# \__\ \___ \    \__\ \/
# \  \ \___ \___ \    0
# function.
function help {
    echo "usage: $0 -[arguments] command query"
    if [ "$COLUMNS" -ge 70 ]
    then
        echo "
,-------------------------------------------------------------------,
| commands                      : discription                       |
|-------------------------------------------------------------------|
| -h --help                     : show this help                    |
| -R --refresh                  : refresh the cache                 |"
# | -g --get                      : download and install a program    |
# | -r --remove                   : remove a program                  |
echo "
'-------------------------------------------------------------------'
"
    else
        echo "
command    : description
-h --help  : show this help
"
    fi
    exit $1
}

# test if there is any argument
# [ "$@" == '' ] && {
#     help 1
# }

# set functions
function resolvefile {
    linenr=1
    while read line
    do
        read name eq value <<< "$line"
        # [[ "$eq" == "=" ]] && {
        #     [[ "$name" == "/#" ]] || {
        #     echo -e "error on line $linenr:\nexpected '$name = $value' but got '$name $eq $value'."
        #     return 1
        #     }
        # }
        case $name in
            /#      ) [[ "$loglevel" -ge 2 ]] && echo "$linenr: comment!" ;;
            name    ) NAME="$value"     ;;
            type    ) TYPE="$value"     ;;
            format  ) FORMAT="$value"   ;;
            url     ) URL="$value"      ;;
            id      ) ID="$value"       ;;
            info    ) INFO="$value"     ;;
            install ) InstallFile="$value" ;;
            readme  ) README="$value"   ;;
            * ) echo -e "error on line $linenr:\n$line\n'$name' not found. see the github for more info on writing these files."; return 1 ;;
        esac
    ((linenr++))
    done < $1
}
function listfile {
    resolvefile $1
    echo "name: $NAME | desciption: $INFO | type: $TYPE "
}

function install {
    echo "not implemented yet"
}
function download {
    echo "not implemented yet"
}
function remove {
    echo "not implemented yet"
}
function search {
    echo "not implemented yet"
}
function list {
    case $1 in
        cache ) 
            cd "$data/repo"
            for repo in *
            do
                [[ -d "$repo" ]] || continue
                cd $repo
                for program in *.vpmfile
                do listfile $program
                done
                cd ..
            done
            cd "$data"
    esac

    skip=1
}
function refresh {
    for repo in ./repolist/*.vpmfile
    do
        echo "'$repo' found!"
        resolvefile "$repo"
        code=$?
        [[ $code == 1 ]] && echo "error! resolvefile exited with code $code" && continue
        echo "TYPE='$TYPE' NAME='$NAME' FORMAT='$FORMAT' URL='$URL'"
        [[ "$TYPE" == repo ]] || {
            echo "OOPS! file is not a repository! skipping repo '$NAME' ..."
            continue
        }
        cd repo
        [[ -d "$ID" ]] && {
            echo "repo $NAME already here. deleting it's cache..."
            rm -rf "$NAME"
            }
        mkdir "$NAME"
        cd "$NAME"
            case $FORMAT in
                http/zip    ) wget -O repofiles.zip "$URL" && unzip repofiles.zip && echo "done!"
            esac
        cd ../..
    done
}

skip=0
# parse arguments
for arg in $@
do
    if [ "$skip" == 1 ]
    then skip=0
    else
    #
    case $1 in
        -g | --get      ) download $2 && install $2
                            skip=1 ;;
        -r | --remove   ) remove $2 ;;
        -l | --list     ) list $2 ;;
        -h | --help     ) help 0 ;;
        -R | --refresh  ) refresh ;;
        -* | --*        ) echo "option $1 not found... run '$0 -h' to get help." ;;
        *               ) help 1
    esac
    fi
    shift
done