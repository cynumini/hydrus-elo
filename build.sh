#!/usr/bin/env sh
set -e

bin=hydrus-elo

mkdir -p ./out

case "$1" in
    run)
        shift
        gcc ./src/main.c -o ./out/$bin -std=c99 -Wall -Werror -g -pedantic
        ./out/$bin $@
        ;;
    install)
        shift
        target_dir="$1"
        if [[ -z "$target_dir" ]]; then
            echo "Usage: $0 install <dir>"
            exit 1
        fi
        echo "Installing to $target_dir"
        gcc ./src/main.c -o $target_dir/$bin -std=c99 -Wall -Werror -O2 -pedantic
        ;;
    *)
        echo "Usage: $0 {run|install <dir>}"
        exit 1
        ;;
esac

