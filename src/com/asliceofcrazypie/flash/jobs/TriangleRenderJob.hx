package com.asliceofcrazypie.flash.jobs;

import com.asliceofcrazypie.flash.jobs.RenderJob.RenderJobType;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

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
	
	override public function addQuad(rect:Rectangle, origin:Point, uv:Rectangle, matrix:Matrix, r:Float = 1, g:Float = 1, b:Float = 1, a:Float = 1):Void
	{
		var prevVerticesNumber:Int = Std.int(vertexPos / dataPerVertice);
		
		super.addQuad(rect, origin, uv, matrix, r, g, b, a);
		
		indicesVector[indexPos++] = prevVerticesNumber + 2;
		indicesVector[indexPos++] = prevVerticesNumber + 1;
		indicesVector[indexPos++] = prevVerticesNumber + 0;
		indicesVector[indexPos++] = prevVerticesNumber + 3;
		indicesVector[indexPos++] = prevVerticesNumber + 2;
		indicesVector[indexPos++] = prevVerticesNumber + 0;
	}
	
	public function addTriangles():Void
	{
		
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