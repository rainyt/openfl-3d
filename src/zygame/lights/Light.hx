package zygame.lights;

import zygame.data.Vertex;

class Light {
	/**
	 * 方向
	 */
	public var direction:Vertex;

	public function new(x:Float, y:Float, z:Float) {
		direction = new Vertex(x, y, z);
	}
}
