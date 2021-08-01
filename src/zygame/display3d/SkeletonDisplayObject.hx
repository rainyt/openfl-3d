package zygame.display3d;

import zygame.data.anim.Skeleton;

/**
 * 用于渲染skeleton的显示对象
 */
class SkeletonDisplayObject extends DisplayObject3D {
	public function new(skeleton:Skeleton) {
		super();
		var joints:Map<String, CubeDisplayObject> = [];
		for (joint in skeleton.joints) {
			var display:CubeDisplayObject = new CubeDisplayObject();
			// display.scale(0.1);
			joints.set(joint.id, display);
			display.x = joint.x;
			display.y = joint.y;
			display.scaleX = joint.scaleX;
			display.scaleY = joint.scaleY;
			display.scaleZ = joint.scaleZ;
			display.rotationX = joint.rotationX;
			display.rotationY = joint.rotationY;
			display.rotationZ = joint.rotationZ;
			// display.transform3D = joint.inverseBindPose;
		}

		for (joint in skeleton.joints) {
			var parentJoint = joints.get(joint.parentId);
			var selfJoint = joints.get(joint.id);
			if (parentJoint != null)
				parentJoint.addChild(selfJoint);
			else
				this.addChild(selfJoint);
		}
	}
}
