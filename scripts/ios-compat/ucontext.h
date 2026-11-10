#pragma once
#include <libucontext/libucontext.h>
#define ucontext_t libucontext_ucontext_t
#define getcontext libucontext_getcontext
#define makecontext libucontext_makecontext
#define setcontext libucontext_setcontext
#define swapcontext libucontext_swapcontext
