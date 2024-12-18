package zygame.display3d;

import lime.graphics.opengl.GL;
import zygame.lights.Light;
import openfl.display.DisplayObject;
import zygame.data.anim.AnimationState;
import zygame.data.Vertex;
import haxe.Json;
import lime.utils.Float32Array;
import zygame.data.GeometryData;
import zygame.data.anim.Skeleton;
import openfl.events.Event;
import openfl.geom.Matrix;
#if zygame
import zygame.core.Start;
import zygame.display.DisplayObjectContainer;
#else
import openfl.display.Sprite in DisplayObjectContainer;
#end
import openfl.display3D.IndexBuffer3D;
import openfl.Lib;
import openfl.display3D.VertexBuffer3D;
import openfl.display.BitmapData;
import lime.math.Vector4;
import lime.math.Matrix4;
import lime.graphics.opengl.GLProgram;
import lime.utils.UInt16Array;
import openfl.display.OpenGLRenderer;
import openfl.events.RenderEvent;
import openfl.Vector;

/**
 * 3D显示对象
 */
@:access(openfl.display.DisplayObject)
class DisplayObject3D extends DisplayObjectContainer {
	/**
	 * GeometryData
	 */
	private var __geometryData:GeometryData;

	/**
	 * GeometryData
	 */
	public var geometryData(get, never):GeometryData;

	function get_geometryData():GeometryData {
		return __geometryData;
	}

	/**
	 * 世界模型
	 */
	private var __worldTransform3D:Matrix4;

	/**
	 * 当前模型的坐标
	 */
	private var __transform3D:Matrix4 = new Matrix4();

	/**
	 * 3D对象是否为最外层，不含2D容器
	 */
	private var __isRoot:Bool = true;

	/**
	 * BUFFER数据
	 */
	public var buffers:Vector<Float>;

	/**
	 * 光源
	 */
	public var light(get, set):Light;

	private var _light:Light;

	private function set_light(value:Light):Light {
		_light = value;
		// 绑定到底层的所有3D对象
		for (i in 0...this.numChildren) {
			var display = this.getChildAt(i);
			if (Std.isOfType(display, DisplayObject3D)) {
				cast(display, DisplayObject3D).light = value;
			}
		}
		this.invalidate();
		return value;
	}

	private function get_light():Light {
		return _light;
	}

	/**
	 * 纹理
	 */
	public var texture(get, set):BitmapData3D;

	private var _texture:BitmapData3D;

	private function set_texture(value:BitmapData3D):BitmapData3D {
		_texture = value;
		// 绑定到底层的所有3D对象
		for (i in 0...this.numChildren) {
			var display = this.getChildAt(i);
			if (Std.isOfType(display, DisplayObject3D)) {
				cast(display, DisplayObject3D).texture = value;
			}
		}
		this.invalidate();
		return value;
	}

	private function get_texture():BitmapData3D {
		return _texture;
	}

	/**
	 * 顶点坐标
	 */
	public var vertices:Vector<Float>;

	/**
	 * 顶点索引
	 */
	public var indices:Vector<Int>;

	/**
	 * UV坐标
	 */
	public var uvs:Vector<Float>;

	/**
	 * 顶点缓冲区
	 */
	public var vertexBuffer:VertexBuffer3D;

	/**
	 * 三角形绘制数据
	 */
	public var indexBuffer:IndexBuffer3D;

	/**
	 * 着色器
	 */
	private var shaderProgram:GLProgram;

	public var transPos:Matrix4;

	private var c = [];

	/**
	 * 缩放比例Z
	 */
	public var z(get, set):Float;

	private var _z:Float = 0;

	private function set_z(f:Float):Float {
		_z = f;
		this.invalidate();
		return f;
	}

	private function get_z():Float {
		return _z;
	}

	/**
	 * 缩放比例Z
	 */
	public var scaleZ(get, set):Float;

	private var _scaleZ:Float = 1;

	private function set_scaleZ(f:Float):Float {
		_scaleZ = f;
		this.invalidate();
		return f;
	}

	private function get_scaleZ():Float {
		return _scaleZ;
	}

