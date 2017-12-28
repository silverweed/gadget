module gadget.rendering.texture;

import std.stdio;
import std.string;
import stb_image;
import derelict.opengl;

auto genTexture(string texture) {
	uint tex;
	glGenTextures(1, &tex);
	glBindTexture(GL_TEXTURE_2D, tex);

	int w, h, nChans;
	auto data = stbi_load(texture.toStringz(), &w, &h, &nChans, 0);

	if (data) {
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, w, h, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
		glGenerateMipmap(GL_TEXTURE_2D);
	} else {
		writeln("[FAIL] Failed to load texture: ", texture);
		return -1;
	}

	stbi_image_free(data);

	glBindTexture(GL_TEXTURE_2D, 0);

	return tex;
}
