package com.asliceofcrazypie.flash.jobs;
import com.asliceofcrazypie.flash.jobs.VeryBasicRenderJob.RenderJobType;
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
class SAPRenderJob extends VeryBasicRenderJob
{
	/**
	 * Max number of quads per draw call for this type of render job
	 */
	static private inline var limit:Int = 24;	// Std.int((128 - 4) / 5); where:
												// - 128 is the max number of vertex constant vectors,
												// - 4 is for mvp, 
												// - 5 vectors for each quad
	
	static private var vertexBuffer:VertexBuffer3D;
	static private var indexBuffer:IndexBuffer3D;
	
	static private var program:Program3D;
	static private var colorProgram:Program3D;
	
	private function new() 
	{
		super();
		type = RenderJobType.QUAD;
	}
	
	override function initData():Void 
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
		
		vertexBuffer = context.createVertexBuffer(limit * 4, 3);
		vertexBuffer.uploadFromVector(vertices, 0, limit * 4);
		indexBuffer = context.createIndexBuffer(limit * 6);
		indexBuffer.uploadFromVector(indices, 0, limit * 6);
		var vertexProgram:String =
			// Pivot
				"mov vt2, vc[va0.z]\n" + // originX, originY, width, height
				"sub vt0.z, va0.x, vt2.x\n" +
				"sub vt0.w, va0.y, vt2.y\n" +
			// Width and height
				"mul vt0.z, vt0.z, vt2.z\n" +
				"mul vt0.w, vt0.w, vt2.w\n" +
			// Tranformation
				"mov vt2, vc[va0.z+1]\n" + // a, b, c, d
				"mul vt1.z, vt0.z, vt2.x\n" + // pos.x * a
				"mul vt1.w, vt0.w, vt2.z\n" + // pos.y * c
				"add vt0.x, vt1.z, vt1.w\n" + // X
				"mul vt1.z, vt0.z, vt2.y\n" + // pos.x * b
				"mul vt1.w, vt0.w, vt2.w\n" + // pos.y * d
				"add vt0.y, vt1.z, vt1.w\n" + // Y			
			// Translation
				"mov vt2, vc[va0.z+2]" + // x, y, 0, 0
				"add vt0.x, vt0.x, vt2.x\n" +
				"add vt0.y, vt0.y, vt2.y\n" +
				"mov vt0.zw, va0.ww\n" +
			// Projection
//				"m44 op, vt0, vc124\n" +
				"dp4 op.x, vt0, vc124\n" +
				"dp4 op.y, vt0, vc125\n" +
				"dp4 op.z, vt0, vc126\n" +
				"dp4 op.w, vt0, vc127\n" +
			// UV correction and passing out
				"mov vt2, vc[va0.z+3]\n" + // uvScaleX, uvScaleY, uvOffsetX, uvOffsetY
				"mul vt1.x, va0.x, vt2.x\n" +
				"mul vt1.y, va0.y, vt2.y\n" +
				"add vt1.x, vt1.x, vt2.z\n" +
				"add vt1.y, vt1.y, vt2.w\n" +
				"mov v0, vt1.xy\n" +
			// Passing color
				"mov v1, vc[va0.z+4]\n";// red, green, blue, alpha

		var fragmentProgramString:String =
				"tex ft0, v0, fs0 <2d,clamp,linear,miplinear>\n" +
				"mul oc, ft0, v1\n";
		
		var fragmentColoredProgramString:String =
				"tex ft0, v0, fs0 <2d,clamp,linear,miplinear>\n" +
				"mul ft0, ft0, v1\n" +
				"mul oc, ft0, fc0\n";
				
		diffuseProgram = context.createProgram();
		opacityProgram = context.createProgram();
		diffuseBlendProgram = context.createProgram();
		opacityBlendProgram = context.createProgram();

		diffuseProgram.upload(
				sAssembler.assemble(Context3DProgramType.VERTEX, vertexProgram),
				sAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentDiffuseProgram));

		opacityProgram.upload(
				sAssembler.assemble(Context3DProgramType.VERTEX, vertexProgram),
				sAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentOpacityProgram));

		diffuseBlendProgram.upload(
				sAssembler.assemble(Context3DProgramType.VERTEX, vertexProgram),
				sAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentDiffuseBlendProgram));

		opacityBlendProgram.upload(
				sAssembler.assemble(Context3DProgramType.VERTEX, vertexProgram),
				sAssembler.assemble(Context3DProgramType.FRAGMENT, fragmentOpacityBlendProgram));
	}
	
	#if flash11
	override public function render(context:ContextWrapper = null, colored:Bool = false):Void
	{
		
	}
	#else
	override public function render(context:Sprite = null, colored:Bool = false):Void
	{
		
	}
	#end
	
	public function addQuad(rect:Rectangle, normalizedOrigin:Point, uv:Rectangle, matrix:Matrix, r:Float = 1, g:Float = 1, b:Float = 1, a:Float = 1):Void
	{
		
	}
	
	override public function canAddQuad():Bool
	{
		return false;
	}
	
}