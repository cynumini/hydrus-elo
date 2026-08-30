FLAGS := $(shell tr '\n' ' ' < compile_flags.txt)
LIBS := -lsakana -lSDL3 -lSDL3_image -lcurl -lcjson

run: build/hydrus-elo
	./build/hydrus-elo

build/hydrus-elo: src/main.cpp compile_flags.txt sakana/build/libsakana.a
	@mkdir -p build
	clang++ src/main.cpp -o build/hydrus-elo $(FLAGS) -g -Lsakana/build $(LIBS)

sakana/build/libsakana.a: sakana/src/sakana.cpp
	$(MAKE) -C sakana

tidy:
	clang-tidy src/main.cpp

clean:
	rm -rf build
