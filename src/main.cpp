#include <stdio.h>

#include <sakana/unagi.hpp>

unagi::Result unagi::init() {
    printf("hydrus-elo\n");
    return unagi::Result::ongoing;
}

unagi::Result unagi::update() { return unagi::Result::ongoing; }

void unagi::draw() {}

void unagi::quit() {}
