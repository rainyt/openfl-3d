package openfl.loader;

import openfl.Assets;
import zygame.utils.AssetsUtils;

/**
 * OBJ模型加载器
 */
class ObjLoader {
	public function new(path:String, cb:ObjData->Void) {
		AssetsUtils.loadText(path).onComplete(function(data) {
			cb(ObjUtils.parser(data));
		});
	}
}

class ObjUtils {
	public static function parser(data:String):ObjData {
		var obj:ObjData = {
			vertexPoint: [],
			vertexIndex: []
		};
		var array:Array<String> = data.split("\n");
		for (index => value in array) {
			var strs = value.split(" ");
			switch (strs[0]) {
				case "v":
					// 顶点坐标
					obj.vertexPoint.push(Std.parseFloat(strs[1]));
					obj.vertexPoint.push(Std.parseFloat(strs[2]));
					obj.vertexPoint.push(Std.parseFloat(strs[3]));
				case "f":
					// 顶点索引
					parserIndex(obj, strs);
			}
		}
		trace("obj", obj.vertexIndex.length, obj.vertexPoint.length);
		return obj;
	}

	public static function parserIndex(data:ObjData, strs:Array<String>):Void {
		var array:Array<Int> = [];
		for (i in 1...strs.length) {
			if (strs[i] == "")
				continue;
			var d = strs[i].split("/");
			array.push(Std.parseInt(d[0]) - 1);
		}
		// 解析面
		var len = array.length;
		switch (len) {
			case 5:
			case 4:
				data.vertexIndex.push(parseIndex(array[0], data.vertexPoint.length));
				data.vertexIndex.push(parseIndex(array[1], data.vertexPoint.length));
				data.vertexIndex.push(parseIndex(array[2], data.vertexPoint.length));
				data.vertexIndex.push(parseIndex(array[2], data.vertexPoint.length));
				data.vertexIndex.push(parseIndex(array[3], data.vertexPoint.length));
				data.vertexIndex.push(parseIndex(array[0], data.vertexPoint.length));
			case 3:
				for (index => value in array) {
					data.vertexIndex.push(parseIndex(value, data.vertexPoint.length));
				}
		}
	}

	/**
	 * This is a hack around negative face coords
	 */
	private static function parseIndex(index:Int, length:Int):Int {
		if (index < 0)
			return index + length + 1;
		else
			return index;
	}
}

typedef ObjData = {
	public var vertexPoint:Array<Float>;

	public var vertexIndex:Array<Int>;
}
