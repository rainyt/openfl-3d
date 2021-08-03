package zygame.display3d;

import glsl.GLSL.texture2D;
import glsl.Sampler2D;
import VectorMath;
import glsl.OpenFLShader;

// @:debug
@:build(glsl.macro.GLSLCompileMacro.build("glsl"))
class DisplayObject3DShader {
	public var gl_Position:Dynamic;

	public var gl_FragColor:Dynamic;

	/**
	 * 3D顶点
	 */
	@:attribute public var zy_pos:Vec3;

	/**
	 * 3D顶点颜色
	 */
	@:attribute public var zy_color:Vec4;

	/**
	 * 3D纹理
	 */
	@:attribute public var zy_coord:Vec2;

	/**
	 * 骨骼索引
	 */
	@:attribute public var boneIndex:Vec4;

	/**
	 * 骨骼影响权重
	 */
	@:attribute public var boneWeight:Vec4;

	/**
	 * 相机模型矩阵
	 */
	@:uniform public var modelViewMatrix:Mat4;

	/**
	 * 视角矩阵
	 */
	@:uniform public var projectionMatrix:Mat4;

	/**
	 * 骨骼动画 最大支持68根骨头
	 */
	@:arrayLen(68)
	@:uniform public var bonesMatrix:Array<Mat4>;

	@:varying public var vColor:Vec4;

	@:varying public var vCoord:Vec2;

	@:uniform public var texture0:Sampler2D;

	@:vertexglsl public function getBoneMatrixByIndex(i:Float):Mat4 {
		var bone:Mat4 = bonesMatrix[int(i)];
		return bone;
	}

	@:vertexglsl public function getBoneMatrix(a_weights:Vec4, a_indices:Vec4):Mat4 {
		var skinMat:Mat4 = a_weights.x * getBoneMatrixByIndex(a_indices.x);
		skinMat += a_weights.y * getBoneMatrixByIndex(a_indices.y);
		skinMat += a_weights.z * getBoneMatrixByIndex(a_indices.z);
		skinMat += a_weights.w * getBoneMatrixByIndex(a_indices.w);
		return skinMat;
	}

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
		// var scaleMat4:Mat4 = scaleXYZ(scale.x, scale.y, scale.z);
		// var rotaionMat4X:Mat4 = rotaion(rotation.x, vec3(1, 0, 0), vec3(0));
		// var rotaionMat4Y:Mat4 = rotaion(rotation.y, vec3(0, 1, 0), vec3(0));
		// var rotaionMat4Z:Mat4 = rotaion(rotation.z, vec3(0, 0, 1), vec3(0));
		// var transMat4:Mat4 = translation(0.5, 0.5, 0);
		// gl_Position = projectionMatrix * modelViewMatrix * vec4(zy_pos, 1.0) * transMat4 * rotaionMat4X * rotaionMat4Y * rotaionMat4Z * scaleMat4;
		// gl_Position = projectionMatrix * (modelViewMatrix * rotaionMat4X * rotaionMat4Y * rotaionMat4Z * scaleMat4 + transMat4) * vec4(zy_pos, 1.0);
		//
		var mat:Mat4 = modelViewMatrix;
		if (boneIndex.x != -1) {
			var bonemat:Mat4 = getBoneMatrix(boneWeight, boneIndex);
			mat = mat * bonemat;
		}
		// 权重 和 骨骼矩阵
		// var mat2:Mat4 =  * (boneWeight * bonesMatrix[int(boneIndex)]);
		// var mat:Mat4 = (boneWeight * bonesMatrix[int(boneIndex)]) * transMat4;
		// mat = boneWeight * bonesMatrix[int(boneIndex)];
		// gl_Position = projectionMatrix * mat * vec4(zy_pos, 1.0);
		gl_Position = projectionMatrix * (mat) * vec4(zy_pos, 1.0);
		vColor = zy_color;
		vCoord = zy_coord;
	}

	@:precision("mediump float")
	public function fragment() {
		gl_FragColor = texture2D(texture0, vCoord);
	}

	public function int(a:Dynamic):Dynamic {
		return a;
	}
}
