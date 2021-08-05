package zygame.display3d;

import openfl.display.BitmapData;

/**
 * 3D使用的材质
 */
class BitmapData3D {
	/**
	 * 指定材质是否存在透明部分
	 */
	public var transparent:Bool = false;

	/**
	 * 指定材质是否需要双面渲染
	 */
	public var doubleSide:Bool = false;

	/**
	 * 纹理对象
	 */
	public var texture:BitmapData;

	public function new(bitmapData:BitmapData) {
		this.texture = bitmapData;
	}
}
