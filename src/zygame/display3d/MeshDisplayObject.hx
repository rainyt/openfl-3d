package zygame.display3d;

import zygame.data.GeometryData;

/**
 * 网格对象
 */
class MeshDisplayObject extends DisplayObject3D {
	public function new(geomtryData:GeometryData) {
		super(geomtryData.getVertices(), geomtryData.getIndices(), geomtryData.getUVs());
		this.__geometryData = geomtryData;
	}

	override function copy():DisplayObject3D {
		trace("copy:",geometryData);
		var c = new MeshDisplayObject(geometryData);
		__childCopy(c);
		return c;
	}
}
