#include "sakana/skn_build.cpp"

i32 main(i32 argc, const char *argv[]) {
    rebuildAndRestartOnChanges(argc, argv);

    const char *output = "./build/hydrus-elo";
    const char *input[] = {
        "hydrus-elo.cpp",
        "sakana/skn.cpp",
        "sakana/skn_sdl.cpp",
        glslcHpp("shader.frag", "build/shader.frag.hpp", "shader_frag_code"),
        glslcHpp("shader.vert", "build/shader.vert.hpp", "shader_vert_code"),
        0};

    if (needsUpdate(output, input)) {
        Args args = {};
        addArg(&args, CXX);
        addArg(&args, input[0]);

        auto compile_flags = loadFile("compile_flags.txt");

        addArgsFromCompileFlags(&args, compile_flags);

        addArg(&args, "-o");
        addArg(&args, output);

        addArg(&args, "-lcurl");
        addArg(&args, "-lSDL3");
        addArg(&args, "-lSDL3_image");
        addArg(&args, "-lcjson");

        addArg(&args, "-g");

        run(args);

        free(compile_flags.ptr);
    }

    Args tidy_args = {};
    addArg(&tidy_args, "clang-tidy");
    addArg(&tidy_args, input[0]);
    runReplace(tidy_args);

    return 0;
}
