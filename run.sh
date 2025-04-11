#!/usr/bin/env bash

odin run src -out:./out/hydrus-elo -strict-style -vet-unused -debug -- $@
