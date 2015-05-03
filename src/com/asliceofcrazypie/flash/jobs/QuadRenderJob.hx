package com.asliceofcrazypie.flash.jobs;


import com.asliceofcrazypie.flash.jobs.RenderJob.RenderJobType;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;

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
	
	override public function addQuad(rect:Rectangle, origin:Point, uv:Rectangle, matrix:Matrix, r:Float = 1, g:Float = 1, b:Float = 1, a:Float = 1):Void
	{
		super.addQuad(rect, origin, uv, matrix, r, g, b, a);
		indexPos += 6;
	}
	
	public static inline function getJob():QuadRenderJob
	{
		return renderJobPool.length > 0 ? renderJobPool.pop() : new QuadRenderJob();
	}
	
	public static inline function returnJob(renderJob:QuadRenderJob):Void
	{
		renderJobPool.push(renderJob);
	}
	
	public static function __init__():Void
	{
		renderJobPool = [];
		for (i in 0...RenderJob.NUM_JOBS_TO_POOL)
		{
			renderJobPool.push(new QuadRenderJob());
		}
	}
}