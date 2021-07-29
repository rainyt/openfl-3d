package zygame.loader;

import haxe.Json;
import zygame.loader.fbx.Parser;
import haxe.io.Bytes;
import zygame.data.Object3DBaseData;

/**
 * FBX模型解析
 */
class FBXParser extends Object3DBaseData {
	public function new(bytes:Bytes) {
		super();
		var node = Parser.parse(bytes);
		trace(Json.stringify(node));
	}
}
