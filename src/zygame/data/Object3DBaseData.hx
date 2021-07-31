package zygame.data;

import zygame.display3d.DisplayObject3D;
import openfl.Vector;

class Object3DBaseData {
	public var geometrys:Map<String, GeometryData> = [];

	/**
	 * 当前解析数据的3D对象
	 */
	public var display3d:DisplayObject3D;

	public function new() {}

	/**
	 * 根据名字绑定模型形状
	 * @param name 
	 * @param geometry 
	 */
	public function setGeometry(name:String, geometry:GeometryData):Void {
		trace("add Geometry:", name);
		geometrys.set(name, geometry);
	}

	/**
	 * 根据名字获取模型形状
	 * @param name 
	 * @return Geometry
	 */
	public function getGeometry(name:String):GeometryData {
		return geometrys.get(name);
	}

	public function getGeometryAt(arg0:Int):GeometryData {
		var k = geometrys.keys();
		for (s in k) {
			arg0--;
			if (arg0 < 0) {
				return getGeometry(s);
			}
		}
		return null;
	}
}
