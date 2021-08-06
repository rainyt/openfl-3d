package zygame.loader;

import haxe.Exception;
import zygame.data.anim.AnimationClipNode;
import zygame.data.anim.SkeletonPose;
import lime.utils.Float32Array;
import lime.math.Vector4;
import lime.math.Matrix4;
import haxe.Json;
import zygame.display3d.MeshDisplayObject;
import zygame.display3d.DisplayObject3D;
import zygame.data.Vertex;
import zygame.data.anim.SkeletonJoint;
import zygame.data.anim.Skeleton;
import openfl.Vector;
import zygame.data.GeometryData;
import zygame.loader.fbx.Parser;
import haxe.io.Bytes;
import zygame.data.anim.Deformer;
import zygame.data.anim.Skin;
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

	var defaultModelMatrixes:Map<Int, DefaultMatrixes> = [];

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

		autoMerge();

		for (child in root.childs) {
			init(child);
		}

		// loadAnimate 加载动画
		this.loadAnimate();

	}

	public function loadAnimate():Void {
		var animName = null;
		var defNode = null;
		var animNodes = [];
		for (a in this.root.getAll("Objects.AnimationStack"))
			if (animName == null || a.getName() == animName) {
				for (n in getChilds(a, "AnimationLayer")) {
					defNode = n;
					if (getChilds(n, "AnimationCurveNode").length > 0)
						animNodes.push(n);
				}
			}
		var animNode = switch (animNodes.length) {
			case 0:
				defNode;
			case 1:
				animNodes[0];
			default:
				trace("Multiple animation layers curves are currently not supported");
				animNodes[0];
		}

		if (animNode == null) {
			if (animName != null)
				throw "Animation not found " + animName;
			// if (uvAnims == null)
			// return null;
		}

		try {
			if (animName == null)
				animName = getParent(animNode, "AnimationStack").getName();
		} catch (e:Exception) {
			return;
		}

		var curves = new Map();
		var P0 = new Vertex(0, 0, 0);
		var P1 = new Vertex(1, 1, 1);
		// var F = Math.PI / 180;
		var F = 1;
		var allTimes = new Map();

		if (animNode != null)
			for (cn in getChilds(animNode, "AnimationCurveNode")) {
				var model = getParent(cn, "Model", true);
				if (model == null) {
					switch (cn.getName()) {
						case "Roll", "FieldOfView":
							// the parent is not a Model but a NodeAttribute
							var nattr = getParent(cn, "NodeAttribute", true);
							model = nattr == null ? null : getParent(nattr, "Model", true);
							if (model == null)
								continue;
						default:
							continue; // morph support
					}
				}

				var c = getObjectCurve(curves, model, cn.getName(), animName);
				if (c == null)
					continue;

				var dataCurves = getChilds(cn, "AnimationCurve");
				if (dataCurves.length == 0)
					continue;

				var cname = cn.getName();
				// collect all the timestamps
				var times = dataCurves[0].get("KeyTime").getFloats();
				for (i in 0...times.length) {
					var t = times[i];
					// fix rounding error
					if (t % 100 != 0) {
						t += 100 - (t % 100);
						times[i] = t;
					}
					// this should give significant-enough key
					var it = Std.int(t / 200000);
					allTimes.set(it, t);
				}

				// handle special curves
				if (dataCurves.length != 3) {
					var values = dataCurves[0].get("KeyValueFloat").getFloats();
					switch (cname) {
						case "Visibility":
							if (!roundValues(values, 1))
								continue;
							c.a = {
								v: values,
								t: times,
							};
							continue;
						case "Roll":
							if (!roundValues(values, 0))
								continue;
							c.roll = {
								v: values,
								t: times,
							};
							continue;
						case "FieldOfView":
							var ratio = 16 / 9, fov = 45.;
							for (p in getChild(model, "NodeAttribute").getAll("Properties70.P")) {
								switch (p.props[0].toString()) {
									case "FilmAspectRatio": ratio = p.props[4].toFloat();
									case "FieldOfView": fov = p.props[4].toFloat();
									default:
								}
							}
							inline function fovXtoY(v:Float) {
								return 2 * Math.atan(Math.tan(v * 0.5 * Math.PI / 180) / ratio) * 180 / Math.PI;
							}
							for (i in 0...values.length)
								values[i] = fovXtoY(values[i]);
							if (!roundValues(values, fovXtoY(fov)))
								continue;
							c.fov = {
								v: values,
								t: times,
							};
							continue;
						default:
					}
				}
				// handle TRS curves
				var data = {
					x: null,
					y: null,
					z: null,
					t: times,
				};

				var curves = namedConnect.get(cn.getId());
				for (cname in curves.keys()) {
					var values = ids.get(curves.get(cname)).get("KeyValueFloat").getFloats();
					switch (cname) {
						case "d|X":
							data.x = values;
						case "d|Y":
							data.y = values;
						case "d|Z":
							data.z = values;
						default:
							trace("Unsupported key name " + cname);
					}
				}

				// this can happen when resampling anims due to rounding errors, let's ignore it for now
				// if( data.y.length != times.length || data.z.length != times.length )
				//	throw "Unsynchronized curve components on " + model.getName()+"."+cname+" (" + data.x.length + "/" + data.y.length + "/" + data.z.length + ")";
				// optimize empty animations out
				var M = 1.0;
				var def = switch (cname) {
					case "T":
						if (c.def.trans == null) P0 else c.def.trans;
					case "R":
						M = F;
						if (c.def.rotate == null && c.def.preRot == null) P0 else if (c.def.rotate == null) c.def.preRot else if (c.def.preRot == null)
							c.def.rotate else {
							new Vertex(1, 1, 1);
							// var q = new h3d.Quat(), q2 = new h3d.Quat();
							// q2.initRotation(c.def.preRot.x, c.def.preRot.y, c.def.preRot.z);
							// q.initRotation(c.def.rotate.x, c.def.rotate.y, c.def.rotate.z);
							// q.multiply(q2, q);
							// q.toEuler().toPoint();
						}
					case "S":
						if (c.def.scale == null) P1 else c.def.scale;
					default:
						trace("Unknown curve " + model.getName() + "." + cname);
						continue;
				}
				var hasValue = false;
				if (data.x != null && roundValues(data.x, def.x, M))
					hasValue = true;
				if (data.y != null && roundValues(data.y, def.y, M))
					hasValue = true;
				if (data.z != null && roundValues(data.z, def.z, M))
					hasValue = true;
				// no meaningful value found
				if (!hasValue)
					continue;
				var keyCount = 0;
				if (data.x != null)
					keyCount = data.x.length;
				if (data.y != null)
					keyCount = data.y.length;
				if (data.z != null)
					keyCount = data.z.length;
				if (data.x == null)
					data.x = [for (i in 0...keyCount) def.x];
				if (data.y == null)
					data.y = [for (i in 0...keyCount) def.y];
				if (data.z == null)
					data.z = [for (i in 0...keyCount) def.z];
				switch (cname) {
					case "T":
						c.t = data;
					case "R":
						c.r = data;
					case "S":
						c.s = data;
					default:
						throw "assert";
				}
			}

		trace("动画名：", animName, animNodes.length);
		trace(Json.stringify(allTimes));

		var allTimes = [for (a in allTimes) a];

		// trace(allTimes);
		var skeleton:Skeleton = getSkeleton("main");
		var node = new AnimationClipNode(animName);
		var maxTime = allTimes[allTimes.length - 1];

		for (index => t in allTimes) {
			// 开始创建姿势
			var pose = skeleton.pose.copy();
			pose.timestamp = t / 200000 / 200 / 1000;
			var iterator = curves.iterator();
			var lastpose = node.poses.length > 0 ? node.poses[node.poses.length - 1] : null;
			while (iterator.hasNext()) {
				var obj = iterator.next();
				var joint = pose.jointFromName(obj.object);
				var lastjoint = lastpose != null ? lastpose.jointFromName(obj.object) : null;
				if (joint == null) {
					continue;
				}
				// 平移
				var tansIndex = obj.t != null ? obj.t.t.indexOf(t) : -1;
				if (tansIndex != -1) {
					joint.x = obj.t.x[tansIndex];
					joint.y = obj.t.y[tansIndex];
					joint.z = obj.t.z[tansIndex];
				} else {
					// 不存在过渡的时候，是否考虑拷贝上一帧
					if (lastjoint != null) {
						joint.x = lastjoint.x;
						joint.y = lastjoint.y;
						joint.z = lastjoint.z;
					}
				}
				// 旋转
				var rotaIndex = obj.r != null ? obj.r.t.indexOf(t) : -1;
				if (rotaIndex != -1) {
					joint.rotationX = obj.r.x[rotaIndex];
					joint.rotationY = obj.r.y[rotaIndex];
					joint.rotationZ = obj.r.z[rotaIndex];
				} else {
					// 不存在过渡的时候，是否考虑拷贝上一帧
					if (lastjoint != null) {
						joint.rotationX = lastjoint.rotationX;
						joint.rotationY = lastjoint.rotationY;
						joint.rotationZ = lastjoint.rotationZ;
					}
				}
				// 缩放
				var scaleIndex = obj.s != null ? obj.s.t.indexOf(t) : -1;
				if (scaleIndex != -1) {
					joint.scaleX = obj.s.x[scaleIndex];
					joint.scaleY = obj.s.y[scaleIndex];
					joint.scaleZ = obj.s.z[scaleIndex];
				} else {
					// 不存在过渡的时候，是否考虑拷贝上一帧
					if (lastjoint != null) {
						joint.scaleX = lastjoint.scaleX;
						joint.scaleY = lastjoint.scaleY;
						joint.scaleZ = lastjoint.scaleZ;
					}
				}
				if (joint.independentJoint) {
					// 形状偏移值
					var model = ids.get(Std.parseInt(joint.id.substr(1)));
					var def = getDefaultMatrixes(model);
					joint.transPos = def.transPos == null ? new Matrix4() : def.transPos.clone();
					if (def.geomtrans != null) {
						joint.transPos.appendTranslation(def.geomtrans.x, def.geomtrans.y, def.geomtrans.z);
					}
				}
			}
			pose.updateJoints();
			node.poses.push(pose);
		}
		this.setNodeClip(node.name, node);
	}

	function getObjectCurve(curves:Map<Int, AnimCurve>, model:FbxNode, curveName:String, animName:String):AnimCurve {
		var c = curves.get(model.getId());
		if (c != null)
			return c;
		var name = model.getName();
		// if (skipObjects.get(name))
		// 	return null;
		var def = getDefaultMatrixes(model);
		if (def == null)
			return null;
		// if it's a move animation on a terminal unskinned joint, let's skip it
		var isMove = curveName != "Visibility" && curveName != "UV";
		if (def.wasRemoved != null && (isMove || def.wasRemoved == -1))
			return null;
		// allow not move animations on root model
		if (def.wasRemoved != null && def.wasRemoved != -2) {
			// apply it on the skin instead
			model = ids.get(def.wasRemoved);
			name = model.getName();
			c = curves.get(def.wasRemoved);
			def = getDefaultMatrixes(model);
			// todo : change behavior not to remove the mesh but the skin instead!
			if (def == null)
				throw "assert";
		}
		if (c == null) {
			c = new AnimCurve(def, name);
			curves.set(model.getId(), c);
		}
		return c;
	}

	function roundValues(data:Array<Float>, def:Float, mult:Float = 1.) {
		var hasValue = false;
		for (i in 0...data.length) {
			var v = data[i] * mult;
			if (Math.abs(v - def) > 1e-3)
				hasValue = true;
			else
				v = def;
			data[i] = round(v);
		}
		return hasValue;
	}

	private function getAllModels() {
		return this.root.getAll("Objects.Model");
	}

	private function init(child:FbxNode) {
		var type = child.name;
		switch (type) {
			case "Objects":
				// 解析模型
				var geometrys = child.getAll("Geometry");
				for (g in geometrys) {
					parsingGeometry(g);
				}
				buildHierarchy(getAllModels());
		}
	}

	function autoMerge() {
		// if we have multiple deformers on the same joint, let's merge the geometries
		var toMerge = [], mergeGroups = new Map<Int, Array<FbxNode>>();
		for (model in getAllModels()) {
			// if (skipObjects.get(model.getName()))
			// 	continue;
			var mtype = model.getType();
			var isJoint = mtype == "LimbNode" && (!isNullJoint(model));
			if (!isJoint)
				continue;
			var deformers = getParents(model, "Deformer");
			if (deformers.length <= 1)
				continue;
			var group = [];
			for (d in deformers) {
				var def = getParent(d, "Deformer");
				if (def == null)
					continue;
				var geom = getParent(def, "Geometry");
				if (geom == null)
					continue;
				var model2 = getParent(geom, "Model");
				if (model2 == null)
					continue;

				var id = model2.getId();
				var g = mergeGroups.get(id);
				if (g != null) {
					for (g in g) {
						group.remove(g);
						group.push(g);
					}
					toMerge.remove(g);
				}
				group.remove(model2);
				group.push(model2);
				mergeGroups.set(id, group);
			}
			toMerge.push(group);
		}
		for (group in toMerge) {
			group.sort(function(m1, m2) return Reflect.compare(m1.getName(), m2.getName()));
			for (g in toMerge)
				if (g != group) {
					var found = false;
					for (m in group)
						if (g.remove(m))
							found = true;
					if (found)
						g.push(group[0]);
				}
			trace("需要合并：", [for (g in group) g.getName()]);
			// mergeModels([for (g in group) g.getName()]);
		}
		trace("合并结束");
	}

	// public function mergeModels(modelNames:Array<String>) {
	// 	if (modelNames.length <= 1)
	// 		return;
	// 	var models = getAllModels();
	// 	function getModel(name) {
	// 		for (m in models)
	// 			if (m.getName() == name)
	// 				return m;
	// 		throw "Model not found " + name;
	// 		return null;
	// 	}
	// 	var m = getModel(modelNames[0]);
	// 	var geom = new Geometry(this, getChild(m, "Geometry"));
	// 	var def = getChild(geom.getRoot(), "Deformer", true);
	// 	var subDefs = getChilds(def, "Deformer");
	// 	for (i in 1...modelNames.length) {
	// 		var name = modelNames[i];
	// 		var m2 = getModel(name);
	// 		var geom2 = new Geometry(this, getChild(m2, "Geometry"));
	// 		var vcount = Std.int(geom.getVertices().length / 3);
	// 		skipObjects.set(name, true);
	// 		// merge materials
	// 		var mindex = [];
	// 		var materials = getChilds(m, "Material");
	// 		for (mat in getChilds(m2, "Material")) {
	// 			var idx = materials.indexOf(mat);
	// 			if (idx < 0) {
	// 				idx = materials.length;
	// 				materials.push(mat);
	// 				addLink(m, mat);
	// 			}
	// 			mindex.push(idx);
	// 		}
	// 		// merge geometry
	// 		geom.merge(geom2, mindex);
	// 		// merge skinning
	// 		var def2 = getChild(geom2.getRoot(), "Deformer", true);
	// 		if (def2 != null) {
	// 			if (def == null)
	// 				throw m.getName() + " does not have a deformer but " + name + " has one";
	// 			for (subDef in getChilds(def2, "Deformer")) {
	// 				var subModel = getChild(subDef, "Model");
	// 				var prevDef = null;
	// 				for (s in subDefs)
	// 					if (getChild(s, "Model") == subModel) {
	// 						prevDef = s;
	// 						break;
	// 					}
	// 				if (prevDef != null)
	// 					removeLink(subDef, subModel);
	// 				var idx = subDef.get("Indexes", true);
	// 				if (idx == null)
	// 					continue;
	// 				if (prevDef == null) {
	// 					addLink(def, subDef);
	// 					removeLink(def2, subDef);
	// 					subDefs.push(subDef);
	// 					var idx = idx.getInts();
	// 					for (i in 0...idx.length)
	// 						idx[i] += vcount;
	// 				} else {
	// 					var pidx = prevDef.get("Indexes").getInts();
	// 					for (i in idx.getInts())
	// 						pidx.push(i + vcount);
	// 					var weights = prevDef.get("Weights").getFloats();
	// 					for (w in subDef.get("Weights").getFloats())
	// 						weights.push(w);
	// 				}
	// 			}
	// 		}
	// 	}
	// }

	private function buildHierarchy(array:Array<FbxNode>):Void {
		if (array.length == 0) {
			return;
		}
		var rootJoint = new FBXJoint();
		var objects:Array<FBXJoint> = [];
		var hobjects = new Map<Int, FBXJoint>();
		var skeleton = new Skeleton();
		var skeletonPose = new SkeletonPose();
		for (index => model in array) {
			var mtype = model.getType();
			var isJoint = (mtype == "LimbNode" && !isNullJoint(model) || mtype == "Root");
			var o = new FBXJoint();
			o.isJoint = isJoint;
			o.isMesh = mtype == "Mesh";
			if (isJoint || o.isMesh) {
				// 节点
				var joint = new SkeletonJoint();
				joint.name = model.getName();
				if (isJoint)
					joint.id = "j" + model.getId();
				else
					joint.id = "m" + model.getId();
				skeletonPose.joints.push(joint);
				o.joint = joint;
				joint.independentJoint = o.isMesh;
			}
			o.model = model;
			o.defaultMatrixes = getDefaultMatrixes(model);
			objects.push(o);
			// 绑定节点的骨骼矩阵
			o.inverseBindPose();

			hobjects.set(model.getId(), o);
		}

		for (o in objects) {
			var p = getParent(o.model, "Model", true);
			var pid = if (p == null) 0 else p.getId();
			var op = hobjects.get(pid);
			if (op == null)
				op = rootJoint; // if parent has been removed
			op.childs.push(o);
			if (o.joint != null) {
				o.joint.parentId = op.model != null ? "j" + op.model.getId() : null;
				if (op.joint != null) {
					o.joint.parent = op.joint;
					op.joint.childs.push(o.joint);
				}
			}
			o.parent = op;
		}

		// 更新偏移矩阵
		for (o in objects) {
			if (o.joint == null)
				continue;
			if (o.defaultMatrixes.transPos != null) {
				o.joint.transPos = o.defaultMatrixes.transPos;
			}
		}
		skeletonPose.updateJoints();
		skeleton.pose = skeletonPose;
		skeletons.set("main", skeleton);

		#if !undisplay
		display3d = new DisplayObject3D();
		#end
		for (o in objects) {
			if (!o.isMesh)
				continue;
			var g = getChild(o.model, "Geometry");
			var gdata = this.getGeometry("g" + g.getId());
			#if !undisplay
			var mesh = new MeshDisplayObject(gdata);
			display3d.addChild(mesh);
			if (o.joint != null)
				mesh.name = o.joint.name;
			getDefaultMatrixes(o.model).initMesh(mesh);
			#end
			// 变形器绑定
			var def = this.getChild(g, "Deformer", true);
			if (def != null) {
				// 该模型有变形器绑定
				var exportDeformer = new Deformer();
				var defs = this.getChilds(def, "Deformer");
				for (def2 in defs) {
					var skin:Skin = new Skin();
					skin.id = "s" + def2.getId();
					skin.bindJointId = "j" + connect.get(def2.getId())[0];
					var nodeIndexes = def2.get("Indexes", true);
					var nodeWeights = def2.get("Weights", true);
					if (nodeIndexes != null)
						skin.indexes = new Vector(nodeIndexes.getInts());
					if (nodeWeights != null)
						skin.weights = new Vector(nodeWeights.getFloats());
					exportDeformer.skins.push(skin);
				}
				// 让网格绑定变形器
				gdata.deformer = exportDeformer;
				// trace(Json.stringify(exportDeformer));
			}
		}
	}

	/**
	 * 计算深度
	 * @param o 
	 */
	inline function getDepth(o:FBXJoint) {
		var k = 0;
		while (o.parent != null) {
			o = o.parent;
			k++;
		}
		return k;
	}

	function isNullJoint(model:FbxNode) {
		if (getParents(model, "Deformer").length > 0) {
			return false;
		}
		var parent = getParent(model, "Model", true);
		if (parent == null) {
			return true;
		}
		var t = parent.getType();
		if (t == "LimbNode" || t == "Root")
			return false;
		return true;
	}

	function addLink(parent:FbxNode, child:FbxNode) {
		var pid = parent.getId();
		var nid = child.getId();
		connect.get(pid).push(nid);
		invConnect.get(nid).push(pid);
	}

	function removeLink(parent:FbxNode, child:FbxNode) {
		var pid = parent.getId();
		var nid = child.getId();
		connect.get(pid).remove(nid);
		invConnect.get(nid).remove(pid);
	}

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
				for (c in n.childs) {
					ids.set(c.getId(), c);
				}
			default:
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

	public function getChild(node:FbxNode, nodeName:String, ?opt:Bool) {
		var c = getChilds(node, nodeName);
		// if (c.length > 1)
		// throw node.getName() + " has " + c.length + " " + nodeName + " childs " + [for (o in c) o.getName()].join(",");
		if (c.length == 0 && !opt)
			throw "Missing " + node.getName() + " " + nodeName + " child";
		return c[0];
	}

	public function getSpecChild(node:FbxNode, name:String) {
		var nc = namedConnect.get(node.getId());
		if (nc == null)
			return null;
		var id = nc.get(name);
		if (id == null)
			return null;
		return ids.get(id);
	}

	public function getChilds(node:FbxNode, ?nodeName:String) {
		var c = connect.get(node.getId());
		var subs = [];
		if (c != null)
			for (id in c) {
				var n = ids.get(id);
				if (n == null)
					throw id + " not found";
				if (nodeName != null && n.name != nodeName)
					continue;
				subs.push(n);
			}
		return subs;
	}

	public function getParent(node:FbxNode, nodeName:String, ?opt:Bool) {
		var p = getParents(node, nodeName);
		// if (p.length > 1)
		// throw node.getName() + " has " + p.length + " " + nodeName + " parents " + [for (o in p) o.getName()].join(",");
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

	private function getDefaultMatrixes(model:FbxNode):DefaultMatrixes {
		var id = model.getId();
		var d = defaultModelMatrixes.get(id);
		if (d != null)
			return d;
		d = new DefaultMatrixes();
		// var F = Math.PI / 180;
		var F = 1;
		for (p in model.getAll("Properties70.P"))
			switch (p.props[0].toString()) {
				case "GeometricTranslation":
					// handle in Geometry directly
					d.geomtrans = new Vertex(round(p.props[4].toFloat()), round(p.props[5].toFloat()), round(p.props[6].toFloat()));
				case "PreRotation":
					d.preRot = new Vertex(round(p.props[4].toFloat() * F), round(p.props[5].toFloat() * F), round(p.props[6].toFloat() * F));
					if (d.preRot.x == 0 && d.preRot.y == 0 && d.preRot.z == 0)
						d.preRot = null;
				case "Lcl Rotation":
					d.rotate = new Vertex(round(p.props[4].toFloat() * F), round(p.props[5].toFloat() * F), round(p.props[6].toFloat() * F));
					if (d.rotate.x == 0 && d.rotate.y == 0 && d.rotate.z == 0)
						d.rotate = null;
				case "Lcl Translation":
					d.trans = new Vertex(round(p.props[4].toFloat()), round(p.props[5].toFloat()), round(p.props[6].toFloat()));
					if (d.trans.x == 0 && d.trans.y == 0 && d.trans.z == 0)
						d.trans = null;
				case "Lcl Scaling":
					d.scale = new Vertex(round(p.props[4].toFloat()), round(p.props[5].toFloat()), round(p.props[6].toFloat()));
					if (d.scale.x == 1 && d.scale.y == 1 && d.scale.z == 1)
						d.scale = null;
				default:
			}

		if (model.getType() == "LimbNode") {
			var subDef = getParent(model, "Deformer", true);
			if (subDef != null) {
				d.transPos = new Matrix4(new Float32Array(subDef.get("Transform").getFloats()));
			}
			defaultModelMatrixes.set(id, d);
		}
		return d;
	}

	private function round(v:Float) {
		if (v != v)
			throw "NaN found";
		return std.Math.fround(v * 131072) / 131072;
	}
}

