package zygame.data;

import zygame.data.anim.AnimationClipNode;
import zygame.data.anim.Skeleton;
import zygame.display3d.DisplayObject3D;
import openfl.Vector;

class Object3DBaseData {
	/**
	 * 模型形状列表
	 */
	public var geometrys:Map<String, GeometryData> = [];

	/**
	 * 当前解析数据的3D对象
	 */
	public var display3d:DisplayObject3D;

	/**
	 * 骨骼列表
	 */
	public var skeletons:Map<String, Skeleton> = [];

	/**
	 * 动画列表
	 */
	public var nodes:Map<String, AnimationClipNode> = [];

	public function new() {}

	/**
	 * 根据名字绑定模型形状
	 * @param name 
	 * @param geometry 
	 */
	public function setGeometry(name:String, geometry:GeometryData):Void {
		trace("add Geometry:", name);
		geometrys.set(name, geometry);
	}

	/**
	 * 根据名字获取模型形状
	 * @param name 
	 * @return Geometry
	 */
	public function getGeometry(name:String):GeometryData {
		return geometrys.get(name);
	}

	/**
	 * 根据名字绑定骨架
	 * @param name 
	 * @param geometry 
	 */
	public function setSkeleton(name:String, skeleton:Skeleton):Void {
		trace("add Skeleton:", name);
		skeletons.set(name, skeleton);
	}

	/**
	 * 根据名字获取骨架
	 * @param name 
	 * @return Geometry
	 */
	public function getSkeleton(name:String):Skeleton {
		return skeletons.get(name);
	}

	/**
	 * 根据名字绑定骨架
	 * @param name 
	 * @param geometry 
	 */
	public function setNodeClip(name:String, anim:AnimationClipNode):Void {
		trace("add AnimationClipNode:", name);
		nodes.set(name, anim);
	}

	/**
	 * 根据名字获取骨架
	 * @param name 
	 * @return Geometry
	 */
	public function getNodeClip(name:String):AnimationClipNode {
		return nodes.get(name);
	}

	public function getGeometryAt(arg0:Int):GeometryData {
		var k = geometrys.keys();
		for (s in k) {
			arg0--;
			if (arg0 < 0) {
				return getGeometry(s);
			}
		}
		return null;
	}
}
