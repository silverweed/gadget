module gadget.rendering.rendertexture;

import derelict.opengl;
import gadget.rendering.utils;

struct Vertex2D {
	GLfloat[2] position;
	GLfloat[2] texCoords;
}

immutable Vertex2D[12] screenQuadVertices = [
        // positions      // texCoords
	{ [-1.0f,  1.0f], [0.0f, 1.0f] },
	{ [-1.0f, -1.0f], [0.0f, 0.0f] },
	{ [ 1.0f, -1.0f], [1.0f, 0.0f] },
	{ [-1.0f,  1.0f], [0.0f, 1.0f] },
	{ [ 1.0f, -1.0f], [1.0f, 0.0f] },
	{ [ 1.0f,  1.0f], [1.0f, 1.0f] }
];

struct RenderTexture {
	uint fbo;
	uint quadVao;
	uint colorBuf;
	uint depthStencilBuf;
}

auto genRenderTexture(uint width, uint height) {
	uint fbo;
	glGenFramebuffers(1, &fbo);
	glBindFramebuffer(GL_FRAMEBUFFER, fbo);
	scope (exit) glBindFramebuffer(GL_FRAMEBUFFER, 0);

	// Create texture for color buffer
	uint colorBufTex;
	glGenTextures(1, &colorBufTex);
	glBindTexture(GL_TEXTURE_2D, colorBufTex);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, NULL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glBindTexture(GL_TEXTURE_2D, 0);

	// Attach color buffer to fbo
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, colorBufTex, 0);

	// Create renderbuffer for depth and stencil buffers
	uint rbo;
	glGenRenderbuffers(1, &rbo);
	glBindRenderbuffer(GL_RENDERBUFFER, rbo);
	glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width, height);
	glBindRenderbuffer(GL_RENDERBUFFER, 0);

	// Attach it
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, rbo);

	assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);

	return RenderTexture(fbo, genScreenQuad!screenQuadVertices(), colorBufTex, rbo);
}

auto genScreenQuad(alias vertices)() {
	uint vao, vbo;

	glGenVertexArrays(1, &vao);
	glGenBuffers(1, &vbo);

	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBufferData(GL_ARRAY_BUFFER, vertices.sizeof, &vertices, GL_STATIC_DRAW);

	glBindVertexArray(vao);

	// Position
	glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, Vertex2D.sizeof, cast(void*)Vertex2D.position.offsetof);
	glEnableVertexAttribArray(0);
	// Texture coords
	glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, Vertex2D.sizeof, cast(void*)Vertex2D.texCoords.offsetof);
	glEnableVertexAttribArray(1);

	// Unbind the buffer
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindVertexArray(0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); // must do this AFTER unbinding the vao

	return vao;
}
