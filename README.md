TilesheetStage3D
================

This is a class which extends openfl.display.Tilesheet and adds stage3D support to the drawTiles method, if available.

Ported to Haxe 3/OpenFL by AS3Boyan

Original repository: https://code.google.com/p/tilesheet-stage3d/

Currently it's not very fast at rendering lots of sprites, but at least, it's much better than default Flash fallback(In tilelayer).
Also it has much lower CPU consumption.

### How to use it
    //Init Stage3D
    #if flash11
        TilesheetStage3D.init(stage, 0, 5, init, Context3DRenderMode.AUTO);
    #else
        init();
    #end
		
    function init(?result:String):Void
    {
    //init
    addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }
		
    //Add this before calling drawTiles to onEnterFrame handler
    #if flash11
    TilesheetStage3D.clearGraphic(graphics);
    #end

You can use TilesheetStage3D under the terms of the MIT license.

OpenFL Stage3D drawTiles thread:
http://www.openfl.org/developer/forums/general-discussion/stage3d-based-drawtiles-implementation-alpha/
	
Addition from @Beeblerox:
	
I've made some changes to this fork:
 * removed `SpriteSortItem` class and all functionality around it, this means that `drawTiles()` operations aren't sorted in the order of Sprites they are drawn to (so you need to control draw order for yourself).
 * added drawTriangles() method which works like in `Graphics` class.
 * added `Batcher` class around it.
 * added `Viewport` class which works like some sort of camera (like in Flixel engine).

So here is new usage example:

```
	//Init Batcher and Stage3D
    #if flash11
        Batcher.init(stage, 0, 5, init, Context3DRenderMode.AUTO, 2000); //  where the last parameter is max batch size
    #else
        init();
    #end
		
    function init(?result:String):Void
    {
		//init
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }
		
    //Add this before calling drawTiles to onEnterFrame handler
    #if flash11
    Batcher.clear();	// clearing the stage and all draw operations made in previous render
	
	var view:Viewport = Batcher.defaultViewport;
	view.drawPixels(tilesheet, sourceRect, origin, x, y, scale, scale, rotation, r, g, b, a);
	// add ass many draw operations here as you need
	Batcher.render(); // actual rendering of all added drawing operations
    #end
```

`Viewport` class have following drawing methods:
 * `drawMatrix()` which draws specified `sourceRect` from the image and transforms it around `origin` with specified `matrix`
 * `drawPixels()` which draws specified `sourceRect` from the image and scales and rotates it around `origin`
 * `copyPixels()` which draws specified `sourceRect` from the image at specified position.
 * `drawTriangles()`
 
 Viewports have scale and position properties. And `Batcher` have several methods for creating viewports and controling their draw order, like `addViewport()`, `addViewportAt()`, `removeViewport()`, `removeViewportAt()`, `setViewportIndex()`, `swapViewports()` and some other (i hope that their names talks for themselves).