module gadget.rendering.gl;

import derelict.sfml2.system;
import derelict.sfml2.window;
import derelict.opengl;
import std.stdio;
import gl3n.linalg;
import gadget.rendering.presets;
import gadget.rendering.camera;
import gadget.rendering.renderstate;

// FIXME
struct RenderInitOptions {
	string sfmlSystemLib = "/usr/lib/x86_64-linux-gnu/libcsfml-system.so.2.4";
	string sfmlWindowLib = "/usr/lib/x86_64-linux-gnu/libcsfml-window.so.2.4";
}

sfContextSettings ctxSettings;

private bool running = true;

/// Loads the rendering libraries (GL3 + SFML2) and sets the default context settings.
bool initRender(in RenderInitOptions opts = RenderInitOptions()) {
	// Load shared C libraries
	DerelictGL3.load();
	DerelictSFML2System.load(opts.sfmlSystemLib);
	DerelictSFML2Window.load(opts.sfmlWindowLib);

	// Create openGL context
	ctxSettings.majorVersion = 3;
	ctxSettings.minorVersion = 3;
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

		glClearColor(state.clearColor.x, state.clearColor.y, state.clearColor.z, state.clearColor.a);
		glClear(state.clearFlags);

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
