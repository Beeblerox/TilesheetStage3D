package com.asliceofcrazypie.flash;

import com.asliceofcrazypie.flash.jobs.QuadRenderJob;
import com.asliceofcrazypie.flash.jobs.RenderJob;
import com.asliceofcrazypie.flash.jobs.TriangleRenderJob;
import flash.display.BlendMode;
import flash.display.Stage;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.Vector;

import openfl.Lib;

/**
 * Some sort of camera class (works like camera in Flixel engine). Can be zoomed in/out, moved and resized.
 * @author Zaphod
 */
class Viewport
{
	private static var helperMatrix:Matrix = new Matrix();
	private static var helperRect:Rectangle = new Rectangle();
	
	/**
	 * Viewport transformation matrix
	 */
	public var matrix(default, null):Matrix3D;
	
	/**
	 * Viewport scissor rectangle for clipping everything that's outside viewport bounds
	 */
	public var scissor(default, null):Rectangle;
	
	/**
	 * Viewport position. Actual position on the screen is affected by Batcher's gameX/gameY and gameScaleX/gameScaleY values.
	 */
	public var x(default, set):Float;
	public var y(default, set):Float;
	
	/**
	 * Viewport dimensions. Actual size on the screen is affected by Batcher's gameScaleX/gameScaleY values.
	 */
	public var width(default, set):Float;
	public var height(default, set):Float;
	
	/**
	 * Viewport scale. Result scale on the screen equals to the product of viewport scale and Batcher's gameScale.
	 */
	public var scaleX(default, set):Float;
	public var scaleY(default, set):Float;
	
	/**
	 * Draw order of the viewport. Don't change it manually.
	 */
	public var index:Int;
	
	/**
	 * Initial viewport scale.
	 */
	private var initialScaleX:Float;
	private var initialScaleY:Float;
	
	private var numRenderJobs:Int = 0;
	private var numQuadRenderJobs:Int = 0;
	private var numTriangleRenderJobs:Int = 0;
	
	private var renderJobs:Vector<RenderJob>;
	private var quadRenderJobs:Vector<QuadRenderJob>;
	private var triangleRenderJobs:Vector<TriangleRenderJob>;
	
	// TODO: add viewport tinting (this will require adding new shaders or some additional multiplications)...
	
	/**
	 * Viewport consctructor.
	 * 
	 * @param	x		x position of viewport
	 * @param	y		y position of viewport
	 * @param	width	width of viewport
	 * @param	height	height of viewport
	 * @param	scaleX	initial x scale of viewport
	 * @param	scaleY	initial y scale of viewport
	 */
	public function new(x:Float, y:Float, width:Float, height:Float, scaleX:Float = 1, scaleY:Float = 1) 
	{
		scissor = new Rectangle();
		matrix = new Matrix3D();
		
		renderJobs = new Vector<RenderJob>();
		quadRenderJobs = new Vector<QuadRenderJob>();
		triangleRenderJobs = new Vector<TriangleRenderJob>();
		
		initialScaleX = scaleX;
		initialScaleY = scaleY;
		
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		this.scaleX = scaleX;
		this.scaleY = scaleY;
	}
	
