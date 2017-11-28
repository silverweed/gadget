import std.stdio;
import std.file;
import std.math;
import std.random : uniform, uniform01;
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

float deltaTime = 0;
float lastFrame = 0;

void main() {
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

	auto camera = new Camera();

	auto point = new Mesh(genPoint(), 1, presetShaders["billboardQuad"]).setColor(1, 1, 0).setPrimitive(GL_POINTS);
	auto cubes = createCubes(1000);
	auto ground = makePreset(ShapeType.QUAD, vec3(0.4, 0.2, 0))
			.setPos(0, -2, 0).setScale(100, 100, 100).setRot(PI/2, 0, 0);
	ground.uniforms["pointLight.diffuse"] = vec3(1, 1, 1);
	ground.uniforms["pointLight.attenuation"] = 0.01;
	ground.uniforms["ambientLight.color"] = vec3(1, 1, 1);
	ground.uniforms["ambientLight.strength"] = 0.1;
	ground.uniforms["dirLight.diffuse"] = vec3(0.3, 0.3, 0.3);
	ground.uniforms["dirLight.direction"] = vec3(0.4, 0.4, 0.4);

	//RenderState.global.clearColor = vec4(0.2, 0.5, 0.6, 1.0);
	RenderState.global.clearColor = vec4(0.06, 0.0, 0.1, 1.0);
	RenderState.global.projection = mat4.perspective(6, 6, camera.fov, 0.1, 5000f);

	camera.position.z = 4;
	camera.moveSpeed = 12f;
	auto clock = sfClock_create();
	auto fps = new FPSCounter(2f);
	debug writeln("starting render loop");
	renderLoop(window, camera, &processInput, (sfWindow *window, Camera camera, RenderState state) {
		// Update time
		auto t = sfTime_asSeconds(sfClock_getElapsedTime(clock));
		deltaTime = t - lastFrame;
		lastFrame = t;

		auto lightPos = vec3(20 * sin(t), 10f + 10f * sin(t / 5), 20 * cos(t));

		// Draw cubes
		glEnable(GL_CULL_FACE);
		cubes.uniforms["pointLight.position"] = lightPos;
		cubes.draw(window, camera);

		// Draw ground
		glDisable(GL_CULL_FACE);
		ground.uniforms["pointLight.position"] = lightPos;
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

void processInput(sfWindow *window, Camera camera, RenderState state) {
	sfEvent evt;
	while (sfWindow_pollEvent(window, &evt))
		evtHandler(evt, camera, state);

	if (sfKeyboard_isKeyPressed(sfKeyW))
		camera.move(Direction.FWD, deltaTime);
	if (sfKeyboard_isKeyPressed(sfKeyA))
		camera.move(Direction.LEFT, deltaTime);
	if (sfKeyboard_isKeyPressed(sfKeyS))
		camera.move(Direction.BACK, deltaTime);
	if (sfKeyboard_isKeyPressed(sfKeyD))
		camera.move(Direction.RIGHT, deltaTime);
}

void evtHandler(in sfEvent event, Camera camera, RenderState state) {
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

auto createCubes(uint n) {
	auto cubes = new Batch(genCube(), cubeVertices.length, presetShaders["defaultInstanced"]);
	cubes.uniforms["pointLight.diffuse"] = vec3(1, 1, 1);
	cubes.uniforms["pointLight.attenuation"] = 0.01;
	cubes.uniforms["ambientLight.color"] = vec3(1, 1, 1);
	cubes.uniforms["ambientLight.strength"] = 0.01;
	cubes.uniforms["dirLight.diffuse"] = vec3(0.1, 0.1, 0.1);
	cubes.uniforms["dirLight.direction"] = vec3(1, 0, 0);
	GLuint iVbo;
	{
		mat4[] cubeModels = new mat4[n];
		vec3[] cubeColors = new vec3[cubeModels.length];
		for (int i = 0; i < cubeModels.length; ++i) {
			auto pos = vec3(uniform(-30, 30), uniform(-30, 30), uniform(-30, 30));
			auto rot = quat.euler_rotation(uniform(-PI, PI), uniform(-PI, PI), uniform(-PI, PI));
			auto scalex = uniform(0.3, 2);
			auto scale = vec3(scalex, scalex + uniform(-0.5, 1), scalex + uniform(-0.5, 1));
			cubeModels[i] = mat4.identity
						.translate(pos.x, pos.y, pos.z)
						.rotate(rot.alpha, rot.axis)
						.scale(scale.x, scale.y, scale.z)
						.transposed(); // !!!
			cubeColors[i] = vec3(uniform01(), uniform01(), uniform01());
		}
		cubes.nInstances = cast(uint)cubeModels.length;
		cubes.setData("aInstanceModel", cubeModels);
		cubes.setData("aColor", cubeColors);
	}
	return cubes;
}
