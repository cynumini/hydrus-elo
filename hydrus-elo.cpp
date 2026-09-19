#include <cjson/cJSON.h>
#include <curl/curl.h>

#include "skn.cpp"
#include "skn_sdl.cpp"

#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL_main.h>

#include "build/shader.frag.hpp"
#include "build/shader.vert.hpp"

struct Response {
    Arena *arena;
    Slice<u8> data;
};

static size_t writeResponse(char *data, [[maybe_unused]] size_t size, size_t len,
                            void *user_data) {
    auto *response = (Response *)user_data;
    const size_t old_len = response->data.len;
    response->data = response->arena->realloc(response->data, response->data.len + len);
    memcpy(&response->data[old_len], data, len);
    return len;
}

const uint MAX_INSTANCES = 1U << 2U; // 4

struct Instance {
    vec2 position;
    vec2 size;
    u32 texture_index;
};

struct State {

    ivec2 screen;

    SDL_Window *window;
    SDL_GPUDevice *device;
    SDL_GPUSampler *sampler;
    SDL_GPUGraphicsPipeline *pipeline;
    SDL_GPUTransferBuffer *instance_transfer_buffer;

    SDL_GPUBuffer *vertex_buffer;
    SDL_GPUBuffer *index_buffer;
    SDL_GPUBuffer *instance_buffer;

    Texture default_texture;
    Texture font_texture;
    Texture image_texture;

    Array<SDL_GPUTextureSamplerBinding, MAX_TEXTURE_SAMPLERS> texture_sampler_bindings;
};

Slice<u8> request(CURL *curl, Response *response, const char *url) {
    response->data = {};
    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_perform(curl);
    return response->data;
}

static State state;

Arena global;
Arena frame;
Arena scratch;

