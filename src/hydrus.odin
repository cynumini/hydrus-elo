package main

import "core:encoding/json"
import "core:fmt"
import "core:mem"
import "core:net"
import "core:os"
import "core:strings"
import "curl"

@(private = "file")
handle: ^curl.CURL
@(private = "file")
headers: [dynamic]cstring
base := "http://127.0.0.1:45869"

HydrusError :: union {
	mem.Allocator_Error,
	json.Error,
}

hydrus_init :: proc() -> (res: bool, err: HydrusError) {
	handle = curl.easy_init()
	if handle == nil {
		fmt.eprintln("Can't init hydrus")
		return false, nil
	}

	key := os.get_env("HYDRUS_CLIENT_API")
	defer delete(key)

	header_key := strings.builder_make()
	strings.write_string(&header_key, "Hydrus-Client-API-Access-Key: ")
	strings.write_string(&header_key, key)

	header_content := strings.builder_make()
	strings.write_string(&header_content, "Content-Type: application/json")

	append(&headers, (strings.to_cstring(&header_key) or_return))
	append(&headers, strings.to_cstring(&header_content) or_return)

	return true, nil
}

hydrus_deinit :: proc() {
	curl.easy_cleanup(handle)
	for header in headers {
		delete(header)
	}
	delete(headers)
}

// The caller owns the returned memory.
// @(private = "file")
get :: proc(url: string) -> (res: string, err: HydrusError) {
	buffer := strings.builder_make()

	response: curl.Code

	full_url_builder := strings.builder_make()
	strings.write_string(&full_url_builder, base)
	strings.write_string(&full_url_builder, url)
	defer strings.builder_destroy(&full_url_builder)

	full_url := strings.to_cstring(&full_url_builder) or_return

	curl.easy_setopt(handle, curl.Option.URL, full_url)
	write_function := proc(buffer: [^]u8, size: u64, nmemb: u64, userdata: rawptr) -> u64 {
		real_size := size * nmemb
		data := (^strings.Builder)(userdata)
		strings.write_string(data, string(buffer[:real_size]))
		return real_size
	}
	curl.easy_setopt(handle, curl.Option.WRITEFUNCTION, write_function)
	curl.easy_setopt(handle, curl.Option.WRITEDATA, &buffer)

	list: ^curl.slist

	for header in headers {
		list = curl.slist_append(list, header)
	}

	curl.easy_setopt(handle, curl.Option.HTTPHEADER, list)

	response = curl.easy_perform(handle)

	if response != .E_OK {
		fmt.eprintln("Request failed:", curl.easy_strerror(response))
	} else {
	}

	return strings.to_string(buffer), nil
}

// The caller owns the returned memory.
// @(private = "file")
hydrus_get_file_ids :: proc(length: u32) -> (res: json.Array, err: HydrusError) {
	url: string
	defer delete(url)

	url_builder := strings.builder_make()
	strings.write_string(&url_builder, "/get_files/search_files?file_sort_type=4&tags=")

	tags_builder := strings.builder_make()
	defer strings.builder_destroy(&tags_builder)

	fmt.sbprint(&tags_builder, "[\"system:limit is", length, "\", \"system:filetype is image\"]")

	tags_encoded := net.percent_encode(strings.to_string(tags_builder))
	defer delete(tags_encoded)

	strings.write_string(&url_builder, tags_encoded)
	url = strings.to_string(url_builder)

	result := get(url) or_return
	defer delete(result)

	json_data := json.parse(transmute([]u8)result) or_return
	defer json.destroy_value(json_data)

	json_data_file_ids := json_data.(json.Object)["file_ids"].(json.Array)
	ids := make(json.Array, len(json_data_file_ids), cap(json_data_file_ids))
	copy(ids[:], json_data_file_ids[:])

	return ids, nil
}

// The caller owns the returned memory.
hydrus_get_files :: proc(length: u32) -> (res: bool, err: HydrusError) {
	ids := hydrus_get_file_ids(length) or_return
	defer delete(ids)

	url_builder := strings.builder_make()
	defer strings.builder_destroy(&url_builder)

	strings.write_string(&url_builder, "/get_files/file_metadata?file_ids=")

	ids_builder := strings.builder_make()
	defer strings.builder_destroy(&ids_builder)

	strings.write_rune(&ids_builder, '[')
	for id in ids {
		fmt.sbprintf(&ids_builder, "%d,", i64(id.(json.Float)))
	}
	_, _ = strings.pop_rune(&ids_builder)
	strings.write_rune(&ids_builder, ']')

	ids_encoded := net.percent_encode(strings.to_string(ids_builder))
	defer delete(ids_encoded)

	strings.write_string(&url_builder, ids_encoded)

	url := strings.to_string(url_builder)
	result := get(url) or_return
	defer delete(result)
	fmt.println(url)
	fmt.println(result)

	return true, nil
}
