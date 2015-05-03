package com.asliceofcrazypie.flash.jobs;

import com.asliceofcrazypie.flash.jobs.RenderJob.RenderJobType;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.Vector;

import flash.display3D.textures.Texture;
import flash.display.BlendMode;

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
	
	public function addTriangles(vertices:Vector<Float>, indices:Vector<Int> = null, uvtData:Vector<Float> = null, colors:Vector<Int> = null):Void
	{
		var numIndices:Int = indices.length;
		var numVertices:Int = Std.int(vertices.length / 2);
		
		var prevVerticesNumber:Int = Std.int(vertexPos / dataPerVertice);
		
		var vertexIndex:Int = 0;
		var vColor:Int;
		
		var colored:Bool = (isRGB || isAlpha);
		
		for (i in 0...numVertices)
		{
			vertexIndex = 2 * i;
			
			this.vertices[vertexPos++] = vertices[vertexIndex];
			this.vertices[vertexPos++] = vertices[vertexIndex + 1];
			
			this.vertices[vertexPos++] = uvtData[vertexIndex];
			this.vertices[vertexPos++] = uvtData[vertexIndex + 1];
			
			if (colored)
			{
				vColor = colors[i];
				this.vertices[vertexPos++] = ((vColor >> 16) & 0xff) / 255;
				this.vertices[vertexPos++] = ((vColor >> 8) & 0xff) / 255;
				this.vertices[vertexPos++] = (vColor & 0xff) / 255;
				this.vertices[vertexPos++] = ((vColor >> 24) & 0xff) / 255;	
			}
		}
		
		for (i in 0...numIndices)
		{
			this.indicesVector[indexPos++] = prevVerticesNumber + indices[i];
		}
		
		this.numVertices += numVertices;
		this.numIndices += numIndices;
	}
	
	public static inline function getJob(texture:Texture, isRGB:Bool, isAlpha:Bool, isSmooth:Bool, blend:BlendMode, premultiplied:Bool):TriangleRenderJob
	{
		var job:TriangleRenderJob = (renderJobPool.length > 0) ? renderJobPool.pop() : new TriangleRenderJob();
		
		job.texture = texture;
		job.isRGB = isRGB;
		job.isAlpha = isAlpha;
		job.isSmooth = isSmooth;
		job.blendMode = blend;
		job.premultipliedAlpha = premultiplied;
		
		job.dataPerVertice = 4;
		if (isRGB)
		{
			job.dataPerVertice += 3;
		}
		if (isAlpha)
		{
			job.dataPerVertice++;
		}
		
		return job;
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