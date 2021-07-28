package zygame.display3d;

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
	 * 顶点坐标
	 */
	public var vertices:Array<Float>;

	/**
	 * 顶点索引
	 */
	public var indices:Array<Int>;

	/**
	 * 顶点数据
	 */
	private var glBuffer:GLBuffer;

	/**
	 * 顶点索引数据
	 */
	private var indexBuffer:GLBuffer;

	/**
	 * 着色器
	 */
	private var shaderProgram:GLProgram;

	private var r:Float = 0;

	private var c = [];

	public function new(vertices:Array<Float>, indices:Array<Int>) {
		super();
		this.vertices = vertices;
		this.indices = indices;
		this.addEventListener(RenderEvent.RENDER_OPENGL, onRender);
		this.setFrameEvent(true);

		for (i in 0...12) {
			var r = Math.random();
			var g = Math.random();
			var b = Math.random();
			for (i in 0...4) {
				c.push(r);
				c.push(g);
				c.push(b);
				c.push(1);
			}
		}
	}

	override function onFrame() {
		super.onFrame();
		this.invalidate();
	}

	public function onRender(e:RenderEvent):Void {
		var opengl:OpenGLRenderer = cast e.renderer;
		var gl = opengl.gl;
		if (glBuffer == null) {
			glBuffer = gl.createBuffer();
			indexBuffer = gl.createBuffer();
		}

		opengl.setShader(null);
		// 绑定传入顶点数据
		gl.bindBuffer(gl.ARRAY_BUFFER, glBuffer);
		gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices.concat(c)), gl.STATIC_DRAW);
		gl.bindBuffer(gl.ARRAY_BUFFER, null);
		// 绑定传入索引数据
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
		gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new UInt16Array(indices), gl.STATIC_DRAW);
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null);

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
		var color = gl.getAttribLocation(shaderProgram, "zy_color");
		gl.enableVertexAttribArray(color);

		// Bind vertex buffer object
		gl.bindBuffer(gl.ARRAY_BUFFER, glBuffer);

		gl.vertexAttribPointer(color, 4, gl.FLOAT, false, 0, 0);

		// Bind index buffer object
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);

		// Get the attribute location
		var coord = gl.getAttribLocation(shaderProgram, "zy_coord");

		// Point an attribute to the currently bound VBO
		gl.vertexAttribPointer(coord, 3, gl.FLOAT, false, 0, 0);

		// Enable the attriute
		gl.enableVertexAttribArray(coord);

		/*=========Drawing the triangle===========*/

		var modelViewMatrixIndex = gl.getUniformLocation(shaderProgram, "modelViewMatrix");
		var projectionMatrixIndex = gl.getUniformLocation(shaderProgram, "projectionMatrix");

		var m = new Matrix4();
		m.appendScale(100, 100, 100);
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

		// Clear the color buffer bit
		// gl.clear(gl.COLOR_BUFFER_BIT);
		// gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

		// Draw the triangle
		gl.drawElements(gl.TRIANGLES, indices.length, gl.UNSIGNED_SHORT, 0);
		gl.bindBuffer(gl.ARRAY_BUFFER, null);
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null);

		opengl.setShader(this.__worldShader);
		@:privateAccess opengl.__context3D.__flushGL();

		gl.disable(gl.DEPTH_TEST);
		gl.depthMask(false);
	}
}
