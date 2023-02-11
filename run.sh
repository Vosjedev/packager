#!/usr/bin/bash



loglevel=0
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

[[ -v HOME ]] || HOME="$data/../../"

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
| -R --refresh                  : refresh the cache                 |
| -g --get                      : download and install a program    |
| -r --remove                   : remove a program                  |"
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

function unreachable {
    info="no further info"
    exit="255"
    [[ "$1" == '' ]] && info="$1"
    [[ "$2" == '' ]] && exit="$2"
    echo -e "\e[1;31;40mreached unreachable code:\n\e[0m${FUNCNAME[*]}\ninfo provided by function: $info\n"
    [[ $exit -ge 0 ]] && exit "$exit"
}

# .vpmscript handeling
# shellcheck disable=SC2034,SC2162
function script {
    line=1
    vpmscript_uid="$(date +%s_%N)"
    mkdir -p "$data/bash/"
    mkfifo "$data/bash/$vpmscript_uid"
    { tail -f "$data/bash/$vpmscript_uid" | bash & } 2>/dev/null
    eval "procid_$vpmscript_uid='$!'"
    while read cmd a1 a2 a3 a4 a5 a6 arg
    do
        case "$cmd" in
            R | run ) echo "eval \"$a1\" \"$a2\" \"$a3\" \"$a4\" \"$a5\" \"$a6\" \"$arg\""  >> "$data/bash/$vpmscript_uid";;
            r | rm  ) echo "rm -rf \"$a1\""                                                 >> "$data/bash/$vpmscript_uid";;
            t | mf  ) echo "echo -n '' >> \"$a1\""                                          >> "$data/bash/$vpmscript_uid";;
            d | md  ) echo "mkdir \"$a1\""                                                  >> "$data/bash/$vpmscript_uid";;
            l | lk  ) echo "ln -s \"$a1\" \"$a2\""                                          >> "$data/bash/$vpmscript_uid";;
            c | cp  ) echo "cp -r \"$a1\" \"$a2\""                                          >> "$data/bash/$vpmscript_uid";;
            m | mv  ) echo "cp -r \"$a1\" \"$a2\" && rm -rf \"$a1\""                        >> "$data/bash/$vpmscript_uid";;
            e | ex  ) echo "exit $a1"                                                       >> "$data/bash/$vpmscript_uid";;
            s | scr ) script "$a1";;
            *   ) echo "error: '$1'@'$line': '$cmd' not found."
        esac
        ((line++))
    done < "$1"
    echo "exit" >> "$data/bash/$vpmscript_uid"
    eval "wait \$procid_$vpmscript_uid"
    rm -f "$data/bash/$vpmscript_uid"
}

# http[s] downloader
    if command -v axel
    then
        function dl {
            axel "$1" -o "$2"
        }
    elif command -v curl
    then
        function dl {
            echo "downloading \"$1\""
            axel -# -o "$2" "$1"
        }
    elif command -v wget
    then
        function dl {
            wget "$1" -O "$2"
        }
    else
        echo -e "-------------\nno supported downloader found. make sure to have one of the following installed and in the PATH:\n"\
        "axel: faster downloads\n"\
        "curl: clean output (using -# argument)\n"\
        "wget: great alternative\n"\
        "-------------"
        exit 1
    fi
#

