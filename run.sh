#!/usr/bin/bash

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
.-------------------------------------------------------------------.
| commands                      : discription                       |
|-------------------------------------------------------------------|
| -h --help                     : show this help                    |

"
    else
        echo "
command : description
h help : show this help
"
    fi
    exit $1
}

# test if there is any argument
[ "$@" == '' ] && {
    help 1
}

# parse arguments
while [[ "$#" -gt 0 ]]; do
  case "${1:-}" in
    -h | --help ) help ;;
    * ) echo "did not reconise option '$1'."
        echo "use \"$0\" -h for more info"
        exit 1
  esac
  shift
done