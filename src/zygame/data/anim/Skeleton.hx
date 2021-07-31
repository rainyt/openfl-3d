package zygame.data.anim;

import openfl.Vector;

/**
 * 骨架
 */
class Skeleton {
	/**
	 * 骨骼数量
	 */
	public var numJoints(get, never):Int;

	/**
	 * 骨骼列表
	 */
	public var joints:Vector<SkeletonJoint> = new Vector();

	public function new() {}

	function get_numJoints():Int {
		return joints.length;
	}

	/**
	 * 通过名字获取骨骼 
	 * @param jointName 骨骼名称
	 * @return 返回骨骼
	 */
	public function jointFromName(jointName:String):SkeletonJoint {
		var jointIndex:Int = jointIndexFromName(jointName);
		if (jointIndex != -1)
			return joints[jointIndex];
		else
			return null;
	}

	/**
	 * 通过名字获取骨骼Index
	 * @param jointName 骨骼名称
	 */
	public function jointIndexFromName(jointName:String):Int {
		var jointIndex:Int = 0;
		for (joint in joints) {
			if (joint.name == jointName)
				return jointIndex;
			jointIndex++;
		}
		return -1;
	}
}
