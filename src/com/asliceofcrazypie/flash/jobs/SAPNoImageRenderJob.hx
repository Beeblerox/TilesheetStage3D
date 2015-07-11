package com.asliceofcrazypie.flash.jobs;
import com.asliceofcrazypie.flash.ContextWrapper;
import com.asliceofcrazypie.flash.jobs.VeryBasicRenderJob.RenderJobType;
import com.asliceofcrazypie.flash.TilesheetStage3D;
import openfl.display.BlendMode;
import openfl.display.Sprite;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.Vector;

/**
 * ...
 * @author Zaphod
 */
class SAPNoImageRenderJob extends VeryBasicRenderJob
{
	static private var renderJobPool:Array<SAPNoImageRenderJob>;
	
	public static inline function getJob(tilesheet:TilesheetStage3D, blend:BlendMode):SAPNoImageRenderJob
	{
		var job:SAPNoImageRenderJob = (renderJobPool.length > 0) ? renderJobPool.pop() : new SAPNoImageRenderJob();
		job.set(tilesheet, blend);
		return job;
	}
	
	public static inline function returnJob(renderJob:SAPNoImageRenderJob):Void
	{
		renderJobPool.push(renderJob);
	}
	
	public static inline var numRegistersPerQuad:Int = 4;
	
	static private inline var limit:Int = 31;	// Std.int((128 - 4) / 4); where:
												// - 128 is the max number of vertex constant vectors,
												// - 4 is for mvp, 
												// - 4 vectors for each quad
												
	static private var vertexBuffer:VertexBuffer3D;
	static private var indexBuffer:IndexBuffer3D;
	
	private var constants:Vector<Float>;
	private var numQuads:Int = 0;
	
	private function new() 
	{
		super();
		type = RenderJobType.QUAD;
	}
	
	override function initData():Void 
	{
		constants = new Vector<Float>();
		
		// TODO: init other data...
		
	}
	
	public static function init(context:ContextWrapper):Void
	{
		renderJobPool = [];
		for (i in 0...VeryBasicRenderJob.NUM_JOBS_TO_POOL)
		{
			renderJobPool.push(new SAPRenderJob());
		}
	}
	
	public static function initContextData(context:ContextWrapper):Void
	{
		var vertices:Vector<Float> = new Vector<Float>();
		var indices:Vector<UInt> = new Vector<UInt>();
		var i4:Int;
		for (i in 0...limit) 
		{
			i4 = i * 4;
			vertices.push(0);
			vertices.push(0);
			vertices.push(i4);
			
			vertices.push(0);
			vertices.push(1);
			vertices.push(i4);
			
			vertices.push(1);
			vertices.push(0);
			vertices.push(i4);
			
			vertices.push(1);
			vertices.push(1);
			vertices.push(i4);
			
			indices.push(i4);
			indices.push(i4 + 1);
			indices.push(i4 + 2);
			indices.push(i4 + 1);
			indices.push(i4 + 3);
			indices.push(i4 + 2);
		}
		
		vertexBuffer = context.createVertexBuffer(limit * 4, 3);
		vertexBuffer.uploadFromVector(vertices, 0, limit * 4);
		indexBuffer = context.createIndexBuffer(limit * 6);
		indexBuffer.uploadFromVector(indices, 0, limit * 6);
	}
	
	#if flash11
	override public function render(context:ContextWrapper = null, colored:Bool = false):Void
	{
		// var vertexConstantsCount:Int = 0;
	}
	#else
	override public function render(context:Sprite = null, colored:Bool = false):Void
	{
		
	}
	#end
	
	public function addQuad(rect:Rectangle, normalizedOrigin:Point, uv:Rectangle, matrix:Matrix, r:Float = 1, g:Float = 1, b:Float = 1, a:Float = 1):Void
	{
		var offset:Int = numQuads << 2; // numQuads * 4
		setVertexConstantsFromNumbers(offset++, normalizedOrigin.x, normalizedOrigin.y, rect.width, rect.height);
		setVertexConstantsFromNumbers(offset++, matrix.a, matrix.b, matrix.c, matrix.d);
		setVertexConstantsFromNumbers(offset++, matrix.tx, matrix.ty, 0, 0);
		setVertexConstantsFromNumbers(offset++, r, g, b, a);
		numQuads++;
	}
	
	private function setVertexConstantsFromNumbers(firstRegister:Int, x:Float, y:Float, z:Float = 0, w:Float = 0):Void 
	{
		var offset:Int = firstRegister << 2; // firstRegister * 4
		constants[offset] = x;
		offset++;
		constants[offset] = y;
		offset++;
		constants[offset] = z;
		offset++;
		constants[offset] = w;
	}
	
	override public function canAddQuad():Bool
	{
		return (numQuads < limit);
	}
	
	override public function reset():Void 
	{
		super.reset();
		numQuads = 0;
	}
	
	public function set(tilesheet:TilesheetStage3D, blend:BlendMode):Void 
	{
		this.tilesheet = tilesheet;
		this.blendMode = blend;
	}
	
}