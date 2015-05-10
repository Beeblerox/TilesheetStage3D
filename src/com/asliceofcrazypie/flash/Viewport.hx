package com.asliceofcrazypie.flash;

import com.asliceofcrazypie.flash.jobs.QuadRenderJob;
import com.asliceofcrazypie.flash.jobs.RenderJob;
import com.asliceofcrazypie.flash.jobs.TriangleRenderJob;
import openfl.display.BlendMode;
import openfl.geom.Matrix;
import openfl.geom.Matrix3D;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.Vector;

/**
 * ...
 * @author Zaphod
 */
class Viewport
{
	public var matrix(default, null):Matrix3D;
	
	public var scissor(default, null):Rectangle;
	
	public var x(default, set):Float;
	public var y(default, set):Float;
	
	public var width(default, set):Float;
	public var height(default, set):Float;
	
	public var scaleX(default, set):Float;
	public var scaleY(default, set):Float;
	
	public var index:Int;
	
	private static var helperMatrix:Matrix = new Matrix();
	
	private var numRenderJobs:Int = 0;
	private var numQuadRenderJobs:Int = 0;
	private var numTriangleRenderJobs:Int = 0;
	
	private var renderJobs:Vector<RenderJob>;
	private var quadRenderJobs:Vector<QuadRenderJob>;
	private var triangleRenderJobs:Vector<TriangleRenderJob>;
	
	public function new(x:Float, y:Float, width:Float, height:Float, scaleX:Float, scaleY:Float) 
	{
		scissor = new Rectangle();
		matrix = new Matrix3D();
		
		renderJobs = new Vector<RenderJob>();
		quadRenderJobs = new Vector<QuadRenderJob>();
		triangleRenderJobs = new Vector<TriangleRenderJob>();
		
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}
	
	public function dispose():Void
	{
		
	}
	
	private inline function getLastRenderJob():RenderJob
	{
		return (numRenderJobs > 0) ? renderJobs[numRenderJobs - 1] : null;
	}
	
	private inline function getLastQuadRenderJob():QuadRenderJob
	{
		return (numQuadRenderJobs > 0) ? quadRenderJobs[numQuadRenderJobs - 1] : null;
	}
	
	private inline function getLastTrianglesRenderJob():TriangleRenderJob
	{
		return (numTriangleRenderJobs > 0) ? triangleRenderJobs[numTriangleRenderJobs - 1] : null;
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
	
	public inline function render(context:ContextWrapper):Void
	{
		for (job in renderJobs)
		{
			context.renderJob(job);
		}
	}
	
	public function startQuadBatch(tilesheet:TilesheetStage3D, tinted:Bool, alpha:Bool, blend:BlendMode = null, smooth:Bool = false):QuadRenderJob
	{
		var lastRenderJob:RenderJob = getLastRenderJob();
		var lastQuadRenderJob:QuadRenderJob = getLastQuadRenderJob();
		
		if (lastRenderJob != null && lastQuadRenderJob != null
			&& lastRenderJob == lastQuadRenderJob 
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
	
	public inline function startNewQuadBatch(tilesheet:TilesheetStage3D, tinted:Bool, alpha:Bool, blend:BlendMode = null, smooth:Bool = false):QuadRenderJob
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
		
		if (lastRenderJob != null && lastTriangleRenderJob != null
			&& lastRenderJob == lastTriangleRenderJob 
			&& tilesheet.texture == lastRenderJob.texture
			&& colored == lastRenderJob.isRGB
			&& colored == lastRenderJob.isAlpha
			&& smoothing == lastRenderJob.isSmooth
			&& blend == lastRenderJob.blendMode
			&& tilesheet.premultipliedAlpha == lastRenderJob.premultipliedAlpha) // TODO: add check/change for number of vertices / indices later...
		{
			return lastTriangleRenderJob;
		}
		
		return startNewTrianglesBatch(tilesheet, colored, blend, smoothing);
	}
	
	public inline function startNewTrianglesBatch(tilesheet:TilesheetStage3D, colored:Bool = false, blend:BlendMode = null, smoothing:Bool = false):TriangleRenderJob
	{
		var job:TriangleRenderJob = TriangleRenderJob.getJob(tilesheet.texture, colored, colored, smoothing, blend, tilesheet.premultipliedAlpha);
		renderJobs[numRenderJobs++] = job;
		triangleRenderJobs[numTriangleRenderJobs++] = job;
		return job;
	}
	
	public inline function drawPixels(tilesheet:TilesheetStage3D, sourceRect:Rectangle, origin:Point, uv:Rectangle, matrix:Matrix, cr:Float = 1.0, cg:Float = 1.0, cb:Float = 1.0, ca:Float = 1.0, blend:BlendMode = null, smoothing:Bool = false):Void
	{
		var colored:Bool = (cr != 1.0) || (cg != 1.0) || (cb != 1.0) || (ca != 1.0);
		var job:QuadRenderJob = startQuadBatch(tilesheet, colored, colored, blend, smoothing);
		
		if (!job.canAddQuad())
		{
			job = startNewQuadBatch(tilesheet, colored, colored, blend, smoothing);
		}
		
		job.addQuad(sourceRect, origin, uv, matrix, cr, cg, cb, ca);
	}
	
	public function copyPixels(tilesheet:TilesheetStage3D, sourceRect:Rectangle, origin:Point, uv:Rectangle, destPoint:Point = null, cr:Float = 1.0, cg:Float = 1.0, cb:Float = 1.0, ca:Float = 1.0, blend:BlendMode = null, smoothing:Bool = false):Void
	{
		helperMatrix.identity();
		helperMatrix.translate(destPoint.x, destPoint.y);
		drawPixels(tilesheet, sourceRect, origin, uv, helperMatrix, cr, cg, cb, ca, blend, smoothing);
	}
	
	public function drawTriangles(tilesheet:TilesheetStage3D, vertices:Vector<Float>, indices:Vector<Int>, uv:Vector<Float>, colors:Vector<Int> = null, blend:BlendMode = null, smoothing:Bool = false):Void
	{
		var colored:Bool = (colors != null && colors.length != 0);
		var job:TriangleRenderJob = startTrianglesBatch(tilesheet, colored, blend, smoothing);
		var numVertices:Int = vertices.length;
		
		if (!job.canAddTriangles(numVertices))
		{
			if (job.checkMaxTrianglesCapacity(numVertices))
			{
				job = startNewTrianglesBatch(tilesheet, colored, blend, smoothing);
			}
			else
			{
				return; // too much triangles, even for the new batch
			}
		}
		
		job.addTriangles(vertices, indices, uv, colors);
	}
	
	private function set_x(value:Float):Float
	{
		return x = value;
	}
	
	private function set_y(value:Float):Float
	{
		return y = value;
	}
	
	private function set_width(value:Float):Float
	{
		return width = value;
	}
	
	private function set_height(value:Float):Float
	{
		return height = value;
	}
	
	private function set_scaleX(value:Float):Float
	{
		return scaleX = value;
	}
	
	private function set_scaleY(value:Float):Float
	{
		return scaleY = value;
	}
}