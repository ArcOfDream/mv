#pragma once
#include <stdbool.h>
#include <stdint.h>

/* Lifecycle ---------------------------------------------------------- */
/* Must be called once after the Raylib window is open.                 */
void clay_shim_init(float width, float height);
void clay_shim_resize(float width, float height);
void clay_shim_free(void);

/* Frame -------------------------------------------------------------- */
void clay_shim_begin(void);
int  clay_shim_end(void);   /* returns number of render commands */
int  clay_shim_render_count(void);  /* cached count from last clay_shim_end() call */

/* Input (call before clay_shim_begin every frame) -------------------- */
void clay_shim_pointer(float x, float y, bool pressed);
void clay_shim_scroll(float dx, float dy, float dt);

/* Element push/pop --------------------------------------------------- */
/*
 * direction : 0 = left-to-right row, 1 = top-to-bottom column
 * width_type / height_type:
 *   0 = CLAY_SIZING_FIT   (shrink-wrap children)
 *   1 = CLAY_SIZING_GROW  (fill remaining space)
 *   2 = CLAY_SIZING_FIXED (fixed pixels, use width_value / height_value)
 *   3 = CLAY_SIZING_PERCENT (percent of parent, use width_value 0.0-1.0)
 * padding_x / padding_y : uniform horizontal / vertical inner padding (px)
 * child_gap             : gap between children (px)
 * has_bg                : if non-zero, fill with bg_r/g/b/a
 * corner_radius         : rounded corners (px)
 * border_w              : 0 = no border; > 0 = border width (px)
 */
void clay_shim_push(
    const char* id,
    int         direction,
    int         width_type,  float width_value,
    int         height_type, float height_value,
    int         padding_x,   int   padding_y,
    int         child_gap,
    int         has_bg,
    uint8_t     bg_r, uint8_t bg_g, uint8_t bg_b, uint8_t bg_a,
    float       corner_radius,
    float       border_w,
    uint8_t     bord_r, uint8_t bord_g, uint8_t bord_b, uint8_t bord_a
);

/* Scroll container: clips children to its bounding box.              */
void clay_shim_push_scroll(
    const char* id,
    int         width_type,  float width_value,
    int         height_type, float height_value,
    int         padding
);

/* Floating (overlay) element at absolute screen coords.             */
void clay_shim_push_float(
    const char* id,
    float x, float y,
    float w, float h
);

void clay_shim_pop(void);

/* Queries (valid after clay_shim_end) -------------------------------- */
bool clay_shim_get_rect(const char* id,
                        float* x, float* y,
                        float* w, float* h);
/* Returns scroll offset for a scroll container (y component = vertical). */
bool clay_shim_get_scroll(const char* id, float* sx, float* sy);
/* Set the scroll Y position for a scroll container. */
void clay_shim_set_scroll_y(const char* id, float sy);

/* Render commands (iterate i = 0 .. clay_shim_render_count()-1) ------ */
/*
 * type: 1=rectangle fill, 2=border, 5=scissor_start, 6=scissor_end
 * color / border_color : r/g/b/a as float 0-255 (Clay convention)
 */
bool clay_shim_render_get(
    int     i,
    int*    type,
    float*  x,      float* y,      float* w,     float* h,
    float*  color_r, float* color_g, float* color_b, float* color_a,
    float*  corner_radius,
    float*  border_w,
    float*  border_r, float* border_g, float* border_b, float* border_a
);
