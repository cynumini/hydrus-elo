bin := ./out/hydrus-elo

$(bin): ./src/*.odin
	mkdir -p ./out
	odin build src -out:$(bin) -strict-style -vet-unused

run: $(bin)
	$(bin)