class FBXJoint {
	public var joint:SkeletonJoint;

	public var model:FbxNode;

	public var parent:FBXJoint;

	public var childs:Array<FBXJoint> = [];

	public var isJoint:Bool = false;

	public var isMesh:Bool = false;

	public var defaultMatrixes:DefaultMatrixes;

	public function new() {}

	public function inverseBindPose():Void {
		if (defaultMatrixes != null && joint != null) {
			defaultMatrixes.init(joint);
		}
	}
}

class DefaultMatrixes {
	public var geomtrans:Null<Vertex>;
	public var trans:Null<Vertex>;
	public var scale:Null<Vertex>;
	public var rotate:Null<Vertex>;
	public var preRot:Null<Vertex>;
	public var wasRemoved:Null<Int>;

	public function new() {}

	public function initMesh(mesh:DisplayObject3D):Void {
		if (scale != null) {
			mesh.scaleX = this.scale.x;
			mesh.scaleX = this.scale.y;
			mesh.scaleZ = this.scale.z;
		}
		if (rotate != null) {
			mesh.rotationX = rotate.x * 180 / Math.PI;
			mesh.rotationY = rotate.y * 180 / Math.PI;
			mesh.rotationZ = rotate.z * 180 / Math.PI;
		}
		if (preRot != null) {
			mesh.rotationX += preRot.x * 180 / Math.PI;
			mesh.rotationY += preRot.y * 180 / Math.PI;
			mesh.rotationZ += preRot.z * 180 / Math.PI;
		}
		if (trans != null) {
			mesh.x = trans.x;
			mesh.y = trans.y;
			mesh.z = trans.z;
		}
	}

