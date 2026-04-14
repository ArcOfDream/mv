foreign class Color {
    construct new(r, g, b, a) {}

    foreign r
    foreign g
    foreign b
    foreign a
}

// pure Wren convenience - no foreign needed
class Colors {
    static white   { Color.new(255, 255, 255, 255) }
    static black   { Color.new(0,   0,   0,   255) }
    static blank   { Color.new(0,   0,   0,   0)   }
    static red     { Color.new(230, 41,  55,  255) }
    static green   { Color.new(0,   228, 48,  255) }
    static blue    { Color.new(0,   121, 241, 255) }
    static yellow  { Color.new(253, 249, 0,   255) }
    static magenta { Color.new(255, 0,   255, 255) }
    static cyan    { Color.new(0,   255, 255, 255) }
    static orange  { Color.new(255, 161, 0,   255) }
    static gray    { Color.new(130, 130, 130, 255) }
    static darkgray { Color.new(80, 80,  80,  255) }
}

class Key {
    // printable
    static space  { 32  }
    static apostrophe { 39 }
    static comma  { 44  }
    static minus  { 45  }
    static period { 46  }
    static slash  { 47  }
    static num0 { 48 } 
    static num1 { 49 } 
    static num2 { 50 }
    static num3 { 51 } 
    static num4 { 52 } 
    static num5 { 53 }
    static num6 { 54 } 
    static num7 { 55 } 
    static num8 { 56 }
    static num9 { 57 }
    static a { 65 } 
    static b { 66 } 
    static c { 67 } 
    static d { 68 }
    static e { 69 } 
    static f { 70 } 
    static g { 71 } 
    static h { 72 }
    static i { 73 } 
    static j { 74 }
    static k { 75 }
    static l { 76 }
    static m { 77 }
    static n { 78 }
    static o { 79 } 
    static p { 80 }
    static q { 81 } 
    static r { 82 } 
    static s { 83 }
    static t { 84 }
    static u { 85 }
    static v { 86 }
    static w { 87 }
    static x { 88 }
    static y { 89 }
    static z { 90 }
    // function keys
    static f1  { 290 }
    static f2  { 291 }
    static f3  { 292 }
    static f4  { 293 }
    static f5  { 294 }
    static f6  { 295 }
    static f7  { 296 }
    static f8  { 297 }
    static f9  { 298 } 
    static f10 { 299 }
    static f11 { 300 }
    static f12 { 301 }
    // control
    static escape    { 256 }
    static enter     { 257 }
    static tab       { 258 }
    static backspace { 259 }
    static insert    { 260 }
    static delete    { 261 }
    static right     { 262 }
    static left      { 263 }
    static down      { 264 }
    static up        { 265 }
    static pageUp    { 266 }
    static pageDown  { 267 }
    static home      { 268 }
    static end       { 269 }
    static capsLock  { 280 }
    static leftShift   { 340 }
    static leftControl { 341 }
    static leftAlt     { 342 }
    static rightShift   { 344 }
    static rightControl { 345 }
    static rightAlt     { 346 }
    // numpad
    static kp0 { 320 }
    static kp1 { 321 }
    static kp2 { 322 }
    static kp3 { 323 }
    static kp4 { 324 }
    static kp5 { 325 }
    static kp6 { 326 }
    static kp7 { 327 }
    static kp8 { 328 }
    static kp9 { 329 }
    static kpDecimal  { 330 }
    static kpEnter    { 335 }
}

class Mouse {
    static left   { 0 }
    static right  { 1 }
    static middle { 2 }
    static side   { 3 }
    static extra  { 4 }
    static forward { 5 }
    static back    { 6 }
}

class GamepadButton {
    static unknown        { 0  }
    static leftFaceUp     { 1  }
    static leftFaceRight  { 2  }
    static leftFaceDown   { 3  }
    static leftFaceLeft   { 4  }
    static rightFaceUp    { 5  }
    static rightFaceRight { 6  }
    static rightFaceDown  { 7  }
    static rightFaceLeft  { 8  }
    static leftTrigger1   { 9  }
    static leftTrigger2   { 10 }
    static rightTrigger1  { 11 }
    static rightTrigger2  { 12 }
    static middleLeft     { 13 }
    static middle         { 14 }
    static middleRight    { 15 }
    static leftThumb      { 16 }
    static rightThumb     { 17 }
}

class GamepadAxis {
    static leftX        { 0 }
    static leftY        { 1 }
    static rightX       { 2 }
    static rightY       { 3 }
    static leftTrigger  { 4 }
    static rightTrigger { 5 }
}

// not a foreign class - has no instances, just static foreign methods
class RL {
    // filled shapes
    foreign static drawRectangle(x, y, w, h, color)
    foreign static drawRectangleV(pos, size, color)
    foreign static drawRectangleRounded(x, y, w, h, roundness, segments, color)
    foreign static drawCircle(x, y, radius, color)
    foreign static drawCircleV(center, radius, color)
    foreign static drawEllipse(cx, cy, rx, ry, color)
    foreign static drawRing(center, innerRadius, outerRadius, startAngle, endAngle, segments, color)
    foreign static drawTriangle(v1, v2, v3, color)

    // outlines
    foreign static drawRectangleLines(x, y, w, h, color)
    foreign static drawRectangleLinesEx(x, y, w, h, lineThick, color)
    foreign static drawCircleLines(x, y, radius, color)
    foreign static drawTriangleLines(v1, v2, v3, color)

    // lines
    foreign static drawLine(x1, y1, x2, y2, color)
    foreign static drawLineV(start, end, color)
    foreign static drawLineEx(start, end, thick, color)

    // text
    foreign static drawText(text, x, y, fontSize, color)
    foreign static drawFps(x, y)
    foreign static measureText(text, fontSize)

    // keyboard
    foreign static isKeyDown(key)
    foreign static isKeyPressed(key)
    foreign static isKeyReleased(key)
    foreign static isKeyUp(key)

    // mouse
    foreign static isMouseButtonDown(button)
    foreign static isMouseButtonPressed(button)
    foreign static isMouseButtonReleased(button)
    foreign static getMousePosition()
    foreign static getMouseDelta()
    foreign static getMouseWheelMove()

    // gamepad
    foreign static isGamepadAvailable(gamepad)
    foreign static isGamepadButtonDown(gamepad, button)
    foreign static isGamepadButtonPressed(gamepad, button)
    foreign static isGamepadButtonReleased(gamepad, button)
    foreign static isGamepadButtonUp(gamepad, button)
    foreign static getGamepadAxisMovement(gamepad, axis)
    foreign static getGamepadAxisCount(gamepad)

    // cursor
    foreign static showCursor()
    foreign static hideCursor()
    foreign static isCursorHidden
    foreign static enableCursor()
    foreign static disableCursor()
}