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

enum WIDTH = 1920;
enum HEIGHT = 1080;

float deltaTime = 0;
float lastFrame = 0;

void main(string[] args) {

	auto nCubes = 1;
	if (args.length > 1)
		nCubes = args[1].to!uint;

	//// Init rendering system
	initRender();
	auto window = newWindow(WIDTH, HEIGHT);

	enum nLights = 1;

	auto camera = new Camera();
	auto world = new World();

	Mesh[] points;
	auto cubes = createCubes(nCubes);
	world.objects ~= cubes;
	auto ground = makePreset(ShapeType.QUAD, vec3(0.4, 0.2, 0));
	ground.transform.position = vec3(0, -2, 0);
	ground.transform.scale = vec3(100, 100, 100);
	ground.transform.rotation = to_quat(PI/2, 0, 0);
	world.ambientLight = AmbientLight(
		vec3(1, 1, 1), // color
		0.05,           // strength
	);
	world.dirLight = DirLight(
		vec3(0.4, 0.4, 0.4), // direction
		vec3(0.05, 0.05, 0.05), // diffuse
	);
	for (int i = 0; i < nLights; ++i) {
		auto color = vec3(uniform01(), uniform01(), uniform01());
		world.pointLights ~= PointLight(
			vec3(0, 0, 0), // position
			color,
			0.03,          // attenuation
		);
		auto point = new Mesh(genPoint(), 1, presetShaders["billboardQuad"]);
		point.material.diffuse = vec3(color.r, color.g, color.b);
		point.primitive = GL_POINTS;
		points ~= point;
		world.objects ~= point;
	}
	world.objects ~= ground;

	RenderState.global.clearColor = vec4(0.01, 0.0, 0.09, 1.0);

	camera.position.z = 4;
	camera.moveSpeed = 12f;
	auto clock = sfClock_create();
	auto fps = new FPSCounter(2f);
	debug writeln("starting render loop");

	auto screenQuadShader = presetShaders["screenQuad"];
	screenQuadShader.use();
	screenQuadShader.setInt("screenTex", 0);
	auto renderTex = genRenderTexture(WIDTH, HEIGHT);
	auto depthMap = genDepthMap(1024, 1024);

	renderLoop(window, camera, &processInput, (sfWindow *window, Camera camera, RenderState state) {
		// Update time
		auto t = sfTime_asSeconds(sfClock_getElapsedTime(clock));
		deltaTime = t - lastFrame;
		lastFrame = t;

		//world.dirLight.direction = vec3(1, sin(t), 1);

		moveLights(world, points, t);

		// First pass: render scene to render target
		glBindFramebuffer(GL_FRAMEBUFFER, renderTex.fbo);
		const clCol = RenderState.global.clearColor;
		glClearColor(clCol.r, clCol.g, clCol.b, clCol.a);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		world.draw(camera);

		// Second pass: draw render target to screen
		glBindFramebuffer(GL_FRAMEBUFFER, 0);
		glClearColor(1, 1, 1, 1);
		glClear(GL_COLOR_BUFFER_BIT);
		screenQuadShader.use();
		glDisable(GL_DEPTH_TEST);
		glBindTexture(GL_TEXTURE_2D, renderTex.colorBuf);
		drawArrays(renderTex.quadVao, quadVertices.length);

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
		cubeShininess[i] = uniform(0, 10);
	}
	// Put first cube in origin, for convenience
	cubeModels[0] = mat4.identity;
	cubes.nInstances = cast(uint)cubeModels.length;
	cubes.setData("aInstanceModel", cubeModels);
	cubes.setData("aDiffuse", cubeDiffuse);
	cubes.setData("aSpecular", cubeSpecular);
	cubes.setData("aShininess", cubeShininess);
	return cubes;
}

void moveLights(World world, Mesh[] points, float t) {
	for (int i = 0; i < points.length; ++i) {
		auto lightPos = vec3(5 * (i+1) * sin(t + i * 0.7),
				1f + 2f * (i+1) * sin(t / 5 + i * 0.7),
				7 * (i+1) * cos(t + i * 0.7));

		// Update light gizmo
		points[i].uniforms["radius"] = 0.8;
		points[i].uniforms["scrWidth"] = RenderState.global.screenSize.x;
		points[i].uniforms["scrHeight"] = RenderState.global.screenSize.y;
		points[i].transform.position = lightPos;

		world.pointLights[i].position = lightPos;
	}
}
