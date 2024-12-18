## OpenFL-3D

在OpenFL渲染层上支持3D渲染，与普通的渲染对象一起渲染，该库仍然在开发当中，如有问题，可以创建问题。该库仍然在开发中，可能无法正常运行或者编译。
3D rendering is supported on the OpenFL rendering layer, which is rendered together with ordinary rendering objects. The library is still under development. If you have any problems, you can create problems. The library is still under development and may not run or compile normally.

## 例子

```haxe
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
d3d.z = -100;
d3d.scale(100);

// 2D
var quadTop = new Sprite();
quadTop.graphics.beginFill(0xff0000);
quadTop.graphics.drawCircle(0, 0, 100);
quadTop.x = stage.stageWidth / 2 + 100;
quadTop.y = stage.stageHeight / 2 + 100;
this.addChild(quadTop);

this.addEventListener(Event.ENTER_FRAME, (e) -> {
    d3d.rotationX++;
    d3d.rotationZ++;
});
```

## 依赖库

- openfl 9.1.x+
- openfl-glsl
- lime

## 当前已支持
- 3D模型渲染，可以跟2D混合渲染
- OBJ模型读取
- 纹理UV映射
- 角度XYZ
- FBX模型读取
- FBX骨骼动画
- FBX轨迹动画支持

## 限制
- 当前仅支持最大28根骨头

## 路线图

1. 支持在2D层之间渲染3D对象。
2. 支持载入3D模型。
3. 支持纹理。
4. 支持3D动画。
5. 支持各种格式的模型文件（例如FBX？）。
