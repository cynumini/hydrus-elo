#define _POSIX_C_SOURCE 200112L
#include "window.h"
#include "xdg-decoration-client-protocol.h"
#include "xdg-shell-client-protocol.h"
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>
#include <wayland-client.h>

typedef struct
{
    struct wl_display *wl_display;
    struct wl_registry *wl_registry;
    struct wl_compositor *wl_compositor;
    struct wl_surface *wl_surface;
    struct xdg_wm_base *xdg_wm_base;
    struct xdg_surface *xdg_surface;
    struct xdg_toplevel *xdg_toplevel;
    struct wl_shm *wl_shm;
    struct zxdg_decoration_manager_v1 *zxdg_decoration_manager;
    struct zxdg_toplevel_decoration_v1 *zxdg_toplevel_decoration;
    struct wl_seat *wl_seat;
    struct wl_keyboard *wl_keyboard;

    void (*on_keyboard_key)(u32, u32);

    u32 width;
    u32 height;
    bool running;

} Window;


static void wl_keyboard_keymap(void *data, struct wl_keyboard *wl_keyboard, u32 format, i32 fd, u32 size)
{
}

static void wl_keyboard_enter(void *data, struct wl_keyboard *wl_keyboard, u32 serial,
                              struct wl_surface *wl_surface, struct wl_array *keys)
{
}

static void wl_keyboard_leave(void *data, struct wl_keyboard *wl_keyboard, u32 serial,
                              struct wl_surface *wl_surface)
{
}

static void wl_keyboard_key(void *data, struct wl_keyboard *wl_keyboard, u32 serial, u32 time, u32 key,
                            u32 state)
{
    Window *window = data;
    window->on_keyboard_key(key, state);
    if (key == KEY_ESCAPE && state == KEY_RELEASED)
    {
        window->running = false;
    }
}

static void wl_keyboard_modifiers(void *data, struct wl_keyboard *wl_keyboard, u32 serial, u32 mods_depressed,
                                  u32 mods_latched, u32 mods_locked, u32 group)
{
}

static void wl_keyboard_repeat_info(void *data, struct wl_keyboard *wl_keyboard, i32 rate, i32 delay)
{
}

static struct wl_keyboard_listener wl_keyboard_listener = {
    .keymap = wl_keyboard_keymap,
    .enter = wl_keyboard_enter,
    .leave = wl_keyboard_leave,
    .key = wl_keyboard_key,
    .modifiers = wl_keyboard_modifiers,
    .repeat_info = wl_keyboard_repeat_info,
};

static void wl_seat_capabilities(void *data, struct wl_seat *wl_seat, u32 capabilities)
{
}

static void wl_seat_name(void *data, struct wl_seat *wl_seat, const char *name)
{
}

static const struct wl_seat_listener wl_seat_listener = {
    .capabilities = wl_seat_capabilities,
    .name = wl_seat_name,
};

static void xdg_toplevel_configure(void *data, struct xdg_toplevel *xdg_toplevel, int32_t width,
                                   int32_t height, struct wl_array *states)
{
}

static void xdg_toplevel_close(void *data, struct xdg_toplevel *xdg_toplevel)
{
    Window *state = data;
    state->running = false;
}

static void xdg_toplevel_configure_bounds(void *data, struct xdg_toplevel *xdg_toplevel, int32_t width,
                                          int32_t height)
{
}

static void xdg_toplevel_wm_capabilities(void *data, struct xdg_toplevel *xdg_toplevel,
                                         struct wl_array *states)
{
}

static const struct xdg_toplevel_listener xdg_toplevel_listener = {
    .configure = xdg_toplevel_configure,
    .close = xdg_toplevel_close,
    .configure_bounds = xdg_toplevel_configure_bounds,
    .wm_capabilities = xdg_toplevel_wm_capabilities,
};

static void randname(char *buf)
{
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    long r = ts.tv_nsec;
    for (int i = 0; i < 6; i++)
    {
        buf[i] = 'A' + (r & 15) + (r & 16) * 2;
        r >>= 5;
    }
}

static int create_shm_file(void)
{
    int retries = 100;
    do
    {
        char name[] = "/wl_shm-XXXXXX";
        randname(name + sizeof(name) - 7);
        --retries;
        int fd = shm_open(name, O_RDWR | O_CREAT | O_EXCL, 0600);
        if (fd >= 0)
        {
            shm_unlink(name);
            return fd;
        }
    } while (retries > 0 && errno == EEXIST);
    return -1;
}

static int allocate_shm_file(size_t size)
{
    int fd = create_shm_file();
    if (fd < 0)
        return -1;
    int ret;
    do
    {
        ret = ftruncate(fd, size);
    } while (ret < 0 && errno == EINTR);
    if (ret < 0)
    {
        close(fd);
        return -1;
    }
    return fd;
}

static void wl_buffer_release(void *data, struct wl_buffer *wl_buffer)
{
    wl_buffer_destroy(wl_buffer);
}

