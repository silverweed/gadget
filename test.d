import std.stdio;
import std.file;
import std.math;
import gadget.physics;
import gadget.rendering;
import gadget.fpscounter;
import derelict.sfml2.window;
import derelict.sfml2.system;
import derelict.opengl;
import gl3n.linalg;
import derelict.opengl;

enum WIDTH = 800;
enum HEIGHT = 600;

__gshared auto camera = new Camera();
float deltaTime = 0;
float lastFrame = 0;
int lastMouseX = WIDTH/2;
int lastMouseY = HEIGHT/2;

void main() {
	/+
	vec2 v = vec2(2, 3);
	writeln(v.x, ", ", v.y);

	AABB a = AABB(vec2(1, 2), vec2(3, 4)),
	     b = AABB(vec2(1, 1), vec2(3, 2));
	writeln(AABBOverlapsAABB(a, b));

	Circle c = Circle(vec2(2, 2), 3),
	       d = Circle(vec2(3, 3), 4);
	writeln(circleOverlapsCircle(c, d));

	PhysicsObj obj = PhysicsObj(a, v, v, 0.4f);
	PhysicsWorld world = new PhysicsWorld();
	world.add(obj);
	+/

	//// Init rendering system
	initRender();
	auto window = newWindow(WIDTH, HEIGHT);
	sfWindow_setMouseCursorVisible(window, false);
	//sfWindow_setMouseCursorGrabbed(window, true);
	sfWindow_setFramerateLimit(window, 60);

	glDepthMask(GL_TRUE);
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_CULL_FACE);
	glCullFace(GL_BACK);

	auto basicShader = new Shader(getcwd() ~ "/shaders/basic.vert", getcwd() ~ "/shaders/basic.frag");
	auto basicTransformShader = new Shader(getcwd() ~ "/shaders/basicTransform.vert", getcwd() ~ "/shaders/basic.frag");
	auto basicLightingShader = new Shader(
		getcwd() ~ "/shaders/basicLighting.vert",
		getcwd() ~ "/shaders/basicLighting.frag");
	auto quadVAO = genQuad();
	auto cubeVAO = genCube();

	auto opts = RenderOptions();
	opts.clearColor = vec4(0.2, 0.5, 0.6, 1.0);
	camera.position.z = 4;
	auto clock = sfClock_create();
	auto fps = new FPSCounter(2f);
	debug writeln("starting render loop");
	renderLoop(window, &processInput, () {
		// Update time
		auto t = sfTime_asSeconds(sfClock_getElapsedTime(clock));
		deltaTime = t - lastFrame;
		lastFrame = t;

		basicLightingShader.use();
		basicLightingShader.setUni("objectColor", 1f, 0.5f, 0.31f);
		basicLightingShader.setUni("lightColor", 1f, 1f, 1f);
		basicLightingShader.setUni("lightPos", 2 * sin(t), 1f, 2 * cos(t));
		basicLightingShader.setUni("viewPos", camera.position);
		basicLightingShader.setUni("projection", mat4.perspective(6, 6, camera.fov, 0.1, 30f));
		basicLightingShader.setUni("view", camera.viewMatrix);
		basicLightingShader.setUni("model", mat4.identity
				//.scale(1.0, 1.0, 1.0)
				//.rotatex(0.2).rotatez(0.2).rotatey(0.25));
			);
		drawArrays(cubeVAO, cubeVertices.length);
		basicLightingShader.setUni("model", mat4.translation(2, 2, 0));
		drawElements(quadVAO, quadIndices.length);

		// Hack to get mouse relative deltas for FPS camera
		if (sfWindow_hasFocus(window)) {
			auto mpos = sfMouse_getPosition(window);
			camera.turn(mpos.x - WIDTH/2, HEIGHT/2 - mpos.y);
			sfMouse_setPosition(sfVector2i(WIDTH/2, HEIGHT/2), window);
		}

		fps.update(deltaTime);
	}, opts);
}

void processInput(in sfEvent event, ref RenderOptions opts) {
	switch (event.type) {
	case sfEvtResized:
		handleResize(event);
		break;
	case sfEvtMouseWheelMoved:
		camera.zoom(event.mouseWheel.delta);
		break;
	default:
		break;
	}

	if (sfKeyboard_isKeyPressed(sfKeyQ))
		quitRender();

	if (sfKeyboard_isKeyPressed(sfKeyW))
		camera.move(Direction.FWD, deltaTime);
	if (sfKeyboard_isKeyPressed(sfKeyA))
		camera.move(Direction.LEFT, deltaTime);
	if (sfKeyboard_isKeyPressed(sfKeyS))
		camera.move(Direction.BACK, deltaTime);
	if (sfKeyboard_isKeyPressed(sfKeyD))
		camera.move(Direction.RIGHT, deltaTime);
}
