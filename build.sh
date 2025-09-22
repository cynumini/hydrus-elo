#!/usr/bin/env sh
set -e

bin=hydrus-elo

mkdir -p ./out

case "$1" in
    run)
        shift
        wayland-scanner private-code  /usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml ./src/xdg-shell-protocol.c
        wayland-scanner client-header /usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml ./src/xdg-shell-client-protocol.h
        wayland-scanner private-code  /usr/share/wayland-protocols/unstable/xdg-decoration/xdg-decoration-unstable-v1.xml ./src/xdg-decoration-protocol.c
        wayland-scanner client-header /usr/share/wayland-protocols/unstable/xdg-decoration/xdg-decoration-unstable-v1.xml ./src/xdg-decoration-client-protocol.h
        gcc ./src/main.c ./src/window.c ./src/xdg-shell-protocol.c ./src/xdg-decoration-protocol.c -o ./out/$bin -std=c99 -Wall -Werror -g -pedantic -lwayland-client -lrt
        WAYLAND_DEBUG=1 ./out/$bin $@
        ;;
    install)
        shift
        target_dir="$1"
        if [[ -z "$target_dir" ]]; then
            echo "Usage: $0 install <dir>"
            exit 1
        fi
        echo "Installing to $target_dir"
        gcc ./src/main.c ./src/window.c ./src/xdg-shell-protocol.c ./src/xdg-decoration-protocol.c -o $target_dir/$bin -std=c99 -Wall -Werror -pedantic -lwayland-client -lrt -O2
        ;;
    *)
        echo "Usage: $0 {run|install <dir>}"
        exit 1
        ;;
esac

