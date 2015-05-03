package com.asliceofcrazypie.flash;

import com.asliceofcrazypie.flash.jobs.QuadRenderJob;
import com.asliceofcrazypie.flash.jobs.TriangleRenderJob;
import openfl.Vector;
import flash.display.TriangleCulling;
import flash.display.BlendMode;

/**
 * ...
 * @author Zaphod
 */
class Batcher
{
	public static function startQuadBatch(tilesheet:TilesheetStage3D, colored:Bool, blend:BlendMode = null, smooth:Bool = false):QuadRenderJob
	{
		return null;
	}
	
	public static function startTrianglesBatch(tilesheet:TilesheetStage3D, colored:Bool = false, blend:BlendMode = null, smoothing:Bool = false):TriangleRenderJob
	{
		return null;
	}
	/*
	public static function drawPixels(tilesheet:TilesheetStage3D, sourceRect:Rectangle, origin:Point = null, matrix:Matrix, cr:Float = 1.0, cg:Float = 1.0, cb:Float = 1.0, ca:Float = 1.0, blend:BlendMode = null, smoothing:Bool = false):Void
	{
		var colored:Bool = (cr != 1.0) || (cg != 1.0) || (cb != 1.0) || (ca != 1.0);
		#if !FLX_RENDER_TRIANGLE
		var drawItem:FlxDrawTilesItem = startQuadBatch(frame.parent, colored, blend, smoothing);
		#else
		var drawItem:FlxDrawTrianglesItem = startTrianglesBatch(frame.parent, smoothing, colored, blend);
		#end
		drawItem.addQuad(frame, matrix, cr, cg, cb, ca);
	}
	
	public static function copyPixels(tilesheet:TilesheetStage3D, sourceRect:Rectangle, origin:Point = null, destPoint:Point = null, cr:Float = 1.0, cg:Float = 1.0, cb:Float = 1.0, ca:Float = 1.0, blend:BlendMode = null, smoothing:Bool = false):Void
	{
		_helperMatrix.identity();
		_helperMatrix.translate(destPoint.x + frame.offset.x, destPoint.y + frame.offset.y);
		var colored:Bool = (cr != 1.0) || (cg != 1.0) || (cb != 1.0) || (ca != 1.0);
		#if !FLX_RENDER_TRIANGLE
		var drawItem:FlxDrawTilesItem = startQuadBatch(frame.parent, colored, blend, smoothing);
		#else
		var drawItem:FlxDrawTrianglesItem = startTrianglesBatch(frame.parent, smoothing, colored, blend);
		#end
		drawItem.addQuad(frame, _helperMatrix, cr, cg, cb, ca);
	}
	
	public static function drawTriangles(tilesheet:TilesheetStage3D, vertices:Vector<Float>, indices:Vector<Int>, uv:Vector<Float>, colors:Vector<Int> = null, position:Point = null, blend:BlendMode = null, smoothing:Bool = false):Void
	{
		_bounds.set(0, 0, width, height);
		var isColored:Bool = (colors != null && colors.length != 0);
		var drawItem:FlxDrawTrianglesItem = startTrianglesBatch(graphic, smoothing, isColored, blend);
		drawItem.addTriangles(vertices, indices, uvs, colors, position, _bounds);
	}
	*/
}