	public function init(joint:SkeletonJoint):Void {
		if (scale != null) {
			joint.scaleX = this.scale.x;
			joint.scaleX = this.scale.y;
			joint.scaleX = this.scale.z;
		}
		if (rotate != null) {
			joint.rotationX = rotate.x;
			joint.rotationY = rotate.y;
			joint.rotationZ = rotate.z;
		}
		if (trans != null) {
			joint.x = trans.x;
			joint.y = trans.y;
			joint.z = trans.z;
		}
	}

	public var transPos:Matrix4;

	public function toMatrix4():Matrix4 {
		var m4 = new Matrix4();
		if (scale != null) {
			m4.appendScale(scale.x, scale.y, scale.z);
		}
		if (rotate != null) {
			m4.appendRotation(rotate.x, new Vector4(1, 0, 0, 0));
			m4.appendRotation(rotate.y, new Vector4(0, 1, 0, 0));
			m4.appendRotation(rotate.z, new Vector4(0, 0, 1, 0));
		}
		if (trans != null) {
			m4.appendTranslation(trans.x, trans.y, trans.z);
		}
		return m4;
	}
}

private class AnimCurve {
	public var def:DefaultMatrixes;
	public var object:String;
	public var t:{
		t:Array<Float>,
		x:Array<Float>,
		y:Array<Float>,
		z:Array<Float>
	};
	public var r:{
		t:Array<Float>,
		x:Array<Float>,
		y:Array<Float>,
		z:Array<Float>
	};
	public var s:{
		t:Array<Float>,
		x:Array<Float>,
		y:Array<Float>,
		z:Array<Float>
	};
	public var a:{t:Array<Float>, v:Array<Float>};
	public var fov:{t:Array<Float>, v:Array<Float>};
	public var roll:{t:Array<Float>, v:Array<Float>};
	public var uv:Array<{t:Float, u:Float, v:Float}>;

	public function new(def, object) {
		this.def = def;
		this.object = object;
	}

	public function toString():String {
		return "object=" + object + " t=" + t + " r=" + r + " s=" + s;
	}
}
