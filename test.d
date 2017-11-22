import std.stdio;
import std.file;
import std.math;
import gadget.physics;
import gadget.rendering;
import derelict.sfml2.window;
import derelict.sfml2.system;
import derelict.opengl3.gl3;
import gl3n.linalg;

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

	auto basicShader = new Shader(getcwd() ~ "/shaders/basic.vert", getcwd() ~ "/shaders/basic.frag");
	auto basicLightingShader = new Shader(
		getcwd() ~ "/shaders/basicLighting.vert",
		getcwd() ~ "/shaders/basicLighting.frag");
	auto quadVAO = genQuad();
	auto cubeVAO = genCube();

	auto clock = sfClock_create();
	debug writeln("starting render loop");
	renderLoop(window, &processInput, () {
		// Update time
		auto t = sfTime_asSeconds(sfClock_getElapsedTime(clock));
		deltaTime = t - lastFrame;
		lastFrame = t;

		//basicShader.use();
		//drawTriangles(quadVAO, quadIndices.length);
		basicLightingShader.use();
		basicLightingShader.setUni("objectColor", 1f, 0.5f, 0.31f);
		basicLightingShader.setUni("lightColor", 1f, 1f, 1f);
		basicLightingShader.setUni("lightPos", 1.2f, 1f, 2f);
		basicLightingShader.setUni("viewPos", camera.pos);
		//basicLightingShader.setUni("projection", mat4.orthographic(0, 800, 0, 600, 0.1, 30f));
		basicLightingShader.setUni("projection", mat4.perspective(800, 600, camera.fov, 0.1f, 30f));
		basicLightingShader.setUni("view", camera.viewMatrix);
		basicLightingShader.setUni("model", mat4.identity
				.scale(10.0, 10.0, 10.0)
				//.rotatex(0.2).rotatez(0.2).rotatey(0.25));
			);
		drawArrays(cubeVAO, cubeVertices.length);

		//sfMouse_setPosition(sfVector2i(WIDTH/2, HEIGHT/2), window);
	});
}

void processInput(in sfEvent event) {
	switch (event.type) {
	case sfEvtResized:
		handleResize(event);
		break;
	// FIXME: fires automatically?
	//case sfEvtClosed:
		//gr.quitRender();
		//break;
	case sfEvtKeyPressed:
		switch (event.key.code) {
		case sfKeyQ:
			quitRender();
			break;
		default:
			break;
		}
		break;
	case sfEvtMouseMoved:
		{
			static bool firstMouse = true;
			int x = event.mouseMove.x,
			    y = event.mouseMove.y;
			if (firstMouse) {
				lastMouseX = x;
				lastMouseY = y;
				firstMouse = false;
			}
			camera.turn(x - lastMouseX, lastMouseY - y);
			lastMouseX = x;
			lastMouseY = y;
			break;
		}
	case sfEvtMouseWheelMoved:
		camera.zoom(event.mouseWheel.delta);
		break;
	default:
		break;
	}

	if (sfKeyboard_isKeyPressed(sfKeyW))
		camera.move(Direction.FWD, deltaTime);
	if (sfKeyboard_isKeyPressed(sfKeyA))
		camera.move(Direction.LEFT, deltaTime);
	if (sfKeyboard_isKeyPressed(sfKeyS))
		camera.move(Direction.BACK, deltaTime);
	if (sfKeyboard_isKeyPressed(sfKeyD))
		camera.move(Direction.RIGHT, deltaTime);
}
