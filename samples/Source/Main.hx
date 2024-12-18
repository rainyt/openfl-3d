package;

import openfl.events.MouseEvent;
import openfl.events.RenderEvent;
import openfl.Assets;
import zygame.display3d.BitmapData3D;
import openfl.events.Event;
import zygame.display3d.CubeDisplayObject;
import openfl.display.Sprite;

class Main extends Sprite {
	public function new() {
		super();

		stage.color = 0x0;

		// 2D
		var quadBottom = new Sprite();
		quadBottom.graphics.beginFill(0xff0000);
		quadBottom.graphics.drawCircle(0, 0, 100);
		this.addChild(quadBottom);
		quadBottom.x = stage.stageWidth / 2 - 100;
		quadBottom.y = stage.stageHeight / 2 - 100;

		// 3D
		var d3d = new CubeDisplayObject();
		this.addChild(d3d);
		d3d.texture = new BitmapData3D(Assets.getBitmapData("assets/1_0.png"));
		d3d.x = stage.stageWidth / 2;
		d3d.y = stage.stageHeight / 2;
		d3d.rotationY = 45;
		d3d.scale(100);

		// 2D
		var quadTop = new Sprite();
		quadTop.graphics.beginFill(0xff0000);
		quadTop.graphics.drawCircle(0, 0, 100);
		quadTop.x = stage.stageWidth / 2 + 100;
		quadTop.y = stage.stageHeight / 2 + 100;
		this.addChild(quadTop);

		var isStop = false;
		stage.addEventListener(MouseEvent.CLICK, (e) -> {
			isStop = !isStop;
		});
		this.addEventListener(Event.ENTER_FRAME, (e) -> {
			if (!isStop) {
				d3d.rotationY++;
				d3d.rotationZ++;
			}
		});
	}
}
