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
data="$(pwd)"
[[ $loglevel -ge 2 ]] && echo "data found in '$data'"

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
    [ "$1" -ne 0 ] && exit $1
}

# test if there is any argument
# [ "$@" == '' ] && {
#     help 1
# }

# set functions
function resolvefile {
    [[ $loglevel -ge 2 ]] && echo "resolving $(pwd)/$1"
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
            install ) InstallFile="$value"; [[ "$InstallFile" == none ]] && InstallFile="echo 'no installfile provided.'" ;;
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
function searchfile {
    sresult=''
    result=''
    results=''
    nresults=''
    cd repo
    for repo in *
    do
        cd "$repo"
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
        do [[ "$result" == $1 ]] && nresults="$nresults $result" && ((resultcount++))
        done
        if [[ $resultcount -gt 1 ]]
        then
            echo "there are more than 1 results! which one do you want?"
            cnt=1
            for result in $nresults
            do echo "$cnt: $result" ; ((cnt++))
            done
            read -p ' > ' in
            cnt=1
            for result in $nresults
            do [[ $cnt -eq $in ]] && sresult="$result"
            done
        else sresult="$nresults"
        fi
    }
}
function install {
    skip=1
    searchfile $1 s
    cd "$data"
    [[ "$sresult" == '' ]] && echo "no results found. run $0 -R to refresh the cache, and then try again."
    resolvefile "$sresult"
    cd "$data"
    [[ "$TYPE" == program ]] || {
        echo "OOPS! file is not a program."
        return
    }
    download $URL
    eval "$InstallFile"
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
    searchfile $1
    [[ "$results" == '' ]] && {
        echo "no results found for search $1."
        return 1
    }
    for result in $results
    do listfile $result
    done
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
        cd repo
        [[ -d "$ID" ]] && {
            echo "repo $NAME already here. deleting it's cache..."
            rm -rf "$ID"
            }
        mkdir "$ID"
        cd "$ID"
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
    if [[ "$2" == "-"* ]] || [[ "$2" == '' ]]
    then echo "[=======| $1 |=======]"
    else echo "[======| $1 $2 |======]"
    fi
    case $1 in
        -g | --get      ) install $2
                            skip=1 ;;
        -r | --remove   ) remove $2 ;;
        -l | --list     ) list $2 ;;
        -h | --help     ) help 0 ;;
        -R | --refresh  ) refresh ;;
        -s | --search   ) search $2 ;;
        -* | --*        ) echo "option $1 not found... run '$0 -h' to get help."
                            [[ "$2" == -"*" ]] || skip=1
                            ;;
        *               ) help 0
    esac
    fi
    shift
    cd "$data"
done