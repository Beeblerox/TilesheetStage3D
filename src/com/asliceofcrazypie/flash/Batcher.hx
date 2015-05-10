package com.asliceofcrazypie.flash;

import com.asliceofcrazypie.flash.jobs.QuadRenderJob;
import com.asliceofcrazypie.flash.jobs.RenderJob;
import com.asliceofcrazypie.flash.jobs.TriangleRenderJob;
import flash.display.BlendMode;
import flash.display3D.Context3DRenderMode;
import flash.display.Stage;
import flash.display.TriangleCulling;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.Vector;
import openfl.Lib;

/**
 * ...
 * @author Zaphod
 */
class Batcher
{
	public static var gameScaleX(default, set):Float = 1;
	public static var gameScaleY(default, set):Float = 1;
	
	public static var gameX(default, set):Float = 0;
	public static var gameY(default, set):Float = 0;
	
	private static var viewports:Array<Viewport> = [];
	
	public static var numViewports(default, null):Int;
	
	public static var defaultViewport(get, null):Viewport;
	
	private static var _isInited:Bool = false;
	
	private static inline function get_defaultViewport():Viewport
	{
		if (viewports[0] == null)
		{
			addViewport(0, 0, Lib.current.stage.stageWidth / gameScaleX, Lib.current.stage.stageHeight / gameScaleY, 1, 1);
		}
		
		return viewports[0];
	}
	
	public static function getViewport(index:Int):Viewport
	{
		return null;
	}
	
	public static function addViewport(x:Float, y:Float, width:Float, height:Float, scaleX:Float = 1, scaleY:Float = 1):Int
	{
		var viewport:Viewport = new Viewport(x, y, width, height, scaleX, scaleY);
		var index:Int = numViewports;
		viewports[index] = viewport;
		viewport.index = index;
		numViewports++;
		return index;
	}
	
	public static function removeViewport(index:Int):Void
	{
		if (index < numViewports)
		{
			var viewport:Viewport = viewports[index];
			viewport.dispose();
			viewports.splice(index, 1);
			numViewports--;
			for (i in index...(numViewports - 1))
			{
				viewports[i].index = i; 
			}
		}
	}
	
	private static function set_gameScaleX(value:Float):Float
	{
		gameScaleX = value;
		updateViewports();
		return value;
	}
	
	private static function set_gameScaleY(value:Float):Float
	{
		gameScaleY = value;
		updateViewports();
		return value;
	}
	
	private static function set_gameX(value:Float):Float
	{
		gameX = value;
		updateViewports();
		return value;
	}
	
	private static function set_gameY(value:Float):Float
	{
		gameY = value;
		updateViewports();
		return value;
	}
	
	private static function updateViewports():Void
	{
		for (viewport in viewports)
		{
			viewport.update();
		}
	}
	
	public static function init(stage:Stage, stage3DLevel:Int = 0, antiAliasLevel:Int = 5, initCallback:String->Void = null, renderMode:Context3DRenderMode = null, batchSize:Int = 0):Void
	{
		if (!_isInited)
		{
			TilesheetStage3D.init(stage, stage3DLevel, antiAliasLevel, initCallback, renderMode, batchSize);
			TilesheetStage3D.context.renderCallback = render;
		}
	}
	
	private static inline function reset():Void
	{
		for (viewport in viewports)
		{
			viewport.reset();
		}
	}
	
	public static inline function render():Void
	{
		var context = TilesheetStage3D.context;
		for (viewport in viewports)
		{
			viewport.render(context);
		}
	}
	
	public static inline function clear():Void
	{
		TilesheetStage3D.clear();
		reset();
	}
}