	/**
	 * Viewport disposing method for nulling some variables, which should help automatic garbage collection.
	 */
	public function dispose():Void
	{
		reset();
		renderJobs = null;
		quadRenderJobs = null;
		triangleRenderJobs = null;
		
		scissor = null;
		matrix = null;
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
	
	/**
	 * Reseting Viewport before next rendering.
	 */
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
		context.setMatrix(matrix);
		context.setScissor(scissor);
		
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
			&& tilesheet.premultipliedAlpha == lastRenderJob.premultipliedAlpha)
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
			&& tilesheet.premultipliedAlpha == lastRenderJob.premultipliedAlpha) 
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
	
	/**
	 * Drawing transformed part of image. 
	 * 
	 * @param	tilesheet
	 * @param	sourceRect
	 * @param	origin
	 * @param	matrix
	 * @param	cr
	 * @param	cg
	 * @param	cb
	 * @param	ca
	 * @param	blend
	 * @param	smoothing
	 */
	public inline function drawPixels(tilesheet:TilesheetStage3D, sourceRect:Rectangle, origin:Point, matrix:Matrix, cr:Float = 1.0, cg:Float = 1.0, cb:Float = 1.0, ca:Float = 1.0, blend:BlendMode = null, smoothing:Bool = false):Void
	{
		var uv:Rectangle = Viewport.helperRect;
		uv.setTo(sourceRect.left / tilesheet.bitmapWidth, sourceRect.top / tilesheet.bitmapHeight, sourceRect.right / tilesheet.bitmapWidth, sourceRect.bottom / tilesheet.bitmapHeight);
		drawPixels2(tilesheet, sourceRect, origin, uv, matrix, cr, cg, cb, ca, blend, smoothing);
	}
	
	/**
	 * 
	 * 
	 * @param	tilesheet
	 * @param	sourceRect
	 * @param	origin
	 * @param	uv
	 * @param	matrix
	 * @param	cr
	 * @param	cg
	 * @param	cb
	 * @param	ca
	 * @param	blend
	 * @param	smoothing
	 */
	public inline function drawPixels2(tilesheet:TilesheetStage3D, sourceRect:Rectangle, origin:Point, uv:Rectangle, matrix:Matrix, cr:Float = 1.0, cg:Float = 1.0, cb:Float = 1.0, ca:Float = 1.0, blend:BlendMode = null, smoothing:Bool = false):Void
	{
		var colored:Bool = (cr != 1.0) || (cg != 1.0) || (cb != 1.0) || (ca != 1.0);
		var job:QuadRenderJob = startQuadBatch(tilesheet, colored, colored, blend, smoothing);
		
		if (!job.canAddQuad())
		{
			job = startNewQuadBatch(tilesheet, colored, colored, blend, smoothing);
		}
		
		job.addQuad(sourceRect, origin, uv, matrix, cr, cg, cb, ca);
	}
	
	public function copyPixels(tilesheet:TilesheetStage3D, sourceRect:Rectangle, origin:Point, destPoint:Point = null, cr:Float = 1.0, cg:Float = 1.0, cb:Float = 1.0, ca:Float = 1.0, blend:BlendMode = null, smoothing:Bool = false):Void
	{
		helperMatrix.identity();
		var destX:Float = 0;
		var destY:Float = 0;
		if (destPoint != null)
		{
			destX = destPoint.x;
			destY = destPoint.y;
		}
		helperMatrix.translate(destX, destY);
		drawPixels(tilesheet, sourceRect, origin, helperMatrix, cr, cg, cb, ca, blend, smoothing);
	}
	
	public function copyPixels2(tilesheet:TilesheetStage3D, sourceRect:Rectangle, origin:Point, uv:Rectangle, destPoint:Point = null, cr:Float = 1.0, cg:Float = 1.0, cb:Float = 1.0, ca:Float = 1.0, blend:BlendMode = null, smoothing:Bool = false):Void
	{
		helperMatrix.identity();
		helperMatrix.translate(destPoint.x, destPoint.y);
		drawPixels2(tilesheet, sourceRect, origin, uv, helperMatrix, cr, cg, cb, ca, blend, smoothing);
	}
	
	public function drawTriangles(tilesheet:TilesheetStage3D, vertices:Vector<Float>, indices:Vector<Int>, uv:Vector<Float>, colors:Vector<Int> = null, blend:BlendMode = null, smoothing:Bool = false, position:Point = null):Void
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
		
		job.addTriangles(vertices, indices, uv, colors, position);
	}
	
	private function set_x(value:Float):Float
	{
		x = value;
		update();
		return value;
	}
	
	private function set_y(value:Float):Float
	{
		y = value;
		update();
		return value;
	}
	
	private function set_width(value:Float):Float
	{
		width = value;
		update();
		return value;
	}
	
	private function set_height(value:Float):Float
	{
		height = value;
		update();
		return value;
	}
	
	private function set_scaleX(value:Float):Float
	{
		scaleX = value;
		update();
		return value;
	}
	
	private function set_scaleY(value:Float):Float
	{
		scaleY = value;
		update();
		return value;
	}
	
	private function updateMatrix():Void
	{
		if (matrix == null)	return;
		
		var stage:Stage = Lib.current.stage;
		
		var totalScaleX:Float = scaleX * Batcher.gameScaleX;
		var totalScaleY:Float = scaleY * Batcher.gameScaleY;
		
		matrix.identity();
		matrix.appendTranslation( -0.5 * stage.stageWidth / totalScaleX, -0.5 * stage.stageHeight / totalScaleY, 0);
		// viewport position
		matrix.appendTranslation(	Batcher.gameX / totalScaleX,
									Batcher.gameY / totalScaleY,
									0); // game position offset
									
		matrix.appendTranslation(	(x + 0.5 * width) / scaleX,
									(y + 0.5 * height) / scaleY,
									0); // viewport center offset
									
		matrix.appendTranslation(	-0.5 * width / initialScaleX,
									-0.5 * height / initialScaleY,
									0); // viewport top left corner
		
		matrix.appendScale(2 / stage.stageWidth, -2 / stage.stageHeight, 1);
		matrix.appendScale(totalScaleX, totalScaleY, 1); // total viewport scale
	}
	
	private function updateScissor():Void
	{
		if (scissor == null)	return;
		
		scissor.setTo(	Batcher.gameX + x * Batcher.gameScaleX, 
						Batcher.gameY + y * Batcher.gameScaleY, 
						width * Batcher.gameScaleX, 
						height * Batcher.gameScaleY);
	}
	
	public function update():Void
	{
		updateMatrix();
		updateScissor();
	}
}