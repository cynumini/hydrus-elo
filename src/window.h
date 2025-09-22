#ifndef WINDOW_H
#define WINDOW_H

#include "sakana.h"

enum
{
    KEY_ESCAPE = 1,
    KEY_SPACE = 57,
};

enum
{
    KEY_RELEASED,
    KEY_PRESSED,
};

void WindowDoStaff(u32 width, u32 height, const char *title, void (*OnKeyboardKey)(u32, u32));

#endif // !WINDOW_H
