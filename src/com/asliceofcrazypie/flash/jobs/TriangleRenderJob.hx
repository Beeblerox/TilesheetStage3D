package com.asliceofcrazypie.flash.jobs;

import com.asliceofcrazypie.flash.jobs.RenderJob.RenderJobType;

/**
 * ...
 * @author Zaphod
 */
class TriangleRenderJob extends RenderJob
{
	private static var renderJobPool:Array<TriangleRenderJob>;
	
	public function new() 
	{
		super(false);
		type = RenderJobType.TRIANGLE;
	}
	
	public static inline function getJob():TriangleRenderJob
	{
		return renderJobPool.length > 0 ? renderJobPool.pop() : new TriangleRenderJob();
	}
	
	public static inline function returnJob(renderJob:TriangleRenderJob):Void
	{
		renderJobPool.push(renderJob);
	}
	
	public static function __init__():Void
	{
		renderJobPool = [];
		for (i in 0...RenderJob.NUM_JOBS_TO_POOL)
		{
			renderJobPool.push(new TriangleRenderJob());
		}
	}
}