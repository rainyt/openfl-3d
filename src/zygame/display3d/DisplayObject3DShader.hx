package zygame.display3d;

import glsl.GLSL.texture2D;
import glsl.Sampler2D;
import VectorMath;
import glsl.OpenFLShader;

@:build(glsl.macro.GLSLCompileMacro.build("glsl"))
class DisplayObject3DShader {
	public var gl_Position:Dynamic;

	public var gl_FragColor:Dynamic;

	public var gl_FragCoord:Dynamic;

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

	@:varying public var vColor:Vec4;

	@:varying public var vCoord:Vec2;

	@:uniform public var texture0:Sampler2D;

	// /**
	//  * 骨骼动画 最大支持68根骨头
	//  */
	@:arrayLen(28)
	@:uniform public var bonesMatrix:Array<Mat4>;

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

	public function vertex() {
		var mat:Mat4 = modelViewMatrix;
		if (boneIndex.x != -1) {
			var bonemat:Mat4 = getBoneMatrix(boneWeight, boneIndex);
			mat = mat * bonemat;
		}
		// 权重 和 骨骼矩阵
		gl_Position = projectionMatrix * (mat) * vec4(zy_pos, 1.0);
		vColor = zy_color;
		vCoord = zy_coord;
	}

	@:precision("mediump float")
	public function fragment() {
		var color:Vec4 = texture2D(texture0, vCoord);
		var f:Float = gl_FragCoord.z;
		gl_FragColor = color * vec4(vec3(f), 1);
	}

	public function int(a:Dynamic):Dynamic {
		return a;
	}
}
