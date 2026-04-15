import "mv/node" for Vec2, NativeNode, Node, NativeApp
import "mv/raylib" for Color, Colors, RL

class RectNode is Node {
    construct new(name) {
        super(name)
        _time = 0
    }

    update(dt) {
        _time = _time + dt
        this.angleDeg = _time * 120
    }

    draw() {
        var hw = 30
        var hh = 20
        RL.drawRectangle(-hw, -hh, hw * 2, hh * 2, Colors.red)
        RL.drawRectangleLines(-hw, -hh, hw * 2, hh * 2, Colors.white)
    }
}

var rect = RectNode.new("rect")
rect.pos = Vec2.new(160, 120)
NativeApp.setRoot(rect.inner)
