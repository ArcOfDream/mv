#version 100

precision mediump float;

varying vec2 fragTexCoord;
varying vec4 fragColor;

// particle texture: greyscale recommended; colour is reduced to luminance
uniform sampler2D texture0;

// 1D gradient lookup texture generated from core.Gradient via Gradient2D
uniform sampler2D gradient;

// shifts the gradient sample position over the particle lifetime; range [-1, 1]
uniform float colorOffset;

void main() {
    vec4  texColor  = texture2D(texture0, fragTexCoord);
    float luminance = (texColor.r + texColor.g + texColor.b) / 3.0;
    float sampleU   = clamp(luminance + colorOffset, 0.0, 1.0);
    vec4  gradColor = texture2D(gradient, vec2(sampleU, 0.5));

    vec4 result;
    result.rgb = gradColor.rgb * fragColor.rgb;
    result.a   = texColor.a * gradColor.a * fragColor.a;
    result.a   = smoothstep(0.05, 0.06, result.a);

    gl_FragColor = result;
}
