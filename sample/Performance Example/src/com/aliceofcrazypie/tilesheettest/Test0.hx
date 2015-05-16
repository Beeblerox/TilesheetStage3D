package com.aliceofcrazypie.tilesheettest;
import com.asliceofcrazypie.flash.Batcher;
import com.asliceofcrazypie.flash.jobs.TriangleRenderJob;
import com.asliceofcrazypie.flash.TilesheetStage3D;
import com.asliceofcrazypie.flash.Viewport;
import flash.display.DisplayObject;
import openfl.display.Tilesheet;
import flash.events.KeyboardEvent;
import flash.geom.Point;
import openfl.Assets;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.display.BlendMode;
import flash.events.Event;
import flash.geom.Rectangle;
import flash.Lib;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.ui.Keyboard;
import flash.utils.Timer;
import openfl.geom.Matrix;
import openfl.Vector;

/**
 * ...
 * @author Paul M Pepper
 */

class Test0 extends ATest
{
	private var tilesheet:TilesheetStage3D;
	private var cols:Int;
	private var rows:Int;
	private var smooth:Bool;
	private var isRGB:Bool;
	private var isAlpha:Bool;
	private var stats:DisplayObject;
	private var instructions:TextField;
	private var totals:TextField;
	
	var colors:Vector<Int>;
	var batcher:Batcher;
	
	var scale:Float = 1;
	var view:Viewport;
	var view2:Viewport;
	var sourceRect:Rectangle;
	var origin:Point;

	public function new() 
	{
		super();
	}
	
	override private function init():Void 
	{
		//entry point
		var bmp:BitmapData = Assets.getBitmapData('img/Rock.png');
		tilesheet = new TilesheetStage3D(bmp);
		
		sourceRect = new Rectangle(0, 0, 37, 35);
		origin = new Point(0.5 * sourceRect.width, 0.5 * sourceRect.height);
		
		cols = 138;
		rows = 118;
		
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		stage.addEventListener(Event.RESIZE, onStageResize);
		
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
		
		totals = new TextField();
		totals.width = 200;
		totals.height = 20;
		totals.autoSize = TextFieldAutoSize.LEFT;
		totals.selectable = false;
		totals.mouseEnabled = false;
		totals.wordWrap = true;
		totals.multiline = true;
		totals.defaultTextFormat = new TextFormat('_sans', 12, 0xFFFFFF);
		
		updateTotals();
		
		instructions = new TextField();
		instructions.width = 200;
		instructions.height = 200;
		instructions.autoSize = TextFieldAutoSize.LEFT;
		instructions.selectable = false;
		instructions.mouseEnabled = false;
		instructions.wordWrap = true;
		instructions.multiline = true;
		instructions.defaultTextFormat = new TextFormat( '_sans', 12, 0xCCCCCC );
		
		instructions.text = "Spacebar toggles smoothing\nInsert toggles RGB effect\nDelete toggles Alpha Effect\nHome/End increase/decrease rows\nPage Up/Down increase/decrease columns\n\nMoving mouse rotates/scales\n\nNumpad +/- Increases/decreased Antialiasing\n\nEnter toggles between stage3D and fallback rendering\n\nEscape triggers context loss";
		
		addChild(totals);
		addChild(instructions);
		
		onStageResize(null);
	}
	
	override public function dispose():Void 
	{
		removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		stage.removeEventListener(Event.RESIZE, onStageResize);
		
		stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
		
		#if flash11
		TilesheetStage3D.clear();
		tilesheet.dispose();
		#end
		
		graphics.clear();
		
		super.dispose();
	}
	
	private inline function updateTotals():Void
	{
		totals.text = 'Sprites: ' + ( cols * rows ) + ' (' + cols + 'x' + rows + ')';
		#if flash11
		totals.text += "\nRenderer: " + ( Type.enumEq( tilesheet.fallbackMode, FallbackMode.FORCE_FALLBACK ) ? 'fallback renderer' : TilesheetStage3D.driverInfo + "\nAntialias: "+TilesheetStage3D.antiAliasing );
		#end
	}
	
	private function onStageResize(e:Event):Void 
	{
		instructions.x = Math.floor( stage.stageWidth - instructions.width );
		totals.x = Math.floor( stage.stageWidth - totals.width );
	}
	
	private function keyPressed(e:KeyboardEvent):Void 
	{
		switch (e.keyCode)
		{
			case Keyboard.PAGE_UP:
			{
				cols++;
			}
			case Keyboard.PAGE_DOWN:
			{
				cols--;
				cols = Std.int(Math.max(cols, 2));
			}
			case Keyboard.HOME:
			{
				rows++;
			}
			case Keyboard.END:
			{
				rows--;
				rows = Std.int(Math.max(rows, 2));
			}
			case Keyboard.SPACE:
			{
				smooth = !smooth;
			}
			case Keyboard.INSERT:
			{
				isRGB = !isRGB;
			}
			case Keyboard.DELETE:
			{
				isAlpha = !isAlpha;
			}
			case Keyboard.NUMPAD_ADD:
			{
				#if flash11
				TilesheetStage3D.antiAliasing++;
				#end
			}
			case Keyboard.NUMPAD_SUBTRACT:
			{
				#if flash11
				TilesheetStage3D.antiAliasing--;
				#end
			}
			case Keyboard.ENTER:
			{
				#if flash11
				tilesheet.fallbackMode = Type.enumEq(tilesheet.fallbackMode, FallbackMode.ALLOW_FALLBACK ) ? FallbackMode.FORCE_FALLBACK : FallbackMode.ALLOW_FALLBACK;
				#end
			}
			case Keyboard.ESCAPE:
			{
				#if flash11
				stage.stage3Ds[0].context3D.dispose();
				#end
			}
			default:
		}
	}
	
	private function onEnterFrame(e:Event):Void 
	{
		var padding:Float = 10;
		
		var spacingX:Float = (stage.stageWidth - (padding * 2)) / (cols - 1);
		var spacingY:Float = (stage.stageHeight - (padding * 2)) / (rows - 1);
		var scale:Float = 0.1 + stage.mouseY / stage.stageHeight;
		var rotation:Float = (stage.mouseX / stage.stageWidth) * Math.PI * 2;
		
		var view:Viewport = Batcher.defaultViewport;
		
		var x:Float = 0;
		var y:Float = 0;
		
		var r:Float = 1;
		var g:Float = 1;
		var b:Float = 1;
		var a:Float = isAlpha ? Math.abs(Math.sin(Lib.getTimer() / 1000)) : 1;
		
		#if flash11
		Batcher.clear();
		#end
		
		graphics.clear();
		
		for (i in 0...cols)
		{
			for (j in 0...rows)
			{
				x = padding + (i * spacingX);
				y = padding + (j * spacingY);
				
				if (isRGB)
				{
					r = i / cols;
					g = j / rows;
					b = 1;
				}
				
				view.drawPixels(tilesheet, sourceRect, origin, x, y, scale, scale, rotation, r, g, b, a);
			}
		}
		
		Batcher.render();
		
		updateTotals();
	}
	
	//misc methods
	public static inline function clear<T>(array:Array<T>):Void
	{
		#if (cpp||php)
           array.splice(0, array.length);          
        #else
           untyped array.length = 0;
        #end
	}
	
}