module gadget.rendering.rendertexture;

import derelict.opengl;
import gadget.rendering.utils;
import gadget.rendering.gl;

struct Vertex2D {
	GLfloat[2] position;
	GLfloat[2] texCoords;
}

immutable Vertex2D[4] screenQuadElements = [
        // positions      // texCoords
	{ [-1.0f,  1.0f], [0.0f, 1.0f] },
	{ [-1.0f, -1.0f], [0.0f, 0.0f] },
	{ [ 1.0f, -1.0f], [1.0f, 0.0f] },
	{ [ 1.0f,  1.0f], [1.0f, 1.0f] }
];

immutable uint[6] screenQuadIndices = [
	0, 1, 2, 0, 2, 3
];

struct RenderTexture {
	uint fbo;
	uint quadVao;
	uint[] colorBufs;
	uint depthStencilBuf;
}

auto genRenderTexture(uint width, uint height, uint nColorBufs = 1, bool withDepthStencil = true) {
	mixin(DEFER_REBIND_CUR_FBO);

	uint fbo;
	glGenFramebuffers(1, &fbo);
	glBindFramebuffer(GL_FRAMEBUFFER, fbo);

	// Create texture for color buffer
	auto colorBufTex = new uint[nColorBufs];
	glGenTextures(nColorBufs, colorBufTex.ptr);
	for (uint i = 0; i < colorBufTex.length; ++i) {
		glBindTexture(GL_TEXTURE_2D, colorBufTex[i]);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB16F, width, height,
				0, GL_RGB, GL_FLOAT, NULL);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

		// Attach color buffer to fbo
		glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + i,
				GL_TEXTURE_2D, colorBufTex[i], 0);
	}
	glBindTexture(GL_TEXTURE_2D, 0);
	uint[] attachments;
	for (uint i = 0; i < nColorBufs; ++i)
		attachments ~= GL_COLOR_ATTACHMENT0 + i;
	glDrawBuffers(nColorBufs, attachments.ptr);

	// Create renderbuffer for depth and stencil buffers
	uint rbo;
	if (withDepthStencil) {
		glGenRenderbuffers(1, &rbo);
		glBindRenderbuffer(GL_RENDERBUFFER, rbo);
		glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, width, height);
		glBindRenderbuffer(GL_RENDERBUFFER, 0);

		// Attach it
		glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT,
				GL_RENDERBUFFER, rbo);
	}

	assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);

	return RenderTexture(fbo, genScreenQuad(), colorBufTex, rbo);
}

auto genScreenQuad() {
	uint vao, vbo, ebo;

	glGenVertexArrays(1, &vao);
	glGenBuffers(1, &vbo);
	glGenBuffers(1, &ebo);

	glBindVertexArray(vao);

	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBufferData(GL_ARRAY_BUFFER, screenQuadElements.sizeof, &screenQuadElements, GL_STATIC_DRAW);

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, screenQuadIndices.sizeof, &screenQuadIndices, GL_STATIC_DRAW);

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
