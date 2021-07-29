package;

import zygame.loader.FBXParser;

class FBXTest {
    
    static function main() {
        trace("开始解析FBX");
        var fbx = new FBXParser(sys.io.File.getBytes("assets/model.fbx"));
    }

}