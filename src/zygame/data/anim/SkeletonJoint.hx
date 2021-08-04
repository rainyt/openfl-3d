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
	 * 是否为一个独立的节点
	 */
	public var independentJoint:Bool = false;

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

	/**
	 * 可能存在一个偏移值，如果存在，则与结果矩阵相乘
	 */
	public var transPos:Matrix4;

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

	/**
	 * 更新默认矩阵，但需要先调用updatenverseBindPose
	 */
	public function updateTransPos():Void {
		if (transPos != null && inverseBindPose != null)
			inverseBindPose.prepend(transPos);
	}

	/**
	 * 这里的拷贝不会拷贝parent和childs
	 * @return SkeletonJoint
	 */
	public function copy():SkeletonJoint {
		var joint = new SkeletonJoint();
		joint.name = name;
		joint.independentJoint = independentJoint;
		joint.parentId = parentId;
		joint.id = id;
		joint.index = index;
		joint.rotationX = rotationX;
		joint.rotationY = rotationY;
		joint.rotationZ = rotationZ;
		joint.scaleX = scaleX;
		joint.scaleY = scaleY;
		joint.scaleZ = scaleZ;
		joint.x = x;
		joint.y = y;
		joint.z = z;
		joint.transPos = transPos;
		return joint;
	}
}
