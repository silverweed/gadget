module gadget.rendering.gl;

import derelict.sfml2.system;
import derelict.sfml2.window;
import derelict.opengl3.gl3;
import std.stdio;

struct RenderInitOptions {
	string sfmlSystemLib;
	string sfmlWindowLib;
}

sfContextSettings ctxSettings;

private immutable defaultRenderInitOpts = RenderInitOptions(
	"/usr/lib/x86_64-linux-gnu/libcsfml-system.so.2.4",
	"/usr/lib/x86_64-linux-gnu/libcsfml-window.so.2.4"
);
private bool running = true;

/// Loads the rendering libraries (GL3 + SFML2) and sets the default context settings.
bool initRender(in RenderInitOptions opts = defaultRenderInitOpts) {
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

void renderLoop(EH, RF)(sfWindow* window, EH evtHandler, RF rendFunc) {
	while (running) {
		sfEvent evt;
		sfWindow_pollEvent(window, &evt);
		evtHandler(evt);
		
		glClear(GL_COLOR_BUFFER_BIT);
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

void drawTriangles(GLuint vao, GLuint count) {
	glBindVertexArray(vao);
	glDrawElements(GL_TRIANGLES, count, GL_UNSIGNED_INT, cast(const(void)*)0);
	glBindVertexArray(0);
}

void drawArrays(GLuint vao, GLuint count) {
	glBindVertexArray(vao);
	glDrawArrays(GL_TRIANGLES, 0, count);
	glBindVertexArray(0);
}
