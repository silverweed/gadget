module gadget.rendering.shapes;

import std.typecons;
import derelict.opengl;
debug import std.stdio;

struct Vertex {
	GLfloat[3] position;
	GLfloat[3] normal;
	GLfloat[2] texCoords;
}

alias Index = uint;

enum ShapeType {
	CUBE,
	QUAD,
	POINT
}

/// Utility module to create basic 2d or 3d shapes
immutable Vertex[1] pointVertices = [
	{ [0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0] }
];

immutable Vertex[6] quadVertices = [
	{ [ 0.5f,  0.5f, 0f], [0f, 0f, 1f], [1f, 1f] },
	{ [-0.5f,  0.5f, 0f], [0f, 0f, 1f], [0f, 1f] },
	{ [-0.5f, -0.5f, 0f], [0f, 0f, 1f], [0f, 0f] },
	{ [ 0.5f,  0.5f, 0f], [0f, 0f, 1f], [1f, 1f] },
	{ [-0.5f, -0.5f, 0f], [0f, 0f, 1f], [0f, 0f] },
	{ [ 0.5f, -0.5f, 0f], [0f, 0f, 1f], [1f, 0f] },
];

immutable Vertex[4] quadElements = [
	{ [ 0.5f,  0.5f, 0f], [0f, 0f, 1f], [1f, 1f] },
	{ [-0.5f,  0.5f, 0f], [0f, 0f, 1f], [0f, 1f] },
	{ [-0.5f, -0.5f, 0f], [0f, 0f, 1f], [0f, 0f] },
	{ [ 0.5f, -0.5f, 0f], [0f, 0f, 1f], [1f, 0f] },
];

immutable uint[6] quadIndices = [
	0, 1, 2, 0, 2, 3
];

/*
immutable Vertex[36] cubeVertices = [
	// positions              // normals             // texture coords
	{ [-0.5f, -0.5f, -0.5f],  [0.0f,  0.0f, -1.0f],  [0.0f, 0.0f] },
	{ [ 0.5f,  0.5f, -0.5f],  [0.0f,  0.0f, -1.0f],  [1.0f, 1.0f] },
	{ [ 0.5f, -0.5f, -0.5f],  [0.0f,  0.0f, -1.0f],  [1.0f, 0.0f] },
	{ [ 0.5f,  0.5f, -0.5f],  [0.0f,  0.0f, -1.0f],  [1.0f, 1.0f] },
	{ [-0.5f, -0.5f, -0.5f],  [0.0f,  0.0f, -1.0f],  [0.0f, 0.0f] },
	{ [-0.5f,  0.5f, -0.5f],  [0.0f,  0.0f, -1.0f],  [0.0f, 1.0f] },

	{ [-0.5f, -0.5f,  0.5f],  [0.0f,  0.0f, 1.0f],   [0.0f, 0.0f] },
	{ [ 0.5f, -0.5f,  0.5f],  [0.0f,  0.0f, 1.0f],   [1.0f, 0.0f] },
	{ [ 0.5f,  0.5f,  0.5f],  [0.0f,  0.0f, 1.0f],   [1.0f, 1.0f] },
	{ [ 0.5f,  0.5f,  0.5f],  [0.0f,  0.0f, 1.0f],   [1.0f, 1.0f] },
	{ [-0.5f,  0.5f,  0.5f],  [0.0f,  0.0f, 1.0f],   [0.0f, 1.0f] },
	{ [-0.5f, -0.5f,  0.5f],  [0.0f,  0.0f, 1.0f],   [0.0f, 0.0f] },

	{ [-0.5f,  0.5f,  0.5f],  [-1.0f,  0.0f, 0.0f],  [1.0f, 0.0f] },
	{ [-0.5f,  0.5f, -0.5f],  [-1.0f,  0.0f, 0.0f],  [1.0f, 1.0f] },
	{ [-0.5f, -0.5f, -0.5f],  [-1.0f,  0.0f, 0.0f],  [0.0f, 1.0f] },
	{ [-0.5f, -0.5f, -0.5f],  [-1.0f,  0.0f, 0.0f],  [0.0f, 1.0f] },
	{ [-0.5f, -0.5f,  0.5f],  [-1.0f,  0.0f, 0.0f],  [0.0f, 0.0f] },
	{ [-0.5f,  0.5f,  0.5f],  [-1.0f,  0.0f, 0.0f],  [1.0f, 0.0f] },

	{ [ 0.5f,  0.5f,  0.5f],  [1.0f,  0.0f,  0.0f],  [1.0f, 0.0f] },
	{ [ 0.5f, -0.5f, -0.5f],  [1.0f,  0.0f,  0.0f],  [0.0f, 1.0f] },
	{ [ 0.5f,  0.5f, -0.5f],  [1.0f,  0.0f,  0.0f],  [1.0f, 1.0f] },
	{ [ 0.5f, -0.5f, -0.5f],  [1.0f,  0.0f,  0.0f],  [0.0f, 1.0f] },
	{ [ 0.5f,  0.5f,  0.5f],  [1.0f,  0.0f,  0.0f],  [1.0f, 0.0f] },
	{ [ 0.5f, -0.5f,  0.5f],  [1.0f,  0.0f,  0.0f],  [0.0f, 0.0f] },

	{ [-0.5f, -0.5f, -0.5f],  [0.0f, -1.0f,  0.0f],  [0.0f, 1.0f] },
	{ [ 0.5f, -0.5f, -0.5f],  [0.0f, -1.0f,  0.0f],  [1.0f, 1.0f] },
	{ [ 0.5f, -0.5f,  0.5f],  [0.0f, -1.0f,  0.0f],  [1.0f, 0.0f] },
	{ [ 0.5f, -0.5f,  0.5f],  [0.0f, -1.0f,  0.0f],  [1.0f, 0.0f] },
	{ [-0.5f, -0.5f,  0.5f],  [0.0f, -1.0f,  0.0f],  [0.0f, 0.0f] },
	{ [-0.5f, -0.5f, -0.5f],  [0.0f, -1.0f,  0.0f],  [0.0f, 1.0f] },

	{ [ 0.5f,  0.5f, -0.5f],  [0.0f,  1.0f,  0.0f],  [1.0f, 1.0f] },
	{ [-0.5f,  0.5f, -0.5f],  [0.0f,  1.0f,  0.0f],  [0.0f, 1.0f] },
	{ [ 0.5f,  0.5f,  0.5f],  [0.0f,  1.0f,  0.0f],  [1.0f, 0.0f] },
	{ [-0.5f,  0.5f,  0.5f],  [0.0f,  1.0f,  0.0f],  [0.0f, 0.0f] },
	{ [ 0.5f,  0.5f,  0.5f],  [0.0f,  1.0f,  0.0f],  [1.0f, 0.0f] },
	{ [-0.5f,  0.5f, -0.5f],  [0.0f,  1.0f,  0.0f],  [0.0f, 1.0f] }
];
*/

