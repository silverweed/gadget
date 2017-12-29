import std.stdio;
import std.file;
import std.math;
import std.conv : to;
import std.random : uniform, uniform01;
import std.algorithm;
import gadget.physics;
import gadget.rendering;
import gadget.fpscounter;
import gadget.chronometer;
import gadget.rendering.renderstate;
import derelict.sfml2.window;
import derelict.sfml2.system;
import derelict.opengl;
import gl3n.linalg;
import derelict.opengl;

enum WIDTH = 1920;
enum HEIGHT = 1080;
enum SHAD_WIDTH = 16384;
enum SHAD_HEIGHT = 16384;

float deltaTime = 0;
float lastFrame = 0;
Chronometer clock;

void main(string[] args) {

	enum nLights = 5;

	auto nCubes = 3;
	if (args.length > 1)
		nCubes = args[1].to!uint;

	//// Init rendering system
	initRender();
	auto window = newWindow(WIDTH, HEIGHT);

	auto world = new World();
	world.enableShadows(SHAD_WIDTH, SHAD_HEIGHT);
	world.enablePostProcessing();

	auto camera = new Camera();
	camera.position.y = 2;

	RenderState.global.clearColor = vec4(0.01, 0.0, 0.09, 1.0);

	Mesh[] points;
	auto cubes = createCubes(nCubes);
	world.objects ~= cubes;
	//auto cube = new Mesh(genCube(), cubeVertices.length, presetShaders["default"]);
	//world.objects ~= cube;
	//auto ground = makePreset(ShapeType.QUAD, vec3(0.4, 0.2, 0));
	auto ground = createGround();
	world.objects ~= ground;
	world.ambientLight = AmbientLight(
		vec3(1, 1, 1), // color
		0.05,          // strength
	);
	world.dirLight = DirLight(
		vec3(0.4, 0.4, 0.4), // direction
		vec3(0.35, 0.35, 0.35), // diffuse
	);
	for (int i = 0; i < nLights; ++i) {
		auto color = vec3(uniform01(), uniform01(), uniform01());
		world.pointLights ~= PointLight(
			vec3(0, 0, 0), // position
			color,
			0.03,          // attenuation
		);
	}
	auto lightGizmos = createLightGizmos(world);
	world.objects ~= lightGizmos;

	camera.position.z = 4;
	camera.moveSpeed = 12f;
	clock = new Chronometer();
	auto fps = new FPSCounter(2f);
	debug writeln("starting render loop");

	auto blurShader = Shader.fromFiles("shaders/gaussianblur.vert", "shaders/gaussianblur.frag");
	auto blurTex = [
		genRenderTexture(WIDTH, HEIGHT, 1, false),
		genRenderTexture(WIDTH, HEIGHT, 1, false)
	];
	auto bloomShader = Shader.fromFiles("shaders/gaussianblur.vert", "shaders/bloom.frag");

	renderLoop(window, camera, &processInput, (sfWindow *window, Camera camera, RenderState state) {
		// Update time
		auto t = sfTime_asSeconds(clock.getElapsedTime());
		deltaTime = t - lastFrame;
		lastFrame = t;

		//moveCubes(cubes, deltaTime);

		moveLights(world, t);
		updateLightGizmos(world, lightGizmos);
		world.dirLight.direction = -world.pointLights[0].position;

		// First pass: render scene to depth map
		world.renderDepthMaps();

		// Second pass: render scene to quad using generated depth map
		world.renderToInternalTex(camera);

		// [Insert post processing passes here]
		//gaussBlur(blurShader, blurTex, world);

		//glBindFramebuffer(GL_FRAMEBUFFER, 0);
		//glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
		//bloomShader.use();
		//glActiveTexture(GL_TEXTURE0);
		//glBindTexture(GL_TEXTURE_2D, world.renderTex.colorBufs[0]);
		//glActiveTexture(GL_TEXTURE1);
		//glBindTexture(GL_TEXTURE_2D, blurTex[0].colorBufs[0]);
		//bloomShader.uniforms["bloom"] = doBloom;
		//bloomShader.uniforms["scene"] = 0;
		//bloomShader.uniforms["bloomBlur"] = 1;
		//debug bloomShader.assertAllUniformsDefined();
		//bloomShader.applyUniforms();
		//drawArrays(world.renderTex.quadVao, quadVertices.length);

		// Final pass: render quad to screen
		world.renderQuad();
		//world.render(camera);

		updateMouse(window, camera);
		if (clock.isRunning())
			fps.update(deltaTime);
	});
}

