package zygame.display3d;

import glsl.GLSL.texture2D;
import glsl.Sampler2D;
import VectorMath;
import glsl.OpenFLShader;

@:build(glsl.macro.GLSLCompileMacro.build("glsl"))
class DisplayObject3DShader {
	public var gl_Position:Dynamic;

	public var gl_FragColor:Dynamic;

	/**
	 * 3D顶点
	 */
	@:attribute public var zy_pos:Vec3;

	/**
	 * 移动点
	 */
	@:attribute public var pos:Vec3;

	/**
	 * 缩放比
	 */
	@:attribute public var scale:Vec3;

	/**
	 * 旋转角度
	 */
	@:attribute public var rotation:Vec3;

	/**
	 * 3D顶点颜色
	 */
	@:attribute public var zy_color:Vec4;

	/**
	 * 3D纹理
	 */
	@:attribute public var zy_coord:Vec2;

	/**
	 * 相机模型矩阵
	 */
	@:uniform public var modelViewMatrix:Mat4;

	/**
	 * 视角矩阵
	 */
	@:uniform public var projectionMatrix:Mat4;

	@:varying public var vColor:Vec4;

	@:varying public var vCoord:Vec2;

	@:uniform public var texture0:Sampler2D;

	/**
	 * 旋转实现
	 * @return Mat4
	 */
	@:vertexglsl public function rotaion(degrees:Float, axis:Vec3, ts:Vec3):Mat4 {
		var tx:Float = ts.x;
		var ty:Float = ts.y;
		var tz:Float = ts.z;

		var radian:Float = degrees * 3.14 / 180;
		var c:Float = cos(radian);
		var s:Float = sin(radian);
		var x:Float = axis.x;
		var y:Float = axis.y;
		var z:Float = axis.z;
		var x2:Float = x * x;
		var y2:Float = y * y;
		var z2:Float = z * z;
		var ls:Float = x2 + y2 + z2;
		if (ls != 0) {
			var l:Float = sqrt(ls);
			x /= l;
			y /= l;
			z /= l;
			x2 /= ls;
			y2 /= ls;
			z2 /= ls;
		}
		var ccos:Float = 1 - c;
		var d:Mat4 = modelViewMatrix;
		d[0].x = x2 + (y2 + z2) * c;
		d[0].y = x * y * ccos + z * s;
		d[0].z = x * z * ccos - y * s;
		d[1].x = x * y * ccos - z * s;
		d[1].y = y2 + (x2 + z2) * c;
		d[1].z = y * z * ccos + x * s;
		d[2].x = x * z * ccos + y * s;
		d[2].y = y * z * ccos - x * s;
		d[2].z = z2 + (x2 + y2) * c;
		d[3].x = (tx * (y2 + z2) - x * (ty * y + tz * z)) * ccos + (ty * z - tz * y) * s;
		d[3].y = (ty * (x2 + z2) - y * (tx * x + tz * z)) * ccos + (tz * x - tx * z) * s;
		d[3].z = (tz * (x2 + y2) - z * (tx * x + ty * y)) * ccos + (tx * y - ty * x) * s;
		return d;
	}

	/**
	 * 比例缩放
	 * @param scaleX 
	 * @param scaleY 
	 */
	@:vertexglsl public function scaleXYZ(xScale:Float, yScale:Float, zScale:Float):Mat4 {
		return mat4(xScale, 0.0, 0.0, 0.0, 0.0, yScale, 0.0, 0.0, 0.0, 0.0, zScale, 0.0, 0.0, 0.0, 0.0, 1.0);
	}

	/**
	 * 平移
	 * @param x 
	 * @param y 
	 */
	@:vertexglsl public function translation(x:Float, y:Float, z:Float):Mat4 {
		return mat4(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, x, y, 0, 0);
	}

	// @:uniform public var projectionMatrix:Mat4;
	public function vertex() {
		// 缩放 -> 旋转 -> 平移
		var scaleMat4:Mat4 = scaleXYZ(scale.x, scale.y, scale.z);
		var rotaionMat4X:Mat4 = rotaion(rotation.x, vec3(1, 0, 0), vec3(0));
		var rotaionMat4Y:Mat4 = rotaion(rotation.y, vec3(0, 1, 0), vec3(0));
		var rotaionMat4Z:Mat4 = rotaion(rotation.z, vec3(0, 0, 1), vec3(0));
		var transMat4:Mat4 = translation(pos.x, pos.y, pos.z);
		// gl_Position = projectionMatrix * modelViewMatrix * vec4(zy_pos, 1.0) * transMat4 * rotaionMat4X * rotaionMat4Y * rotaionMat4Z * scaleMat4;
		gl_Position = projectionMatrix * (modelViewMatrix * rotaionMat4X * rotaionMat4Y * rotaionMat4Z * scaleMat4 + transMat4) * vec4(zy_pos, 1.0);
		vColor = zy_color;
		vCoord = zy_coord;
	}

	@:precision("mediump float")
	public function fragment() {
		gl_FragColor = texture2D(texture0, vCoord);
	}
}
