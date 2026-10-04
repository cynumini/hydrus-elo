import std.stdio;
import sdl = sdl;

void main()
{
    string name = "hydrus-elo";

    sdl.setLogPriorities(sdl.LogPriority.VERBOSE);

    assert(sdl.setAppMetadata(name, "0.1.0", "cynumini.hydrus-elo"));

    bool ok = sdl.init(sdl.InitFlags.VIDEO);
    scope (exit)
        sdl.quit();
    assert(ok);

    auto window = sdl.createWindow(name, 1280, 720, sdl.WindowFlags.init);
    scope (exit)
        sdl.destroyWindow(window);
    assert(window);

    auto device = sdl.createGPUDevice(
        sdl.GPUShaderFormat.SPIRV | sdl.GPUShaderFormat.DXIL, true, null);
    scope (exit)
        sdl.destroyWindow(device);
    assert(device);

    assert(sdl.claimWindowForGPUDevice(device, window));

    sdl.GPUSampler* sampler;
    {
        const sdl.GPUSamplerCreateInfo createinfo = {};
        sampler = sdl.createGPUSampler(device, &createinfo);
    }
    scope (exit)
        sdl.releaseGPUSampler(device, sampler);
    assert(sampler);

    {
        sdl.GPUGraphicsPipelineCreateInfo createinfo = {};

        // createinfo.vertex_shader =
        //     createGPUShader(state.device, shader_vert_code, SDL_GPU_SHADERSTAGE_VERTEX, 0, 1);
        //     defer(SDL_ReleaseGPUShader(state.device, createinfo.vertex_shader));
        //     SDL_CHECK(createinfo.vertex_shader);
        //
        //     createinfo.fragment_shader =
        //         createGPUShader(state.device, shader_frag_code, SDL_GPU_SHADERSTAGE_FRAGMENT,
        //                         MAX_TEXTURE_SAMPLERS, 0);
        //     defer(SDL_ReleaseGPUShader(state.device, createinfo.fragment_shader));
        //     SDL_CHECK(createinfo.fragment_shader);
        //
        //     const SDL_GPUVertexBufferDescription vertex_buffer_descriptions[] = {
        //         {0, sizeof(vec2), SDL_GPU_VERTEXINPUTRATE_VERTEX, 0},
        //         {1, sizeof(Instance), SDL_GPU_VERTEXINPUTRATE_INSTANCE, 0},
        //     };
        //     createinfo.vertex_input_state.vertex_buffer_descriptions = vertex_buffer_descriptions;
        //     createinfo.vertex_input_state.num_vertex_buffers = ARRAY_LEN(vertex_buffer_descriptions);
        //
        //     const SDL_GPUVertexAttribute vertex_attributes[] = {
        //         // vertex
        //         {0, 0, SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, 0},
        //         // instance
        //         {1, 1, SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, offsetof(Instance, position)},
        //         {2, 1, SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, offsetof(Instance, size)},
        //         {3, 1, SDL_GPU_VERTEXELEMENTFORMAT_UINT, offsetof(Instance, texture_index)},
        //     };
        //     createinfo.vertex_input_state.vertex_attributes = vertex_attributes;
        //     createinfo.vertex_input_state.num_vertex_attributes = ARRAY_LEN(vertex_attributes);
        //
        //     const SDL_GPUColorTargetDescription color_target_description = {
        //         .format = SDL_GetGPUSwapchainTextureFormat(state.device, state.window),
        //         .blend_state = {
        //             .src_color_blendfactor = SDL_GPU_BLENDFACTOR_SRC_ALPHA,
        //             .dst_color_blendfactor = SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
        //             .color_blend_op = SDL_GPU_BLENDOP_ADD,
        //             .src_alpha_blendfactor = SDL_GPU_BLENDFACTOR_ONE,
        //             .dst_alpha_blendfactor = SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
        //             .alpha_blend_op = SDL_GPU_BLENDOP_ADD,
        //             .enable_blend = true,
        //
        //         }};
        //     createinfo.target_info.color_target_descriptions = &color_target_description;
        //     createinfo.target_info.num_color_targets = 1;
        //     state.pipeline = SDL_CreateGPUGraphicsPipeline(state.device, &createinfo);
    }
    // SDL_CHECK(state.pipeline);
}
