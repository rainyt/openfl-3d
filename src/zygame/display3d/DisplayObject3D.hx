package zygame.display3d;

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
import zygame.display.DisplayObjectContainer;
import openfl.events.RenderEvent;

/**
 * 3D显示对象
 */
class DisplayObject3D extends DisplayObjectContainer {
	/**
	 * 纹理
	 * 
	 */
	public var texture:BitmapData;

	/**
	 * 顶点坐标
	 */
	public var vertices:Array<Float>;

	/**
	 * 顶点索引
	 */
	public var indices:Array<Int>;

	/**
	 * UV坐标
	 */
	public var uvs:Array<Float>;

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

	private var r:Float = 0;

	private var c = [];

	public var scaleZ:Float = 1;

	public function new(vertices:Array<Float>, indices:Array<Int>, uvs:Array<Float> = null) {
		super();
		this.vertices = vertices;
		this.indices = indices;
		trace("indices=", indices.length);
		this.uvs = uvs;
		var context = Lib.application.window.stage.context3D;
		vertexBuffer = context.createVertexBuffer(Std.int(vertices.length / 3), 9);
		indexBuffer = context.createIndexBuffer(this.indices.length);
		indexBuffer.uploadFromTypedArray(new UInt16Array(indices));

		this.addEventListener(RenderEvent.RENDER_OPENGL, onRender);
		this.setFrameEvent(true);

		var buffers:openfl.Vector<Float> = new openfl.Vector();

		var num = Std.int(this.vertices.length / 3);
		for (i in 0...num) {
			buffers.push(vertices[i * 3]);
			buffers.push(vertices[i * 3 + 1]);
			buffers.push(vertices[i * 3 + 2]);
			// 颜色
			var r = Math.random();
			var g = Math.random();
			var b = Math.random();
			buffers.push(r);
			buffers.push(g);
			buffers.push(b);
			buffers.push(1);
			// 纹理
			buffers.push(uvs[i * 2]);
			buffers.push(uvs[i * 2 + 1]);
		}
		trace("vertices=",vertices);
		trace("buffers=",buffers);
		vertexBuffer.uploadFromVector(buffers, 0, num);
	}

	override function onFrame() {
		super.onFrame();
		this.invalidate();
	}

	public function onRender(e:RenderEvent):Void {
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

		var m = new Matrix4();
		// m.appendScale(100, 100, 100);
		m.appendScale(this.scaleX, this.scaleY, this.scaleZ);
		m.appendRotation(r, new Vector4(0, 0, 1, 0));
		m.appendRotation(r, new Vector4(0, 1, 0, 0));
		r += 1;

		var p = new Matrix4();
		@:privateAccess p.createOrtho(0, getStageWidth(), getStageHeight(), 0, -1000, 1000);
		m.appendTranslation(this.x, this.y, 0);

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

	override function scale(f:Float):DisplayObjectContainer {
		this.scaleZ = f;
		return super.scale(f);
	}
}
