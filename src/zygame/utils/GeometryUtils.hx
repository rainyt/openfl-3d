package zygame.utils;

import zygame.data.GeometryData;

/**
 * 模型工具
 */
class GeometryUtils {
	/**
	 * 合并多个模型
	 * @param mainGeometry 
	 * @param pushGeometry 
	 * @return GeometryData
	 */
	public static function merge(mainGeometry:GeometryData, pushGeometry:GeometryData):GeometryData {
		var geometry = mainGeometry;
		for (v in pushGeometry.uvs) {
			geometry.uvs.push(v);
		}
		var id = pushGeometry.getMaxIndicesId();
		for (v in pushGeometry.indicesArray) {
			geometry.indicesArray.push(v + id);
		}
		for (v in pushGeometry.uvsArray) {
			geometry.uvsArray.push(v);
		}
		for (v in pushGeometry.vertexNormals) {
			geometry.vertexNormals.push(v);
		}
		for (v in pushGeometry.vertexNormalsArray) {
			geometry.vertexNormalsArray.push(v);
		}
		for (v in pushGeometry.vertices) {
			geometry.vertices.push(v);
		}
		for (v in pushGeometry.verticesArray) {
			geometry.verticesArray.push(v);
		}
		return geometry;
	}
}
