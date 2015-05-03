package com.asliceofcrazypie.flash.jobs;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;

#if flash11
import flash.display3D.IndexBuffer3D;
import flash.display3D.textures.Texture;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.VertexBuffer3D;
import flash.display3D.Context3DTriangleFace;
import flash.display.TriangleCulling;
import flash.Vector;
import flash.errors.Error;
import flash.utils.ByteArray;
import flash.utils.Endian;
import haxe.ds.StringMap;

/**
 * ...
 * @author Paul M Pepper
 */
class RenderJob 
{
	public static inline var NUM_JOBS_TO_POOL:Int = 25;
	
	public static inline var BLEND_NORMAL:String = "normal";
	public static inline var BLEND_ADD:String = "add";
	public static inline var BLEND_MULTIPLY:String = "multiply";
	public static inline var BLEND_SCREEN:String = "screen";
	
	private static var premultipliedBlendFactors:StringMap<Array<Context3DBlendFactor>>;
	private static var noPremultipliedBlendFactors:StringMap<Array<Context3DBlendFactor>>;
	
	public var texture:Texture;
	public var vertices(default, null):Vector<Float>;
	public var isRGB:Bool;
	public var isAlpha:Bool;
	public var isSmooth:Bool;
	
	public var blendMode:String;
	public var premultipliedAlpha:Bool;
	
	public var type(default, null):RenderJobType;
	
	public var dataPerVertice:Int;
	public var numVertices:Int;
	public var numIndices:Int;
	
	public var indicesBytes(default, null):ByteArray;
	public var indicesVector(default, null):Vector<UInt>;
	
	public var vertexPos:Int = 0;
	public var indexPos:Int = 0;
	
	public function new(useBytes:Bool = false)
	{
		this.vertices = new Vector<Float>(TilesheetStage3D.vertexPerBuffer >> 2);
		
		if (useBytes)
		{
			indicesBytes = new ByteArray();
			indicesBytes.endian = Endian.LITTLE_ENDIAN;
			
			for (i in 0...Std.int(TilesheetStage3D.vertexPerBuffer / 4))
			{
				indicesBytes.writeShort((i * 4) + 2);
				indicesBytes.writeShort((i * 4) + 1);
				indicesBytes.writeShort((i * 4) + 0);
				indicesBytes.writeShort((i * 4) + 3);
				indicesBytes.writeShort((i * 4) + 2);
				indicesBytes.writeShort((i * 4) + 0);
			}
		}
		else
		{
			indicesVector = new Vector<UInt>();
		}
	}
	
	public function addQuad(rect:Rectangle, origin:Point, uv:Rectangle, matrix:Matrix, r:Float = 1, g:Float = 1, b:Float = 1, a:Float = 1):Void
	{
		
	}
	
	public function render(context:ContextWrapper):Void
	{
		if (context.context3D.driverInfo != 'Disposed')
		{
			//blend mode
			setBlending(context);
			
			context.setProgram(isRGB, isAlpha, isSmooth); //assign appropriate shader
			
			// context.context3D.setCulling();
			
			context.setTexture(texture);
			
			//actually create the buffers
			var vertexbuffer:VertexBuffer3D = null;
			var indexbuffer:IndexBuffer3D = null;
			
			// Create VertexBuffer3D. numVertices vertices, of dataPerVertice Numbers each
			vertexbuffer = context.context3D.createVertexBuffer(numVertices, dataPerVertice);
			
			// Upload VertexBuffer3D to GPU. Offset 0, numVertices vertices
			vertexbuffer.uploadFromVector(vertices, 0, numVertices);
			
			// Create IndexBuffer3D.
			indexbuffer = context.context3D.createIndexBuffer(numIndices);
			
			// Upload IndexBuffer3D to GPU.
			if (indicesBytes != null)
			{
				indexbuffer.uploadFromByteArray(indicesBytes, 0, 0, numIndices);
			}
			else
			{
				indexbuffer.uploadFromVector(indicesVector, 0, numIndices);
			}
			
			// vertex position to attribute register 0
			context.context3D.setVertexBufferAt(0, vertexbuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			// UV to attribute register 1
			context.context3D.setVertexBufferAt(1, vertexbuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
			
			if (isRGB && isAlpha)
			{
				context.context3D.setVertexBufferAt(2, vertexbuffer, 4, Context3DVertexBufferFormat.FLOAT_4); //rgba data
			}
			else if (isRGB)
			{
				context.context3D.setVertexBufferAt(2, vertexbuffer, 4, Context3DVertexBufferFormat.FLOAT_3); //rgb data
			}
			else if (isAlpha)
			{
				context.context3D.setVertexBufferAt(2, vertexbuffer, 4, Context3DVertexBufferFormat.FLOAT_1); //a data
			}
			else
			{
				context.context3D.setVertexBufferAt(2, null, 4);
			}
			
			context.context3D.drawTriangles(indexbuffer);
		}
	}
	
	private inline function setBlending(context:ContextWrapper):Void
	{
		var factors = RenderJob.premultipliedBlendFactors;
		if (!premultipliedAlpha)
		{
			factors = RenderJob.noPremultipliedBlendFactors;
		}
		
		var factor:Array<Context3DBlendFactor> = factors.get(blendMode);
		if (factor == null)
		{
			factor = factors.get(RenderJob.BLEND_NORMAL);
		}
		
		context.context3D.setBlendFactors(factor[0], factor[1]);
	}
	
	public function reset():Void
	{
		vertexPos = 0;
		indexPos = 0;
		numVertices = 0;
		numIndices = 0;
	}
	
	public static function __init__():Void
	{
	//	QuadRenderJob.__init__();
	//	TriangleRenderJob.__init__();
		RenderJob.initBlendFactors();
	}
	
	private static function initBlendFactors():Void
	{
		if (RenderJob.premultipliedBlendFactors == null)
		{
			RenderJob.premultipliedBlendFactors = new StringMap();
			RenderJob.premultipliedBlendFactors.set(BLEND_NORMAL, [Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA]);
			RenderJob.premultipliedBlendFactors.set(BLEND_ADD, [Context3DBlendFactor.ONE, Context3DBlendFactor.ONE]);
			RenderJob.premultipliedBlendFactors.set(BLEND_MULTIPLY, [Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA]);
			RenderJob.premultipliedBlendFactors.set(BLEND_SCREEN, [Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR]);
			
			RenderJob.noPremultipliedBlendFactors = new StringMap();
			RenderJob.noPremultipliedBlendFactors.set(BLEND_NORMAL, [Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA]);
			RenderJob.noPremultipliedBlendFactors.set(BLEND_ADD, [Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.DESTINATION_ALPHA]);
			RenderJob.noPremultipliedBlendFactors.set(BLEND_MULTIPLY, [Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA]);
			RenderJob.noPremultipliedBlendFactors.set(BLEND_SCREEN, [Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE]);
		}
	}
}
#end

enum RenderJobType
{
	QUAD;
	TRIANGLE;
}