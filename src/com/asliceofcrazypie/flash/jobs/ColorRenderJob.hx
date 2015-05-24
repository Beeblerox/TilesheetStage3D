package com.asliceofcrazypie.flash.jobs;

import flash.display3D.VertexBuffer3D;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Context3DVertexBufferFormat;

import com.asliceofcrazypie.flash.ContextWrapper;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.geom.Matrix;
import openfl.display.BlendMode;

import openfl.Vector;

/**
 * ...
 * @author Zaphod
 */
class ColorRenderJob extends BaseRenderJob
{
	private static var renderJobPool:Array<ColorRenderJob>;
	
	public function new() 
	{
		super(false);
	}
	
	public function addAAQuad(rect:Rectangle, r:Float = 1, g:Float = 1, b:Float = 1, a:Float = 1):Void
	{
		var prevVerticesNumber:Int = Std.int(vertexPos / dataPerVertice);
		
		vertices[vertexPos++] = rect.x; //top left x
		vertices[vertexPos++] = rect.y; //top left y
		
		vertices[vertexPos++] = r;
		vertices[vertexPos++] = g;
		vertices[vertexPos++] = b;
		vertices[vertexPos++] = a;
		
		vertices[vertexPos++] = rect.right; //top right x
		vertices[vertexPos++] = rect.y; //top right y
		
		vertices[vertexPos++] = r;
		vertices[vertexPos++] = g;
		vertices[vertexPos++] = b;
		vertices[vertexPos++] = a;
		
		vertices[vertexPos++] = rect.right; //bottom right x
		vertices[vertexPos++] = rect.bottom; //bottom right y
		
		vertices[vertexPos++] = r;
		vertices[vertexPos++] = g;
		vertices[vertexPos++] = b;
		vertices[vertexPos++] = a;
		
		vertices[vertexPos++] = rect.x; //bottom left x
		vertices[vertexPos++] = rect.bottom; //bottom left y
		
		vertices[vertexPos++] = r;
		vertices[vertexPos++] = g;
		vertices[vertexPos++] = b;
		vertices[vertexPos++] = a;
		
		numVertices += 4;
		numIndices += 6;
		
		indicesVector[indexPos++] = prevVerticesNumber + 2;
		indicesVector[indexPos++] = prevVerticesNumber + 1;
		indicesVector[indexPos++] = prevVerticesNumber + 0;
		indicesVector[indexPos++] = prevVerticesNumber + 3;
		indicesVector[indexPos++] = prevVerticesNumber + 2;
		indicesVector[indexPos++] = prevVerticesNumber + 0;
	}
	
	public function addQuad(rect:Rectangle, normalizedOrigin:Point, matrix:Matrix, r:Float = 1, g:Float = 1, b:Float = 1, a:Float = 1):Void
	{
		var prevVerticesNumber:Int = Std.int(vertexPos / dataPerVertice);
		
		var imgWidth:Int = Std.int(rect.width);
		var imgHeight:Int = Std.int(rect.height);
		
		var centerX:Float = normalizedOrigin.x * imgWidth;
		var centerY:Float = normalizedOrigin.y * imgHeight;
		
		var px:Float;
		var py:Float;
		
		//top left
		px = -centerX;
		py = -centerY;
		
		vertices[vertexPos++] = px * matrix.a + py * matrix.c + matrix.tx; //top left x
		vertices[vertexPos++] = px * matrix.b + py * matrix.d + matrix.ty; //top left y
		
		vertices[vertexPos++] = r;
		vertices[vertexPos++] = g;
		vertices[vertexPos++] = b;
		vertices[vertexPos++] = a;
		
		//top right
		px = imgWidth - centerX;
		py = -centerY;
		
		vertices[vertexPos++] = px * matrix.a + py * matrix.c + matrix.tx; //top right x
		vertices[vertexPos++] = px * matrix.b + py * matrix.d + matrix.ty; //top right y
		
		vertices[vertexPos++] = r;
		vertices[vertexPos++] = g;
		vertices[vertexPos++] = b;
		vertices[vertexPos++] = a;
		
		//bottom right
		px = imgWidth - centerX;
		py = imgHeight - centerY;
		
		vertices[vertexPos++] = px * matrix.a + py * matrix.c + matrix.tx; //bottom right x
		vertices[vertexPos++] = px * matrix.b + py * matrix.d + matrix.ty; //bottom right y
		
		vertices[vertexPos++] = r;
		vertices[vertexPos++] = g;
		vertices[vertexPos++] = b;
		vertices[vertexPos++] = a;
		
		//bottom left
		px = -centerX;
		py = imgHeight - centerY;
		
		vertices[vertexPos++] = px * matrix.a + py * matrix.c + matrix.tx; //bottom left x
		vertices[vertexPos++] = px * matrix.b + py * matrix.d + matrix.ty; //bottom left y
		
		vertices[vertexPos++] = r;
		vertices[vertexPos++] = g;
		vertices[vertexPos++] = b;
		vertices[vertexPos++] = a;
		
		numVertices += 4;
		numIndices += 6;
		
		indicesVector[indexPos++] = prevVerticesNumber + 2;
		indicesVector[indexPos++] = prevVerticesNumber + 1;
		indicesVector[indexPos++] = prevVerticesNumber + 0;
		indicesVector[indexPos++] = prevVerticesNumber + 3;
		indicesVector[indexPos++] = prevVerticesNumber + 2;
		indicesVector[indexPos++] = prevVerticesNumber + 0;
	}
	
