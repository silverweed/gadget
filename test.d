import std.stdio;
import std.file;
import gadget.physics;
import gadget.rendering;
import derelict.sfml2.window;
import derelict.opengl3.gl3;

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
	auto quadVAO = genQuad();

	debug writeln("starting render loop");
	renderLoop(window, &processInput, () {
		basicShader.use();
		drawTriangles(quadVAO, quadIndices.length);
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
