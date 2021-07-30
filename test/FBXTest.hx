package;

import sys.io.File;
import zygame.loader.OBJParser;
import zygame.loader.FBXParser;

class FBXTest {
	static function main() {
		trace("开始解析FBX");
		var fbx = new FBXParser(sys.io.File.getBytes("assets/idle1.fbx"));

		// var obj = new OBJParser(File.getContent("assets/cube.obj"));

        // trace("\n\n");
		// trace("FBX UVS", fbx.getGeometry("main").uvsArray, fbx.getGeometry("main").uvsArray.length);
        // trace("\n\n");
		// trace("OBJ UVS", obj.getGeometry("main").uvsArray, obj.getGeometry("main").uvsArray.length);
	}
}
