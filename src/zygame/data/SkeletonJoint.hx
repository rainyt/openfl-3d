package zygame.data;

import lime.math.Matrix4;

class SkeletonJoint {
	/**
	 * 父节点骨骼的索引
	 */
	public var parentIndex:Int = -1;

	/**
	 * 骨骼名字
	 */
	public var name:String;

	/**
	 * 反向绑定姿势矩阵作为原始数据，用于变换顶点以绑定关节空间，以准备使用关节矩阵进行变换。
	 */
	public var inverseBindPose:Matrix4;

	public function new() {}
}
