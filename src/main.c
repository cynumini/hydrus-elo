#include "xdg-shell-client-protocol.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wayland-client.h>

typedef struct
{
    struct wl_display *display;
    struct wl_registry *registry;
    struct wl_compositor *compositor;
    struct wl_surface *surface;
    struct xdg_surface * xdg_surface;
} State;

static void registry_global(void *data, struct wl_registry *registry, uint32_t name, const char *interface,
                            uint32_t version)
{
    State *state = data;
    if (strcmp(interface, wl_compositor_interface.name) == 0)
    {
        state->compositor = wl_registry_bind(registry, name, &wl_compositor_interface, 6);
    }
    else
    {
        printf("hydrus_elo %s\n", interface);
    }
}

static void registry_global_remove(void *data, struct wl_registry *registry, uint32_t name)
{
}

static const struct wl_registry_listener registry_listener = {
    .global = registry_global,
    .global_remove = registry_global_remove,
};

int main(int argc, char *argv[])
{
    State state = {0};
    state.display = wl_display_connect(NULL);
    state.registry = wl_display_get_registry(state.display);
    wl_registry_add_listener(state.registry, &registry_listener, &state);
    wl_display_roundtrip(state.display);
    state.surface = wl_compositor_create_surface(state.compositor);

    while (wl_display_dispatch(state.display))
    {
    }

    return EXIT_SUCCESS;
}
