package zygame.loader;

import haxe.macro.Expr.Error;
import openfl.Vector;
import zygame.data.Object3DBaseData;
import zygame.data.UV;
import zygame.data.Vertex;

/**
 * 用于解析OBJ格式模型
 */
class OBJParser extends Object3DBaseData {
	public var faces:Array<FaceData> = [];

	private var _realIndices:Map<String, Int>;

	private var _vertexIndex:Int = 0;

	public function new(data:String) {
		super();
		var datas = data.split("\n");
		for (index => value in datas) {
			parseLine(value.split(" "));
		}
		translateMaterialGroup();
	}

	/**
	 * Parses a single line in the OBJ file.
	 */
	private function parseLine(trunk:Array<String>):Void {
		switch (trunk[0]) {
			case "mtllib":
			// _mtlLib = true;
			// _mtlLibLoaded = false;
			// loadMtl(trunk[1]);
			case "g":
			// createGroup(trunk);
			case "o":
			// createObject(trunk);
			case "usemtl":
			// if (_mtlLib) {
			// 	if (trunk[1] == "")
			// 		trunk[1] = "def000";
			// 	_materialIDs.push(trunk[1]);
			// 	_activeMaterialID = trunk[1];
			// 	if (_currentGroup != null)
			// 		_currentGroup.materialID = _activeMaterialID;
			// }
			case "v":
				parseVertex(trunk);
			case "vt":
				parseUV(trunk);
			case "vn":
			// parseVertexNormal(trunk);
			case "f":
				parseFace(trunk);
		}
	}

	/**
	 * Reads the next vertex coordinates.
	 * @param trunk The data block containing the vertex tag and its parameters
	 */
	private function parseVertex(trunk:Array<String>):Void {
		// for the very rare cases of other delimiters/charcodes seen in some obj files
		if (trunk.length > 4) {
			var nTrunk:Array<Float> = [];
			var val:Float;
			for (i in 1...trunk.length) {
				val = Std.parseFloat(trunk[i]);
				if (!Math.isNaN(val))
					nTrunk.push(val);
			}
			vertices.push(new Vertex(nTrunk[0], nTrunk[1], -nTrunk[2]));
		} else
			vertices.push(new Vertex(Std.parseFloat(trunk[1]), Std.parseFloat(trunk[2]), -Std.parseFloat(trunk[3])));
	}

	/**
	 * Reads the next uv coordinates.
	 * @param trunk The data block containing the uv tag and its parameters
	 */
	private function parseUV(trunk:Array<String>):Void {
		if (trunk.length > 3) {
			var nTrunk:Array<Float> = [];
			var val:Float;
			for (i in 1...trunk.length) {
				val = Std.parseFloat(trunk[i]);
				if (!Math.isNaN(val))
					nTrunk.push(val);
			}
			uvs.push(new UV(nTrunk[0], 1 - nTrunk[1]));
		} else
			uvs.push(new UV(Std.parseFloat(trunk[1]), 1 - Std.parseFloat(trunk[2])));
	}

	/**
	 * Reads the next face's indices.
	 * @param trunk The data block containing the face tag and its parameters
	 */
	private function parseFace(trunk:Array<String>):Void {
		var len:Int = trunk.length;
		var face:FaceData = new FaceData();

		// if (_currentGroup == null)
		// 	createGroup(null);

		var indices:Array<String>;
		for (i in 1...len) {
			if (trunk[i] == "")
				continue;
			indices = trunk[i].split("/");
			face.vertexIndices.push(parseIndex(Std.parseInt(indices[0]), vertices.length));
			if (indices[1] != null && indices[1].length > 0)
				face.uvIndices.push(parseIndex(Std.parseInt(indices[1]), uvs.length));
			// if (indices[2] != null && indices[2].length > 0)
			// 	face.normalIndices.push(parseIndex(Std.parseInt(indices[2]), _vertexNormals.length));
			face.indexIds.push(trunk[i]);
		}

		faces.push(face);
		// _currentMaterialGroup.faces.push(face);
	}

	/**
	 * This is a hack around negative face coords
	 */
	private function parseIndex(index:Int, length:Int):Int {
		if (index < 0)
			return index + length + 1;
		else
			return index;
	}

	/**
	 * Translates an obj's material group to a subgeometry.
	 * @param materialGroup The material group data to convert.
	 * @param geometry The Geometry to contain the converted SubGeometry.
	 */
	private function translateMaterialGroup():Void {
		_realIndices = [];
		_vertexIndex = 0;
		var numFaces:UInt = faces.length;
		for (i in 0...numFaces) {
			var face = faces[i];
			var numVerts = face.indexIds.length - 1;
			var normals = null;
			for (j in 1...numVerts) {
				translateVertexData(face, j, verticesArray, uvsArray, indicesArray, normals);
				translateVertexData(face, 0, verticesArray, uvsArray, indicesArray, normals);
				translateVertexData(face, j + 1, verticesArray, uvsArray, indicesArray, normals);
			}
		}
	}

	private function translateVertexData(face:FaceData, vertexIndex:Int, vertices:Vector<Float>, uvs:Vector<Float>, indices:Vector<UInt>,
			normals:Vector<Float>):Void {
		var index:Int;
		var vertex:Vertex;
		var vertexNormal:Vertex;
		var uv:UV;

		if (!_realIndices.exists(face.indexIds[vertexIndex])) {
			index = _vertexIndex;
			_realIndices.set(face.indexIds[vertexIndex], ++_vertexIndex);
			vertex = this.vertices[face.vertexIndices[vertexIndex] - 1];
			vertices.push(vertex.x * 1);
			vertices.push(vertex.y * 1);
			vertices.push(vertex.z * 1);

			// if (face.normalIndices.length > 0) {
			// 	vertexNormal = _vertexNormals[face.normalIndices[vertexIndex] - 1];
			// 	normals.push(vertexNormal.x);
			// 	normals.push(vertexNormal.y);
			// 	normals.push(vertexNormal.z);
			// }

			if (face.uvIndices.length > 0) {
				try {
					uv = this.uvs[face.uvIndices[vertexIndex] - 1];
					uvs.push(uv.u);
					uvs.push(uv.v);
				} catch (e:Error) {
					switch (vertexIndex) {
						case 0:
							uvs.push(0);
							uvs.push(1);
						case 1:
							uvs.push(.5);
							uvs.push(0);
						case 2:
							uvs.push(1);
							uvs.push(1);
					}
				}
			}
		} else
			index = _realIndices.get(face.indexIds[vertexIndex]) - 1;

		indices.push(index);
	}
}

class FaceData {
	public var vertexIndices:Vector<UInt> = new Vector<UInt>();
	public var uvIndices:Vector<UInt> = new Vector<UInt>();
	public var normalIndices:Vector<UInt> = new Vector<UInt>();
	public var indexIds:Vector<String> = new Vector<String>(); // used for real index lookups

	public function new() {}
}
