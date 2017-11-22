import std.stdio;
import std.file;
import gadget.physics;
import gadget.rendering;
import derelict.sfml2.window;
import derelict.opengl3.gl3;
import gl3n.linalg;

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
	auto window = newWindow(800, 600);

	auto basicShader = new Shader(getcwd() ~ "/shaders/basic.vert", getcwd() ~ "/shaders/basic.frag");
	auto basicLightingShader = new Shader(
		getcwd() ~ "/shaders/basicLighting.vert",
		getcwd() ~ "/shaders/basicLighting.frag");
	auto quadVAO = genQuad();
	auto cubeVAO = genCube();

	debug writeln("starting render loop");
	renderLoop(window, &processInput, () {
		basicShader.use();
		//drawTriangles(quadVAO, quadIndices.length);
		basicLightingShader.use();
		basicLightingShader.setUni("objectColor", 1f, 0.5f, 0.31f);
		basicLightingShader.setUni("lightColor", 1f, 1f, 1f);
		basicLightingShader.setUni("lightPos", 1.2f, 1f, 2f);
		basicLightingShader.setUni("viewPos", 0f, 0f, 3f);
		basicLightingShader.setUni("projection", mat4.perspective(800, 600, 60, 0.2f, 3f));
		basicLightingShader.setUni("view", mat4.look_at(vec3(0f, 0f, 3f), vec3(0f, 0f, 0f),
					vec3(0f, 1f, 0f)));
		basicLightingShader.setUni("model", mat4.identity.scale(0.3, 0.3, 0.3)
				.rotatex(0.2).rotatez(0.2).rotatey(0.25));
		drawArrays(cubeVAO, cubeVertices.length);
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
	default:
		break;
	}
}
