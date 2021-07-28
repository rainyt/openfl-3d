package zygame.display3d;

import VectorMath;
import glsl.OpenFLShader;

@:build(glsl.macro.GLSLCompileMacro.build("glsl"))
class DisplayObject3DShader {
	public var gl_Position:Dynamic;

	public var gl_FragColor:Dynamic;

	/**
	 * 3D顶点
	 */
	@:attribute public var zy_coord:Vec3;

	/**
	 * 3D顶点颜色
	 */
	@:attribute public var zy_color:Vec4;

	/**
	 * 相机模型矩阵
	 */
	@:uniform public var modelViewMatrix:Mat4;

	/**
	 * 视角矩阵
	 */
	@:uniform public var projectionMatrix:Mat4;

	@:varying public var vColor:Vec4;

	// @:uniform public var projectionMatrix:Mat4;
	public function vertex() {
		gl_Position = projectionMatrix * modelViewMatrix * vec4(zy_coord, 1.0);
		vColor = zy_color;
	}

	@:precision("mediump float")
	public function fragment() {
		gl_FragColor = vec4(vColor.r, vColor.g, vColor.b, 1);
		// gl_FragColor = vec4(1,0,0,1);
	}
}
