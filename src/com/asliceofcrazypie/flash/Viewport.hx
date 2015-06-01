package com.asliceofcrazypie.flash;

import com.asliceofcrazypie.flash.jobs.QuadRenderJob;
import com.asliceofcrazypie.flash.jobs.RenderJob;
import com.asliceofcrazypie.flash.jobs.BaseRenderJob;
import com.asliceofcrazypie.flash.jobs.ColorRenderJob;
import com.asliceofcrazypie.flash.jobs.TriangleRenderJob;
import flash.display.BlendMode;
import flash.display.Stage;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.Vector;
import openfl.display.Sprite;

import openfl.Lib;

/**
 * Some sort of camera class (works like camera in Flixel engine). Can be zoomed in/out, moved and resized.
 * @author Zaphod
 */
class Viewport
{
	private static var helperMatrix:Matrix = new Matrix();
	private static var helperRect:Rectangle = new Rectangle();
	private static var helperPoint:Point = new Point();
	private static var helperPoint2:Point = new Point();
	
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
	public var x(default, set):Float = 0;
	public var y(default, set):Float = 0;
	
	/**
	 * Viewport dimensions. Actual size on the screen is affected by Batcher's gameScaleX/gameScaleY values.
	 */
	public var width(default, set):Float = 0;
	public var height(default, set):Float = 0;
	
	/**
	 * Viewport scale. Result scale on the screen equals to the product of viewport scale and Batcher's gameScale.
	 */
	public var scaleX(default, set):Float = 1;
	public var scaleY(default, set):Float = 1;
	
	/**
	 * Draw order of the viewport. Don't change it manually.
	 */
	// TODO: convert it to property...
	public var index(default, set):Int;
	
	/**
	 * Whether to render this viewport or not
	 */
	public var visible(default, set):Bool = true;
	
	/**
	 * Initial viewport scale.
	 */
	private var initialScaleX:Float = 1;
	private var initialScaleY:Float = 1;
	
	#if flash11
	private var numRenderJobs:Int = 0;
	private var numQuadRenderJobs:Int = 0;
	private var numTriangleRenderJobs:Int = 0;
	private var numColorRenderJobs:Int = 0;
	
	private var renderJobs:Vector<BaseRenderJob>;
	private var quadRenderJobs:Vector<QuadRenderJob>;
	private var triangleRenderJobs:Vector<TriangleRenderJob>;
	private var colorRenderJobs:Vector<ColorRenderJob>;
	
	private var bgRenderJob:ColorRenderJob;
	#else
	private var currentRenderJob:BaseRenderJob;
	private var quadRenderJob:QuadRenderJob;
	private var triangleRenderJob:TriangleRenderJob;
	private var colorRenderJob:ColorRenderJob;
	#end
	
	public var color(get, set):UInt;
	public var cRed(default, set):Float = 1.0;
	public var cGreen(default, set):Float = 1.0;
	public var cBlue(default, set):Float = 1.0;
	public var cAlpha(default, set):Float = 1.0;
	
	private var isColored:Bool = false;
	
	public var bgColor(get, set):UInt;
	public var bgRed:Float = 0.0;
	public var bgGreen:Float = 0.0;
	public var bgBlue:Float = 0.0;
	public var bgAlpha:Float = 0.0;
	
	public var useBgColor:Bool = false;
	
	private var view:Sprite;
	
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
		view = new Sprite();
		
		scissor = new Rectangle();
		matrix = new Matrix3D();
		
		#if flash11
		renderJobs = new Vector<BaseRenderJob>();
		quadRenderJobs = new Vector<QuadRenderJob>();
		triangleRenderJobs = new Vector<TriangleRenderJob>();
		colorRenderJobs = new Vector<ColorRenderJob>();
		bgRenderJob = ColorRenderJob.getJob();
		#else
		quadRenderJob = new QuadRenderJob();
		triangleRenderJob = new TriangleRenderJob();
		colorRenderJob = new ColorRenderJob();
		#end
		
		initialScaleX = scaleX;
		initialScaleY = scaleY;
		
