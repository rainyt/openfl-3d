package zygame.data.anim;

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
	public var skeleton:Skeleton;

	public function new(name:String) {
		this.name = name;
	}

	/**
	 * 更新
	 */
	public function update(dt:Float, display:DisplayObject3D):Void {
		for (joint in skeleton.joints) {
			// joint
		}
	}
}