	/**
	 * 角度X
	 */
	public var rotationX(get, set):Float;

	private var _rotationX:Float = 0;

	private function set_rotationX(f:Float):Float {
		_rotationX = f;
		this.invalidate();
		return f;
	}

	private function get_rotationX():Float {
		return _rotationX;
	}

	/**
	 * 角度Y
	 */
	public var rotationY(get, set):Float;

	private var _rotationY:Float = 0;

	private function set_rotationY(f:Float):Float {
		_rotationY = f;
		this.invalidate();
		return f;
	}

	private function get_rotationY():Float {
		return _rotationY;
	}

	/**
	 * 角度Z
	 */
	public var rotationZ(get, set):Float;

	private var _rotationZ:Float = 0;

	private function set_rotationZ(f:Float):Float {
		_rotationZ = f;
		this.invalidate();
		return f;
	}

	private function get_rotationZ():Float {
		return _rotationZ;
	}

	/**
	 * 动画状态绑定
	 */
	public var animationState(get, set):AnimationState;

	private var _animationState:AnimationState;

	function get_animationState():AnimationState {
		return _animationState;
	}

	function set_animationState(value:AnimationState):AnimationState {
		_animationState = value;
		// 绑定到底层的所有3D对象
		for (i in 0...this.numChildren) {
			var display = this.getChildAt(i);
			if (Std.isOfType(display, DisplayObject3D)) {
				cast(display, DisplayObject3D).animationState = value;
			}
		}
		__updateGeometryData();
		return value;
	}

	public function new(vertices:Vector<Float> = null, indices:Vector<Int> = null, uvs:Vector<Float> = null, normals:Vector<Float> = null) {
		super();
		#if !zygame
		this.addEventListener(Event.ADDED_TO_STAGE, onAddToStage);
		#end
		this.vertices = vertices;
		this.indices = indices;
		this.uvs = uvs;
		if (vertices == null || indices == null)
			return;
		var context = Lib.application.window.stage.context3D;
		vertexBuffer = context.createVertexBuffer(Std.int(vertices.length / 3), 20);
		indexBuffer = context.createIndexBuffer(this.indices.length);
		indexBuffer.uploadFromTypedArray(new UInt16Array(indices));

		this.addEventListener(RenderEvent.RENDER_OPENGL, onRender);
		#if zygame
		this.setFrameEvent(true);
		#end

		buffers = new openfl.Vector();

		var num = Std.int(this.vertices.length / 3);
		for (i in 0...num) {
			buffers.push(vertices[i * 3]);
			buffers.push(vertices[i * 3 + 1]);
			buffers.push(vertices[i * 3 + 2]);
			// 颜色
			var r = 1;
			var g = 1;
			var b = 1;
			var a = 1;
			buffers.push(r);
			buffers.push(g);
			buffers.push(b);
			buffers.push(a);
			// 纹理
			if (uvs == null) {
				buffers.push(0);
				buffers.push(1);
			} else {
				buffers.push(uvs[i * 2]);
				buffers.push(uvs[i * 2 + 1]);
			}
			// 骨骼索引，如果不存在则默认-1
			buffers.push(-1);
			buffers.push(-1);
			buffers.push(-1);
			buffers.push(-1);
			// 骨骼权重，如果不存在则默认为0
			buffers.push(0);
			buffers.push(0);
			buffers.push(0);
			buffers.push(0);
			// 法线
			if (normals != null) {
				buffers.push(normals[i * 3]);
				buffers.push(normals[i * 3 + 1]);
				buffers.push(normals[i * 3 + 2]);
			} else {
				buffers.push(0);
				buffers.push(0);
				buffers.push(0);
			}
		}
		vertexBuffer.uploadFromVector(buffers, 0, num);
	}

	private function __updateBuffersData(index:Int, start:Int, value:Float):Void {
		var id = 20 * index + start;
		buffers[id] = value;
	}

