## OpenFL-3D

在OpenFL渲染层上支持3D渲染，与普通的渲染对象一起渲染，该库仍然在开发当中，如有问题，可以创建问题。该库仍然在开发中，可能无法正常运行或者编译。
3D rendering is supported on the OpenFL rendering layer, which is rendered together with ordinary rendering objects. The library is still under development. If you have any problems, you can create problems. The library is still under development and may not run or compile normally.

## 例子

```haxe
// 2D
var quadBottom = new ZQuad();
quadBottom.width = getStageWidth() / 2;
quadBottom.height = getStageHeight() / 2;
this.addChild(quadBottom);

// 3D
var d3d = new CubeDisplayObject();
this.addChild(d3d);
d3d.x = getStageWidth() / 2;
d3d.y = getStageHeight() / 2;

// 2D
var quadTop = new ZQuad();
quadTop.width = getStageWidth() / 2;
quadTop.height = getStageHeight() / 2;
quadTop.x = getStageWidth() / 2;
quadTop.y = getStageHeight() / 2;
this.addChild(quadTop);
```

## 依赖库

- openfl 9.1.x+
- openfl-glsl
- lime

## 路线图

1. 支持在2D层之间渲染3D对象。
2. 支持载入3D模型。
3. 支持纹理。
4. 支持3D动画。
5. 支持各种格式的模型文件（例如FBX？）。
