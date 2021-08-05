package zygame.data;

class Vertex {
	public var x:Float;

	public var y:Float;

	public var z:Float;

	public function new(x:Float, y:Float, z:Float) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public function toString():String {
		return "x=" + x + ",y=" + y + ",z=" + z;
	}
}
