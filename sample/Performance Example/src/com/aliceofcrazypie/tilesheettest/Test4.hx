package com.aliceofcrazypie.tilesheettest;
import com.asliceofcrazypie.flash.TextureUtil;
import com.asliceofcrazypie.flash.TilesheetStage3D;
//import net.hires.debug.Stats;
import openfl.Assets;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.Lib;

/**
 * ...
 * @author Paul M Pepper
 */

class Test4 extends ATest
{
	private var tilesheet:TilesheetStage3D;
	private var layer1:Sprite;
	private var layer2:Sprite;
	private var isCleared:Bool;
	
	public function new() 
	{
		super();
	}
	
	
	override private function init():Void 
	{
		super.init();
		
		var bmp:BitmapData = Assets.getBitmapData( 'img/Rock.png' ).clone();
		var rect:Rectangle = bmp.rect.clone();
		#if flash11
		bmp = TextureUtil.fixTextureSize( bmp );
		#end
		var center:Point = new Point( rect.width * 0.5, rect.height * 0.5 );
		
		tilesheet = new TilesheetStage3D( bmp );
		tilesheet.addTileRect( rect, center );
		
		addChild( layer2 = new Sprite() );
		addChild( layer1 = new Sprite() );
		
		addEventListener(Event.ENTER_FRAME, onEnterFrame );
		
		var flags:Int = 0;
		var smooth:Bool = true;
		var tileData:Array<Float>;
		
		
		tileData = [100, 100, 0];
		tilesheet.drawTiles( layer1.graphics, tileData, smooth, flags );
		
		tileData = [110, 110, 0];
		tilesheet.drawTiles( graphics, tileData, smooth, flags );
		
		
		tileData = [105, 105, 0];
		tilesheet.drawTiles( layer2.graphics, tileData, smooth, flags );
		
	//	addChild( new Stats() );
	}
	
	override public function dispose():Void 
	{
		super.dispose();
		
		removeEventListener(Event.ENTER_FRAME, onEnterFrame );
	}
	
	private function onEnterFrame( e:Event ):Void
	{
		if (Lib.getTimer() > 3000)
		{
			#if flash11
			TilesheetStage3D.clear();
			#else
			graphics.clear();
			#end
		}
		
		/*if ( Math.random() > 0.01 )
		{
			swapChildren( layer1, layer2 );
		}*/
	}
}