	/**
	 * 更新Geometry的顶点属性
	 */
	private function __updateGeometryData():Void {
		if (this.geometryData == null || animationState == null) {
			return;
		}

		var _maps:Map<Int, Int> = [];

		// 更新权重和骨骼索引
		if (this.geometryData.deformer != null) {
			for (skin in this.geometryData.deformer.skins) {
				var joint = animationState.skeleton.jointFromId(skin.bindJointId);
				if (joint != null && skin.indexes != null && skin.weights != null) {
					for (i in 0...skin.indexes.length) {
						var skinIndex = skin.indexes[i];
						if (!_maps.exists(skinIndex)) {
							_maps.set(skinIndex, 1);
						} else {
							_maps.set(skinIndex, _maps.get(skinIndex) + 1);
						}
						if (_maps.get(skinIndex) + 1 <= 4) {
							__updateBuffersData(skinIndex, 8 + _maps.get(skinIndex), joint.index);
							__updateBuffersData(skinIndex, 12 + _maps.get(skinIndex), skin.weights[i]);
						} else {
							throw "骨骼影响顶点的数量不能大于4个。";
						}
					}
				}
			}
			var num = Std.int(this.vertices.length / 3);
			vertexBuffer.uploadFromVector(buffers, 0, num);
		}
	}

	#if zygame
	override function onFrame() {
		super.onFrame();
		// this.invalidate();
	}
	#end

