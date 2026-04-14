foreign class Vec2 {
    construct new(x, y) {}

    foreign x
    foreign y
    foreign x=(val)
    foreign y=(val)

    foreign length
    foreign lengthSqr
    foreign dot(other)
    foreign cross(other)
    foreign distance(other)
    foreign distanceSqr(other)
    foreign angle(other)
    foreign lineAngle(other)

    foreign normalize
    foreign invert
    foreign negate
    foreign perpendicular
    foreign abs
    foreign floor
    foreign ceil
    foreign round

    foreign scale(f)
    foreign rotate(angle)
    foreign addValue(f)
    foreign subtractValue(f)

    foreign reflect(normal)
    foreign min(other)
    foreign max(other)

    foreign lerp(other, t)
    foreign moveTowards(target, maxDist)
    foreign clamp(min, max)
    foreign clampValue(min, max)

    foreign +(other)
    foreign -(other)
    foreign *(other)
    foreign /(other)
    foreign %(other)
    foreign ==(other)

    foreign toString
}

// native (foreign) classes
// these wrap V structs directly. do not subclass - use Node and Sprite instead

foreign class NativeNode {
    construct new(name) {}

    foreign setWrapper(wrapper)

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
    foreign globalPos=(val)
    foreign globalScale
    foreign globalScale=(val)
    foreign globalAngleDeg
    foreign globalAngleDeg=(val)
    foreign globalAngleRad
    foreign globalAngleRad=(val)

    foreign parent
    foreign children
    foreign childCount
    foreign addChild(child)
    foreign removeChild(child)
    foreign getChildAt(index)
    foreign findChild(child)
    foreign reparent(newParent)
    foreign moveChild(from, to)
    foreign swapChildren(a, b)

    foreign queueFree()
}

foreign class NativeSprite {
    construct new(name) {}

    foreign setWrapper(wrapper)

    // Node methods
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
    foreign globalPos=(val)
    foreign globalScale
    foreign globalScale=(val)
    foreign globalAngleDeg
    foreign globalAngleDeg=(val)
    foreign globalAngleRad
    foreign globalAngleRad=(val)
    foreign parent
    foreign children
    foreign childCount
    foreign addChild(child)
    foreign removeChild(child)
    foreign getChildAt(index)
    foreign findChild(child)
    foreign reparent(newParent)
    foreign moveChild(from, to)
    foreign swapChildren(a, b)
    foreign queueFree()

    // Sprite-specific
    foreign centered
    foreign centered=(val)
    foreign offset
    foreign offset=(val)
    foreign textureId
    foreign textureId=(val)
    foreign shaderId
    foreign shaderId=(val)
    foreign tint
    foreign tint=(val)
    foreign hFrames
    foreign hFrames=(val)
    foreign vFrames
    foreign vFrames=(val)
    foreign currentFrame
    foreign currentFrame=(val)
}

// registers a node as the scene root, hooking it into the V-side update/draw loop
foreign class NativeApp {
    foreign static setRoot(nativeNode)
}

// Subclassable Wren wrappers
// rxtend these in user scripts. setWrapper stores the outer object's handle on
// the native so notify() dispatches update/draw to the correct Wren class

class Node {
  construct new(name) {
      _inner = NativeNode.new(name)
      _inner.setWrapper(this)
  }
  
  construct fromNative(native) {
      _inner = native
      _inner.setWrapper(this)
  }

    inner { _inner }

    name            { _inner.name }

    pos             { _inner.pos }
    pos=(v)         { _inner.pos = v }
    scale           { _inner.scale }
    scale=(v)       { _inner.scale = v }
    angleDeg        { _inner.angleDeg }
    angleDeg=(v)    { _inner.angleDeg = v }
    angleRad        { _inner.angleRad }
    angleRad=(v)    { _inner.angleRad = v }

    globalPos           { _inner.globalPos }
    globalPos=(v)       { _inner.globalPos = v }
    globalScale         { _inner.globalScale }
    globalScale=(v)     { _inner.globalScale = v }
    globalAngleDeg      { _inner.globalAngleDeg }
    globalAngleDeg=(v)  { _inner.globalAngleDeg = v }
    globalAngleRad      { _inner.globalAngleRad }
    globalAngleRad=(v)  { _inner.globalAngleRad = v }

    parent          { _inner.parent }
    children        { _inner.children }
    childCount      { _inner.childCount }

    // unwrap child wrappers before passing to native
    addChild(child)      { _inner.addChild(child.inner) }
    removeChild(child)   { _inner.removeChild(child.inner) }
    findChild(child)     { _inner.findChild(child.inner) }
    reparent(newParent)  { _inner.reparent(newParent.inner) }
    getChildAt(index)    { _inner.getChildAt(index) }
    moveChild(from, to)  { _inner.moveChild(from, to) }
    swapChildren(a, b)   { _inner.swapChildren(a, b) }

    queueFree()     { _inner.queueFree() }

    update(dt) {}
    draw() {}
}

class Sprite is Node {
    construct new(name) {
      super.fromNative(NativeSprite.new(name))
    }

    centered         { inner.centered }
    centered=(v)     { inner.centered = v }
    offset           { inner.offset }
    offset=(v)       { inner.offset = v }
    textureId        { inner.textureId }
    textureId=(v)    { inner.textureId = v }
    shaderId         { inner.shaderId }
    shaderId=(v)     { inner.shaderId = v }
    tint             { inner.tint }
    tint=(v)         { inner.tint = v }
    hFrames          { inner.hFrames }
    hFrames=(v)      { inner.hFrames = v }
    vFrames          { inner.vFrames }
    vFrames=(v)      { inner.vFrames = v }
    currentFrame     { inner.currentFrame }
    currentFrame=(v) { inner.currentFrame = v }
}
