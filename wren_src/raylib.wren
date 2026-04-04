foreign class Color {
    construct new(r, g, b, a) {}
    foreign r
    foreign g
    foreign b
    foreign a
}

// Pure Wren convenience — no foreign needed
class Colors {
    static white  { Color.new(255, 255, 255, 255) }
    static black  { Color.new(0,   0,   0,   255) }
    static blank  { Color.new(0,   0,   0,   0)   }
    static red    { Color.new(230, 41,  55,  255) }
    static green  { Color.new(0,   228, 48,  255) }
    static blue   { Color.new(0,   121, 241, 255) }
    static yellow { Color.new(253, 249, 0,   255) }
}

class Key {
    static space  { 32  }
    static escape { 256 }
    static enter  { 257 }
    static up     { 265 }
    static down   { 264 }
    static left   { 263 }
    static right  { 262 }
    static w { 87 } 
    static a { 65 }
    static s { 83 } 
    static d { 68 }
}

class Mouse {
    static left   { 0 }
    static right  { 1 }
    static middle { 2 }
}

// Not a foreign class — has no instances, just static foreign methods
class RL {
    foreign static drawRectangle(x, y, w, h, color)
    foreign static drawCircle(x, y, radius, color)
    foreign static drawLine(x1, y1, x2, y2, color)
    foreign static drawText(text, x, y, fontSize, color)

    foreign static isKeyDown(key)
    foreign static isKeyPressed(key)
    foreign static isMouseButtonDown(button)
    foreign static getMousePosition()
}