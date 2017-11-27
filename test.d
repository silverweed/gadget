import std.stdio;
import std.file;
import std.math;
import std.random : uniform;
import std.algorithm;
import gadget.physics;
import gadget.rendering;
import gadget.fpscounter;
import gadget.rendering.renderstate;
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
	sfWindow_setMouseCursorGrabbed(window, true);
	sfWindow_setFramerateLimit(window, 60);

	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LESS);
	glDepthMask(GL_TRUE);
	glCullFace(GL_BACK);

	auto sphereShader = Shader.fromFiles(getcwd() ~ "/shaders/sphere.vert"
			, getcwd() ~ "/shaders/sphere.frag"
			, getcwd() ~ "/shaders/sphere.geom"
			);
	auto point = new Shape(genPoint(), 1, sphereShader).setColor(1, 1, 0).setPrimitive(GL_POINTS);
	Shape[] cubes;
	for (int i = 0; i < 300; ++i) {
		auto pos = vec3(uniform(-30, 30), uniform(-30, 30), uniform(-30, 30));
		auto rot = vec3(uniform(-PI, PI), uniform(-PI, PI), uniform(-PI, PI));
		auto scalex = uniform(0.3, 2);
		auto scale = vec3(scalex, scalex + uniform(-0.2, 0.2), scalex + uniform(-0.2, 0.2));
		cubes ~= makePreset(ShapeType.CUBE).setPos(pos.x, pos.y, pos.z)
						.setRot(rot.x, rot.y, rot.z)
						.setScale(scale.x, scale.y, scale.z);
	}
	auto ground = makePreset(ShapeType.QUAD, vec3(0.4, 0.2, 0))
			.setPos(0, -2, 0).setScale(100, 100, 100).setRot(PI/2, 0, 0);
	foreach (c; cubes) c.uniforms["lightColor"] = vec3(1, 1, 1);
	ground.uniforms["lightColor"] = vec3(1, 1, 1);

	RenderState.global.clearColor = vec4(0.2, 0.5, 0.6, 1.0);
	RenderState.global.projection = mat4.perspective(6, 6, camera.fov, 0.1, 100f);
	camera.position.z = 4;
	auto clock = sfClock_create();
	auto fps = new FPSCounter(2f);
	debug writeln("starting render loop");
	renderLoop(window, &processInput, () {
		// Update time
		auto t = sfTime_asSeconds(sfClock_getElapsedTime(clock));
		deltaTime = t - lastFrame;
		lastFrame = t;

		auto lightPos = vec3(20 * sin(t), 1f, 20 * cos(t));

		// Draw cubes
		glEnable(GL_CULL_FACE);
		foreach (c; cubes) {
			c.uniforms["lightPos"] = lightPos;
			c.draw(window, camera);
		}

		// Draw ground
		glDisable(GL_CULL_FACE);
		ground.uniforms["lightPos"] = lightPos;
		ground.draw(window, camera);

		// Draw light
		point.uniforms["radius"] = 0.3;
		point.uniforms["scrWidth"] = RenderState.global.screenSize.x;
		point.uniforms["scrHeight"] = RenderState.global.screenSize.y;
		point.setPos(lightPos);
		point.draw(window, camera);

		updateMouse(window, camera);
		fps.update(deltaTime);
	});
}

void processInput(sfWindow *window, RenderState state) {
	sfEvent evt;
	while (sfWindow_pollEvent(window, &evt))
		evtHandler(evt, state);

	if (sfKeyboard_isKeyPressed(sfKeyW))
		camera.move(Direction.FWD, deltaTime);
	if (sfKeyboard_isKeyPressed(sfKeyA))
		camera.move(Direction.LEFT, deltaTime);
	if (sfKeyboard_isKeyPressed(sfKeyS))
		camera.move(Direction.BACK, deltaTime);
	if (sfKeyboard_isKeyPressed(sfKeyD))
		camera.move(Direction.RIGHT, deltaTime);
}

void evtHandler(in sfEvent event, RenderState state) {
	switch (event.type) {
	case sfEvtResized:
		handleResize(event);
		break;
	case sfEvtMouseWheelMoved:
		camera.zoom(event.mouseWheel.delta);
		break;
	case sfEvtKeyPressed:
		switch (event.key.code) {
		case sfKeyQ:
			quitRender();
			break;
		default:
			break;
		}
		break;
	case sfEvtClosed:
		quitRender();
		break;
	default:
		break;
	}
}

void updateMouse(sfWindow *window, Camera camera) {
	// Hack to get mouse relative deltas for FPS camera
	if (sfWindow_hasFocus(window)) {
		auto mpos = sfMouse_getPosition(window);
		camera.turn(mpos.x - WIDTH/2, HEIGHT/2 - mpos.y);
		sfMouse_setPosition(sfVector2i(WIDTH/2, HEIGHT/2), window);
	}
}
