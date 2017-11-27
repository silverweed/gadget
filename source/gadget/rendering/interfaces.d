module gadget.rendering.interfaces;

import derelict.sfml2;
import gadget.rendering.camera;

interface Drawable {
	void draw(sfWindow *window, Camera camera);
}
