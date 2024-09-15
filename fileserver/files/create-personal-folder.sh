#!/bin/bash

DIR_MODE="0700"

function usage {
    cat <<EOF
Usage:
$( basename $0) --user  USERNAME --mode MODE --path PATH
EOF
    exit
}

while [ -n "$1" ]; do
    case "$1" in
        "--user")
            shift
            DIR_USER="$1"
            ;;
        "--mode")
            shift
            DIR_MODE="$1"
            ;;
        "--path")
            shift
            DIR_PATH="$1"
            ;;
        "*")
            usage
            ;;
    esac
    shift
done

if [ -z "$DIR_USER" -o -z "$DIR_PATH" ]; then
    usage
fi

DIR_PATH="$DIR_PATH/$DIR_USER"

if [ ! -e "$DIR_PATH" ]; then
    mkdir -v "$DIR_PATH" || exit 1

    cat <<EOF > "${DIR_PATH}/.directory"
[Desktop Entry]
Icon=user
Comment="$( getent passwd $DIR_USER | awk -F: '{ print $5; }' )'s private data"
EOF

    chown -vR "$DIR_USER" "$DIR_PATH" || exit 1
    chmod -v "$DIR_MODE" "$DIR_PATH" || exit 1
fi