SDL_AppResult SDL_AppInit([[maybe_unused]] void **appstate, [[maybe_unused]] i32 argc,
                          [[maybe_unused]] char *argv[]) {
    global.init(128);
    frame.init(1);
    scratch.init(MB(5));

    const char *name = "hydrus-elo";
    SDL_SetLogPriorities(SDL_LOG_PRIORITY_VERBOSE);
    SDL_SetAppMetadata(name, "0.1.0", "cynumini.hydrus-elo");
    SDL_CHECK(SDL_Init(SDL_INIT_VIDEO));

    state.screen = {1280, 720};
    state.window = SDL_CreateWindow(name, state.screen.x, state.screen.y, 0);
    SDL_CHECK(state.window);

    state.device = SDL_CreateGPUDevice(SDL_GPU_SHADERFORMAT_SPIRV, true, 0);
    SDL_CHECK(state.device);

    SDL_CHECK(SDL_ClaimWindowForGPUDevice(state.device, state.window));

    {
        const SDL_GPUSamplerCreateInfo createinfo{};
        state.sampler = SDL_CreateGPUSampler(state.device, &createinfo);
        SDL_CHECK(state.sampler);
    }

    SDL_CHECK(Texture::create(state.device, {1, 1}, &state.default_texture));

    {
        SDL_GPUGraphicsPipelineCreateInfo createinfo = {};
        createinfo.vertex_shader =
            createGPUShader(state.device, shader_vert_code, SDL_GPU_SHADERSTAGE_VERTEX, 0, 1);
        SDL_CHECK(createinfo.vertex_shader);

        createinfo.fragment_shader =
            createGPUShader(state.device, shader_frag_code, SDL_GPU_SHADERSTAGE_FRAGMENT,
                            MAX_TEXTURE_SAMPLERS, 0);
        SDL_CHECK(createinfo.fragment_shader);

        const SDL_GPUVertexBufferDescription vertex_buffer_descriptions[] = {
            {0, sizeof(vec2), SDL_GPU_VERTEXINPUTRATE_VERTEX, 0},
            {1, sizeof(Instance), SDL_GPU_VERTEXINPUTRATE_INSTANCE, 0},
        };
        createinfo.vertex_input_state.vertex_buffer_descriptions = vertex_buffer_descriptions;
        createinfo.vertex_input_state.num_vertex_buffers = ARRAY_LEN(vertex_buffer_descriptions);

        const SDL_GPUVertexAttribute vertex_attributes[] = {
            // vertex
            {0, 0, SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, 0},
            // instance
            {1, 1, SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, offsetof(Instance, position)},
            {2, 1, SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, offsetof(Instance, size)},
            {3, 1, SDL_GPU_VERTEXELEMENTFORMAT_UINT, offsetof(Instance, texture_index)},
        };
        createinfo.vertex_input_state.vertex_attributes = vertex_attributes;
        createinfo.vertex_input_state.num_vertex_attributes = ARRAY_LEN(vertex_attributes);

        const SDL_GPUColorTargetDescription color_target_description = {
            .format = SDL_GetGPUSwapchainTextureFormat(state.device, state.window),
            .blend_state = {
                .src_color_blendfactor = SDL_GPU_BLENDFACTOR_SRC_ALPHA,
                .dst_color_blendfactor = SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
                .color_blend_op = SDL_GPU_BLENDOP_ADD,
                .src_alpha_blendfactor = SDL_GPU_BLENDFACTOR_ONE,
                .dst_alpha_blendfactor = SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
                .alpha_blend_op = SDL_GPU_BLENDOP_ADD,
                .enable_blend = true,

            }};
        createinfo.target_info.color_target_descriptions = &color_target_description;
        createinfo.target_info.num_color_targets = 1;
        state.pipeline = SDL_CreateGPUGraphicsPipeline(state.device, &createinfo);

        SDL_ReleaseGPUShader(state.device, createinfo.vertex_shader);
        SDL_ReleaseGPUShader(state.device, createinfo.fragment_shader);

        SDL_CHECK(state.pipeline);
    }

    vec2 vertices[4] = {{0, 0}, {1, 0}, {1, 1}, {0, 1}};
    i16 indices[6]{0, 1, 2, 0, 2, 3};

    state.vertex_buffer =
        createGPUBuffer(state.device, SDL_GPU_BUFFERUSAGE_VERTEX, sizeof(vertices));
    SDL_CHECK(state.vertex_buffer);

    state.index_buffer =
        createGPUBuffer(state.device, SDL_GPU_BUFFERUSAGE_INDEX, sizeof(indices));
    SDL_CHECK(state.index_buffer);

    state.instance_buffer = createGPUBuffer(state.device, SDL_GPU_BUFFERUSAGE_VERTEX,
                                            sizeof(Instance) * MAX_INSTANCES);
    SDL_CHECK(state.instance_buffer);

    auto *command_buffer = SDL_AcquireGPUCommandBuffer(state.device);
    SDL_CHECK(command_buffer);
    auto *copy_pass = SDL_BeginGPUCopyPass(command_buffer);

    {
        auto *transfer_buffer = createGPUTransferBuffer(
            state.device, sizeof(Color) + sizeof(vertices) + sizeof(indices));
        SDL_CHECK(transfer_buffer);

        {
            u8 *memory = (u8 *)SDL_MapGPUTransferBuffer(state.device, transfer_buffer, false);
            SDL_CHECK(memory);

            *(Color *)memory = WHITE;
            memory += sizeof(Color);

            SDL_memcpy(memory, vertices, sizeof(vertices));
            memory += sizeof(vertices);

            SDL_memcpy(memory, indices, sizeof(indices));

            SDL_UnmapGPUTransferBuffer(state.device, transfer_buffer);
        }

        {
            SDL_GPUTextureTransferInfo source = {};
            source.transfer_buffer = transfer_buffer;
            SDL_GPUTextureRegion destination = {};
            destination.texture = state.default_texture.ptr;
            destination.w = 1;
            destination.h = 1;
            destination.d = 1;
            SDL_UploadToGPUTexture(copy_pass, &source, &destination, false);
        }

        uploadToGPUBuffer(copy_pass, transfer_buffer, sizeof(Color), state.vertex_buffer,
                          sizeof(vertices));
        uploadToGPUBuffer(copy_pass, transfer_buffer, sizeof(Color) + sizeof(vertices),
                          state.index_buffer, sizeof(indices));

        SDL_ReleaseGPUTransferBuffer(state.device, transfer_buffer);
    }

    SDL_CHECK(Texture::load(state.device, copy_pass, "font.png", &state.font_texture));

    {
        ScopeArena scope(&scratch);
        auto *curl = curl_easy_init();
        SDL_CHECK(curl);
        defer(curl_easy_cleanup(curl));

        struct curl_slist *slist = 0;
        defer(curl_slist_free_all(slist));

        auto buffer = global.allocPrintZ("Hydrus-Client-API-Access-Key: %s",
                                         SDL_getenv("HYDRUS_CLIENT_API"));
        slist = curl_slist_append(slist, buffer.ptr);
        SDL_assert(slist);

        // TODO: check different amount of tags start from less than
        // one, until find less tag with rating = 1100

        Response response = {.arena = scope.arena};

        // get files - search files
        Slice<u8> result;
        {
            SliceZ<char> string;
            const u32 elo = 1100;
            auto *tags = cJSON_CreateArray();
            // json
            auto tag = scope.tmp.allocPrintZ("system:count for elo more than %u", elo);
            cJSON_AddItemToArray(tags, cJSON_CreateString(tag.ptr));
            cJSON_AddItemToArray(tags, cJSON_CreateString("system:number of tags < 4"));
            string = scope.tmp.dupeAndFreeZ(cJSON_Print(tags));
            cJSON_Delete(tags);
            // escape
            string = scope.tmp.dupeAndFreeZ(curl_easy_escape(curl, string.ptr, (int)string.len),
                                            curl_free);
            // url
            string = scope.tmp.allocPrintZ(
                "http://127.0.0.1:45869/get_files/search_files?tags=%s", string.ptr);
            // set

            curl_easy_setopt(curl, CURLOPT_HTTPHEADER, slist);

            curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writeResponse);
            curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&response);

            result = request(curl, &response, string.ptr);
        }

        auto *json = cJSON_ParseWithLength((char *)result.ptr, result.len);
        defer(cJSON_Delete(json));
        SDL_assert(json);

        const cJSON *file_ids = cJSON_GetObjectItemCaseSensitive(json, "file_ids");

        SDL_assert(file_ids);

        size_t file_id = 0;

        const cJSON *file_id_cjson = NULL;
        cJSON_ArrayForEach(file_id_cjson, file_ids) {
            SDL_assert(cJSON_IsNumber(file_id_cjson));
            file_id = file_id_cjson->valueint;
            break; // TODO: choose image based on elo rating instead of choosing first one
        }

        SDL_assert(file_id);
        SDL_Log("file_id: %lu", file_id);

        {
            auto string = scope.tmp.allocPrintZ(
                "http://127.0.0.1:45869/get_files/render?file_id=%d", file_id_cjson->valueint);

            auto result = request(curl, &response, string.ptr);

            SDL_CHECK(Texture::load(state.device, copy_pass, result, &state.image_texture));
        }

        // get file path
        {
            auto string = scope.tmp.allocPrintZ(
                "http://127.0.0.1:45869/get_files/file_path?file_id=%lu", file_id);
            auto result = request(curl, &response, string.ptr);

            auto *json = cJSON_ParseWithLength((char *)result.ptr, result.len);
            defer(cJSON_Delete(json));

            auto *key = cJSON_GetObjectItemCaseSensitive(json, "path");
            auto *value = cJSON_GetStringValue(key);

            // TODO copy file link to clipboard
        }

        // TODO input box for text
        // TODO check how to get list of all possible tags
        // TODO check if I can create parent tags and alias
        // TODO i need something like config file, that provide list of tags I check
    }
    SDL_EndGPUCopyPass(copy_pass);
    SDL_SubmitGPUCommandBuffer(command_buffer);

    state.instance_transfer_buffer =
        createGPUTransferBuffer(state.device, sizeof(Instance) * MAX_INSTANCES);
    SDL_CHECK(state.instance_transfer_buffer);

    for (uint i = 0; i < MAX_TEXTURE_SAMPLERS; i++) {
        state.texture_sampler_bindings[i].texture = state.default_texture.ptr;
        state.texture_sampler_bindings[i].sampler = state.sampler;
    }

    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent([[maybe_unused]] void *appstate, SDL_Event *event) {
    if (event->type == SDL_EVENT_QUIT) {
        return SDL_APP_SUCCESS;
    }
    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate([[maybe_unused]] void *appstate) {
    auto *command_buffer = SDL_AcquireGPUCommandBuffer(state.device);
    SDL_CHECK(command_buffer);

    uint instances_len = 0;

    auto *copy_pass = SDL_BeginGPUCopyPass(command_buffer);
    {
        {
            Instance *instances_raw = (Instance *)SDL_MapGPUTransferBuffer(
                state.device, state.instance_transfer_buffer, true);
            SDL_CHECK(instances_raw);

            const float scale = float(state.screen.y) / float(state.image_texture.size.y);
            instances_raw[0] = {
                {0, 0}, {float(state.image_texture.size.x) * scale, float(state.screen.y)}, 1};
            instances_len = 1;

            SDL_CHECK(instances_len <= MAX_INSTANCES);

            SDL_UnmapGPUTransferBuffer(state.device, state.instance_transfer_buffer);
        }

        uploadToGPUBuffer(copy_pass, state.instance_transfer_buffer, 0, state.instance_buffer,
                          sizeof(Instance) * instances_len);
    }
    SDL_EndGPUCopyPass(copy_pass);

    SDL_GPUTexture *swapchain_texture = 0;

    SDL_CHECK(SDL_WaitAndAcquireGPUSwapchainTexture(command_buffer, state.window,
                                                    &swapchain_texture, 0, 0));

    if (swapchain_texture) {
        SDL_GPUColorTargetInfo color_target_info = {};
        color_target_info.texture = swapchain_texture;
        color_target_info.clear_color = {
            .r = float(GRAY.r) / 255.0F,
            .g = float(GRAY.g) / 255.0F,
            .b = float(GRAY.b) / 255.0F,
            .a = float(GRAY.a) / 255.0F,
        };
        color_target_info.load_op = SDL_GPU_LOADOP_CLEAR;
        color_target_info.store_op = SDL_GPU_STOREOP_STORE;
        auto *render_pass = SDL_BeginGPURenderPass(command_buffer, &color_target_info, 1, 0);

        SDL_BindGPUGraphicsPipeline(render_pass, state.pipeline);
        SDL_GPUBufferBinding buffer_bindings[2] = {{state.vertex_buffer, 0},
                                                   {state.instance_buffer, 0}};
        SDL_BindGPUVertexBuffers(render_pass, 0, buffer_bindings, 2);
        const SDL_GPUBufferBinding buffer_binding = {state.index_buffer, 0};
        SDL_BindGPUIndexBuffer(render_pass, &buffer_binding, SDL_GPU_INDEXELEMENTSIZE_16BIT);

        // TODO: auto bind
        state.texture_sampler_bindings[0].texture = state.font_texture.ptr;
        state.texture_sampler_bindings[1].texture = state.image_texture.ptr;
        for (uint i = 2; i < state.texture_sampler_bindings.len; i++) {
            state.texture_sampler_bindings[i].texture = state.default_texture.ptr;
        }

        SDL_BindGPUFragmentSamplers(render_pass, 0, state.texture_sampler_bindings.data,
                                    state.texture_sampler_bindings.len);
        struct UBO {
            ivec2 screen;
        } ubo{};
        ubo.screen = {state.screen};
        SDL_PushGPUVertexUniformData(command_buffer, 0, &ubo, sizeof(UBO));
        SDL_DrawGPUIndexedPrimitives(render_pass, 6, instances_len, 0, 0, 0);

        SDL_EndGPURenderPass(render_pass);
    }

    SDL_SubmitGPUCommandBuffer(command_buffer);
    return SDL_APP_CONTINUE;
}

void SDL_AppQuit([[maybe_unused]] void *appstate, [[maybe_unused]] SDL_AppResult result) {
    global.deinit();
    frame.deinit();
    scratch.deinit();

    SDL_ReleaseGPUTexture(state.device, state.default_texture.ptr);
    SDL_ReleaseGPUTexture(state.device, state.font_texture.ptr);
    SDL_ReleaseGPUTexture(state.device, state.image_texture.ptr);

    SDL_ReleaseGPUBuffer(state.device, state.instance_buffer);
    SDL_ReleaseGPUBuffer(state.device, state.index_buffer);
    SDL_ReleaseGPUBuffer(state.device, state.vertex_buffer);

    SDL_ReleaseGPUTransferBuffer(state.device, state.instance_transfer_buffer);
    SDL_ReleaseGPUGraphicsPipeline(state.device, state.pipeline);
    SDL_ReleaseGPUSampler(state.device, state.sampler);
    SDL_ReleaseWindowFromGPUDevice(state.device, state.window);
    SDL_DestroyGPUDevice(state.device);
    SDL_DestroyWindow(state.window);
}
