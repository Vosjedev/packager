#!/usr/bin/bash

loglevel=1
#  get data dir
file="$(which "$0")"
while :
do
    if [[ -L "$file" ]]
    then [[ $loglevel -ge 2 ]] && echo "Symlink! '$file'"
        file="$(readlink "$file")"
    elif [[ -d "$file" ]]
    then echo "error while finding data directory"; exit 1
    elif [[ -f "$file" ]]
    then [[ "$loglevel" -ge 2 ]] && echo "found orginal! '$file'"
        break
    fi
done
data="$(dirname "$file")"
cd "$data" || exit
data="$(pwd)"
[[ $loglevel -ge 2 ]] && echo "data found in '$data'"

# set $COLUMNS if unset
if ! [[ "$COLUMNS" > /dev/null ]]
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
    [[ "$1" -ne 0 ]] && exit "$1"
}

# test if there is any argument
# [ "$@" == '' ] && {
#     help 1
# }

# .vpmscript handeling
function script {
    line=1
    # shellcheck disable=SC2034
    while read -r cmd a1 a2 a3 a4 a5 a6 arg
    do
        case $cmd in
            R   ) eval "$a1"        ;;
            r   ) rm -rf "$a1"      ;;
            t   ) touch "$a1"       ;;
            d   ) mkdir "$a1"       ;;
            l   ) ln -s "$a1" "$a2" ;;
            c   ) cp -r "$a1" "$a2" ;;
            m   ) mv -r "$a1" "$a2" ;;
            *   ) echo "error: '$1'@'$line': '$cmd' not found."
        esac
    done < "$1"
    ((line++))
}

# set functions
function resolvefile {
    [[ $loglevel -ge 2 ]] && echo "resolving $(pwd)/$1"
    linenr=1
    # shellcheck disable=SC2034,SC2162
    while read name eq value
    do
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
            readme  ) README="$value"   ;;
            * ) echo -e "error on line $linenr:\n$line\n'$name' not found. see the github for more info on writing these files."; return 1 ;;
        esac
    ((linenr++))
    done < "$1"
}
function listfile {
    resolvefile "$1"
    echo "name: $NAME | desciption: $INFO | type: $TYPE "
}
function searchfile {
    sresult=''
    result=''
    results=''
    nresults=''
    cd repo || return 1
    for repo in *
    do
        cd "$repo" || return 1
        for file in *.vpmfile
        do [[ "$file" == *"$1"*.vpmfile ]] && {
            results="${results}repo/$repo/$file "
        }
        done
        cd ..
    done
    cd ..
    [[ "$2" == s ]] && {
        resultcount=0
        ifs="$IFS"
        IFS=";"
        for result in $results
        do [[ "$result" == "$1" ]] && nresults="$nresults $result" && ((resultcount++))
        done
        if [[ $resultcount -gt 1 ]]
        then
            echo "there are more than 1 results! which one do you want?"
            cnt=1
            for result in $nresults
            do echo "$cnt: $result" ; ((cnt++))
            done
            # shellcheck disable=SC2162
            read -p ' > ' in
            cnt=1
            for result in $nresults
            do [[ $cnt -eq $in ]] && sresult="$result"
            done
        else sresult="$nresults"; [[ $loglevel -ge 2 ]] && echo "only one result found."
        fi
        IFS="$ifs"
    }
}
function install {
    skip=1
    searchfile "$1" s
    cd "$data" || return 1
    [[ "$sresult" == '' ]] && echo "no results found. run $0 -R to refresh the cache, and then try again."
    resolvefile "$sresult"
    cd "$data" || return 1
    [[ "$TYPE" == program ]] || {
        echo "OOPS! file is not a program."
        return
    }
    download "$URL"
    [[ -f install.vpmscript ]] && script install.vpmscript
    # shellcheck disable=SC2164
    cd "$data"
    cp "$sresult" "$HOME/.vosjedev/$ID/info.vpmfile"
    echo "done."
}
function download {
    case $FORMAT in
        git     ) cd "$HOME/.vosjedev/" && git clone "$URL" && cd "$ID" && echo "download done."     ;;
        *       ) echo "error: unkown format."
    esac
}
function remove {
    echo "not implemented yet"
    skip=1
}
function search {
    skip=1
    searchfile "$1"
    [[ "$results" == '' ]] && {
        echo "no results found for search $1."
        return 1
    }
    for result in $results
    do listfile "$result"
    done
}
function list {
    case $1 in
        cache ) 
            cd "$data/repo" || return 1
            for repo in *
            do
                cd "$repo"|| continue
                for program in *.vpmfile
                do listfile "$program"
                done
                cd ..
            done
            cd "$data" || return
    esac

    skip=1
}
function refresh {
    rm -rf repo/*
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
        cd repo || return 1
        [[ -d "$ID" ]] && {
            echo "repo $NAME already here. deleting it's cache..."
            rm -rf "$ID"
            }
        mkdir "$ID"
        # shellcheck disable=SC2164
        cd "$ID"
            case $FORMAT in
                http/zip    ) wget -O repofiles.zip "$URL" && unzip repofiles.zip && echo "done!"
            esac
        cd ../..
    done
}

skip=0
# parse arguments
until [[ $# -le 0 ]]
do
    [[ "$skip" == 1 ]] && {
        shift
        continue
    }
    if [[ "$2" == "-"* ]] || [[ "$2" == '' ]]
    then echo "[=======| $1 |=======]"
    else echo "[======| $1 $2 |======]"
    fi
    case $1 in
        -g | --get      ) install "$2" ;;
        -r | --remove   ) remove "$2" ;;
        -l | --list     ) list "$2" ;;
        -h | --help     ) help 0 ;;
        -R | --refresh  ) refresh ;;
        -s | --search   ) search "$2" ;;
        "-"*            ) echo "option $1 not found... run '$0 -h' to get help."
                            [[ "$2" == -"*" ]] || skip=1
                            ;;
        *               ) help 0
    esac
    shift
    cd "$data" || exit 1
done