foreign class Vec2 {
    construct new(x, y) {}

    foreign x
    foreign y
    foreign x=(val)
    foreign y=(val)

    foreign +(other)
    foreign -(other)
    foreign *(other)
    foreign /(other)

    foreign toString
}

foreign class Node {
    construct new(name) {}

    foreign name

    foreign pos
    foreign pos=(val)
    foreign scale
    foreign scale=(val)

    foreign angleDeg
    foreign angleDeg=(val)
    foreign angleRad
    foreign angleRad=(val)

    foreign globalPos
    foreign globalScale
    foreign globalAngleDeg
    foreign globalAngleRad

    foreign addChild(child)
    
    update(dt) {}
    draw() {}
}

foreign class Sprite {
    construct new(name) {}

    // Node methods — must be redeclared; Wren has no foreign class inheritance
    foreign name
    foreign pos
    foreign pos=(val)
    foreign scale
    foreign scale=(val)
    foreign angleDeg
    foreign angleDeg=(val)
    foreign angleRad
    foreign angleRad=(val)
    foreign globalPos
    foreign globalScale
    foreign globalAngleDeg
    foreign globalAngleRad
    foreign addChild(child)

    // Sprite-specific
    foreign centered
    foreign centered=(val)
    foreign offset
    foreign offset=(val)
    foreign textureId=(val)
    foreign shaderId=(val)
    foreign hFrames
    foreign hFrames=(val)
    foreign vFrames
    foreign vFrames=(val)
    foreign currentFrame
    foreign currentFrame=(val)
    
    update(dt) {}
    draw() {}
}