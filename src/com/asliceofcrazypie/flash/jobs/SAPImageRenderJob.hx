package com.asliceofcrazypie.flash.jobs;
import com.asliceofcrazypie.flash.ContextWrapper;
import com.asliceofcrazypie.flash.jobs.VeryBasicRenderJob.RenderJobType;
import com.asliceofcrazypie.flash.TilesheetStage3D;
import openfl.display.BlendMode;
import openfl.display.Sprite;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DVertexBufferFormat;
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
class SAPImageRenderJob extends VeryBasicRenderJob
{
	static private var renderJobPool:Array<SAPImageRenderJob>;
	
	public static inline function getJob(tilesheet:TilesheetStage3D, smooth:Bool, blend:BlendMode):SAPImageRenderJob
	{
		var job:SAPImageRenderJob = (renderJobPool.length > 0) ? renderJobPool.pop() : new SAPImageRenderJob();
		job.set(tilesheet, smooth, blend);
		return job;
	}
	
	public static inline function returnJob(renderJob:SAPImageRenderJob):Void
	{
		renderJobPool.push(renderJob);
	}
	
	static public inline var numRegistersPerQuad:Int = 5;
	
	/**
	 * Max number of quads per draw call for this type of render job
	 */
	static private inline var limit:Int = 24;	// Std.int((128 - 4) / 5); where:
												// - 128 is the max number of vertex constant vectors,
												// - 4 is for mvp, 
												// - 5 vectors for each quad
	
	static private var vertexBuffer:VertexBuffer3D;
	static private var indexBuffer:IndexBuffer3D;
	
	private var constants:Vector<Float>;
	private var numConstants:Int = 0;
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
	
	public static function init():Void
	{
		renderJobPool = [];
		for (i in 0...VeryBasicRenderJob.NUM_JOBS_TO_POOL)
		{
			renderJobPool.push(new SAPImageRenderJob());
		}
	}
	
	public static function initContextData(context:ContextWrapper):Void
	{
		var vertices:Vector<Float> = new Vector<Float>();
		var indices:Vector<UInt> = new Vector<UInt>();
		var i4:Int;
		var i5:Int;
		for (i in 0...limit) 
		{
			i5 = i * 5;
			vertices.push(0);
			vertices.push(0);
			vertices.push(i5);
			
			vertices.push(0);
			vertices.push(1);
			vertices.push(i5);
			
			vertices.push(1);
			vertices.push(0);
			vertices.push(i5);
			
			vertices.push(1);
			vertices.push(1);
			vertices.push(i5);
			
			i4 = i * 4;
			indices.push(i4);
			indices.push(i4 + 1);
			indices.push(i4 + 2);
			indices.push(i4 + 1);
			indices.push(i4 + 3);
			indices.push(i4 + 2);
		}
		
		var context3D:Context3D = context.context3D;
		
		vertexBuffer = context3D.createVertexBuffer(limit * 4, 3);
		vertexBuffer.uploadFromVector(vertices, 0, limit * 4);
		indexBuffer = context3D.createIndexBuffer(limit * 6);
		indexBuffer.uploadFromVector(indices, 0, limit * 6);
	}
	
	#if flash11
	override public function render(context:ContextWrapper = null, colored:Bool = false):Void
	{
		var context3D:Context3D = context.context3D;
		
		context.setBlendMode(blendMode, tilesheet.premultipliedAlpha);
		context.setQuadImageProgram(isSmooth, tilesheet.mipmap, colored);
		
		// Set streams
		context3D.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
		context.context3D.setVertexBufferAt(1, null);
		context.context3D.setVertexBufferAt(2, null);
		context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, constants, numConstants);
		
		// Set constants
	//	mvp.copyFrom(support.mvpMatrix3D);
	//	context.context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 124, context.baseTransformMatrix, true);
		
		context.setTexture(tilesheet.texture);
		context.context3D.drawTriangles(indexBuffer, 0, numQuads << 1); // numQuads * 2
		
	//	trace(constants.length);
	//	trace(constants);
	}
	#else
	override public function render(context:Sprite = null, colored:Bool = false):Void
	{
		
	}
	#end
	
	public function addQuad(rect:Rectangle, normalizedOrigin:Point, uv:Rectangle, matrix:Matrix, r:Float = 1, g:Float = 1, b:Float = 1, a:Float = 1):Void
	{
		setVertexConstantsFromNumbers(numConstants++, normalizedOrigin.x, normalizedOrigin.y, rect.width, rect.height);
		setVertexConstantsFromNumbers(numConstants++, matrix.a, matrix.b, matrix.c, matrix.d);
		setVertexConstantsFromNumbers(numConstants++, matrix.tx, matrix.ty, 0, 0);
		setVertexConstantsFromNumbers(numConstants++, uv.width - uv.x, uv.height - uv.y, uv.x, uv.y);
		setVertexConstantsFromNumbers(numConstants++, r, g, b, a);
		numQuads++;
	}
	
	private function setVertexConstantsFromNumbers(firstRegister:Int, x:Float, y:Float, z:Float = 0, w:Float = 0):Void 
	{
		var offset:Int = firstRegister << 2; // firstRegister * 4
		constants[offset++] = x;
		constants[offset++] = y;
		constants[offset++] = z;
		constants[offset++] = w;
	}
	
	override public function canAddQuad():Bool
	{
		return (numQuads < limit);
	}
	
	override public function reset():Void 
	{
		super.reset();
		numQuads = 0;
		numConstants = 0;
	}
	
	public function set(tilesheet:TilesheetStage3D, smooth:Bool, blend:BlendMode):Void 
	{
		this.tilesheet = tilesheet;
		this.blendMode = blend;
		this.isSmooth = smooth;
	}
	
	override public function stateChanged(tilesheet:TilesheetStage3D, tint:Bool, alpha:Bool, smooth:Bool, blend:BlendMode):Bool 
	{
		return (this.tilesheet != tilesheet || this.blendMode != blend);
	}
	
}