package zygame.loader;

import openfl.Vector;
import zygame.data.GeometryData;
import zygame.loader.fbx.Parser;
import haxe.io.Bytes;
import zygame.data.Object3DBaseData;

using zygame.loader.fbx.Data;

/**
 * FBX模型解析
 */
class FBXParser extends Object3DBaseData {
	/**
	 * FBX的原始数据
	 */
	public var root:FbxNode;

	/**
	 * 版本号
	 */
	public var version:Float = 0;

	/**
	 * 是否使用Maya导出
	 */
	public var isMaya:Bool = false;

	public function new(bytes:Bytes) {
		super();
		root = Parser.parse(bytes);
		version = root.get("FBXHeaderExtension.FBXVersion").props[0].toInt() / 1000;
		if (Std.int(version) != 7)
			throw "FBX Version 7.x required : use FBX 2010 export";

		for (p in root.getAll("FBXHeaderExtension.SceneInfo.Properties70.P"))
			if (p.props[0].toString() == "Original|ApplicationName") {
				isMaya = p.props[4].toString().toLowerCase().indexOf("maya") >= 0;
				break;
			}

		for (child in root.childs) {
			init(child);
		}
	}

	private function init(child:FbxNode) {
		trace("init", child.name);
		var type = child.name;
		switch (type) {
			case "Objects":
				// 解析模型
				var geometrys = child.getAll("Geometry");
				for (g in geometrys) {
					parsingGeometry(g);
				}
				var animationCurveNodes = child.getAll("AnimationCurveNode");
				for (a in animationCurveNodes) {
					parsingAnimate(a);
					break;
				}
				// for (c in child.childs) {
				// parsingObject(c);
				// }
		}
	}

	private function parsingAnimate(child:FbxNode):Void {
		for (c in child.childs) {
			trace(c);
		}
	}

	private function parsingGeometry(child:FbxNode) {
		if (child.name == "Geometry") {
			var geomtry = new GeometryData();
			// 获取顶点
			geomtry.verticesArray = new Vector(child.get("Vertices").getFloats().copy());
			// 获取索引
			var array = child.get("PolygonVertexIndex").getInts();
			var indices = [];
			var uvIndices = [];
			// UV索引对应
			var uvIndicesArray:Array<UInt> = [];
			var uvIndexs = child.get("LayerElementUV.UVIndex").getInts();
			for (index => value in array) {
				uvIndices.push(uvIndexs[index]);
				if (value < 0) {
					array[index] = -value - 1;
					indices.push(array[index]);
					// 开始写入顶点
					switch (indices.length) {
						case 4:
							// 4边形
							geomtry.indicesArray.push(indices[0]);
							geomtry.indicesArray.push(indices[1]);
							geomtry.indicesArray.push(indices[2]);
							geomtry.indicesArray.push(indices[0]);
							geomtry.indicesArray.push(indices[2]);
							geomtry.indicesArray.push(indices[3]);

							uvIndicesArray.push(uvIndices[0]);
							uvIndicesArray.push(uvIndices[1]);
							uvIndicesArray.push(uvIndices[2]);
							uvIndicesArray.push(uvIndices[0]);
							uvIndicesArray.push(uvIndices[2]);
							uvIndicesArray.push(uvIndices[3]);
						case 3:
							// 3边形
							geomtry.indicesArray.push(indices[0]);
							geomtry.indicesArray.push(indices[1]);
							geomtry.indicesArray.push(indices[2]);

							uvIndicesArray.push(uvIndices[0]);
							uvIndicesArray.push(uvIndices[1]);
							uvIndicesArray.push(uvIndices[2]);
					}
					indices = [];
					uvIndices = [];
				} else
					indices.push(value);
			}
			// 获取UV
			var uvs = child.get("LayerElementUV.UV").getFloats();

			for (index => value in uvIndicesArray) {
				var vIdx = geomtry.indicesArray[index];
				if (geomtry.uvsArray[vIdx * 2] == null) {
					geomtry.uvsArray[vIdx * 2] = uvs[value * 2];
					geomtry.uvsArray[vIdx * 2 + 1] = 1 - uvs[value * 2 + 1];
				}
			}

			this.setGeometry("g" + child.getId(), geomtry);
		}
	}
}