static const struct wl_buffer_listener wl_buffer_listener = {
    .release = wl_buffer_release,
};

static struct wl_buffer *draw_frame(Window *window)
{
    int stride = window->width * 4;
    int size = stride * window->height;
    int fd = allocate_shm_file(size);
    if (fd == -1)
    {
        return NULL;
    }
    uint32_t *data = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (data == MAP_FAILED)
    {
        close(fd);
        return NULL;
    }
    struct wl_shm_pool *pool = wl_shm_create_pool(window->wl_shm, fd, size);
    struct wl_buffer *buffer =
        wl_shm_pool_create_buffer(pool, 0, window->width, window->height, stride, WL_SHM_FORMAT_XRGB8888);
    // for (size_t i = 0; i < 640 * 480; i++)
    // {
    //     data[i] = 0xffffffff;
    // };
    munmap(data, size);
    wl_buffer_add_listener(buffer, &wl_buffer_listener, NULL);
    return buffer;
}
static void xdg_surface_configure(void *data, struct xdg_surface *xdg_surface, u32 serial)
{
    Window *window = data;
    xdg_surface_ack_configure(xdg_surface, serial);

    struct wl_buffer *buffer = draw_frame(window);
    wl_surface_attach(window->wl_surface, buffer, 0, 0);
    wl_surface_commit(window->wl_surface);
}

static const struct xdg_surface_listener xdg_surface_listener = {
    .configure = xdg_surface_configure,
};

static void xdg_wm_base_ping(void *data, struct xdg_wm_base *xdg_wm_base, u32 serial)
{
    xdg_wm_base_pong(xdg_wm_base, serial);
}

static const struct xdg_wm_base_listener xdg_wm_base_listener = {
    .ping = xdg_wm_base_ping,
};

static void registry_global(void *data, struct wl_registry *registry, u32 name, const char *interface,
                            u32 version)
{
    Window *window = data;
    if (strcmp(interface, wl_compositor_interface.name) == 0)
    {
        window->wl_compositor = wl_registry_bind(registry, name, &wl_compositor_interface, 6);
    }
    else if (strcmp(interface, xdg_wm_base_interface.name) == 0)
    {
        window->xdg_wm_base = wl_registry_bind(registry, name, &xdg_wm_base_interface, version);
        xdg_wm_base_add_listener(window->xdg_wm_base, &xdg_wm_base_listener, window);
    }
    else if (strcmp(interface, wl_shm_interface.name) == 0)
    {
        window->wl_shm = wl_registry_bind(registry, name, &wl_shm_interface, 2);
    }
    else if (strcmp(interface, zxdg_decoration_manager_v1_interface.name) == 0)
    {
        window->zxdg_decoration_manager =
            wl_registry_bind(registry, name, &zxdg_decoration_manager_v1_interface, version);
    }
    else if (strcmp(interface, wl_seat_interface.name) == 0)
    {
        window->wl_seat = wl_registry_bind(registry, name, &wl_seat_interface, version);
        wl_seat_add_listener(window->wl_seat, &wl_seat_listener, window);
    }
    else
    {
        // printf("name: %i, interface: %s, version: %i\n", name, interface, version);
    }
}

static void registry_global_remove(void *data, struct wl_registry *wl_registry, u32 name)
{
}

static const struct wl_registry_listener registry_listener = {
    .global = registry_global,
    .global_remove = registry_global_remove,
};

void WindowDoStaff(u32 width, u32 height, const char *title, void (*OnKeyboardKey)(u32, u32))
{
    Window window = {0};
    window.width = width;
    window.height = height;
    window.on_keyboard_key = OnKeyboardKey;
    window.wl_display = wl_display_connect(NULL);
    window.wl_registry = wl_display_get_registry(window.wl_display);
    window.running = true;
    wl_registry_add_listener(window.wl_registry, &registry_listener, &window);
    wl_display_roundtrip(window.wl_display);

    window.wl_surface = wl_compositor_create_surface(window.wl_compositor);
    window.xdg_surface = xdg_wm_base_get_xdg_surface(window.xdg_wm_base, window.wl_surface);
    xdg_surface_add_listener(window.xdg_surface, &xdg_surface_listener, &window);
    window.xdg_toplevel = xdg_surface_get_toplevel(window.xdg_surface);
    xdg_toplevel_add_listener(window.xdg_toplevel, &xdg_toplevel_listener, &window);
    xdg_toplevel_set_title(window.xdg_toplevel, title);
    window.zxdg_toplevel_decoration = zxdg_decoration_manager_v1_get_toplevel_decoration(
        window.zxdg_decoration_manager, window.xdg_toplevel);
    wl_surface_commit(window.wl_surface);
    window.wl_keyboard = wl_seat_get_keyboard(window.wl_seat);
    wl_keyboard_add_listener(window.wl_keyboard, &wl_keyboard_listener, &window);

    while (wl_display_dispatch(window.wl_display) && window.running == true)
    {
        printf("update\n");
    }
}
