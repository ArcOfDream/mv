module binary

pub const (
	vertex_shader = '#version 100
attribute vec2 aVertex;
attribute vec4 aColor;
attribute vec2 aUV;
// attribute mat4 model;

varying lowp vec4 vertexColor;
varying mediump vec2 texUV;

uniform mat4 view; 
uniform mat4 projection;

void main() {
	vertexColor = aColor;
	texUV = aUV;
    gl_Position = projection * vec4(aVertex, 0.0, 1.0);
}'
	fragment_shader = '#version 100
varying lowp vec4 vertexColor;
varying mediump vec2 texUV;

uniform sampler2D tex;

void main() {
	gl_FragColor = texture2D(tex, texUV) * vertexColor;
}
'
	mask_fragment_shader = '#version 100
varying lowp vec4 vertexColor;
varying mediump vec2 texUV;

uniform sampler2D tex;

void main() {
	gl_FragColor = vec4(vertexColor.rgb, texture2D(tex, texUV).a);
}
'
)
