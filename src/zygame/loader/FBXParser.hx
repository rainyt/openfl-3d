package zygame.loader;

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

		trace("version=", version);
		trace("isMaya=", isMaya);

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
				for (c in child.childs) {
					parsingObject(c);
				}
		}
	}

	private function parsingObject(child:FbxNode) {
		if (child.name == "Geometry") {
			trace(child.name);
			for (index => value in child.childs.keyValueIterator()) {
				trace(value.name);
			}
			trace(child.get("Vertices").props[0].getParameters()[0]);
            trace(child.get("PolygonVertexIndex").props[0].getParameters()[0]);
            
		}
	}
}
