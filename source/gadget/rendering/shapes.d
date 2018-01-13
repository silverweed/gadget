module gadget.rendering.shapes;

import std.typecons;
import derelict.opengl;
import gl3n.linalg;
import gadget.rendering.utils;
debug import std.stdio;

struct Vertex {
	vec3 position;
	vec3 normal;
	vec2 texCoords;
	vec3 tangent;
	vec3 bitangent;
}

alias Index = uint;

enum ShapeType {
	CUBE,
	QUAD,
	POINT
}

/// Utility module to create basic 2d or 3d shapes
immutable Vertex[1] pointVertices = [
	{ vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), vec2(0.0, 0.0) }
];

Vertex[6] quadVertices = [
	{ vec3( 0.5f,  0.5f, 0f), vec3(0f, 0f, 1f), vec2(1f, 1f) },
	{ vec3(-0.5f,  0.5f, 0f), vec3(0f, 0f, 1f), vec2(0f, 1f) },
	{ vec3(-0.5f, -0.5f, 0f), vec3(0f, 0f, 1f), vec2(0f, 0f) },
	{ vec3( 0.5f,  0.5f, 0f), vec3(0f, 0f, 1f), vec2(1f, 1f) },
	{ vec3(-0.5f, -0.5f, 0f), vec3(0f, 0f, 1f), vec2(0f, 0f) },
	{ vec3( 0.5f, -0.5f, 0f), vec3(0f, 0f, 1f), vec2(1f, 0f) },
];

immutable Vertex[4] quadElements = [
	{ vec3( 0.5f,  0.5f, 0f), vec3(0f, 0f, 1f), vec2(1f, 1f) },
	{ vec3(-0.5f,  0.5f, 0f), vec3(0f, 0f, 1f), vec2(0f, 1f) },
	{ vec3(-0.5f, -0.5f, 0f), vec3(0f, 0f, 1f), vec2(0f, 0f) },
	{ vec3( 0.5f, -0.5f, 0f), vec3(0f, 0f, 1f), vec2(1f, 0f) },
];

immutable Index[6] quadIndices = [
	0, 1, 2, 0, 2, 3
];

