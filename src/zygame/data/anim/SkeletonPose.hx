package zygame.data.anim;

import openfl.Vector;

class SkeletonPose {
	/**
	 * 骨骼列表
	 */
	public var joints:Vector<SkeletonJoint> = new Vector();

	public function new() {}

	/**
	 * 更新骨架
	 * @return Int
	 */
	public function updateJoints():Void {
		if (joints == null)
			return;
		for (i in 0...joints.length) {
			var joint = joints[i];
			if (joint.parent == null)
				joint.updatenverseBindPose();
			joint.index = i;
		}
	}
}
