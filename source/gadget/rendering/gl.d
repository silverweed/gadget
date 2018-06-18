module gadget.rendering.gl;

import std.conv;
import std.stdio;
import derelict.sfml2.system;
import derelict.sfml2.window;
import derelict.opengl;
import derelict.opengl.extensions.arb_f;
import derelict.util.exception;
mixin(arbFramebufferSRGB);
import gl3n.linalg;
import gadget.rendering.presets;
import gadget.rendering.camera;
import gadget.rendering.renderstate;

private immutable string[] sfmlSearchPath = [
	"/usr/lib/x86_64-linux-gnu/",
	"/usr/lib/",
	"/usr/local/lib/",
];

sfContextSettings ctxSettings;

private bool running = true;

/// Loads the rendering libraries (GL3 + SFML2) and sets the default context settings.
bool initRender() {
	// Load shared C libraries
	DerelictGL3.load();
	bool ok = false;
	for (int i = 0; i < sfmlSearchPath.length; ++i) {
		import std.file;
		if (!exists(sfmlSearchPath[i] ~ "libcsfml-system.so.2.4"))
			continue;

		try {
			DerelictSFML2System.load(sfmlSearchPath[i] ~ "libcsfml-system.so.2.4");
			DerelictSFML2Window.load(sfmlSearchPath[i] ~ "libcsfml-window.so.2.4");
			ok = true;
			break;
		} catch (SharedLibLoadException e) {
			writeln("SharedLibLoadException: " ~ e.msg);
			continue;
		} catch (SymbolLoadException e) {
			writeln("SymbolLoadException: " ~ e.msg);
			continue;
		}
	}

	if (!ok) {
		auto err = "Could not load libcsfml-{window,system}.so.2.4! Not found in paths: ";
		foreach (s; sfmlSearchPath)
			err ~= "\n\t" ~ s;
		throw new Exception(err);
	}

	// Create openGL context
	ctxSettings.majorVersion = 4;
	ctxSettings.minorVersion = 0;
	ctxSettings.attributeFlags = sfContextCore;
	ctxSettings.depthBits = 24;
	ctxSettings.antialiasingLevel = 4;

	return true;
}

/// Creates an SFML window, sets it as active and returns it.
auto newWindow(uint w, uint h, const char* title = "Unnamed Gadget App", uint flags = sfClose|sfResize) {
	RenderState.global.screenSize.x = w;
	RenderState.global.screenSize.y = h;
	auto window = sfWindow_create(sfVideoMode(w, h), title, flags, &ctxSettings);
	sfWindow_setActive(window, true);
	DerelictGL3.reload();

	debug writeln("Using OpenGL version: ", ctxSettings.majorVersion, ".", ctxSettings.minorVersion);

	// Set reasonable defaults
	sfWindow_setMouseCursorVisible(window, false);
	sfWindow_setMouseCursorGrabbed(window, true);
	sfWindow_setFramerateLimit(window, 60);

	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LESS);
	glDepthMask(GL_TRUE);
	glCullFace(GL_BACK);
	glEnable(GL_FRAMEBUFFER_SRGB);

	return window;
}

void renderLoop(IF, RF)(sfWindow* window, Camera camera,
		IF inputProcessFunc, RF renderFunc, RenderState state = RenderState.global)
{
	debug (2) import std.datetime.stopwatch;
	while (running) {
		debug (2) {
			StopWatch sw;
			sw.start();
		}
		inputProcessFunc(window, camera, state);

		renderFunc(window, camera, state);
		debug (2) writeln("Time = \n\tdraw:    ", sw.peek());

		sfWindow_display(window);
		debug (2) writeln("\tdisplay: ", sw.peek());
	}
	debug writeln("Closing window.");
	sfWindow_close(window);
}

void quitRender() {
	running = false;
}

auto handleResize(in sfEvent event, Camera camera) {
	auto state = RenderState.global;
	state.screenSize.x = event.size.width;
	state.screenSize.y = event.size.height;
	glViewport(0, 0, state.screenSize.x, state.screenSize.y);
	writeln("resize to ", state.screenSize.x, " ", state.screenSize.y);
	camera.width = state.screenSize.x;
	camera.height = state.screenSize.y;
}

void drawElements(GLuint vao, GLuint count, GLenum primitive = GL_TRIANGLES) {
	glBindVertexArray(vao);
	glDrawElements(primitive, count, GL_UNSIGNED_INT, cast(const(void)*)0);
	glBindVertexArray(0);
}

void drawArrays(GLuint vao, GLuint count, GLenum primitive = GL_TRIANGLES) {
	glBindVertexArray(vao);
	glDrawArrays(primitive, 0, count);
	glBindVertexArray(0);
}

void cull(GLubyte cullFace) {
	if (cullFace)
		glEnable(GL_CULL_FACE);
	else
		glDisable(GL_CULL_FACE);
}

/// Defers rebinding the current framebuffer to the function exit.
/// Use like `mixin(DEFER_REBIND_CUR_FBO);`
enum DEFER_REBIND_CUR_FBO = q{
	{
		GLint curFbo;
		glGetIntegerv(GL_FRAMEBUFFER_BINDING, &curFbo);
		scope (exit) glBindFramebuffer(GL_FRAMEBUFFER, curFbo);
	}
};

void checkFramebuffer() {
	const s = glCheckFramebufferStatus(GL_FRAMEBUFFER);
	switch (s) {
	case GL_FRAMEBUFFER_COMPLETE:
		return;
	case GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
		assert(false, "Framebuffer has incomplete attachment!");
	case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
		assert(false, "Framebuffer is missing an attachment!");
	case GL_FRAMEBUFFER_UNSUPPORTED:
		assert(false, "Framebuffer is unsupported!");
	default:
		assert(false, "Framebuffer incomplete! Error code: " ~ s.to!string);
	}
}

void checkGLError() {
	const s = glGetError();
	switch (s) {
	case GL_NO_ERROR: return;
	case GL_INVALID_ENUM: assert(false, "GL_INVALID_ENUM!");
	case GL_INVALID_OPERATION: assert(false, "GL_INVALID_OPERATION!");
	case GL_INVALID_VALUE: assert(false, "GL_INVALID_VALUE!");
	default: assert(false, "Other GL error: " ~ s.to!string);
	}
}
