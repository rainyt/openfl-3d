package zygame.display3d;

import zygame.data.GeometryData;

/**
 * 网格对象
 */
class MeshDisplayObject extends DisplayObject3D {
	public function new(geomtryData:GeometryData) {
		super(geomtryData.getVertices(), geomtryData.getIndices(), geomtryData.getUVs());
		this.__geometryData = geomtryData;
		// if (geomtryData == null || geomtryData.getVertices().length == 0 || geomtryData.getIndices().length == 0)
			// throw "无效的GeometryData数据";
	}
}
