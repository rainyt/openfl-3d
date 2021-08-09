package zygame.utils;

import openfl.display.BitmapData;
import zygame.display3d.BitmapData3D;

class OpenFl3D {
	public static function toBitmapData3D(bitmapData:BitmapData):BitmapData3D {
		return new BitmapData3D(bitmapData);
	}
}
