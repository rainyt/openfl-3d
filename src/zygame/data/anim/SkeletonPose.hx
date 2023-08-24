package zygame.data.anim;

import openfl.Vector;

/**
 * 骨骼姿势
 */
class SkeletonPose {
	/**
	 * 时间戳
	 */
	public var timestamp:Float = 0;

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
			if (joint.parent == null) {
				joint.updatenverseBindPose();
			}
			joint.index = i;
		}
		for (i in 0...joints.length) {
			var joint = joints[i];
			joint.updateTransPos();
		}
	}

	public function copy():SkeletonPose {
		var pose = new SkeletonPose();
		pose.timestamp = this.timestamp;
		var map = new Map<String, SkeletonJoint>();
		for (joint in joints) {
			var j = joint.copy();
			pose.joints.push(j);
			map.set(j.id, j);
		}
		// 将pose关系重构
		for (joint in pose.joints) {
			if (joint.parentId != null) {
				var parentJoint = map.get(joint.parentId);
				if (parentJoint != null) {
					parentJoint.childs.push(joint);
					joint.parent = parentJoint;
				} else {
					joint.parent = parentJoint;
				}
			}
		}
		return pose;
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
	public function jointIndexFromName(jointName:String):Null<Int> {
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
	public function jointIndexFromId(jointId:String):Null<Int> {
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
