package zygame.data;

import openfl.Vector;

class Object3DBaseData {
	private var geometrys:Map<String, GeometryData> = [];

	public function new() {}

	/**
	 * 根据名字绑定模型形状
	 * @param name 
	 * @param geometry 
	 */
	public function setGeometry(name:String, geometry:GeometryData):Void {
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
}
