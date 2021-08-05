package zygame.data.anim;

import lime.math.Matrix4;

/**
 * 动画状态
 */
class AnimationState {
	/**
	 * 动画姿势映射
	 */
	private var _anims:Map<String, AnimationClipNode> = [];

	/**
	 * 骨架
	 */
	public var skeleton:Skeleton;

	/**
	 * 当前插值Pose
	 */
	public var currentPose:SkeletonPose;

	/**
	 * 当前播放的NODE
	 */
	public var currentAnimationClipNode:AnimationClipNode;

	public var time(get, never):Float;

	private var _time:Float = 0;

	function get_time():Float {
		return _time;
	}

	public function new(skeleton:Skeleton, anims:Array<AnimationClipNode>) {
		this.skeleton = skeleton;
		this.currentPose = skeleton.pose.copy();
		this.currentPose.updateJoints();
		for (node in anims) {
			_anims.set(node.name, node);
		}
	}

	/**
	 * 更新动画
	 * @param dt 
	 */
	public function update(dt:Float):Void {
		if (currentAnimationClipNode == null)
			return;
		_time += dt;
		var poses = currentAnimationClipNode.getPoses(_time);
		if (poses.startPose != null && poses.endPose != null) {
			// 开始更新骨骼动画
			var p = poses.endPose.timestamp - poses.startPose.timestamp;
			var p2 = _time % p / p;
			for (i in 0...currentPose.joints.length) {
				var joint = currentPose.joints[i];
				var startJoint = poses.startPose.joints[i];
				var endJoint = poses.endPose.joints[i];
				if (joint.independentJoint) {
					// 独立的节点
					joint.x = startJoint.x + (endJoint.x - startJoint.x) * p2;
					joint.y = startJoint.y + (endJoint.y - startJoint.y) * p2;
					joint.z = startJoint.z + (endJoint.z - startJoint.z) * p2;
					joint.rotationX = startJoint.rotationX + (endJoint.rotationX - startJoint.rotationX) * p2;
					joint.rotationY = startJoint.rotationY + (endJoint.rotationY - startJoint.rotationY) * p2;
					joint.rotationZ = startJoint.rotationZ + (endJoint.rotationZ - startJoint.rotationZ) * p2;
					joint.scaleX = startJoint.scaleX + (endJoint.scaleX - startJoint.scaleX) * p2;
					joint.scaleY = startJoint.scaleX + (endJoint.scaleX - startJoint.scaleX) * p2;
					joint.scaleZ = startJoint.scaleX + (endJoint.scaleX - startJoint.scaleX) * p2;
					joint.transPos = startJoint.transPos;
				} else {
					Matrix4.interpolate(startJoint.inverseBindPose, endJoint.inverseBindPose, p2, joint.inverseBindPose);
				}
			}
		}
	}

	/**
	 * 播放动画
	 * @param name 
	 */
	public function play(name:String):Void {
		_time = 0;
		currentAnimationClipNode = _anims.get(name);
	}
}
