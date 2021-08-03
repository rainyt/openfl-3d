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
	 * 骨骼姿势，0永远存放0帧骨架
	 */
	public var poses:Vector<SkeletonPose> = new Vector();

	/**
	 * 指定Pose渲染索引
	 */
	public var poseIndex:Int = 0;

	public var joints(get, never):Vector<SkeletonJoint>;

	function get_joints():Vector<SkeletonJoint> {
		if (poses[poseIndex] == null) {
			return null;
		}
		return poses[poseIndex].joints;
	}

	public function new() {}

	function get_numJoints():Int {
		if (poses.length == 0)
			return 0;
		return poses[0].joints.length;
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
