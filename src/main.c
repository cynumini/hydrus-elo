#include "sakana.h"
#include "window.h"
#include <stdio.h>

void on_keyboard_key(u32 key, u32 state)
{
    if (key == KEY_SPACE && state == KEY_RELEASED)
    {
        printf("You released space!\n");
    }
}

int main(int argc, char *argv[])
{
    const u32 screenWidth = 800;
    const u32 screenHeight = 450;

    WindowDoStaff(screenWidth, screenHeight, "hydrus-elo", on_keyboard_key);
}
