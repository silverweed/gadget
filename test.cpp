#include <iostream>
#include <memory>
#include <SFML/Graphics.hpp>
#include <SFML/Window.hpp>
#include "gadget.h"

using namespace std;

int main() {
	vec2 v{2, 3};
	cout << v.x << ", " << v.y << endl;

	AABB a{{1, 2}, {3, 4}}, b{{1, 1}, {3, 2}};
	cout << AABBOverlapsAABB(a, b) << endl;

	Circle c{{2, 2}, 3}, d{{3, 3}, 4};
	cout << circleOverlapsCircle(c, d) << endl;

	PhysicsObj obj{a, v, v, 0.4f};
	PhysicsWorld world;
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

	return 0;
}
