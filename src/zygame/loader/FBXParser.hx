package zygame.loader;

import haxe.Json;
import zygame.data.SkeletonJoint;
import zygame.data.Skeleton;
import openfl.Vector;
import zygame.data.GeometryData;
import zygame.loader.fbx.Parser;
import haxe.io.Bytes;
import zygame.data.Object3DBaseData;

using zygame.loader.fbx.Data;

/**
 * FBX模型解析
 */
class FBXParser extends Object3DBaseData {
	/**
	 * FBX的原始数据
	 */
	public var root:FbxNode;

	/**
	 * 版本号
	 */
	public var version:Float = 0;

	/**
	 * 是否使用Maya导出
	 */
	public var isMaya:Bool = false;

	public var fileName:String = "";

	private var ids:Map<Int, FbxNode> = [];
	private var connect:Map<Int, Array<Int>> = [];
	private var namedConnect:Map<Int, Map<String, Int>> = [];
	private var invConnect:Map<Int, Array<Int>> = [];

	public function new(bytes:Bytes) {
		super();
		root = Parser.parse(bytes);
		version = root.get("FBXHeaderExtension.FBXVersion").props[0].toInt() / 1000;
		if (Std.int(version) != 7)
			throw "FBX Version 7.x required : use FBX 2010 export";

		for (p in root.getAll("FBXHeaderExtension.SceneInfo.Properties70.P"))
			if (p.props[0].toString() == "Original|ApplicationName") {
				isMaya = p.props[4].toString().toLowerCase().indexOf("maya") >= 0;
				break;
			}

		// 先初始化ID
		for (child in root.childs) {
			this.initFbxNode(child);
		}

		trace(invConnect);
		for (child in root.childs) {
			init(child);
		}
		
		// fileName = root.getAll("Takes.Take.FileName")[0].props[0].toString();
		// trace(root.getAll("Takes.Take"));
		// trace(root.getAll("Takes.Take.LocalTime"));
		// trace(root.getAll("Takes.Take.ReferenceTime"));
	}

	private function init(child:FbxNode) {
		trace("init", child.name);
		var type = child.name;
		switch (type) {
			case "Objects":
				// 解析模型
				for (c in child.childs) {
					trace(c.name, c.getName());
				}
				var geometrys = child.getAll("Geometry");
				for (g in geometrys) {
					parsingGeometry(g);
				}

				parsingModel(child.getAll("Model"));

				// var animationCurveNodes = child.getAll("AnimationCurveNode");
				// trace("animationCurveNodes.length=", animationCurveNodes.length);
				// for (a in animationCurveNodes) {
				// 	parsingAnimate(a);
				// }
		}
	}

	private function parsingModel(array:Array<FbxNode>):Void {
		if (array.length == 0) {
			return;
		}
		trace("创建骨骼");
		var rootJoint = new FBXJoint();
		var objects:Array<FBXJoint> = [];
		var hobjects = new Map<Int, FBXJoint>();
		var skeleton = new Skeleton();
		for (index => model in array) {
			var mtype = model.getType();
			if (mtype != "LimbNode")
				continue;
			var o = new FBXJoint();
			var joint = new SkeletonJoint();
			joint.name = model.getName();
			skeleton.joints.push(joint);
			o.model = model;
			o.joint = joint;
			objects.push(o);
			hobjects.set(model.getId(), o);
		}

		trace("\n\n");
		trace(Json.stringify(skeleton));
		trace("\n\n");

		for (o in objects) {
			var p = getParent(o.model, "Model", true);
			var pid = if (p == null) 0 else p.getId();
			var op = hobjects.get(pid);
			if (op == null)
				op = rootJoint; // if parent has been removed
			op.childs.push(o);
			o.joint.parentIndex = op.model != null ? op.model.getId() : -1;
			o.parent = op;
			trace(o.model.getName());
		}

		trace("rootJoint.length", rootJoint.childs.length);
		trace("objects.length", Json.stringify(skeleton.joints));

		// var isJoint = mtype == "LimbNode" && (!unskinnedJointsAsObjects || !isNullJoint(model));
		// var o = new TmpObject();
		// o.model = model;
		// o.isJoint = isJoint;
		// o.isMesh = mtype == "Mesh";
		// hobjects.set(model.getId(), o);
		// objects.push(o);
	}

	// private function getDefaultMatrixes(model:FbxNode) {
	// 	var id = model.getId();
	// 	var d = defaultModelMatrixes.get(id);
	// 	if (d != null)
	// 		return d;
	// 	d = new DefaultMatrixes();
	// 	var F = Math.PI / 180;
	// 	for (p in model.getAll("Properties70.P"))
	// 		switch (p.props[0].toString()) {
	// 			case "GeometricTranslation":
	// 			// handle in Geometry directly
	// 			case "PreRotation":
	// 				d.preRot = new Point(round(p.props[4].toFloat() * F), round(p.props[5].toFloat() * F), round(p.props[6].toFloat() * F));
	// 				if (d.preRot.x == 0 && d.preRot.y == 0 && d.preRot.z == 0)
	// 					d.preRot = null;
	// 			case "Lcl Rotation":
	// 				d.rotate = new Point(round(p.props[4].toFloat() * F), round(p.props[5].toFloat() * F), round(p.props[6].toFloat() * F));
	// 				if (d.rotate.x == 0 && d.rotate.y == 0 && d.rotate.z == 0)
	// 					d.rotate = null;
	// 			case "Lcl Translation":
	// 				d.trans = new Point(round(p.props[4].toFloat()), round(p.props[5].toFloat()), round(p.props[6].toFloat()));
	// 				if (d.trans.x == 0 && d.trans.y == 0 && d.trans.z == 0)
	// 					d.trans = null;
	// 			case "Lcl Scaling":
	// 				d.scale = new Point(round(p.props[4].toFloat()), round(p.props[5].toFloat()), round(p.props[6].toFloat()));
	// 				if (d.scale.x == 1 && d.scale.y == 1 && d.scale.z == 1)
	// 					d.scale = null;
	// 			default:
	// 		}
	// 	if (model.getType() == "LimbNode")
	// 		updateDefaultMatrix(model, d);
	// 	defaultModelMatrixes.set(id, d);
	// 	return d;
	// }

