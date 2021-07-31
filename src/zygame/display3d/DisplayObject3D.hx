package zygame.display3d;

import openfl.geom.Matrix;
#if zygame
import zygame.core.Start;
#end
import openfl.display3D.IndexBuffer3D;
import openfl.Lib;
import openfl.display3D.Context3DBufferUsage;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.Context3DTextureFilter;
import openfl.display3D.Context3DWrapMode;
import openfl.display3D.Context3DMipFilter;
import lime.graphics.opengl.GLTexture;
import openfl.display.BitmapData;
import lime.math.Vector4;
import lime.math.Matrix4;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLBuffer;
import lime.utils.UInt16Array;
import lime.utils.Float32Array;
import openfl.display.OpenGLRenderer;
#if zygame
import zygame.display.DisplayObjectContainer;
#else
import openfl.display.DisplayObjectContainer;
#end
import openfl.events.RenderEvent;
import openfl.Vector;

/**
 * 3D显示对象
 */
@:access(openfl.display.DisplayObject)
class DisplayObject3D extends DisplayObjectContainer {
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
	 * 纹理
	 * 
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

	public var scaleZ:Float = 1;

	public var rotationX:Float = 0;

	public var rotationY:Float = 0;

	public var rotationZ:Float = 0;

	public function new(vertices:Vector<Float> = null, indices:Vector<Int> = null, uvs:Vector<Float> = null) {
		super();
		this.vertices = vertices;
		this.indices = indices;
		this.uvs = uvs;
		if (vertices == null || indices == null)
			return;
		var context = Lib.application.window.stage.context3D;
		vertexBuffer = context.createVertexBuffer(Std.int(vertices.length / 3), 9);
		indexBuffer = context.createIndexBuffer(this.indices.length);
		indexBuffer.uploadFromTypedArray(new UInt16Array(indices));

		this.addEventListener(RenderEvent.RENDER_OPENGL, onRender);
		#if zygame
		this.setFrameEvent(true);
		#end

		var buffers:openfl.Vector<Float> = new openfl.Vector();

		var num = Std.int(this.vertices.length / 3);
		for (i in 0...num) {
			buffers.push(vertices[i * 3]);
			buffers.push(vertices[i * 3 + 1]);
			buffers.push(vertices[i * 3 + 2]);
			// 颜色
			var r = 1;
			var g = 0;
			var b = 0;
			buffers.push(r);
			buffers.push(g);
			buffers.push(b);
			buffers.push(1);
			// 纹理
			if (uvs == null) {
				buffers.push(0);
				buffers.push(1);
			} else {
				buffers.push(uvs[i * 2]);
				buffers.push(uvs[i * 2 + 1]);
			}
		}
		vertexBuffer.uploadFromVector(buffers, 0, num);
		trace("buffers=", buffers);
		trace("indices=", indices);
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
		// vertexBuffer.uploadFromTypedArray(new Float32Array(vertices.concat(c).concat(uvs)));
		var pos = gl.getAttribLocation(shaderProgram, "zy_pos");
		context.setVertexBufferAt(pos, vertexBuffer, 0, FLOAT_3);

		var color = gl.getAttribLocation(shaderProgram, "zy_color");
		context.setVertexBufferAt(color, vertexBuffer, 3, FLOAT_4);

		// 纹理绑定
		var coord = gl.getAttribLocation(shaderProgram, "zy_coord");
		context.setVertexBufferAt(coord, vertexBuffer, 7, FLOAT_2);

		/*=========Drawing the triangle===========*/

		var modelViewMatrixIndex = gl.getUniformLocation(shaderProgram, "modelViewMatrix");
		var projectionMatrixIndex = gl.getUniformLocation(shaderProgram, "projectionMatrix");

		var p = new Matrix4();
		#if zygame
		@:privateAccess p.createOrtho(0, getStageWidth(), getStageHeight(), 0, -1000, 1000);
		#else
		@:privateAccess p.createOrtho(0, stage.stageWidth, stage.stageHeight, 0, -1000, 1000);
		#end
		// @:privateAccess m.appendTranslation(this.x, this.y, 0);
		var m = __worldTransform3D.clone();
		// @:privateAccess m.appendTranslation(__worldTransform.tx / Start.currentScale, __worldTransform.ty / Start.currentScale, 0);

		gl.uniformMatrix4fv(modelViewMatrixIndex, false, m);
		gl.uniformMatrix4fv(projectionMatrixIndex, false, p);

		// Enable the depth test
		gl.enable(gl.DEPTH_TEST);
		gl.depthFunc(gl.LESS);
		gl.depthMask(true);

		// 绑定纹理
		if (texture != null) {
			var glTex = texture.getTexture(context);
			context.setTextureAt(0, glTex);
		}
		context.drawTriangles(indexBuffer);

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

	override function onAddToStage() {
		super.onAddToStage();
		__isRoot = !Std.isOfType(this.parent, DisplayObject3D);
	}

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
		__transform3D.appendTranslation(this.x, this.y, 0);

		if (__isRoot) {
			__worldTransform3D = __transform3D.clone();
		} else {
			__worldTransform3D = cast(this.parent, DisplayObject3D).__worldTransform3D.clone();
			__worldTransform3D.prepend(__transform3D);
		}
	}
}