	public function onRender(e:RenderEvent):Void {
		if (vertices.length == 0 || indices.length == 0)
			return;
		var opengl:OpenGLRenderer = cast e.renderer;
		var gl = opengl.gl;
		var context = Lib.application.window.stage.context3D;

		opengl.setShader(null);

		// 创建shader
		/*================ Shaders ====================*/

		if (shaderProgram == null) {
			// Vertex shader Code
			#if cpp
			var glsl = [];
			// glsl.push("#ifdef GL_FRAGMENT_PRECISION_HIGH\n");
			// glsl.push("precision highp float;\n");
			// glsl.push("#else\n");
			// glsl.push("precision mediump float;\n");
			// glsl.push("#endif\n");
			var glslHeader = glsl.join("");
			#end

			#if cpp
			var shaderVersion = Std.parseFloat(GL.getParameter(GL.SHADING_LANGUAGE_VERSION)) * 100;
			var vertCode = "#version " + shaderVersion + "\n\n" + DisplayObject3DShader.vertexSource;
			trace("vertCode=", vertCode);
			#else
			var vertCode = DisplayObject3DShader.vertexSource;
			#end

			// Create a vertex shader object
			var vertShader = gl.createShader(gl.VERTEX_SHADER);

			// Attach vertex shader source code
			gl.shaderSource(vertShader, vertCode);

			// Compile the vertex shader
			gl.compileShader(vertShader);

			if (gl.getShaderParameter(vertShader, gl.COMPILE_STATUS) == 0) {
				var message = "Error compiling vertex shader";
				message += "\n" + gl.getShaderInfoLog(vertShader);
				message += "\n" + vertCode;
				throw message;
			}

			// fragment shader source code
			#if cpp
			var fragCode = "#version " + shaderVersion + "\n\n" + glslHeader + DisplayObject3DShader.fragmentSource;
			#else
			var fragCode = DisplayObject3DShader.fragmentSource;
			#end

			// Create fragment shader object
			var fragShader = gl.createShader(gl.FRAGMENT_SHADER);

			// Attach fragment shader source code
			gl.shaderSource(fragShader, fragCode);

			// Compile the fragmentt shader
			gl.compileShader(fragShader);

			if (gl.getShaderParameter(fragShader, gl.COMPILE_STATUS) == 0) {
				var message = "Error compiling frag shader";
				message += "\n" + gl.getShaderInfoLog(fragShader);
				message += "\n" + fragCode;
				throw message;
			}

			// Create a shader program object to store
			// the combined shader program
			shaderProgram = gl.createProgram();

			// Attach a vertex shader
			gl.attachShader(shaderProgram, vertShader);

			// Attach a fragment shader
			gl.attachShader(shaderProgram, fragShader);

			// Link both the programs
			gl.linkProgram(shaderProgram);

			if (gl.getProgramParameter(shaderProgram, gl.LINK_STATUS) == 0) {
				trace("VALIDATE_STATUS: " + gl.getProgramParameter(shaderProgram, gl.VALIDATE_STATUS));
				throw("ERROR: " + gl.getProgramInfoLog(shaderProgram));
			}
		}

		// Use the combined shader program object
		gl.useProgram(shaderProgram);

		/*======= Associating shaders to buffer objects =======*/

		// 绑定属性
		var pos = gl.getAttribLocation(shaderProgram, "zy_pos");
		context.setVertexBufferAt(pos, vertexBuffer, 0, FLOAT_3);

		// 颜色
		var color = gl.getAttribLocation(shaderProgram, "zy_color");
		context.setVertexBufferAt(color, vertexBuffer, 3, FLOAT_4);

		// 纹理绑定
		var coord = gl.getAttribLocation(shaderProgram, "zy_coord");
		context.setVertexBufferAt(coord, vertexBuffer, 7, FLOAT_2);

		// 骨骼索引
		var boneIndex = gl.getAttribLocation(shaderProgram, "boneIndex");
		context.setVertexBufferAt(boneIndex, vertexBuffer, 9, FLOAT_4);

		// 骨骼影响权重
		var boneWeight = gl.getAttribLocation(shaderProgram, "boneWeight");
		context.setVertexBufferAt(boneWeight, vertexBuffer, 13, FLOAT_4);

		// 法线
		var normal = gl.getAttribLocation(shaderProgram, "zy_normal");
		context.setVertexBufferAt(normal, vertexBuffer, 17, FLOAT_3);

		// 位移
		// var _matpos = gl.getAttribLocation(shaderProgram, "pos");
		// context.setVertexBufferAt(_matpos, vertexBuffer, 9, FLOAT_3);

		// 缩放
		// var _matscale = gl.getAttribLocation(shaderProgram, "scale");
		// context.setVertexBufferAt(_matscale, vertexBuffer, 12, FLOAT_3);

		// 旋转
		// var _matrotation = gl.getAttribLocation(shaderProgram, "rotation");
		// context.setVertexBufferAt(_matrotation, vertexBuffer, 15, FLOAT_3);

		/*=========Drawing the triangle===========*/

		var modelViewMatrixIndex = gl.getUniformLocation(shaderProgram, "modelViewMatrix");
		var projectionMatrixIndex = gl.getUniformLocation(shaderProgram, "projectionMatrix");
		var bonesMatrixIndex = gl.getUniformLocation(shaderProgram, "bonesMatrix");
		var lightIndex = gl.getUniformLocation(shaderProgram, "light");

		var p = new Matrix4();
		@:privateAccess p.createOrtho(0, stage.stageWidth, stage.stageHeight, 0, -1000, 1000);

		var m = __worldTransform3D.clone();
		gl.uniformMatrix4fv(modelViewMatrixIndex, false, m);
		gl.uniformMatrix4fv(projectionMatrixIndex, false, p);

		var bones = [];
		if (animationState != null && animationState.currentPose != null) {
			for (i in 0...animationState.currentPose.joints.length) {
				var joint = animationState.currentPose.joints[i];
				if (joint.independentJoint) {
					// 独立的节点
					if (this.name == joint.name) {
						this.x = joint.x;
						this.y = joint.y;
						this.z = joint.z;
						this.rotationX = joint.rotationX;
						this.rotationY = joint.rotationY;
						this.rotationZ = joint.rotationZ;
						this.scaleX = joint.scaleX;
						this.scaleY = joint.scaleY;
						this.scaleZ = joint.scaleZ;
						this.transPos = joint.transPos;
						// __updateTransforms3D();
					}
				} else {
					for (i in 0...16) {
						bones.push(joint.inverseBindPose[i]);
					}
				}
			}
		}
		if (bones.length != 0)
			gl.uniformMatrix4fv(bonesMatrixIndex, false, new Float32Array(bones));

		if (light != null) {
			var lightArray = [light.direction.x, light.direction.y, light.direction.z];
			gl.uniform3fv(lightIndex, new Float32Array(lightArray));
		}

		// Enable the depth test
		gl.enable(gl.DEPTH_TEST);)
		gl.depthFunc(gl.LESS);
		gl.depthMask(true);

