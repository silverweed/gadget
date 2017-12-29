module gadget.rendering.texture;

import std.conv;
import std.stdio;
import std.string;
import stb_image;
import derelict.opengl;

/// Creates a texture from given path and returns its handle
auto genTexture(string texture) {
	uint tex;
	glGenTextures(1, &tex);

	auto img = loadImg(texture);
	if (img.data == null)
		return -1;

	glBindTexture(GL_TEXTURE_2D, tex);
	glTexImage2D(GL_TEXTURE_2D, 0, img.format, img.width, img.height, 0, img.format, GL_UNSIGNED_BYTE, img.data);
	stderr.writeln("Loaded texture ", texture, ": ", img);
	glGenerateMipmap(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, 0);

	stbi_image_free(img.data);

	return tex;
}

/// Creates a cubemap from given paths (must be 6) and returns its handle
auto genCubemap(string[] textures) {
	assert(textures.length == 6, "Number of textures given to cubemap isn't 6!");

	uint tex;
	glGenTextures(1, &tex);
	glBindTexture(GL_TEXTURE_CUBE_MAP, tex);

	foreach (i, texture; textures) {
		auto img = loadImg(texture);
		if (img.data == null)
			return -1;
		glTexImage2D(cast(uint)(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i), 0, img.format,
				img.width, img.height, 0, img.format, GL_UNSIGNED_BYTE, img.data);
		stbi_image_free(img.data);
	}
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);

	return tex;
}

private:

struct ImgInfo {
	int width;
	int height;
	int nChans;
	ubyte* data;
	int format;
}

auto loadImg(string texture) {
	int w, h, nChans;
	auto data = stbi_load(texture.toStringz(), &w, &h, &nChans, 0);

	if (!data) {
		string reason = to!string(stbi_failure_reason());
		stderr.writeln("[FAIL] Failed to load texture: ", texture, " with reason: ", reason);
		return ImgInfo();
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
		stderr.writeln("[FAIL] Unknown format for texture ", texture, " (", nChans, " channels?)");
		return ImgInfo();
	}

	return ImgInfo(w, h, nChans, data, format);
}
