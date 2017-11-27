module gadget.rendering.renderstate;

import gl3n.linalg;
import derelict.opengl;

/// The "global" set of options used when rendering
class RenderState {
	Vector!(uint, 2) screenSize;

	mat4 projection;

	vec4 clearColor = vec4(0, 0, 0, 1);
	GLuint clearFlags = GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT;

	static RenderState global;
}

static this() {
	RenderState.global = new RenderState();
}