		// 绑定纹理
		if (texture != null && texture.texture != null) {
			var glTex = texture.texture.getTexture(context);
			context.setTextureAt(0, glTex);
		} else {
			context.setTextureAt(0, null);
		}

		if (texture != null && (texture.transparent || texture.doubleSide)) {
			// 剔除正面
			gl.enable(gl.CULL_FACE);
			gl.cullFace(gl.FRONT);
			context.drawTriangles(indexBuffer);
			// 剔除背面
			gl.cullFace(gl.BACK);
			context.drawTriangles(indexBuffer);
		} else {
			// 仅剔除背面
			gl.disable(gl.CULL_FACE);
			context.drawTriangles(indexBuffer);
		}

		gl.disable(gl.CULL_FACE);
		gl.disable(gl.DEPTH_TEST);
		gl.depthMask(false);
	}

	#if zygame override #else public #end function scale(f:Float):DisplayObjectContainer {
		this.scaleZ = f;
		#if zygame
		return super.scale(f);
		#else
		this.scaleX = f;
		this.scaleY = f;
		return this;
		#end
	}

	#if zygame
	override function onAddToStage() {
		super.onAddToStage();
		__isRoot = !Std.isOfType(this.parent, DisplayObject3D);
	}
	#else
	private function onAddToStage(_) {
		__isRoot = !Std.isOfType(this.parent, DisplayObject3D);
	}
	#end

	/**
	 * 更新Transform
	 * @param overrideTransform 
	 */
	override private function __updateTransforms(overrideTransform:Matrix = null):Void {
		super.__updateTransforms(overrideTransform);
		__updateTransforms3D();
	}

	/**
	 * 更新3D的transforms
	 */
	private function __updateTransforms3D():Void {
		__transform3D = new Matrix4();
		__transform3D.appendScale(this.scaleX, this.scaleY, this.scaleZ);
		__transform3D.appendRotation(rotationX, new Vector4(1, 0, 0, 0));
		__transform3D.appendRotation(rotationY, new Vector4(0, 1, 0, 0));
		__transform3D.appendRotation(rotationZ, new Vector4(0, 0, 1, 0));
		__transform3D.appendTranslation(this.x, this.y, this.z);

		if (__isRoot) {
			__worldTransform3D = __transform3D.clone();
			__worldTransform3D.appendTranslation(this.parent.__worldTransform.tx, this.parent.__worldTransform.ty, 0);
			__worldTransform3D.appendScale(this.parent.__worldTransform.a, this.parent.__worldTransform.d,
				0.5 * (this.parent.__worldTransform.a + this.parent.__worldTransform.d));
		} else {
			__worldTransform3D = cast(this.parent, DisplayObject3D).__worldTransform3D.clone();
			__worldTransform3D.prepend(__transform3D);
		}

		if (transPos != null) {
			__worldTransform3D.prepend(transPos);
		}
	}

	public function getChild3DByName(name:String):DisplayObject3D {
		for (i in 0...this.numChildren) {
			var display = this.getChildAt(i);
			if (display.name == name) {
				return cast display;
			} else if (Std.isOfType(display, DisplayObject3D)) {
				display = cast(display, DisplayObject3D).getChild3DByName(name);
				if (display != null)
					return cast display;
			}
		}
		return null;
	}

	private function __childCopy(c:DisplayObject3D):Void {
		c.x = this.x;
		c.y = this.y;
		c.z = this.z;
		c.scaleX = this.scaleX;
		c.scaleY = this.scaleY;
		c.scaleZ = this.scaleZ;
		c.texture = this.texture;
		c.rotationX = this.rotationX;
		c.rotationY = this.rotationY;
		c.rotationZ = this.rotationZ;
		for (i in 0...this.numChildren) {
			var child = this.getChildAt(i);
			if (Std.isOfType(child, DisplayObject3D)) {
				var c2 = cast(child, DisplayObject3D).copy();
				c.addChild(c2);
			}
		}
	}

	/**
	 * 拷贝一个副本
	 * @return DisplayObject3D
	 */
	public function copy():DisplayObject3D {
		var c = new DisplayObject3D(this.vertices, this.indices, this.uvs);
		__childCopy(c);
		return c;
	}
}
