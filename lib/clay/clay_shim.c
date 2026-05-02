#define CLAY_IMPLEMENTATION
#define CLAY_DISABLE_SIMD
#include "clay.h"
#include "clay_shim.h"

#include <string.h>  /* strlen */
#include <stdint.h>
#include <float.h>   /* FLT_MAX */
#include <stdlib.h>  /* malloc, free */

static void *s_clay_mem = NULL;

/* Cached render command array from the last clay_shim_end() call */
static Clay_RenderCommandArray s_render_cmds;

/* -----------------------------------------------------------------------
 * Helper: make a Clay_ElementId from a runtime C string
 * --------------------------------------------------------------------- */
static Clay_ElementId make_id(const char *id) {
    Clay_String s;
    s.isStaticallyAllocated = false;
    s.length = (int32_t)strlen(id);
    s.chars  = id;
    return Clay__HashString(s, 0);
}

/* -----------------------------------------------------------------------
 * Lifecycle
 * --------------------------------------------------------------------- */
static void clay_noop_error(Clay_ErrorData e) { (void)e; }

void clay_shim_init(float width, float height) {
    /* Lower element counts — our layout has ~10-15 elements, 512 is ample. */
    Clay_SetMaxElementCount(512);
    Clay_SetMaxMeasureTextCacheWordCount(1024);

    uint32_t needed = Clay_MinMemorySize();
    if (s_clay_mem) { free(s_clay_mem); }
    s_clay_mem = malloc(needed);

    Clay_Arena arena = Clay_CreateArenaWithCapacityAndMemory(needed, s_clay_mem);
    Clay_ErrorHandler err_handler;
    err_handler.errorHandlerFunction = clay_noop_error;
    err_handler.userData = NULL;
    Clay_Dimensions dims = { width, height };
    Clay_Initialize(arena, dims, err_handler);
    memset(&s_render_cmds, 0, sizeof(s_render_cmds));
}

void clay_shim_resize(float width, float height) {
    Clay_Dimensions dims = { width, height };
    Clay_SetLayoutDimensions(dims);
}

void clay_shim_free(void) {
    if (s_clay_mem) { free(s_clay_mem); s_clay_mem = NULL; }
}

/* -----------------------------------------------------------------------
 * Frame
 * --------------------------------------------------------------------- */
void clay_shim_begin(void) {
    Clay_BeginLayout();
}

int clay_shim_end(void) {
    s_render_cmds = Clay_EndLayout(0.0f);
    return s_render_cmds.length;
}

int clay_shim_render_count(void) {
    return s_render_cmds.length;
}

/* -----------------------------------------------------------------------
 * Input
 * --------------------------------------------------------------------- */
void clay_shim_pointer(float x, float y, bool pressed) {
    Clay_Vector2 pos = { x, y };
    Clay_SetPointerState(pos, pressed);
}

void clay_shim_scroll(float dx, float dy, float dt) {
    Clay_Vector2 delta = { dx, dy };
    Clay_UpdateScrollContainers(false, delta, dt);
}

/* -----------------------------------------------------------------------
 * Helper: build a Clay_SizingAxis from our type enum + value
 * --------------------------------------------------------------------- */
static Clay_SizingAxis make_sizing(int type, float value) {
    /* For FIT/GROW, value=0 means uncapped (use FLT_MAX); value>0 is a max cap. */
    float max = (value > 0.0f) ? value : FLT_MAX;
    switch (type) {
    case 0: return CLAY_SIZING_FIT(0, max);     /* FIT  */
    case 1: return CLAY_SIZING_GROW(0, max);    /* GROW */
    case 2: return CLAY_SIZING_FIXED(value);    /* FIXED */
    case 3: return CLAY_SIZING_PERCENT(value);  /* PERCENT */
    default: return CLAY_SIZING_FIT(0, FLT_MAX);
    }
}

/* -----------------------------------------------------------------------
 * Element push / pop
 * --------------------------------------------------------------------- */
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
) {
    Clay_ElementDeclaration decl;
    memset(&decl, 0, sizeof(decl));

    /* Layout */
    decl.layout.sizing.width  = make_sizing(width_type,  width_value);
    decl.layout.sizing.height = make_sizing(height_type, height_value);
    decl.layout.padding.left   = (uint16_t)padding_x;
    decl.layout.padding.right  = (uint16_t)padding_x;
    decl.layout.padding.top    = (uint16_t)padding_y;
    decl.layout.padding.bottom = (uint16_t)padding_y;
    decl.layout.childGap       = (uint16_t)child_gap;
    decl.layout.layoutDirection =
        (direction == 1) ? CLAY_TOP_TO_BOTTOM : CLAY_LEFT_TO_RIGHT;

    /* Background */
    if (has_bg) {
        decl.backgroundColor.r = (float)bg_r;
        decl.backgroundColor.g = (float)bg_g;
        decl.backgroundColor.b = (float)bg_b;
        decl.backgroundColor.a = (float)bg_a;
    }

    /* Corner radius */
    decl.cornerRadius.topLeft     = corner_radius;
    decl.cornerRadius.topRight    = corner_radius;
    decl.cornerRadius.bottomLeft  = corner_radius;
    decl.cornerRadius.bottomRight = corner_radius;

    /* Border */
    if (border_w > 0.0f) {
        uint16_t bw = (uint16_t)border_w;
        decl.border.width.left   = bw;
        decl.border.width.right  = bw;
        decl.border.width.top    = bw;
        decl.border.width.bottom = bw;
        decl.border.color.r = (float)bord_r;
        decl.border.color.g = (float)bord_g;
        decl.border.color.b = (float)bord_b;
        decl.border.color.a = (float)bord_a;
    }

    if (id && id[0]) {
        Clay__OpenElementWithId(make_id(id));
    } else {
        Clay__OpenElement();
    }
    Clay__ConfigureOpenElement(decl);
}