void processInput(sfWindow *window, Camera camera, RenderState state) {
	sfEvent evt;
	while (sfWindow_pollEvent(window, &evt))
		evtHandler(evt, camera, state);

	if (sfKeyboard_isKeyPressed(sfKeyW))
		camera.move(Direction.FWD);
	if (sfKeyboard_isKeyPressed(sfKeyA))
		camera.move(Direction.LEFT);
	if (sfKeyboard_isKeyPressed(sfKeyS))
		camera.move(Direction.BACK);
	if (sfKeyboard_isKeyPressed(sfKeyD))
		camera.move(Direction.RIGHT);
}

bool doBloom = true;
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
		case sfKeyP:
			clock.toggle();
			break;
		case sfKeyB:
			doBloom = !doBloom;
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

mat4[] cubeModels;
int cubeModelsVbo;

auto createCubes(uint n) {
	auto cubes = makePreset(ShapeType.CUBE);
	cubes.material.diffuse = genTexture("textures/box.jpg");
	cubes.material.specular = genTexture("textures/box_specular.jpg");
	cubes.material.shininess = 16;
	cubes.cullFace = true;
	cubeModels = new mat4[n];
	//auto cubeDiffuse = new vec3[cubeModels.length];
	//auto cubeSpecular = new vec3[cubeModels.length];
	//auto cubeShininess = new float[cubeModels.length];
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
		//cubeDiffuse[i] = vec3(uniform01(), uniform01(), uniform01());
		//cubeSpecular[i] = vec3(uniform01(), uniform01(), uniform01());
		//cubeShininess[i] = uniform(0, 10);
	}
	// Put first cube in origin, for convenience
	cubeModels[0] = mat4.identity.rotate(PI/4, vec3(1, 0, 0)).transposed();
	cubeModels[1] = mat4.identity.translate(0, 2, 0).rotate(0.0, vec3(1, 0, 0)).transposed();
	cubeModels[2] = mat4.identity.translate(0, 0.5, 2).rotate(0.0, vec3(0, 1, 0)).transposed();
	cubes.nInstances = cast(uint)cubeModels.length;
	cubeModelsVbo = cubes.setData("aInstanceModel", cubeModels, GL_STREAM_DRAW); // this data will be updated every frame
	return cubes;
}

void moveLights(World world, float t) {
	for (int i = 0; i < world.pointLights.length; ++i) {
		auto lightPos = vec3(5 * (i+1) * sin(t + i * 0.7),
				3f + 2f * (i+1) * sin(t / 5 + i * 0.7),
				7 * (i+1) * cos(t + i * 0.7));
		world.pointLights[i].position = lightPos;
	}
}

