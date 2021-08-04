package zygame.data.anim;

import zygame.data.anim.SkeletonPose;
import openfl.Vector;
import zygame.display3d.DisplayObject3D;

/**
 * 动画数据
 */
class AnimationClipNode {
	/**
	 * 动画名
	 */
	public var name:String = null;

	/**
	 * 骨骼
	 */
	public var poses:Vector<SkeletonPose> = new Vector();

	public function new(name:String) {
		this.name = name;
	}

	/**
	 * 更新
	 */
	public function update(dt:Float, display:DisplayObject3D):Void {
		// for (joint in skeleton.joints) {
		// 	// joint
		// }
	}

	public function getPoses(_time:Float):AnimationClipNodeTween {
		var obj:AnimationClipNodeTween = {
			startPose: null,
			endPose: null
		};
		var maxTime = poses[poses.length - 1].timestamp;
		_time %= maxTime;
		for (i in 0...poses.length) {
			var pose = poses[i];
			if (pose.timestamp >= _time) {
				if (i == 0) {
					obj.startPose = pose;
					obj.endPose = poses[i + 1];
				} else {
					obj.startPose = poses[i - 1];
					obj.endPose = pose;
				}
				break;
			}
		}
		return obj;
	}
}

typedef AnimationClipNodeTween = {
	startPose:SkeletonPose,
	endPose:SkeletonPose
}
