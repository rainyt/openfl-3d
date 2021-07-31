package zygame.data.anim;

import openfl.Vector;

/**
 * 蒙皮数据
 */
class Skin {

    /**
     * 皮肤ID
     */
    public var id:String;

	/**
	 * 绑定的JointId
	 */
	public var bindJointId:String;

	/**
	 * 顶点索引
	 */
	public var indexes:Vector<Int>;

	/**
	 * 权重值
	 */
	public var weights:Vector<Float>;

	public function new() {}
}
