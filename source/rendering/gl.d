module gadget.rendering.gl;

import derelict.sfml2.system;
import derelict.sfml2.window;
import derelict.opengl;
import std.stdio;
import gl3n.linalg;

struct RenderInitOptions {
	string sfmlSystemLib = "/usr/lib/x86_64-linux-gnu/libcsfml-system.so.2.4";
	string sfmlWindowLib = "/usr/lib/x86_64-linux-gnu/libcsfml-window.so.2.4";
}

struct RenderOptions {
	vec4 clearColor = vec4(0, 0, 0, 1);
	GLuint clearFlags = GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT;
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

	return true;
}

/// Creates an SFML window, sets it as active and returns it.
auto newWindow(uint w, uint h, const char* title = "Unnamed Gadget App", uint flags = sfClose|sfResize) {
	auto window = sfWindow_create(sfVideoMode(w, h), title, flags, &ctxSettings);
	sfWindow_setActive(window, true);
	DerelictGL3.reload();
	return window;
}

void renderLoop(EH, RF)(sfWindow* window, EH evtHandler, RF rendFunc, RenderOptions opts = RenderOptions()) {
	while (running) {

		sfEvent evt;
		sfWindow_pollEvent(window, &evt);
		evtHandler(evt, opts);

		glClearColor(opts.clearColor.x, opts.clearColor.y, opts.clearColor.z, opts.clearColor.a);
		glClear(opts.clearFlags);

		rendFunc();
		sfWindow_display(window);
	}
	debug writeln("Closing window.");
	sfWindow_close(window);
}

void quitRender() {
	running = false;
}

void handleResize(in sfEvent event) {
	glViewport(0, 0, event.size.width, event.size.height);
}

void drawElements(GLuint vao, GLuint count, GLenum primitive = GL_TRIANGLES) {
	glBindVertexArray(vao);
	glDrawElements(primitive, count, GL_UNSIGNED_INT, cast(const(void)*)0);
	glBindVertexArray(0);
}

void drawArrays(GLuint vao, GLuint count) {
	glBindVertexArray(vao);
	glDrawArrays(GL_TRIANGLES, 0, count);
	glBindVertexArray(0);
}
