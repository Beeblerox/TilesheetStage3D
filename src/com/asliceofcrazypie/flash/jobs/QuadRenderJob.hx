package com.asliceofcrazypie.flash.jobs;

import com.asliceofcrazypie.flash.TilesheetStage3D;
import com.asliceofcrazypie.flash.jobs.BaseRenderJob.RenderJobType;

import flash.display.BlendMode;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

#if flash11
import flash.display3D.textures.Texture;
#end

/**
 * ...
 * @author Zaphod
 */
class QuadRenderJob extends RenderJob
{
	private static var renderJobPool:Array<QuadRenderJob>;
	
	public function new() 
	{
		super(true);
		type = RenderJobType.QUAD;
	}
	
	#if flash11
	override public function addQuad(rect:Rectangle, normalizedOrigin:Point, uv:Rectangle, matrix:Matrix, r:Float = 1, g:Float = 1, b:Float = 1, a:Float = 1):Void
	{
		super.addQuad(rect, normalizedOrigin, uv, matrix, r, g, b, a);
		indexPos += 6;
	}
	#end
	
	public function set(tilesheet:TilesheetStage3D, isRGB:Bool, isAlpha:Bool, isSmooth:Bool, blend:BlendMode):Void
	{
		this.tilesheet = tilesheet;
		this.isRGB = isRGB;
		this.isAlpha = isAlpha;
		this.isSmooth = isSmooth;
		this.blendMode = blend;
		
		var dataPerVertice:Int = 4;
		if (isRGB)
		{
			dataPerVertice += 3;
		}
		if (isAlpha)
		{
			dataPerVertice++;
		}
		
		this.dataPerVertice = dataPerVertice;
	}
	
	public static inline function getJob(tilesheet:TilesheetStage3D, isRGB:Bool, isAlpha:Bool, isSmooth:Bool, blend:BlendMode):QuadRenderJob
	{
		var job:QuadRenderJob = (renderJobPool.length > 0) ? renderJobPool.pop() : new QuadRenderJob();
		job.set(tilesheet, isRGB, isAlpha, isSmooth, blend);
		return job;
	}
	
	public static inline function returnJob(renderJob:QuadRenderJob):Void
	{
		renderJobPool.push(renderJob);
	}
	
	public static function __init__():Void
	{
		renderJobPool = [];
		for (i in 0...BaseRenderJob.NUM_JOBS_TO_POOL)
		{
			renderJobPool.push(new QuadRenderJob());
		}
	}
}