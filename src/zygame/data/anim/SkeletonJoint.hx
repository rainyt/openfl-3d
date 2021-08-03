package zygame.data.anim;

import lime.math.Vector4;
import lime.math.Matrix4;

class SkeletonJoint {
	/**
	 * 数组索引ID
	 */
	public var index:Int = -1;

	/**
	 * 父节点骨骼的索引
	 */
	public var parentId:String = null;

	/**
	 * 父节点
	 */
	public var parent:SkeletonJoint;

	/**
	 * 子节点
	 */
	public var childs:Array<SkeletonJoint> = [];

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
	public var inverseBindPose:Matrix4;

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

	private var __transform3D:Matrix4;

	public function updatenverseBindPose():Void {
		__transform3D = new Matrix4();
		__transform3D.appendScale(this.scaleX, this.scaleY, this.scaleZ);
		__transform3D.appendRotation(rotationX, new Vector4(1, 0, 0, 0));
		__transform3D.appendRotation(rotationY, new Vector4(0, 1, 0, 0));
		__transform3D.appendRotation(rotationZ, new Vector4(0, 0, 1, 0));
		__transform3D.appendTranslation(this.x, this.y, this.z);
		if (this.parent == null) {
			inverseBindPose = __transform3D;
		} else {
			inverseBindPose = this.parent.inverseBindPose.clone();
			inverseBindPose.prepend(__transform3D);
		}
		for (index => value in childs) {
			value.updatenverseBindPose();
		}
	}
}
