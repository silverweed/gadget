module gadget.rendering.renderstate;

import std.typecons;
import gl3n.linalg;
import derelict.opengl;

/// The "global" set of options used when rendering
class RenderState {
	Vector!(uint, 2) screenSize;

	vec4 clearColor = vec4(0, 0, 0, 1);
	GLuint clearFlags = GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT;

	bool showNormals = false;

	static RenderState global;
}

static this() {
	RenderState.global = new RenderState();
}
