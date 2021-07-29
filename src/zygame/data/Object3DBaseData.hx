package zygame.data;

import openfl.Vector;

class Object3DBaseData {
	/**
	 * 顶点数组数据
	 */
	public var vertices:Array<Vertex> = [];

	/**
	 * 纹理数据
	 */
	public var uvs:Array<UV> = [];

	/**
	 * 法线，未支持
	 */
	public var vertexNormals:Array<Dynamic>;

	/**
	 * 顶点索引
	 */
	public var indicesArray:Vector<UInt> = new Vector();

	public var uvsArray:Vector<Float> = new Vector();

	public var verticesArray:Vector<Float> = new Vector();

	public function new() {}

	/**
	 * 获取顶点坐标的数组
	 * @return Array<Float>
	 */
	public function getVertices():Vector<Float> {
		if (verticesArray.length == 0) {
			var array:Vector<Float> = new Vector();
			for (index => value in vertices) {
				array.push(value.x);
				array.push(value.y);
				array.push(value.z);
			}
			return array;
		}
		return verticesArray;
	}

	/**
	 * 获取顶点索引
	 * @return Array<Int>
	 */
	public function getIndices():Vector<Int> {
		return indicesArray;
	}

	public function getUVs():Vector<Float> {
		if (uvsArray.length == 0) {
			var array:Vector<Float> = new Vector();
			for (index => value in uvs) {
				array.push(value.u);
				array.push(value.v);
			}
			return array;
		} else {
			return uvsArray;
		}
	}
}
