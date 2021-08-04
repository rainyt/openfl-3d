package zygame.display3d;

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
import openfl.display.DisplayObjectContainer;
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
	 * 当前坐标的补充
	 */
	// public var transform3D:Matrix4;

	/**
	 * BUFFER数据
	 */
	public var buffers:Vector<Float>;

	/**
	 * 纹理
	 */
	public var texture:BitmapData;

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
	 * 绑定骨骼动画
	 */
	public var skeleton(get, set):Skeleton;

	private var _skeleton:Skeleton;

	function get_skeleton():Skeleton {
		return _skeleton;
	}

	function set_skeleton(value:Skeleton):Skeleton {
		_skeleton = value;
		// 绑定到底层的所有3D对象
		for (i in 0...this.numChildren) {
			var display = this.getChildAt(i);
			if (Std.isOfType(display, DisplayObject3D)) {
				cast(display, DisplayObject3D).skeleton = value;
			}
		}
		__updateGeometryData();
		return value;
	}

	public function new(vertices:Vector<Float> = null, indices:Vector<Int> = null, uvs:Vector<Float> = null) {
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
		vertexBuffer = context.createVertexBuffer(Std.int(vertices.length / 3), 17);
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
		}
		vertexBuffer.uploadFromVector(buffers, 0, num);
		// trace("indices=", indices);
		// trace(buffers.length, vertices.length / 3, buffers.length / (vertices.length / 3));
	}

	private function __updateBuffersData(index:Int, start:Int, value:Float):Void {
		var id = 17 * index + start;
		buffers[id] = value;
		// trace("update", start, "[", 17, index, start, "]", id, buffers.length);
	}

	/**
	 * 更新Geometry的顶点属性
	 */
	private function __updateGeometryData():Void {
		if (this.geometryData == null || skeleton == null) {
			return;
		}

		var _maps:Map<Int, Int> = [];

		// 更新权重和骨骼索引
		if (this.geometryData.deformer != null) {
			for (skin in this.geometryData.deformer.skins) {
				var joint = skeleton.jointFromId(skin.bindJointId);
				if (joint != null) {
					for (i in 0...skin.indexes.length) {
						var skinIndex = skin.indexes[i];
						if (!_maps.exists(skinIndex)) {
							_maps.set(skinIndex, 1);
						} else {
							_maps.set(skinIndex, _maps.get(skinIndex) + 1);
						}
						__updateBuffersData(skinIndex, 8 + _maps.get(skinIndex), joint.index);
						__updateBuffersData(skinIndex, 12 + _maps.get(skinIndex), skin.weights[i]);
					}
				}
			}
			// trace("映射索引影响结果：", _maps);
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
			var vertCode = DisplayObject3DShader.vertexSource;

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
			var fragCode = DisplayObject3DShader.fragmentSource;

			// Create fragment shader object
			var fragShader = gl.createShader(gl.FRAGMENT_SHADER);

			// Attach fragment shader source code
			gl.shaderSource(fragShader, fragCode);

			// Compile the fragmentt shader
			gl.compileShader(fragShader);

			if (gl.getShaderParameter(fragShader, gl.COMPILE_STATUS) == 0) {
				var message = "Error compiling vertex shader";
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
				trace(gl.getProgramInfoLog(shaderProgram));
				trace("VALIDATE_STATUS: " + gl.getProgramParameter(shaderProgram, gl.VALIDATE_STATUS));
				throw("ERROR: " + gl.getError());
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

		var p = new Matrix4();
		#if zygame
		@:privateAccess p.createOrtho(0, getStageWidth(), getStageHeight(), 0, -1000, 1000);
		#else
		@:privateAccess p.createOrtho(0, stage.stageWidth, stage.stageHeight, 0, -1000, 1000);
		#end

		var m = __worldTransform3D.clone();
		gl.uniformMatrix4fv(modelViewMatrixIndex, false, m);
		gl.uniformMatrix4fv(projectionMatrixIndex, false, p);

		var bones = [];
		if (skeleton != null) {
			for (i in 0...skeleton.joints.length) {
				var joint = skeleton.joints[i];
				for (i in 0...16) {
					bones.push(joint.inverseBindPose[i]);
				}
			}
		}
		if (bones.length != 0)
			gl.uniformMatrix4fv(bonesMatrixIndex, false, new Float32Array(bones));

		// Enable the depth test
		gl.enable(gl.DEPTH_TEST);
		gl.depthFunc(gl.LESS);
		gl.depthMask(true);

		// 绑定纹理
		if (texture != null) {
			var glTex = texture.getTexture(context);
			context.setTextureAt(0, glTex);
		}

		// 剔除正面
		gl.enable(gl.CULL_FACE);
		gl.cullFace(gl.FRONT);

		context.drawTriangles(indexBuffer);

		// 剔除背面
		gl.cullFace(gl.BACK);
		context.drawTriangles(indexBuffer);

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
		} else {
			__worldTransform3D = cast(this.parent, DisplayObject3D).__worldTransform3D.clone();
			__worldTransform3D.prepend(__transform3D);
		}
	}
}