		this.scaleX = scaleX;
		this.scaleY = scaleY;
		
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}
	
	/**
	 * Viewport disposing method for nulling some variables, which should help automatic garbage collection.
	 */
	public function dispose():Void
	{
		reset();
		
		#if flash11
		renderJobs = null;
		quadRenderJobs = null;
		triangleRenderJobs = null;
		colorRenderJobs = null;
		
		ColorRenderJob.returnJob(bgRenderJob);
		bgRenderJob = null;
		#else
		quadRenderJob = null;
		triangleRenderJob = null;
		colorRenderJob = null;
		#end
		
		scissor = null;
		matrix = null;
		
		view = null;
	}
	
	#if flash11
	private inline function getLastRenderJob():BaseRenderJob
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
	
	private inline function getLastColorRenderJob():ColorRenderJob
	{
		return (numColorRenderJobs > 0) ? colorRenderJobs[numColorRenderJobs - 1] : null;
	}
	#end
	
	/**
	 * Reseting Viewport before next rendering.
	 */
	public inline function reset():Void
	{
		#if flash11
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
		
		for (renderJob in colorRenderJobs)
		{
			renderJob.reset();
			ColorRenderJob.returnJob(renderJob);
		}
		
		bgRenderJob.reset();
		
		untyped renderJobs.length = 0;
		untyped quadRenderJobs.length = 0;
		untyped triangleRenderJobs.length = 0;
		untyped colorRenderJobs.length = 0;
		
		numRenderJobs = 0;
		numQuadRenderJobs = 0;
		numTriangleRenderJobs = 0;
		numColorRenderJobs = 0;
		#else
		quadRenderJob.reset();
		triangleRenderJob.reset();
		colorRenderJob.reset();
		currentRenderJob = null;
		#end
	}
	
	#if flash11
	public inline function render(context:ContextWrapper):Void
	{
		if (!visible)	return;
		
		context.setMatrix(matrix);
		context.setScissor(scissor);
		
		if (isColored) context.setColorMultiplier(cRed, cGreen, cBlue, cAlpha);
		
		if (useBgColor)
		{
			helperRect.setTo(0, 0, width + 1, height + 1);
			bgRenderJob.addAAQuad(helperRect, bgRed, bgGreen, bgBlue, bgAlpha);
			context.renderJob(bgRenderJob, isColored);
		}
		
		for (job in renderJobs)
		{
			context.renderJob(job, isColored);
		}
	}
	#else
	public inline function render(context:Dynamic = null):Void
	{
		
	}
	#end
	
	public function startQuadBatch(tilesheet:TilesheetStage3D, tinted:Bool, alpha:Bool, blend:BlendMode = null, smooth:Bool = false):QuadRenderJob
	{
		var lastRenderJob:BaseRenderJob = getLastRenderJob();
		var lastQuadRenderJob:QuadRenderJob = getLastQuadRenderJob();
		
		if (lastRenderJob != null && lastQuadRenderJob != null
			&& lastRenderJob == lastQuadRenderJob 
			&& tilesheet == lastRenderJob.tilesheet
			&& tinted == lastRenderJob.isRGB
			&& alpha == lastRenderJob.isAlpha
			&& smooth == lastRenderJob.isSmooth
			&& blend == lastRenderJob.blendMode)
		{
			return lastQuadRenderJob;
		}
		
		return startNewQuadBatch(tilesheet, tinted, alpha, blend, smooth);
	}
	
	public inline function startNewQuadBatch(tilesheet:TilesheetStage3D, tinted:Bool, alpha:Bool, blend:BlendMode = null, smooth:Bool = false):QuadRenderJob
	{
		var job:QuadRenderJob = QuadRenderJob.getJob(tilesheet, tinted, alpha, smooth, blend);
		renderJobs[numRenderJobs++] = job;
		quadRenderJobs[numQuadRenderJobs++] = job;
		return job;
	}
	
	public function startTrianglesBatch(tilesheet:TilesheetStage3D, colored:Bool = false, blend:BlendMode = null, smoothing:Bool = false):TriangleRenderJob
	{
		var lastRenderJob:BaseRenderJob = getLastRenderJob();
		var lastTriangleRenderJob:TriangleRenderJob = getLastTrianglesRenderJob();
		
		if (lastRenderJob != null && lastTriangleRenderJob != null
			&& lastRenderJob == lastTriangleRenderJob 
			&& tilesheet == lastRenderJob.tilesheet
			&& colored == lastRenderJob.isRGB
			&& colored == lastRenderJob.isAlpha
			&& smoothing == lastRenderJob.isSmooth
			&& blend == lastRenderJob.blendMode) 
		{
			return lastTriangleRenderJob;
		}
		
		return startNewTrianglesBatch(tilesheet, colored, blend, smoothing);
	}
	
	public inline function startNewTrianglesBatch(tilesheet:TilesheetStage3D, colored:Bool = false, blend:BlendMode = null, smoothing:Bool = false):TriangleRenderJob
	{
		var job:TriangleRenderJob = TriangleRenderJob.getJob(tilesheet, colored, colored, smoothing, blend);
		renderJobs[numRenderJobs++] = job;
		triangleRenderJobs[numTriangleRenderJobs++] = job;
		return job;
	}
	
	public function startColorBatch(blend:BlendMode = null):ColorRenderJob
	{
		var lastRenderJob:BaseRenderJob = getLastRenderJob();
		var lastColorRenderJob:ColorRenderJob = getLastColorRenderJob();
		
		if (lastRenderJob != null && lastColorRenderJob != null
			&& lastRenderJob == lastColorRenderJob 
			&& blend == lastRenderJob.blendMode)
		{
			return lastColorRenderJob;
		}
		
		return startNewColorBatch(blend);
	}
	
	public inline function startNewColorBatch(blend:BlendMode = null):ColorRenderJob
	{
		var job:ColorRenderJob = ColorRenderJob.getJob(blend);
		renderJobs[numRenderJobs++] = job;
		colorRenderJobs[numColorRenderJobs++] = job;
		return job;
	}
	
	/**
	 * Drawing a transformed image region.
	 * 
	 * @param	tilesheet		texture provider
	 * @param	sourceRect		source rectangle from image to draw
	 * @param	origin			point to transform image around
	 * @param	matrix			image transformation matrix
	 * @param	cr				red color multiplier
	 * @param	cg				green color multiplier
	 * @param	cb				blue color multiplier
	 * @param	ca				alpha multiplier
	 * @param	blend			image blending mode
	 * @param	smoothing		image smoothing
	 */
	public inline function drawMatrix(tilesheet:TilesheetStage3D, sourceRect:Rectangle, origin:Point, matrix:Matrix, cr:Float = 1.0, cg:Float = 1.0, cb:Float = 1.0, ca:Float = 1.0, blend:BlendMode = null, smoothing:Bool = false):Void
	{
		var uv:Rectangle = Viewport.helperRect;
		uv.setTo(sourceRect.left / tilesheet.bitmapWidth, sourceRect.top / tilesheet.bitmapHeight, sourceRect.right / tilesheet.bitmapWidth, sourceRect.bottom / tilesheet.bitmapHeight);
		drawMatrix2(tilesheet, sourceRect, origin, uv, matrix, cr, cg, cb, ca, blend, smoothing);
	}
	
	/**
	 * Drawing scaled and rotated image region
	 * 
	 * @param	tilesheet	texture provider
	 * @param	sourceRect	source rectangle from image to draw
	 * @param	origin		point to transform image around
	 * @param	x			image x position
	 * @param	y			image y position
	 * @param	scaleX		image x scale
	 * @param	scaleY		image y scale
	 * @param	radians		image rotation
	 * @param	cr			red color multiplier
	 * @param	cg			green color multiplier
	 * @param	cb			blue color multiplier
	 * @param	ca			alpha multiplier
	 * @param	blend		image blending mode
	 * @param	smoothing	image smoothing
	 */
	public inline function drawPixels(tilesheet:TilesheetStage3D, sourceRect:Rectangle, origin:Point, x:Float, y:Float, scaleX:Float = 1, scaleY:Float = 1, radians:Float = 0, cr:Float = 1.0, cg:Float = 1.0, cb:Float = 1.0, ca:Float = 1.0, blend:BlendMode = null, smoothing:Bool = false):Void
	{
		helperMatrix.identity();
		helperMatrix.scale(scaleX, scaleY);
		helperMatrix.rotate(radians);
		helperMatrix.tx = x;
		helperMatrix.ty = y;
		drawMatrix(tilesheet, sourceRect, origin, helperMatrix, cr, cg, cb, ca, blend, smoothing);
	}
	
	/**
	 * Drawing a transformed image region. It expects region's uv for less calculations
	 * 
	 * @param	tilesheet	texture provider
	 * @param	sourceRect	source rectangle from image to draw
	 * @param	origin		point to transform image around
	 * @param	uv			image region uv
	 * @param	matrix		image transformation matrix
	 * @param	cr			red color multiplier
	 * @param	cg			green color multiplier
	 * @param	cb			blue color multiplier
	 * @param	ca			alpha multiplier
	 * @param	blend		image blending mode
	 * @param	smoothing	image smoothing
	 */
	public inline function drawMatrix2(tilesheet:TilesheetStage3D, sourceRect:Rectangle, origin:Point, uv:Rectangle, matrix:Matrix, cr:Float = 1.0, cg:Float = 1.0, cb:Float = 1.0, ca:Float = 1.0, blend:BlendMode = null, smoothing:Bool = false):Void
	{
		var colored:Bool = (cr != 1.0) || (cg != 1.0) || (cb != 1.0) || (ca != 1.0);
		var job:QuadRenderJob = startQuadBatch(tilesheet, colored, colored, blend, smoothing);
		
		if (!job.canAddQuad())
		{
			job = startNewQuadBatch(tilesheet, colored, colored, blend, smoothing);
		}
		
		helperPoint2.setTo(origin.x / sourceRect.width, origin.y / sourceRect.height); // normalize origin
		job.addQuad(sourceRect, helperPoint2, uv, matrix, cr, cg, cb, ca);
	}
	
	/**
	 * Drawing non-transformed region of image at specified position
	 * 
	 * @param	tilesheet	texture provider
	 * @param	sourceRect	source rectangle from image to draw
	 * @param	destPoint	where to draw image
	 * @param	cr			red color multiplier
	 * @param	cg			green color multiplier
	 * @param	cb			blue color multiplier
	 * @param	ca			alpha multiplier
	 * @param	blend		image blending mode
	 * @param	smoothing	image smoothing
	 */
	public function copyPixels(tilesheet:TilesheetStage3D, sourceRect:Rectangle, destPoint:Point, cr:Float = 1.0, cg:Float = 1.0, cb:Float = 1.0, ca:Float = 1.0, blend:BlendMode = null, smoothing:Bool = false):Void
	{
		helperMatrix.identity();
		helperMatrix.translate(destPoint.x, destPoint.y);
		helperPoint.setTo(0, 0);
		drawMatrix(tilesheet, sourceRect, helperPoint, helperMatrix, cr, cg, cb, ca, blend, smoothing);
	}
	
	/**
	 * Drawing non-transformed region of image at specified position. It expects region's uv for less calculations
	 * 
	 * @param	tilesheet	texture provider
	 * @param	sourceRect	source rectangle from image to draw
	 * @param	uv			image region uv
	 * @param	destPoint	where to draw image
	 * @param	cr			red color multiplier
	 * @param	cg			green color multiplier
	 * @param	cb			blue color multiplier
	 * @param	ca			alpha multiplier
	 * @param	blend		image blending mode
	 * @param	smoothing	image smoothing
	 */
	public function copyPixels2(tilesheet:TilesheetStage3D, sourceRect:Rectangle, uv:Rectangle, destPoint:Point = null, cr:Float = 1.0, cg:Float = 1.0, cb:Float = 1.0, ca:Float = 1.0, blend:BlendMode = null, smoothing:Bool = false):Void
	{
		helperMatrix.identity();
		helperMatrix.translate(destPoint.x, destPoint.y);
		helperPoint.setTo(0, 0);
		drawMatrix2(tilesheet, sourceRect, helperPoint, uv, helperMatrix, cr, cg, cb, ca, blend, smoothing);
	}
	
	/**
	 * Renders a set of triangles, typically to distort bitmaps and give them a three-dimensional appearance.
	 * 
	 * @param	tilesheet	texture provider
	 * @param	vertices	a Vector of Numbers where each pair of numbers is treated as a coordinate location (an x, y pair)
	 * @param	indices		a Vector of integers or indexes, where every three indexes define a triangle. 
	 * @param	uv			a Vector of normalized coordinates used to apply texture mapping.
	 * @param	colors		a Vector of colors in 0xRRGGBBAA format for vertex tinting.
	 * @param	blend		image blending mode
	 * @param	smoothing	image smoothing
	 * @param	position	position to add to each vertex
	 */
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
	
	public function drawColorTriangles(vertices:Vector<Float>, indices:Vector<Int>, colors:Vector<Int>, blend:BlendMode = null, position:Point = null):Void
	{
		var job:ColorRenderJob = startColorBatch(blend);
		var numVertices:Int = vertices.length;
		
		if (!job.canAddTriangles(numVertices))
		{
			if (job.checkMaxTrianglesCapacity(numVertices))
			{
				job = startNewColorBatch(blend);
			}
			else
			{
				return; // too much triangles, even for the new batch
			}
		}
		
		job.addTriangles(vertices, indices, colors, position);
	}
	
	public inline function drawAAColorRect(rect:Rectangle, cr:Float = 1.0, cg:Float = 1.0, cb:Float = 1.0, ca:Float = 1.0, blend:BlendMode = null):Void
	{
		var job:ColorRenderJob = startColorBatch(blend);
		
		if (!job.canAddQuad())
		{
			job = startNewColorBatch(blend);
		}
		
		job.addAAQuad(rect, cr, cg, cb, ca);
	}
	
	public inline function drawColorRect(sourceRect:Rectangle, origin:Point, matrix:Matrix, cr:Float = 1.0, cg:Float = 1.0, cb:Float = 1.0, ca:Float = 1.0, blend:BlendMode = null):Void
	{
		var job:ColorRenderJob = startColorBatch(blend);
		
		if (!job.canAddQuad())
		{
			job = startNewColorBatch(blend);
		}
		
		helperPoint2.setTo(origin.x / sourceRect.width, origin.y / sourceRect.height); // normalize origin
		job.addQuad(sourceRect, helperPoint2, matrix, cr, cg, cb, ca);
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
	
	private function set_index(value:Int):Int
	{
		#if !flash11
		Batcher.game.addChildAt(view, value);
		index = Batcher.game.getChildIndex(view);
		#else
		index = value;
		#end
		
		return value;
	}
	
	private function set_visible(value:Bool):Bool
	{
		#if !flash11
		view.visible = value;
		#end
		return visible = value;
	}
	
	private function get_bgColor():UInt
	{
		return ((Std.int(bgAlpha * 255) << 24) | (Std.int(bgRed * 255) << 16) | (Std.int(bgGreen * 255) << 8) | Std.int(bgBlue * 255));
	}
	
	private function set_bgColor(value:UInt):UInt
	{
		bgRed = ((value >> 16) & 0xff) / 255;
		bgGreen = ((value >> 8) & 0xff) / 255;
		bgBlue = (value & 0xff) / 255;
		bgAlpha = ((value >> 24) & 0xff) / 255;
		return value;
	}
	
	private function get_color():UInt
	{
		return ((Std.int(cAlpha * 255) << 24) | (Std.int(cRed * 255) << 16) | (Std.int(cGreen * 255) << 8) | Std.int(cBlue * 255));
	}
	
	private function set_color(value:UInt):UInt
	{
		cRed = ((value >> 16) & 0xff) / 255;
		cGreen = ((value >> 8) & 0xff) / 255;
		cBlue = (value & 0xff) / 255;
		cAlpha = ((value >> 24) & 0xff) / 255;
		return value;
	}
	
	private function set_cRed(value:Float):Float
	{
		cRed = value;
		checkColor();
		return value;
	}
	
	private function set_cGreen(value:Float):Float
	{
		cGreen = value;
		checkColor();
		return value;
	}
	
	private function set_cBlue(value:Float):Float
	{
		cBlue = value;
		checkColor();
		return value;
	}
	
	private function set_cAlpha(value:Float):Float
	{
		cAlpha = value;
		checkColor();
		return value;
	}
	
	private function checkColor():Void
	{
		isColored = (cRed != 1.0) || (cGreen != 1.0) || (cBlue != 1.0) || (cAlpha != 1.0);
	}
	
	private function updateMatrix():Void
	{
		#if flash11
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
		#else
		
		#end
	}
	
	private function updateScissor():Void
	{
		#if flash11
		if (scissor == null)	return;
		
		scissor.setTo(	Batcher.gameX + x * Batcher.gameScaleX, 
						Batcher.gameY + y * Batcher.gameScaleY, 
						width * Batcher.gameScaleX, 
						height * Batcher.gameScaleY);
		#else
		
		#end
	}
	
	/**
	 * Matrix and scissor rectangle recalculation
	 */
	public function update():Void
	{
		updateMatrix();
		updateScissor();
	}
}