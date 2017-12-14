import std.stdio;
import std.file;
import std.math;
import std.conv : to;
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

void main(string[] args) {

	auto nCubes = 1000;
	if (args.length > 1)
		nCubes = args[1].to!uint;

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
	auto world = new World();

	auto point = new Mesh(genPoint(), 1, presetShaders["billboardQuad"]).setColor(1, 1, 0).setPrimitive(GL_POINTS);
	world.addObject(point);
	world.addObject(createCubes(nCubes));
	auto ground = makePreset(ShapeType.QUAD, vec3(0.4, 0.2, 0))
			.setPos(0, -2, 0).setScale(100, 100, 100).setRot(PI/2, 0, 0);
	world.ambientLight = AmbientLight(
		vec3(1, 1, 1), // color 
		0.2,           // strength
	);
	world.dirLight = DirLight(
		vec3(0.4, 0.4, 0.4), // direction
		vec3(0.03, 0.03, 0.03), // diffuse
	);
	//world.addPointLight(PointLight(
		//vec3(0, 0, 0), // position
		//vec3(1, 1, 1), // diffuse
		//0.00,          // attenuation
	//));
	world.addObject(ground);

	//RenderState.global.clearColor = vec4(0.2, 0.5, 0.6, 1.0);
	RenderState.global.clearColor = vec4(0.01, 0.0, 0.09, 1.0);

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

		//auto lightPos = vec3(50 * sin(t), 10f + 10f * sin(t / 5), 50 * cos(t));
		world.dirLight.direction = vec3(1, sin(t), 1);

		// Update light gizmo
		//point.uniforms["radius"] = 0.8;
		//point.uniforms["scrWidth"] = RenderState.global.screenSize.x;
		//point.uniforms["scrHeight"] = RenderState.global.screenSize.y;
		//point.setPos(lightPos);

		//world.getPointLight(0).position = lightPos;

		world.draw(window, camera);

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
		handleResize(event, camera);
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
	GLuint iVbo;
	{
		auto cubeModels = new mat4[n];
		auto cubeDiffuse = new vec3[cubeModels.length];
		auto cubeSpecular = new vec3[cubeModels.length];
		auto cubeShininess = new float[cubeModels.length];
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
			cubeDiffuse[i] = vec3(uniform01(), uniform01(), uniform01());
			cubeSpecular[i] = vec3(uniform01(), uniform01(), uniform01());
			cubeShininess[i] = uniform(0, 100);
		}
		cubes.nInstances = cast(uint)cubeModels.length;
		cubes.setData("aInstanceModel", cubeModels);
		cubes.setData("aDiffuse", cubeDiffuse);
		cubes.setData("aSpecular", cubeSpecular);
		cubes.setData("aShininess", cubeShininess);
	}
	return cubes;
}