void clay_shim_push_scroll(
    const char* id,
    int         width_type,  float width_value,
    int         height_type, float height_value,
    int         padding
) {
    Clay_ElementDeclaration decl;
    memset(&decl, 0, sizeof(decl));

    decl.layout.sizing.width  = make_sizing(width_type,  width_value);
    decl.layout.sizing.height = make_sizing(height_type, height_value);
    decl.layout.padding.left   = (uint16_t)padding;
    decl.layout.padding.right  = (uint16_t)padding;
    decl.layout.padding.top    = (uint16_t)padding;
    decl.layout.padding.bottom = (uint16_t)padding;

    /* Enable vertical (and horizontal) clipping / scrolling */
    decl.clip.vertical   = true;
    decl.clip.horizontal = false;

    if (id && id[0]) {
        Clay__OpenElementWithId(make_id(id));
    } else {
        Clay__OpenElement();
    }
    Clay__ConfigureOpenElement(decl);
}

void clay_shim_push_float(
    const char* id,
    float x, float y,
    float w, float h
) {
    Clay_ElementDeclaration decl;
    memset(&decl, 0, sizeof(decl));

    decl.layout.sizing.width  = CLAY_SIZING_FIXED(w);
    decl.layout.sizing.height = CLAY_SIZING_FIXED(h);

    decl.floating.offset.x  = x;
    decl.floating.offset.y  = y;
    decl.floating.attachTo  = CLAY_ATTACH_TO_ROOT;

    if (id && id[0]) {
        Clay__OpenElementWithId(make_id(id));
    } else {
        Clay__OpenElement();
    }
    Clay__ConfigureOpenElement(decl);
}

void clay_shim_pop(void) {
    Clay__CloseElement();
}

/* -----------------------------------------------------------------------
 * Queries
 * --------------------------------------------------------------------- */
bool clay_shim_get_rect(const char* id,
                        float* x, float* y,
                        float* w, float* h)
{
    Clay_ElementId eid = make_id(id);
    Clay_ElementData data = Clay_GetElementData(eid);
    if (!data.found) return false;
    *x = data.boundingBox.x;
    *y = data.boundingBox.y;
    *w = data.boundingBox.width;
    *h = data.boundingBox.height;
    return true;
}

bool clay_shim_get_scroll(const char* id, float* sx, float* sy) {
    Clay_ElementId eid = make_id(id);
    Clay_ScrollContainerData data = Clay_GetScrollContainerData(eid);
    if (!data.found) return false;
    *sx = data.scrollPosition ? data.scrollPosition->x : 0.0f;
    *sy = data.scrollPosition ? data.scrollPosition->y : 0.0f;
    return true;
}

void clay_shim_set_scroll_y(const char* id, float sy) {
    Clay_ElementId eid = make_id(id);
    Clay_ScrollContainerData data = Clay_GetScrollContainerData(eid);
    if (data.found && data.scrollPosition) {
        data.scrollPosition->y = sy;
    }
}

/* -----------------------------------------------------------------------
 * Render command iterator
 * --------------------------------------------------------------------- */
bool clay_shim_render_get(
    int     i,
    int*    type,
    float*  x,      float* y,      float* w,     float* h,
    float*  color_r, float* color_g, float* color_b, float* color_a,
    float*  corner_radius,
    float*  border_w,
    float*  border_r, float* border_g, float* border_b, float* border_a
) {
    if (i < 0 || i >= s_render_cmds.length) return false;

    Clay_RenderCommand *cmd = Clay_RenderCommandArray_Get(&s_render_cmds, i);
    if (!cmd) return false;

    *type = (int)cmd->commandType;
    *x = cmd->boundingBox.x;
    *y = cmd->boundingBox.y;
    *w = cmd->boundingBox.width;
    *h = cmd->boundingBox.height;

    /* Defaults */
    *color_r = *color_g = *color_b = *color_a = 0.0f;
    *corner_radius = 0.0f;
    *border_w = 0.0f;
    *border_r = *border_g = *border_b = *border_a = 0.0f;

    switch (cmd->commandType) {
    case CLAY_RENDER_COMMAND_TYPE_RECTANGLE: {
        Clay_RectangleRenderData *rd = &cmd->renderData.rectangle;
        *color_r = rd->backgroundColor.r;
        *color_g = rd->backgroundColor.g;
        *color_b = rd->backgroundColor.b;
        *color_a = rd->backgroundColor.a;
        *corner_radius = rd->cornerRadius.topLeft;
        break;
    }
    case CLAY_RENDER_COMMAND_TYPE_BORDER: {
        Clay_BorderRenderData *bd = &cmd->renderData.border;
        *color_r = bd->color.r;
        *color_g = bd->color.g;
        *color_b = bd->color.b;
        *color_a = bd->color.a;
        *corner_radius = bd->cornerRadius.topLeft;
        *border_r = bd->color.r;
        *border_g = bd->color.g;
        *border_b = bd->color.b;
        *border_a = bd->color.a;
        /* Use max of the four side widths as the reported border_w */
        uint16_t bw = bd->width.left;
        if (bd->width.right  > bw) bw = bd->width.right;
        if (bd->width.top    > bw) bw = bd->width.top;
        if (bd->width.bottom > bw) bw = bd->width.bottom;
        *border_w = (float)bw;
        break;
    }
    default:
        break;
    }

    return true;
}
