package com.asliceofcrazypie.flash.jobs;

import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.Vector;

/**
 * ...
 * @author Zaphod
 */
#if flash11
class TriangleRenderJob extends BaseRenderJob
{
	public static inline var MAX_INDICES_PER_BUFFER:Int = 98298;
	public static inline var MAX_VERTEX_PER_BUFFER:Int = 65532;		// (MAX_INDICES_PER_BUFFER * 4 / 6)
	public static inline var MAX_QUADS_PER_BUFFER:Int = 16383;		// (MAX_VERTEX_PER_BUFFER / 4)
	public static inline var MAX_TRIANGLES_PER_BUFFER:Int = 21844;	// (MAX_VERTEX_PER_BUFFER / 3)
	
	// TODO: use these static vars (and document them)...
	public static var vertexPerBuffer(default, null):Int;
	public static var quadsPerBuffer(default, null):Int;
	public static var trianglesPerBuffer(default, null):Int;
	public static var indicesPerBuffer(default, null):Int;
	
	@:allow(com.asliceofcrazypie.flash)
	private static function init(batchSize:Int = 0):Void
	{
		if (batchSize <= 0 || batchSize > MAX_QUADS_PER_BUFFER)
		{
			batchSize = MAX_QUADS_PER_BUFFER;
		}
		
		quadsPerBuffer = batchSize;
		vertexPerBuffer = batchSize * 4;
		trianglesPerBuffer = Std.int(vertexPerBuffer / 3);
		indicesPerBuffer = Std.int(vertexPerBuffer * 6 / 4);	
	}
	
	public var dataPerVertice:Int = 0;
	public var numVertices:Int = 0;
	public var numIndices:Int = 0;
	
	public var vertices(default, null):Vector<Float>;
	public var indices(default, null):Vector<UInt>;
	
	public var vertexPos:Int = 0;
	public var indexPos:Int = 0;
	
	public function new() 
	{
		super();
	}
	
	override private function initData():Void
	{
		this.vertices = new Vector<Float>(TriangleRenderJob.vertexPerBuffer >> 2);
		this.indices = new Vector<UInt>();
	}
	
	override public function render(context:ContextWrapper = null, colored:Bool = false):Void
	{
		if (context != null)
		{
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
			indexbuffer.uploadFromVector(indices, 0, numIndices);
			
			// TODO: culling support...
			// context.context3D.setCulling();
			
			// vertex position to attribute register 0
			context.context3D.setVertexBufferAt(0, vertexbuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			
			if (tilesheet != null)
			{
				//blend mode
				context.setBlendMode(blendMode, tilesheet.premultipliedAlpha);
				
				context.setTriangleImageProgram(isRGB, isAlpha, isSmooth, tilesheet.mipmap, colored); //assign appropriate shader
				
				context.setTexture(tilesheet.texture);
				
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
			}
			else
			{
				//blend mode
				context.setBlendMode(blendMode, false);
				
				context.setTriangleNoImageProgram(colored); //assign appropriate shader
				
				context.setTexture(null);
				
				// color to attribute register 1
				context.context3D.setVertexBufferAt(1, vertexbuffer, 2, Context3DVertexBufferFormat.FLOAT_4);
				context.context3D.setVertexBufferAt(2, null);
			}
			
			context.context3D.drawTriangles(indexbuffer);
		}
	}
	
	override public function reset():Void
	{
		super.reset();
		
		vertexPos = 0;
		indexPos = 0;
		numVertices = 0;
		numIndices = 0;
	}
	
	override public function canAddQuad():Bool
	{
		return (numVertices + 4) <= TriangleRenderJob.vertexPerBuffer;
	}
	
	public inline function canAddTriangles(numVertices:Int):Bool
	{
		return (numVertices + this.numVertices) <= TriangleRenderJob.vertexPerBuffer;
	}
	
	public static inline function checkMaxTrianglesCapacity(numVertices:Int):Bool
	{
		return numVertices <= TriangleRenderJob.vertexPerBuffer;
	}
}
#else
class TriangleRenderJob extends BaseRenderJob
{
	private static function init(batchSize:Int = 0):Void
	{
		
	}
	
	#if flash
	public var vertices(default, null):Vector<Float>;
	public var indices(default, null):Vector<UInt>;
	#else
	public var vertices(default, null):Array<Float>;
	public var indices(default, null):Array<Int>;
	public var colors(default, null):Array<Int>;
	#end
	
	public var dataPerVertice:Int = 0;
	public var numVertices:Int = 0;
	public var numIndices:Int = 0;
	
	public var vertexPos:Int = 0;
	public var indexPos:Int = 0;
	
	#if !flash
	public var colorPos:Int = 0;
	#end
	
	public function new()
	{
		super();
	}
	
	override public function reset():Void 
	{
		super.reset();
		
		vertices.splice(0, vertices.length);
		indices.splice(0, indices.length);
		#if !flash
		colors.splice(0, colors.length);
		#end
		
		dataPerVertice = 0;
		numVertices = 0;
		numIndices = 0;
		
		vertexPos = 0;
		indexPos = 0;
		#if !flash
		colorPos = 0;
		#end
	}
	
	override function initData():Void 
	{
		#if flash
		vertices = new Vector<Float>();
		indices = new Vector<Int>();
		#else
		vertices = new Array<Float>();
		indices = new Array<Int>();
		colors = new Array<Int>();
		#end
	}
	
	override public function canAddQuad():Bool
	{
		return true;
	}
	
	public inline function canAddTriangles(numVertices:Int):Bool
	{
		return true;
	}
	
	public static inline function checkMaxTrianglesCapacity(numVertices:Int):Bool
	{
		return true;
	}
}
#end