void moveCubes(Batch cubes, float dt) {
	static vec3[] cubeVelocities;
	static quat[] cubeSpins;
	static float mt = 3;
	if (cubeVelocities.length == 0) {
		cubeVelocities = new vec3[cubeModels.length];
	}
	if (cubeSpins.length == 0) {
		cubeSpins = new quat[cubeModels.length];
	}
	mt += dt;
	if (mt > 2) {
		for (int i = 0; i < cubeVelocities.length; ++i) {
			cubeVelocities[i] = vec3(uniform(-1, 1), uniform(-1, 1), uniform(-1, 1));
			cubeSpins[i] = to_quat(uniform(-1, 1), uniform(-1, 1), uniform(-1, 1));
		}
		mt = 0;
	}

	glBindBuffer(GL_ARRAY_BUFFER, cubeModelsVbo);
	const bufsize = mat4.sizeof * (cubeModels.length + 1);
	// Realloc the buffer to orphan it
	glBufferData(GL_ARRAY_BUFFER, bufsize, NULL, GL_STREAM_DRAW);
	
	foreach (i, model; cubeModels) {
		const v = cubeVelocities[i] * dt * 3;
		//cubeModels[i] = model
		cubeModels[i] = model.transposed()
				//.rotate(cubeSpins[i].alpha * 0.1, cubeSpins[i].axis)
				.translate(v.x, v.y, v.z)
				.transposed()
				;
	}
	
	// Update the data
	glBufferSubData(GL_ARRAY_BUFFER, 0, bufsize, cubeModels.ptr);
}

auto createGround() {
	auto ground = makePreset(ShapeType.QUAD);
	ground.material.diffuse = genTexture("textures/ground.jpg");
	ground.material.specular = genTexture("textures/ground_specular.jpg");
	ground.material.shininess = 0;
	ground.cullFace = false;
	ground.nInstances = 1;
	ground.setData("aInstanceModel", [
		mat4.identity.scale(100, 100, 100).rotate(PI / 2, vec3(1, 0, 0)).translate(0, -0.5, 0).transposed()
	]);
	return ground;
}

@disable
void gaussBlur(Shader blurShader, RenderTexture[] blurTex, World world) {
	bool horizontal = true, first_iteration = true;
	enum amount = 8;
	blurShader.use();
	blurShader.uniforms["image"] = 0;
	for (uint i = 0; i < amount; i++) {
		glBindFramebuffer(GL_FRAMEBUFFER, blurTex[horizontal].fbo);
		blurShader.uniforms["horizontal"] = horizontal;
		glBindTexture(
			GL_TEXTURE_2D, first_iteration
				? world.renderTex.colorBufs[1]
				: blurTex[!horizontal].colorBufs[0]
		);
		debug blurShader.assertAllUniformsDefined();
		blurShader.applyUniforms();
		//drawArrays(blurTex[horizontal].quadVao, quadVertices.length);
		//world.renderQuad(blurTex[horizontal].quadVao);
		horizontal = !horizontal;
		if (first_iteration)
			first_iteration = false;
	}
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

auto createLightGizmos(in World world) {
	auto points = makePreset(ShapeType.POINT, presetShaders["billboardQuad"]);
	points.primitive = GL_POINTS;
	points.nInstances = cast(uint)world.pointLights.length;
	auto colors = new vec3[points.nInstances];
	foreach (i, pl; world.pointLights) {
		colors[i] = pl.diffuse;
	}
	points.setData("aColor", colors);
	updateLightGizmos(world, points);

	return points;
}

void updateLightGizmos(in World world, Batch points) {
	static uint lightGizmosPosVbo;
	static bool firstTime = true;

	auto pos = new mat4[points.nInstances];
	foreach (i, pl; world.pointLights)
		pos[i] = mat4.identity.translate(pl.position.x, pl.position.y, pl.position.z).transposed();

	if (firstTime) {
		lightGizmosPosVbo = points.setData("aInstanceModel", pos, GL_STREAM_DRAW);
		firstTime = false;
	} else {
		const bufsize = mat4.sizeof * (pos.length + 1);

		glBindBuffer(GL_ARRAY_BUFFER, lightGizmosPosVbo);
		// Realloc the buffer to orphan it
		glBufferData(GL_ARRAY_BUFFER, bufsize, NULL, GL_STREAM_DRAW);
		
		// Update the data
		glBufferSubData(GL_ARRAY_BUFFER, 0, bufsize, pos.ptr);
	}
	points.shader.uniforms["radius"] = 0.8;
	points.shader.uniforms["scrWidth"] = RenderState.global.screenSize.x;
	points.shader.uniforms["scrHeight"] = RenderState.global.screenSize.y;
}
