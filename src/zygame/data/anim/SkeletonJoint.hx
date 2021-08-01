package zygame.data.anim;

import lime.math.Matrix4;

class SkeletonJoint {
	/**
	 * 父节点骨骼的索引
	 */
	public var parentId:String = null;

	/**
	 * 骨骼名字
	 */
	public var name:String;

	/**
	 * 骨骼节点ID
	 */
	public var id:String;

	/**
	 * 反向绑定姿势矩阵作为原始数据，用于变换顶点以绑定关节空间，以准备使用关节矩阵进行变换。
	 */
	// public var inverseBindPose:Matrix4;
	public var scaleX:Float = 1;

	public var scaleY:Float = 1;

	public var scaleZ:Float = 1;

	public var rotationX:Float = 0;

	public var rotationY:Float = 0;

	public var rotationZ:Float = 0;

	public var x:Float = 0;

	public var y:Float = 0;

	public var z:Float = 0;

	public function new() {}
}
