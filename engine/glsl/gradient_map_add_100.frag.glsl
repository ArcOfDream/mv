#version 100

precision mediump float;

varying vec2 fragTexCoord;
varying vec4 fragColor;

uniform sampler2D texture0;
uniform sampler2D gradient;
uniform float colorOffset;

void main() {
    vec4  texColor  = texture2D(texture0, fragTexCoord);
    float luminance = (texColor.r + texColor.g + texColor.b) / 3.0;
    float sampleU   = clamp(luminance + colorOffset, 0.0, 1.0);

    // fragColor is multiplied into the gradient sample here rather than
    // the final composite, which preserves the additive blending intent
    vec4 gradColor  = texture2D(gradient, vec2(sampleU, 0.5)) * fragColor;

    vec4 result;
    result.rgb = gradColor.rgb;
    result.a   = texColor.a * gradColor.a;
    result.a   = smoothstep(0.05, 0.06, result.a);

    gl_FragColor = result;
}
