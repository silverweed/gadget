module gadget.rendering.texture;

import std.conv;
import std.stdio;
import std.string;
import stb_image;
import derelict.opengl;

auto genTexture(string texture) {
	uint tex;
	glGenTextures(1, &tex);

	int w, h, nChans;
	auto data = stbi_load(texture.toStringz(), &w, &h, &nChans, 0);

	if (!data) {
		string reason = to!string(stbi_failure_reason());
		writeln("[FAIL] Failed to load texture: ", texture, " with reason: ", reason);
		return -1;
	}

	GLenum format;
	switch (nChans) {
	case 1:
		format = GL_RED;
		break;
	case 3:
		format = GL_RGB;
		break;
	case 4:
		format = GL_RGBA;
		break;
	default:
		writeln("[FAIL] Unknown format for texture ", texture, " (", nChans, " channels?)");
		return -1;
	}

	glBindTexture(GL_TEXTURE_2D, tex);
	glTexImage2D(GL_TEXTURE_2D, 0, format, w, h, 0, format, GL_UNSIGNED_BYTE, data);
	stderr.writeln("Loaded texture ", texture, ": ", w, "x", h, " with ", nChans, " channels");
	glGenerateMipmap(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, 0);

	stbi_image_free(data);

	return tex;
}