immutable Vertex[25] cubeElements = [
	// positions              // normals             // texture coords
	{ [-0.5f, -0.5f, -0.5f],  [0.0f,  0.0f, -1.0f],  [0.0f, 0.0f] },
	{ [ 0.5f,  0.5f, -0.5f],  [0.0f,  0.0f, -1.0f],  [1.0f, 1.0f] },
	{ [ 0.5f, -0.5f, -0.5f],  [0.0f,  0.0f, -1.0f],  [1.0f, 0.0f] },
	{ [-0.5f,  0.5f, -0.5f],  [0.0f,  0.0f, -1.0f],  [0.0f, 1.0f] },
	{ [-0.5f, -0.5f,  0.5f],  [0.0f,  0.0f, 1.0f],   [0.0f, 0.0f] },
	{ [ 0.5f, -0.5f,  0.5f],  [0.0f,  0.0f, 1.0f],   [1.0f, 0.0f] },
	{ [ 0.5f,  0.5f,  0.5f],  [0.0f,  0.0f, 1.0f],   [1.0f, 1.0f] },
	{ [-0.5f,  0.5f,  0.5f],  [0.0f,  0.0f, 1.0f],   [0.0f, 1.0f] },
	{ [-0.5f,  0.5f,  0.5f],  [-1.0f,  0.0f, 0.0f],  [1.0f, 0.0f] },
	{ [-0.5f,  0.5f, -0.5f],  [-1.0f,  0.0f, 0.0f],  [1.0f, 1.0f] },
	{ [-0.5f, -0.5f, -0.5f],  [-1.0f,  0.0f, 0.0f],  [0.0f, 1.0f] },
	{ [-0.5f, -0.5f,  0.5f],  [-1.0f,  0.0f, 0.0f],  [0.0f, 0.0f] },
	{ [ 0.5f,  0.5f,  0.5f],  [1.0f,  0.0f,  0.0f],  [1.0f, 0.0f] },
	{ [ 0.5f, -0.5f, -0.5f],  [1.0f,  0.0f,  0.0f],  [0.0f, 1.0f] },
	{ [ 0.5f,  0.5f, -0.5f],  [1.0f,  0.0f,  0.0f],  [1.0f, 1.0f] },
	{ [ 0.5f, -0.5f,  0.5f],  [1.0f,  0.0f,  0.0f],  [0.0f, 0.0f] },
	{ [-0.5f, -0.5f, -0.5f],  [0.0f, -1.0f,  0.0f],  [0.0f, 1.0f] },
	{ [ 0.5f, -0.5f, -0.5f],  [0.0f, -1.0f,  0.0f],  [1.0f, 1.0f] },
	{ [ 0.5f, -0.5f,  0.5f],  [0.0f, -1.0f,  0.0f],  [1.0f, 0.0f] },
	{ [-0.5f, -0.5f,  0.5f],  [0.0f, -1.0f,  0.0f],  [0.0f, 0.0f] },
	{ [ 0.5f,  0.5f, -0.5f],  [0.0f,  1.0f,  0.0f],  [1.0f, 1.0f] },
	{ [-0.5f,  0.5f, -0.5f],  [0.0f,  1.0f,  0.0f],  [0.0f, 1.0f] },
	{ [ 0.5f,  0.5f,  0.5f],  [0.0f,  1.0f,  0.0f],  [1.0f, 0.0f] },
	{ [-0.5f,  0.5f,  0.5f],  [0.0f,  1.0f,  0.0f],  [0.0f, 0.0f] },
	{ [-0.5f,  0.5f, -0.5f],  [0.0f,  1.0f,  0.0f],  [0.0f, 1.0f] }
];

