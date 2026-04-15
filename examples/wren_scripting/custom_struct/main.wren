// a node that uses a Timer to pulse a rectangle between two sizes
// demonstrates using a plain foreign type (Timer) alongside Node

import "mv/node" for Vec2, NativeNode, Node, NativeApp
import "mv/raylib" for Color, Colors, RL

foreign class Timer {
    construct new(duration, looping) {}

    foreign start()
    foreign stop()
    foreign reset()
    foreign tick(dt)

    foreign progress
    foreign isDone
    foreign timeLeft
    foreign running
    foreign duration
    foreign duration=(val)
    foreign looping
    foreign looping=(val)
}

class PulseNode is Node {
    construct new(name) {
        super(name)
        // 0.8s looping timer, starts immediately
        _timer = Timer.new(0.8, true)
        _timer.start()
    }

    update(dt) {
        _timer.tick(dt)
    }

    draw() {
        // progress() gives [0,1] over the timer duration;
        // map to a scale that pulses between 0.5 and 1.5
        var t = _timer.progress
        var s = 0.5 + t

        var hw = (30 * s).floor
        var hh = (20 * s).floor

        // filled rect in a colour that shifts from red to yellow
        var r = 230
        var g = (t * 200).floor
        RL.drawRectangle(-hw, -hh, hw * 2, hh * 2, Color.new(r, g, 40, 255))
        RL.drawRectangleLines(-hw, -hh, hw * 2, hh * 2, Colors.white)
    }
}

var pulse = PulseNode.new("pulse")
pulse.pos = Vec2.new(160, 120)
NativeApp.setRoot(pulse.inner)