	/**
	 * 初始化FbxNode的ID索引
	 * @param n 
	 */
	private function initFbxNode(n:FbxNode) {
		switch (n.name) {
			case "Connections":
				for (c in n.childs) {
					if (c.name != "C")
						continue;
					var child = c.props[1].toInt();
					var parent = c.props[2].toInt();

					// Maya exports invalid references
					if (ids.get(child) == null || ids.get(parent) == null)
						continue;

					var name = c.props[3];

					if (name != null) {
						var name = name.toString();
						var nc = namedConnect.get(parent);
						if (nc == null) {
							nc = new Map();
							namedConnect.set(parent, nc);
						}
						nc.set(name, child);
						// don't register as a parent, since the target can also be the child of something else
						if (name == "LookAtProperty")
							continue;
					}

					var c = connect.get(parent);
					if (c == null) {
						c = [];
						connect.set(parent, c);
					}
					c.push(child);

					if (parent == 0)
						continue;

					var c = invConnect.get(child);
					if (c == null) {
						c = [];
						invConnect.set(child, c);
					}
					c.push(parent);
				}
			case "Objects":
				for (c in n.childs)
					ids.set(c.getId(), c);
			default:
		}
	}

	private function parsingAnimate(child:FbxNode):Void {
		for (c in child.childs) {
			trace(c.name);
		}
	}

	private function parsingGeometry(child:FbxNode) {
		if (child.name == "Geometry") {
			var geomtry = new GeometryData();
			// 获取顶点
			geomtry.verticesArray = new Vector(child.get("Vertices").getFloats().copy());
			// 获取索引
			var array = child.get("PolygonVertexIndex").getInts();
			var indices = [];
			var uvIndices = [];
			// UV索引对应
			var uvIndicesArray:Array<UInt> = [];
			var element = child.get("LayerElementUV.UVIndex", true);
			var uvIndexs = element == null ? null : element.getInts();
			for (index => value in array) {
				if (uvIndexs != null)
					uvIndices.push(uvIndexs[index]);
				if (value < 0) {
					array[index] = -value - 1;
					indices.push(array[index]);
					// 开始写入顶点
					switch (indices.length) {
						case 4:
							// 4边形
							geomtry.indicesArray.push(indices[0]);
							geomtry.indicesArray.push(indices[1]);
							geomtry.indicesArray.push(indices[2]);
							geomtry.indicesArray.push(indices[0]);
							geomtry.indicesArray.push(indices[2]);
							geomtry.indicesArray.push(indices[3]);

							if (uvIndexs != null) {
								uvIndicesArray.push(uvIndices[0]);
								uvIndicesArray.push(uvIndices[1]);
								uvIndicesArray.push(uvIndices[2]);
								uvIndicesArray.push(uvIndices[0]);
								uvIndicesArray.push(uvIndices[2]);
								uvIndicesArray.push(uvIndices[3]);
							}
						case 3:
							// 3边形
							geomtry.indicesArray.push(indices[0]);
							geomtry.indicesArray.push(indices[1]);
							geomtry.indicesArray.push(indices[2]);
							if (uvIndexs != null) {
								uvIndicesArray.push(uvIndices[0]);
								uvIndicesArray.push(uvIndices[1]);
								uvIndicesArray.push(uvIndices[2]);
							}
					}
					indices = [];
					uvIndices = [];
				} else
					indices.push(value);
			}

			if (uvIndicesArray.length > 0) {
				// 获取UV
				var uvs = child.get("LayerElementUV.UV").getFloats();

				for (index => value in uvIndicesArray) {
					var vIdx = geomtry.indicesArray[index];
					if (geomtry.uvsArray[vIdx * 2] == null) {
						geomtry.uvsArray[vIdx * 2] = uvs[value * 2];
						geomtry.uvsArray[vIdx * 2 + 1] = 1 - uvs[value * 2 + 1];
					}
				}
			}

			this.setGeometry("g" + child.getId(), geomtry);
		}
	}

	public function getParent(node:FbxNode, nodeName:String, ?opt:Bool) {
		var p = getParents(node, nodeName);
		if (p.length > 1)
			throw node.getName() + " has " + p.length + " " + nodeName + " parents " + [for (o in p) o.getName()].join(",");
		if (p.length == 0 && !opt)
			throw "Missing " + node.getName() + " " + nodeName + " parent";
		return p[0];
	}

	public function getParents(node:FbxNode, ?nodeName:String) {
		var c = invConnect.get(node.getId());
		var pl = [];
		if (c != null)
			for (id in c) {
				var n = ids.get(id);
				if (n == null)
					throw id + " not found";
				if (nodeName != null && n.name != nodeName)
					continue;
				pl.push(n);
			}
		return pl;
	}

	
}

class FBXJoint {
	public var joint:SkeletonJoint;

	public var model:FbxNode;

	public var parent:FBXJoint;

	public var childs:Array<FBXJoint> = [];

	public function new() {}
}