immutable uint[36] cubeIndices = [
	0,  1,  2,  1,  0,  3,
	4,  5,  6,  6,  7,  4,
	8,  9,  10, 10, 11, 8,
	12, 13, 14, 13, 12, 15,
	16, 17, 18, 18, 19, 16,
	20, 21, 22, 23, 22, 24,
];

// Configures a vertex array object to contain a shape. Returns the vao index.
// This shape is meant to be used with glDrawElements.
auto genShapeElem(in Vertex[] vertices, in Index[] indices) {
	uint vbo, vao, ebo;

	glGenVertexArrays(1, &vao);
	glGenBuffers(1, &vbo);
	glGenBuffers(1, &ebo);

	glBindVertexArray(vao);

	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBufferData(GL_ARRAY_BUFFER, Vertex.sizeof * vertices.length, vertices.ptr, GL_STATIC_DRAW);

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, Index.sizeof * indices.length, indices.ptr, GL_STATIC_DRAW);

	/// Position
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(void*)Vertex.position.offsetof);
	glEnableVertexAttribArray(0);
	// Normals
	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(void*)Vertex.normal.offsetof);
	glEnableVertexAttribArray(1);
	// Texture coords
	glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(void*)Vertex.texCoords.offsetof);
	glEnableVertexAttribArray(2);

	// Unbind the buffers
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindVertexArray(0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0); // must do this AFTER unbinding the vao

	return vao;
}

// Like genShapeElem but used with glDrawArrays
auto genShape(in Vertex[] vertices) {
	uint vao, vbo;

	glGenVertexArrays(1, &vao);
	glGenBuffers(1, &vbo);

	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBufferData(GL_ARRAY_BUFFER, Vertex.sizeof * vertices.length, vertices.ptr, GL_STATIC_DRAW);

	glBindVertexArray(vao);

	// Position
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(void*)Vertex.position.offsetof);
	glEnableVertexAttribArray(0);
	// Normals
	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(void*)Vertex.normal.offsetof);
	glEnableVertexAttribArray(1);
	// Texture coords
	glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(void*)Vertex.texCoords.offsetof);
	glEnableVertexAttribArray(2);

	// Unbind the buffers
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindVertexArray(0);

	return vao;
}

auto genCube() {
	return genShapeElem(cubeElements, cubeIndices);
}

auto genQuad() {
	//const tup = createIndexBuffer(quadVertices);
	//return genShapeElem(tup[0], tup[1]);
	return genShapeElem(quadElements, quadIndices);
}

auto genPoint() {
	return genShape(pointVertices);
}

// Given a vertex array, returns a tuple (uniqued vertex array, indices array)
auto createIndexBuffer(in Vertex[] vertices) {
	Vertex[] newVertices;
	uint[] indices;

	static int findSimilar(in uint[] inds, in Vertex[] verts, in Vertex v) pure {
		foreach (idx; inds) {
			const vv = verts[idx];
			if (v.position == vv.position &&
				v.normal == vv.normal &&
				v.texCoords == vv.texCoords)
			{
				return idx;
			}
		}
		return -1;
	}

	foreach (v; vertices) {
		int f = findSimilar(indices, newVertices, v);
		if (f >= 0)
			indices ~= f;
		else {
			newVertices ~= v;
			indices ~= cast(uint)newVertices.length - 1;
		}
	}

	return tuple(newVertices, indices);
}
