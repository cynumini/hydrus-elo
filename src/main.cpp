#include <sakana/sakana.hpp>

#include <cjson/cJSON.h>
#include <curl/curl.h>

struct Response {
    char *ptr;
    size_t len;
};

static size_t writeResponse(char *data, [[maybe_unused]] size_t size, size_t nmemb,
                            void *user_data) {
    size_t len = nmemb;
    auto *response = (Response *)user_data;
    char *ptr = (char *)SDL_realloc(response->ptr, response->len + len);
    if (ptr == 0) return 0;
    response->ptr = ptr;
    memcpy(&(response->ptr[response->len]), data, len);
    response->len += len;
    return len;
}

Sint32 main() {
    auto app = sakanaInit("hydrus-elo", "0.1", "cynumini.hydrus-elo");
    defer(sakanaDeinit(app));

    auto *curl = curl_easy_init();
    defer(curl_easy_cleanup(curl));
    SDL_assert(curl);

    struct curl_slist *slist = 0;
    defer(curl_slist_free_all(slist));

    // get api key from env
    slist = curl_slist_append(slist,
                              "Hydrus-Client-API-Access-Key: "
                              "API_KEY");
    SDL_assert(slist);

    // TODO: https://curl.se/libcurl/c/curl_easy_escape.html for tags
    // TODO: check different amount of tags start from less than one, until find less tag with
    // raiting = 1100
    curl_easy_setopt(curl, CURLOPT_URL,
                     "http://127.0.0.1:45869/get_files/"
                     "search_files?tags=%5B%22system%3Acount%20for%20elo%20more%20than%201100%22%"
                     "2C%20%22system%3Anumber%20of%20tags%20%3C%202%22%5D");
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
    cJSON_ArrayForEach(file_id, file_ids) {
        SDL_assert(cJSON_IsNumber(file_id));
        SDL_Log("file_id: %d", file_id->valueint);
    }

    // TODO: get render file and display it
    // curl_easy_setopt(curl, CURLOPT_URL, "http://127.0.0.1:45869/get_files/render?file_id=")

    return 0;
}
