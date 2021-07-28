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
			vertexIndex: [],
			uvs: [],
			uvsIndex: []
		};
		var array:Array<String> = data.split("\n");
		var uvs:Array<Float> = [];
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
				case "vt":
					// 顶点UV
					uvs.push(Std.parseFloat(strs[1]));
					uvs.push(Std.parseFloat(strs[2]));
					uvs.push(Std.parseFloat(strs[3]));
			}
		}

		for (index => value in obj.uvsIndex) {
			obj.uvs.push(uvs[value * 3]);
			obj.uvs.push(uvs[value * 3 + 1]);
			obj.uvs.push(uvs[value * 3 + 2]);
		}

		trace("obj", obj.uvs.length, obj.vertexIndex.length, obj.vertexPoint.length);
		return obj;
	}

	public static function parserIndex(data:ObjData, strs:Array<String>):Void {
		var array:Array<{v:Int, u:Int}> = [];
		for (i in 1...strs.length) {
			if (strs[i] == "")
				continue;
			var d = strs[i].split("/");
			array.push({
				v: Std.parseInt(d[0]) - 1,
				u: Std.parseInt(d[1]) - 1
			});
		}
		// 解析面
		var len = array.length;
		switch (len) {
			case 5:
				data.vertexIndex.push(parseIndex(array[0].v, data.vertexPoint.length));
				data.vertexIndex.push(parseIndex(array[1].v, data.vertexPoint.length));
				data.vertexIndex.push(parseIndex(array[2].v, data.vertexPoint.length));
				data.vertexIndex.push(parseIndex(array[0].v, data.vertexPoint.length));
				data.vertexIndex.push(parseIndex(array[2].v, data.vertexPoint.length));
				data.vertexIndex.push(parseIndex(array[3].v, data.vertexPoint.length));
				data.vertexIndex.push(parseIndex(array[0].v, data.vertexPoint.length));
				data.vertexIndex.push(parseIndex(array[3].v, data.vertexPoint.length));
				data.vertexIndex.push(parseIndex(array[4].v, data.vertexPoint.length));

				// UV
				data.uvsIndex.push(parseIndex(array[0].u, data.vertexPoint.length));
				data.uvsIndex.push(parseIndex(array[1].u, data.vertexPoint.length));
				data.uvsIndex.push(parseIndex(array[2].u, data.vertexPoint.length));
				data.uvsIndex.push(parseIndex(array[0].u, data.vertexPoint.length));
				data.uvsIndex.push(parseIndex(array[2].u, data.vertexPoint.length));
				data.uvsIndex.push(parseIndex(array[3].u, data.vertexPoint.length));
				data.uvsIndex.push(parseIndex(array[0].u, data.vertexPoint.length));
				data.uvsIndex.push(parseIndex(array[3].u, data.vertexPoint.length));
				data.uvsIndex.push(parseIndex(array[4].u, data.vertexPoint.length));
			case 4:
				data.vertexIndex.push(parseIndex(array[0].v, data.vertexPoint.length));
				data.vertexIndex.push(parseIndex(array[1].v, data.vertexPoint.length));
				data.vertexIndex.push(parseIndex(array[2].v, data.vertexPoint.length));
				data.vertexIndex.push(parseIndex(array[0].v, data.vertexPoint.length));
				data.vertexIndex.push(parseIndex(array[2].v, data.vertexPoint.length));
				data.vertexIndex.push(parseIndex(array[3].v, data.vertexPoint.length));

				// UV
				data.uvsIndex.push(parseIndex(array[0].u, data.vertexPoint.length));
				data.uvsIndex.push(parseIndex(array[1].u, data.vertexPoint.length));
				data.uvsIndex.push(parseIndex(array[2].u, data.vertexPoint.length));
				data.uvsIndex.push(parseIndex(array[0].u, data.vertexPoint.length));
				data.uvsIndex.push(parseIndex(array[2].u, data.vertexPoint.length));
				data.uvsIndex.push(parseIndex(array[3].u, data.vertexPoint.length));
			case 3:
				for (index => value in array) {
					data.vertexIndex.push(parseIndex(value.v, data.vertexPoint.length));
					data.uvsIndex.push(parseIndex(value.u, data.vertexPoint.length));
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
	public var uvs:Array<Float>;
	public var uvsIndex:Array<Int>;
}