Vertex[36] cubeVertices = [
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

immutable Vertex[25] cubeElements = [
	// positions              // normals             // texture coords
	{ vec3(-0.5f, -0.5f, -0.5f),  vec3(0.0f,  0.0f, -1.0f),  vec2(0.0f, 0.0f) },
	{ vec3( 0.5f,  0.5f, -0.5f),  vec3(0.0f,  0.0f, -1.0f),  vec2(1.0f, 1.0f) },
	{ vec3( 0.5f, -0.5f, -0.5f),  vec3(0.0f,  0.0f, -1.0f),  vec2(1.0f, 0.0f) },
	{ vec3(-0.5f,  0.5f, -0.5f),  vec3(0.0f,  0.0f, -1.0f),  vec2(0.0f, 1.0f) },
	{ vec3(-0.5f, -0.5f,  0.5f),  vec3(0.0f,  0.0f, 1.0f),   vec2(0.0f, 0.0f) },
	{ vec3( 0.5f, -0.5f,  0.5f),  vec3(0.0f,  0.0f, 1.0f),   vec2(1.0f, 0.0f) },
	{ vec3( 0.5f,  0.5f,  0.5f),  vec3(0.0f,  0.0f, 1.0f),   vec2(1.0f, 1.0f) },
	{ vec3(-0.5f,  0.5f,  0.5f),  vec3(0.0f,  0.0f, 1.0f),   vec2(0.0f, 1.0f) },
	{ vec3(-0.5f,  0.5f,  0.5f),  vec3(-1.0f,  0.0f, 0.0f),  vec2(1.0f, 0.0f) },
	{ vec3(-0.5f,  0.5f, -0.5f),  vec3(-1.0f,  0.0f, 0.0f),  vec2(1.0f, 1.0f) },
	{ vec3(-0.5f, -0.5f, -0.5f),  vec3(-1.0f,  0.0f, 0.0f),  vec2(0.0f, 1.0f) },
	{ vec3(-0.5f, -0.5f,  0.5f),  vec3(-1.0f,  0.0f, 0.0f),  vec2(0.0f, 0.0f) },
	{ vec3( 0.5f,  0.5f,  0.5f),  vec3(1.0f,  0.0f,  0.0f),  vec2(1.0f, 0.0f) },
	{ vec3( 0.5f, -0.5f, -0.5f),  vec3(1.0f,  0.0f,  0.0f),  vec2(0.0f, 1.0f) },
	{ vec3( 0.5f,  0.5f, -0.5f),  vec3(1.0f,  0.0f,  0.0f),  vec2(1.0f, 1.0f) },
	{ vec3( 0.5f, -0.5f,  0.5f),  vec3(1.0f,  0.0f,  0.0f),  vec2(0.0f, 0.0f) },
	{ vec3(-0.5f, -0.5f, -0.5f),  vec3(0.0f, -1.0f,  0.0f),  vec2(0.0f, 1.0f) },
	{ vec3( 0.5f, -0.5f, -0.5f),  vec3(0.0f, -1.0f,  0.0f),  vec2(1.0f, 1.0f) },
	{ vec3( 0.5f, -0.5f,  0.5f),  vec3(0.0f, -1.0f,  0.0f),  vec2(1.0f, 0.0f) },
	{ vec3(-0.5f, -0.5f,  0.5f),  vec3(0.0f, -1.0f,  0.0f),  vec2(0.0f, 0.0f) },
	{ vec3( 0.5f,  0.5f, -0.5f),  vec3(0.0f,  1.0f,  0.0f),  vec2(1.0f, 1.0f) },
	{ vec3(-0.5f,  0.5f, -0.5f),  vec3(0.0f,  1.0f,  0.0f),  vec2(0.0f, 1.0f) },
	{ vec3( 0.5f,  0.5f,  0.5f),  vec3(0.0f,  1.0f,  0.0f),  vec2(1.0f, 0.0f) },
	{ vec3(-0.5f,  0.5f,  0.5f),  vec3(0.0f,  1.0f,  0.0f),  vec2(0.0f, 0.0f) },
	{ vec3(-0.5f,  0.5f, -0.5f),  vec3(0.0f,  1.0f,  0.0f),  vec2(0.0f, 1.0f) }
];

immutable Index[36] cubeIndices = [
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
	// Tangents
	glVertexAttribPointer(7, 3, GL_FLOAT, GL_FALSE, Vertex.sizeof, cast(void*)Vertex.tangent.offsetof);
	glEnableVertexAttribArray(7);

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
	calcTangents(cubeVertices);
	const tup = createIndexBuffer(cubeVertices);
	return genShapeElem(tup[0], tup[1]);
	//return genShapeElem(cubeElements, cubeIndices);
}

auto genQuad() {
	calcTangents(quadVertices);
	const tup = createIndexBuffer(quadVertices);
	return genShapeElem(tup[0], tup[1]);
	//return genShapeElem(quadElements, quadIndices);
}

auto genPoint() {
	return genShape(pointVertices);
}

// Given a vertex array, fills it with the calculated tangents and bitangents.
void calcTangents(Vertex[] vertices) {
	writeln("calculating ", vertices.length, " tangents.");
	for (int i = 0; i < vertices.length; i += 3) {
		const v0 = vertices[i].position;
		const v1 = vertices[i+1].position;
		const v2 = vertices[i+2].position;
		const uv0 = vertices[i].texCoords;
		const uv1 = vertices[i+1].texCoords;
		const uv2 = vertices[i+2].texCoords;

		const dv1 = v1.add(neg(v0));
		const dv2 = v2.add(neg(v0));
		const duv1 = uv1.add(neg(uv0));
		const duv2 = uv2.add(neg(uv0));

		const r = 1f / (duv1.x * duv2.y - duv1.y * duv2.x);
		const tangent = r * (dv1 * duv2.y - dv2 * duv1.y);
		const bitangent = r * (dv2 * duv1.x - dv1 * duv2.x);

		vertices[i].tangent = tangent;
		vertices[i+1].tangent = tangent;
		vertices[i+2].tangent = tangent;
		// TODO: just store the bitangent's handedness, as per http://terathon.com/code/tangent.html
		vertices[i].bitangent = bitangent;
		vertices[i+1].bitangent = bitangent;
		vertices[i+2].bitangent = bitangent;
	}
}

// Given a vertex array, returns a tuple (uniqued vertex array, indices array).
// NOTE: this function must be called *AFTER* `calcTangents`.
auto createIndexBuffer(Vertex[] vertices) pure {
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
		if (f >= 0) {
			indices ~= f;
			// Average tangents and bitangents
			newVertices[f].tangent = add(newVertices[f].tangent, v.tangent);
			newVertices[f].bitangent = add(newVertices[f].bitangent, v.bitangent);
		} else {
			newVertices ~= v;
			indices ~= cast(uint)newVertices.length - 1;
		}
	}

	return tuple(newVertices, indices);
}

