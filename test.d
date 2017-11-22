import gadget;
import std.stdio;

void main() {
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

	//sf::RenderWindow w(sf::VideoMode(640, 480), "Test gadget");
	//w.setFramerateLimit(60);

	/*sf::RectangleShape r(sf::Vector2f(50, 50));
	r.setPosition(50, 200);
	while (w.isOpen()) {
		sf::Event evt;
		while (w.pollEvent(evt)) {
			switch (evt.type) {
			case sf::Event::Closed:
				w.close();
				break;
			case sf::Event::KeyPressed:
				switch (evt.key.code) {
				case sf::Keyboard::Q:
					w.close();
					break;
				default: break;
				}
			default: break;
			}
		}

		w.clear();
		w.draw(r);
		w.display();
	}*/
}
