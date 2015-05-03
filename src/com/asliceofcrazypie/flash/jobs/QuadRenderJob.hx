package com.asliceofcrazypie.flash.jobs;


import com.asliceofcrazypie.flash.jobs.RenderJob.RenderJobType;
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
	
	override private function set_numVertices(n:Int):Int
	{
		this.numVertices = n;
		this.numIndices = Std.int((numVertices / 2) * 3);
		return n;
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