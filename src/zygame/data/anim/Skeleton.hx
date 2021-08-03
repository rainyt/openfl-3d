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
	 * 骨架会有一个默认姿势
	 */
	public var pose:SkeletonPose;

	/**
	 * 指定Pose渲染索引
	 */
	public var poseIndex:Int = 0;

	public var joints(get, never):Vector<SkeletonJoint>;

	function get_joints():Vector<SkeletonJoint> {
		return pose == null ? null : pose.joints;
	}

	public function new() {}

	function get_numJoints():Int {
		return pose == null ? 0 : pose.joints.length;
	}

	/**
	 * 通过名字获取骨骼 
	 * @param jointName 骨骼名称
	 * @return 返回骨骼
	 */
	public function jointFromName(jointName:String):SkeletonJoint {
		if (joints == null)
			return null;
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
		if (joints == null)
			return null;
		var jointIndex:Int = 0;
		for (joint in joints) {
			if (joint.name == jointName)
				return jointIndex;
			jointIndex++;
		}
		return -1;
	}

	/**
	 * 通过ID获取骨骼 
	 * @param jointName 骨骼名称
	 * @return 返回骨骼
	 */
	public function jointFromId(jointId:String):SkeletonJoint {
		if (joints == null)
			return null;
		var jointIndex:Int = jointIndexFromId(jointId);
		if (jointIndex != -1)
			return joints[jointIndex];
		else
			return null;
	}

	/**
	 * 通过ID获取骨骼Index
	 * @param jointName 骨骼名称
	 */
	public function jointIndexFromId(jointId:String):Int {
		if (joints == null)
			return null;
		var jointIndex:Int = 0;
		for (joint in joints) {
			if (joint.id == jointId)
				return jointIndex;
			jointIndex++;
		}
		return -1;
	}
}
