import std.stdio;
import std.file;
import std.math;
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

	auto basicShader = Shader.fromFiles(getcwd() ~ "/shaders/basic.vert", getcwd() ~ "/shaders/basic.frag");
	auto basicTransformShader = Shader.fromFiles(
			getcwd() ~ "/shaders/basicTransform.vert",
			getcwd() ~ "/shaders/basic.frag");
	auto basicLightingShader = Shader.fromFiles(
		getcwd() ~ "/shaders/basicLighting.vert",
		getcwd() ~ "/shaders/basicLighting.frag");
	auto sphereShader = Shader.fromFiles(getcwd() ~ "/shaders/sphere.vert"
			, getcwd() ~ "/shaders/sphere.frag"
			, getcwd() ~ "/shaders/sphere.geom"
			);
	auto quadVAO = genQuad();
	auto cubeVAO = genCube();
	auto pointVAO = genPoint();
	auto cube = makePresetCube().setPos(-1, -1, 1).setRot(0, PI/4, 0).setScale(1, 2, 1);
	cube.uniforms["lightColor"] = vec3(1, 1, 1);

	RenderState.global.clearColor = vec4(0.2, 0.5, 0.6, 1.0);
	RenderState.global.projection = mat4.perspective(6, 6, camera.fov, 0.1, 30f);
	camera.position.z = 4;
	auto clock = sfClock_create();
	auto fps = new FPSCounter(2f);
	debug writeln("starting render loop");
	renderLoop(window, &processInput, () {
		// Update time
		auto t = sfTime_asSeconds(sfClock_getElapsedTime(clock));
		deltaTime = t - lastFrame;
		lastFrame = t;

		auto lightPos = vec3(2 * sin(t), 1f, 2 * cos(t));
		basicLightingShader.use();
		basicLightingShader.setUni("color", 1f, 0.5f, 0.31f);
		basicLightingShader.setUni("lightColor", 1f, 1f, 1f);
		basicLightingShader.setUni("lightPos", lightPos);
		basicLightingShader.setUni("viewPos", camera.position);
		basicLightingShader.setUni("projection", mat4.perspective(6, 6, camera.fov, 0.1, 30f));
		basicLightingShader.setUni("view", camera.viewMatrix);
		basicLightingShader.setUni("model", mat4.identity
				//.scale(1.0, 1.0, 1.0)
				//.rotatex(0.2).rotatez(0.2).rotatey(0.25));
			);
		glEnable(GL_CULL_FACE);
		drawArrays(cubeVAO, cubeVertices.length); /*
		basicLightingShader.setUni("objectColor", 0f, 0.4f, 1f);
		basicLightingShader.setUni("model", mat4.translation(3, 0, 0));
		drawArrays(cubeVAO, cubeVertices.length);
		basicLightingShader.setUni("model", mat4.translation(2, 2, 0));
		glDisable(GL_CULL_FACE);
		drawElements(quadVAO, quadIndices.length);*/

		cube.uniforms["lightPos"] = lightPos;
		cube.draw(window, camera);

		// Draw light
		sphereShader.use();
		sphereShader.setUni("model", mat4.translation(lightPos));
		sphereShader.setUni("view", camera.viewMatrix);
		sphereShader.setUni("projection", mat4.perspective(6, 6, camera.fov, 0.1, 30f));
		//sphereShader.setUni("projection", mat4.orthographic(-3, 3, -3, 3, 0.1, 30f));
		sphereShader.setUni("color", 1f, 1f, 0f);
		sphereShader.setUni("radius", 0.3f);
		sphereShader.setUni("scrWidth", RenderState.global.screenSize.x);
		sphereShader.setUni("scrHeight", RenderState.global.screenSize.y);
		drawArrays(pointVAO, 1, GL_POINTS);

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
