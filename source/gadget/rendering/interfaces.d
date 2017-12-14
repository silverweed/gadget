module gadget.rendering.interfaces;

import derelict.sfml2;
import gadget.rendering.camera;
import gadget.rendering.shader;

interface Drawable {
	void draw(sfWindow *window, Camera camera);
}

interface ShaderDrawable : Drawable {
	Shader getShader();
}
