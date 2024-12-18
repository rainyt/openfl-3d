package zygame.display3d;

import openfl.Vector;

/**
 * 立方体3D对象
 */
class CubeDisplayObject extends DisplayObject3D {
	public function new() {
		var value = .5;
		var v:Vector<Float> = new Vector([ // 正面
			- value,
			-value,
			value,
			value,
			-value,
			value,
			value,
			value,
			value,
			-value,
			value,
			value,

			// 背面
			- value,
			-value,
			-value,
			-value,
			value,
			-value,
			value,
			value,
			-value,
			value,
			-value,
			-value,

			// 顶面
			- value,
			value,
			-value,
			-value,
			value,
			value,
			value,
			value,
			value,
			value,
			value,
			-value,

			// 底面
			- value,
			-value,
			-value,
			value,
			-value,
			-value,
			value,
			-value,
			value,
			-value,
			-value,
			value,

			// 右面
			value,
			-value,
			-value,
			value,
			value,
			-value,
			value,
			value,
			value,
			value,
			-value,
			value,

			// 左面
			- value,
			-value,
			-value,
			-value,
			-value,
			value,
			-value,
			value,
			value,
			-value,
			value,
			-value]);
		var i:Vector<UInt> = new Vector([
			0,
			1,
			2,
			0,
			2,
			3, // 正面
			4,
			5,
			6,
			4,
			6,
			7, // 背面
			8,
			9,
			10,
			8,
			10,
			11, // 顶面
			12,
			13,
			14,
			12,
			14,
			15, // 底面
			16,
			17,
			18,
			16,
			18,
			19, // 右面
			20,
			21,
			22,
			20,
			22,
			23 // 左面
		]);

		var uvs:Vector<Float> = new Vector([
			// 正面
			0.0,
			0.0,
			1.0,
			0.0,
			1.0,
			1.0,
			0.0,
			1.0,

			// 背面
			1.0,
			0.0,
			1.0,
			1.0,
			0.0,
			1.0,
			0.0,
			0.0,

			// 顶面
			0.0,
			1.0,
			0.0,
			0.0,
			1.0,
			0.0,
			1.0,
			1.0,

			// 底面
			1.0,
			1.0,
			0.0,
			1.0,
			0.0,
			0.0,
			1.0,
			0.0,

			// 右面
			1.0,
			0.0,
			1.0,
			1.0,
			0.0,
			1.0,
			0.0,
			0.0,

			// 左面
			0.0,
			0.0,
			1.0,
			0.0,
			1.0,
			1.0,
			0.0,
			1.0,
		]);

		super(v, i, uvs);
	}

	override function copy():DisplayObject3D {
		var c = new CubeDisplayObject();
		__childCopy(c);
		return c;
	}
}
