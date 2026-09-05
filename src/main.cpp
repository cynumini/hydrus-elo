#include <cjson/cJSON.h>
#include <curl/curl.h>

#include "sakana.cpp"
#include "unagi.cpp"

#include "../build/shader.frag.hpp"
#include "../build/shader.vert.hpp"

struct Response {
    char *ptr;
    size_t len;
};

static size_t writeResponse(char *data, [[maybe_unused]] size_t size, size_t len,
                            void *user_data) {
    auto *response = (Response *)user_data;
    char *ptr = (char *)SDL_realloc(response->ptr, response->len + len);
    if (ptr == 0) return 0;
    response->ptr = ptr;
    memcpy(&(response->ptr[response->len]), data, len);
    response->len += len;
    return len;
}

const u32 INSTANCE_CAPACITY = 1U << 0U; // 2^0 = 1

struct Instance {
    vec2 position;
    vec2 size;
    u32 texture_index;
};

Sint32 main() {
    auto app = unagiInit("hydrus-elo", "0.1", "cynumini.hydrus-elo");
    defer(unagiInit(app));

    auto *curl = curl_easy_init();
    defer(curl_easy_cleanup(curl));
    SDL_assert(curl);

    struct curl_slist *slist = 0;
    defer(curl_slist_free_all(slist));

    const usize BUFFER_SIZE = 1U << 6U; // 2 ^ 6 = 64
    char buffer[BUFFER_SIZE] = {};

    SDL_assert((usize)SDL_snprintf(buffer, BUFFER_SIZE, "Hydrus-Client-API-Access-Key: %s",
                                   SDL_getenv("HYDRUS_CLIENT_API")) < BUFFER_SIZE);

    // get api key from env
    slist = curl_slist_append(slist, buffer);
    SDL_assert(slist);

    // TODO: https://curl.se/libcurl/c/curl_easy_escape.html for tags
    // TODO: check different amount of tags start from less than one, until find less tag with
    // rating = 1100
    curl_easy_setopt(curl, CURLOPT_URL,
                     "http://127.0.0.1:45869/get_files/"
                     "search_files?tags=%5B%22system%3Acount%20for%20elo%20more%20than%201100%22%"
                     "2C%20%22system%3Anumber%20of%20tags%20%3C%204%22%5D");
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, slist);

    Response response = {};
    defer(SDL_free(response.ptr));

    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writeResponse);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&response);

    curl_easy_perform(curl);

    SDL_Log("%.*s\n", Sint32(response.len), response.ptr);

    auto *json = cJSON_ParseWithLength(response.ptr, response.len);
    defer(cJSON_Delete(json));
    SDL_assert(json);

    const cJSON *file_ids = cJSON_GetObjectItemCaseSensitive(json, "file_ids");
    const cJSON *file_id = NULL;
    SDL_assert(file_ids);

    // TODO: get render file and display it
    // curl_easy_setopt(curl, CURLOPT_URL, "http://127.0.0.1:45869/get_files/render?file_id=")

    cJSON_ArrayForEach(file_id, file_ids) {
        SDL_assert(cJSON_IsNumber(file_id));
        SDL_Log("file_id: %d", file_id->valueint);

        SDL_assert((usize)SDL_snprintf(buffer, BUFFER_SIZE,
                                       "http://127.0.0.1:45869/get_files/render?file_id=%d",
                                       file_id->valueint) < BUFFER_SIZE);

        curl_easy_setopt(curl, CURLOPT_URL, buffer);
        SDL_free(response.ptr);
        response.ptr = 0;
        response.len = 0;
        curl_easy_perform(curl);
        break; // TODO: choose image based on elo rating instead of choosing first one
    }

    const SDL_GPUVertexAttribute vertex_attributes[] = {
        {0, 0, SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, 0},
        {1, 1, SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, offsetof(Instance, position)},
        {2, 1, SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2, offsetof(Instance, size)},
        {3, 1, SDL_GPU_VERTEXELEMENTFORMAT_UINT, offsetof(Instance, texture_index)},
    };
    auto texture_format = SDL_GetGPUSwapchainTextureFormat(app.device, app.window);
    auto pipeline = createPipeline(
        app.device, sizeof(Instance) * INSTANCE_CAPACITY, shader_vert_code, shader_frag_code, 2,
        sizeof(Instance), vertex_attributes, SDL_arraysize(vertex_attributes), texture_format);
    defer(destroyPipeline(pipeline, app.device));

    Texture texture = {};
    defer(SDL_ReleaseGPUTexture(app.device, texture.ptr));

    {
        auto *command_buffer = SDL_AcquireGPUCommandBuffer(app.device);
        SDL_assert(command_buffer);
        defer(SDL_SubmitGPUCommandBuffer(command_buffer));

        auto *copy_pass = SDL_BeginGPUCopyPass(command_buffer);
        defer(SDL_EndGPUCopyPass(copy_pass));

        {
            SDL_assert(response.len);
            auto *src = SDL_IOFromConstMem(response.ptr, response.len);
            int width = 0;
            int height = 0;
            texture.ptr =
                IMG_LoadGPUTexture_IO(app.device, copy_pass, src, true, &width, &height);
            texture.size = {f32(width), f32(height)};
            SDL_assert(texture.ptr);
        }

        vec2 vertices[4] = {{0.0F, 0.0F}, {1.0F, 0.0F}, {1.0F, 1.0F}, {0.0F, 1.0F}};
        uploadPipeline(pipeline, app.device, copy_pass, vertices);
    }

    while (app.running) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            switch (event.type) {
            case SDL_EVENT_QUIT: {
                app.running = false;
            } break;
            case SDL_EVENT_KEY_DOWN: {
                if (event.key.scancode == SDL_SCANCODE_ESCAPE) {
                    app.running = false;
                }
            } break;
            default: {
            } break;
            }
        }
    }

    return 0;
}
