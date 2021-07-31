package zygame.display3d;

import zygame.data.anim.Skeleton;

/**
 * 用于渲染skeleton的显示对象
 */
class SkeletonDisplayObject extends DisplayObject3D {
	public function new(skeleton:Skeleton) {
		super();
		for (joint in skeleton.joints) {
			var display:CubeDisplayObject = new CubeDisplayObject();
			this.addChild(display);
			display.transform3D = joint.inverseBindPose;
		}
	}
}
