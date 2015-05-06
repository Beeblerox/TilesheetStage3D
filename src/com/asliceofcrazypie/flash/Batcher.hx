package com.asliceofcrazypie.flash;

import com.asliceofcrazypie.flash.jobs.QuadRenderJob;
import com.asliceofcrazypie.flash.jobs.RenderJob;
import com.asliceofcrazypie.flash.jobs.TriangleRenderJob;
import openfl.geom.Matrix;
import openfl.Vector;
import flash.display.TriangleCulling;
import flash.display.BlendMode;

/**
 * ...
 * @author Zaphod
 */
class Batcher
{
	private static var matrix:Matrix = new Matrix();
	
	private var numRenderJobs:Int = 0;
	private var numQuadRenderJobs:Int = 0;
	private var numTriangleRenderJobs:Int = 0;
	
	private var renderJobs:Vector<RenderJob>;
	private var quadRenderJobs:Vector<QuadRenderJob>;
	private var triangleRenderJobs:Vector<TriangleRenderJob>;
	
	public function new()
	{
		renderJobs = new Vector<RenderJob>();
		quadRenderJobs = new Vector<QuadRenderJob>();
		triangleRenderJobs = new Vector<TriangleRenderJob>();
		
		
	}
	
	public inline function getLastRenderJob():RenderJob
	{
		return currentRenderJobs[numRenderJobs - 1];
	}
	
	public inline function getLastQuadRenderJob():QuadRenderJob
	{
		return quadRenderJobs[numQuadRenderJobs - 1];
	}
	
	public inline function getLastTrianglesRenderJob():TriangleRenderJob
	{
		return triangleRenderJobs[numTriangleRenderJobs - 1];
	}
	
	public inline function reset():Void
	{
		for (renderJob in quadRenderJobs)
		{
			renderJob.reset();
			QuadRenderJob.returnJob(renderJob);
		}
		
		for (renderJob in triangleRenderJobs)
		{
			renderJob.reset();
			TriangleRenderJob.returnJob(renderJob);
		}
		
		untyped renderJobs.length = 0;
		untyped quadRenderJobs.length = 0;
		untyped triangleRenderJobs.length = 0;
		
		numRenderJobs = 0;
		numQuadRenderJobs = 0;
		numTriangleRenderJobs = 0;
	}
	
	public inline function render():Void
	{
		for (job in renderJobs)
		{
			TilesheetStage3D.context.renderJob(job);
		}
		
		TilesheetStage3D.context.present();
	}
	
	public function startQuadBatch(tilesheet:TilesheetStage3D, tinted:Bool, alpha:Bool, blend:BlendMode = null, smooth:Bool = false):QuadRenderJob
	{
		var lastRenderJob:RenderJob = getLastRenderJob();
		var lastQuadRenderJob:QuadRenderJob = getLastQuadRenderJob();
		
		if (lastRenderJob == lastQuadRenderJob 
			&& tilesheet.texture == lastRenderJob.texture
			&& tinted == lastRenderJob.isRGB
			&& alpha == lastRenderJob.isAlpha
			&& smooth == lastRenderJob.isSmooth
			&& blend == lastRenderJob.blendMode
			&& tilesheet.premultipliedAlpha == lastRenderJob.premultipliedAlpha) // TODO: add check/change for number of vertices / indices later...
		{
			return lastQuadRenderJob;
		}
		
		return startNewQuadBatch(tilesheet, tinted, alpha, blend, smooth);
	}
	
	public function startNewQuadBatch(tilesheet:TilesheetStage3D, tinted:Bool, alpha:Bool, blend:BlendMode = null, smooth:Bool = false):QuadRenderJob
	{
		var job:QuadRenderJob = QuadRenderJob.getJob(tilesheet.texture, tinted, alpha, smooth, blend, tilesheet.premultipliedAlpha);
		
		renderJobs[numRenderJobs++] = job;
		quadRenderJobs[numQuadRenderJobs++] = job;
		
		return job;
	}
	
	public function startTrianglesBatch(tilesheet:TilesheetStage3D, colored:Bool = false, blend:BlendMode = null, smoothing:Bool = false):TriangleRenderJob
	{
		var lastRenderJob:RenderJob = getLastRenderJob();
		var lastTriangleRenderJob:TriangleRenderJob = getLastTrianglesRenderJob();
		
		if (lastRenderJob == lastTriangleRenderJob 
			&& tilesheet.texture == lastRenderJob.texture
			&& colored == lastRenderJob.isRGB
			&& colored == lastRenderJob.isAlpha
			&& smooth == lastRenderJob.isSmooth
			&& blend == lastRenderJob.blendMode
			&& tilesheet.premultipliedAlpha == lastRenderJob.premultipliedAlpha) // TODO: add check/change for number of vertices / indices later...
		{
			return lastTriangleRenderJob;
		}
		
		return getNewTrianglesBatch(tilesheet, colored, blend, smoothing);
	}
	
	public function getNewTrianglesBatch(tilesheet:TilesheetStage3D, colored:Bool = false, blend:BlendMode = null, smoothing:Bool = false):TriangleRenderJob
	{
		var job:TriangleRenderJob = TriangleRenderJob.getJob(tilesheet.texture, colored, colored, smoothing, blend, tilesheet.premultipliedAlpha);
		
		renderJobs[numRenderJobs++] = job;
		triangleRenderJobs[numTriangleRenderJobs++] = job;
		
		return job;
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