	public function addTriangles(vertices:Vector<Float>, indices:Vector<Int> = null, colors:Vector<Int> = null, position:Point = null):Void
	{
		var numIndices:Int = indices.length;
		var numVertices:Int = Std.int(vertices.length / 2);
		
		var prevVerticesNumber:Int = Std.int(vertexPos / dataPerVertice);
		
		var vertexIndex:Int = 0;
		var vColor:Int;
		
		var x:Float = 0;
		var y:Float = 0;
		
		if (position != null)
		{
			x = position.x;
			y = position.y;
		}
		
		for (i in 0...numVertices)
		{
			vertexIndex = 2 * i;
			
			this.vertices[vertexPos++] = vertices[vertexIndex] + x;
			this.vertices[vertexPos++] = vertices[vertexIndex + 1] + y;
			
			vColor = colors[i];
			this.vertices[vertexPos++] = ((vColor >> 16) & 0xff) / 255;
			this.vertices[vertexPos++] = ((vColor >> 8) & 0xff) / 255;
			this.vertices[vertexPos++] = (vColor & 0xff) / 255;
			this.vertices[vertexPos++] = ((vColor >> 24) & 0xff) / 255;
		}
		
		for (i in 0...numIndices)
		{
			this.indicesVector[indexPos++] = prevVerticesNumber + indices[i];
		}
		
		this.numVertices += numVertices;
		this.numIndices += numIndices;
	}
	
	override public function render(context:ContextWrapper = null, colored:Bool = false):Void 
	{
		// TODO: implement it...
		
		if (context != null && context.context3D.driverInfo != 'Disposed')
		{
			//blend mode
			context.setBlendMode(blendMode, false);
			
			context.setNoImageProgram(colored); //assign appropriate shader
			
			// TODO: culling support...
			// context.context3D.setCulling();
			
		//	context.setTexture(null);
			
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
			indexbuffer.uploadFromVector(indicesVector, 0, numIndices);
			
			// vertex position to attribute register 0
			context.context3D.setVertexBufferAt(0, vertexbuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			// color to attribute register 1
			context.context3D.setVertexBufferAt(1, vertexbuffer, 2, Context3DVertexBufferFormat.FLOAT_4);
		//	context.context3D.setVertexBufferAt(2, null, 6);
			
			context.context3D.drawTriangles(indexbuffer);
		}
	}
	
	public static inline function getJob(tilesheet:TilesheetStage3D, blend:BlendMode):ColorRenderJob
	{
		var job:ColorRenderJob = (renderJobPool.length > 0) ? renderJobPool.pop() : new ColorRenderJob();
		job.blendMode = blend;
		job.dataPerVertice = 6;
		return job;
	}
	
	public static inline function returnJob(renderJob:ColorRenderJob):Void
	{
		renderJobPool.push(renderJob);
	}
	
	public static function __init__():Void
	{
		renderJobPool = [];
		for (i in 0...BaseRenderJob.NUM_JOBS_TO_POOL)
		{
			renderJobPool.push(new ColorRenderJob());
		}
	}
}