module gadget.rendering.gl;

import derelict.sfml2.system;
import derelict.sfml2.window;
import derelict.opengl3.gl3;

struct RenderInitOptions {
	string sfmlSystemLib;
	string sfmlWindowLib;
}

private auto defaultRenderInitOpts = RenderInitOptions(
	"/usr/lib/x86_64-linux-gnu/libcsfml-system.so.2.4",
	"/usr/lib/x86_64-linux-gnu/libcsfml-window.so.2.4"
);

sfContextSettings ctxSettings;

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