# set functions
function resolvefile {
    [[ $loglevel -ge 2 ]] && echo "resolving $1"
    linenr=1
    for var in NAME TYPE FORMAT URL ID INFO README
    do eval "$var=''"
    done
    [[ "$1" == '' ]] && return
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
            install ) :;;
            protected ) PROTECTED="$value" ;;
            * ) echo -e "error on line $linenr:\n$line\n'$name' not found. see the github for more info on writing these files."; return 1 ;;
        esac
    ((linenr++))
    done < "$1"
}
function listfile {
    resolvefile "$1" && \
    entry="name: $NAME | desciption: $INFO | type: $TYPE"
    echo "${entry:0:$COLUMNS}"
    unset entry
}
function searchfile {
    sresult=''
    result=''
    results=''
    nresults=''
    cd "$data/repo" || return 1
    [[ "$loglevel" -ge 2 ]] && pwd
    for repo in *
    do
        cd "$repo" || return 1
        [[ "$loglevel" -ge 2 ]] && pwd
        for file in *.vpmfile
        do [[ "$file" == *"$1"*.vpmfile ]] && {
            # results="${results}repo/$repo/$file "
            results+=("repo/$repo/$file")
        }
        done
        cd ..
    done
    cd ..
    [[ "$2" == s ]] && {
        resultcount=0
        for result in "${results[@]}"
        do resolvefile "$result"
            [[ "$NAME" == "$1" ]] && nresults+=("$result") && ((resultcount++))
        done
        if [[ $resultcount -gt 1 ]]
        then
            echo "there are more than 1 results! which one do you want?"
            cnt=1
            for result in "${results[@]}"
            do resolvefile "$result"
                echo "$cnt: $NAME" ; ((cnt++))
            done
            # shellcheck disable=SC2162
            read -p ' > ' in
            cnt=1
            for result in "${nresults[@]}"
            do [[ $cnt -eq $in ]] && sresult="$result"
            done
        else sresult="${nresults[1]}"; [[ $loglevel -ge 2 ]] && echo "only one result found."
        fi
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
    cd "$HOME/.vosjedev" || return 1
    for program in *
    do
        resolvefile "$program/info.vpmfile"
        [[ "$PROTECTED" == true ]] && echo "can't remove protected program '$NAME'."
        if [[ "$NAME" == "$1" ]]
        then read -rp "are you sure you want to remove program $NAME with id $ID? [Y/n] " in
            case $in in
                y | yes ) 
                        [[ -f "remove.vpmscript" ]] && script remove.vmpscript
                        rm -rf "$program"
                    ;;
                n | no ) return 0;;
            esac
        fi
    done
    skip=1
}
function search {
    skip=1
    searchfile "$1"
    [[ "${#results[@]}" -eq 0 ]] && {
        echo "no results found for search $1."
        return 1
    }
    for result in "${results[@]}"
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
            ;;
        installed )
                cd "$HOME/.vosjedev" || return 1
                for dir in *
                do listfile "$dir/info.vpmfile"
                done
            ;;
    esac

    skip=1
}
function refresh {
    rm -rf repo/*
    for repo in "$data/repolist/"*".vpmfile"
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
                http/zip )
                    dl "$URL" repofiles.zip
                    if command -v sha256sum
                    then
                        dl "$URL.checksum" checksum.txt
                        read -r CHECKSUM < "checksum.txt"
                        if [[ "$CHECKSUM" == "$(sha256sum "repofiles.zip")" ]]
                        then echo "checksum: $CHECKSUM matched"
                        else echo -e "checksum $CHECKSUM failed to match.\ndo you want to continue?"
                            read -rsn1 -p "[y for yes, anything else for no]" i
                            case $i in
                                y ) echo '';;
                                * ) cd ../.. ;continue
                            esac
                        fi
                    else echo "no sha256sum binary found in PATH."
                    fi
                    unzip -q repofiles.zip
                    echo "done!"
                    ;;
                git )
                    cd ..
                    rm -rf "$ID"
                    git clone "$URL"
                    cd "$ID" || { unreachable "if you see this, contact the owner of repo $NAME with id $ID because the id of the repo does not match the git destination."; cd ..; continue; }
            esac
        cd ../..
    done
}

function update-all {
    cd "$HOME/.vosjedev" || { echo "you should download and install vpm using the commands in the README."; exit 255;}
    for program in *
    do
        [[ ! -d "$program" ]] && continue
        cd "$program" || unreachable "error while cding to \"$HOME/.vosjedev/$program\". if the program is uninstalled, please run vpm again."
        resolvefile info.vpmfile
        echo "updating:"
        listfile "info.vpmfile"
        case $FORMAT in
            git ) git --no-rebase pull
        esac
        cd "$HOME/.vosjedev" || { echo "you should download and install vpm using the commands in the README."; exit 255;}
    done
}

PS2='+ ${FUNCNAME[*]}: '
[[ -v debug ]] && set -x
skip=0
# parse arguments
until [[ $# -le 0 ]]
do
    [[ "$skip" == 1 ]] && {
        shift
        skip=0
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
        -U | --update-all ) update-all ;;
        -s | --search   ) search "$2" ;;
        "-"*            ) echo "option $1 not found... run '$0 -h' to get help."
                            [[ "$2" == -"*" ]] || skip=1
                            ;;
        *               ) help 0
    esac
    shift
    cd "$data" || exit 1
done
[[ -v debug ]] && set +x