package com.asliceofcrazypie.flash.jobs;
import com.asliceofcrazypie.flash.ContextWrapper;
import com.asliceofcrazypie.flash.TilesheetStage3D;
import openfl.display.Sprite;
import openfl.display.Tilesheet;

#if flash11
import flash.display3D.textures.Texture;
#end
import com.asliceofcrazypie.flash.jobs.VeryBasicRenderJob.RenderJobType;
import flash.display.BlendMode;
import flash.display.TriangleCulling;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.Vector;

/**
 * ...
 * @author Zaphod
 */
#if flash11
class TriangleRenderJob extends RenderJob
#else
class TriangleRenderJob extends BaseRenderJob
#end
{
	private static var renderJobPool:Array<TriangleRenderJob>;
	
	public static inline function getJob(tilesheet:TilesheetStage3D, isRGB:Bool, isAlpha:Bool, isSmooth:Bool, blend:BlendMode):TriangleRenderJob
	{
		var job:TriangleRenderJob = (renderJobPool.length > 0) ? renderJobPool.pop() : new TriangleRenderJob();
		job.set(tilesheet, isRGB, isAlpha, isSmooth, blend);
		return job;
	}
	
	public static inline function returnJob(renderJob:TriangleRenderJob):Void
	{
		renderJobPool.push(renderJob);
	}
	
	public static function init():Void
	{
		renderJobPool = [];
		for (i in 0...VeryBasicRenderJob.NUM_JOBS_TO_POOL)
		{
			renderJobPool.push(new TriangleRenderJob());
		}
	}
	
#if !flash11
	#if flash
	public var vertices(default, null):Vector<Float>;
	public var indices(default, null):Vector<UInt>;
	public var uvtData(default, null):Vector<Float>;
	#else
	public var vertices(default, null):Array<Float>;
	public var indices(default, null):Array<Int>;
	public var uvtData(default, null):Array<Float>;
	public var colors(default, null):Array<Int>;
	#end
	
	public var uvtPos:Int = 0;
#end
	
	public function new() 
	{
		super();
		type = RenderJobType.TRIANGLE;
	}
	
	#if flash11
	override public function addQuad(rect:Rectangle, normalizedOrigin:Point, uv:Rectangle, matrix:Matrix, r:Float = 1, g:Float = 1, b:Float = 1, a:Float = 1):Void
	{
		var prevVerticesNumber:Int = Std.int(vertexPos / dataPerVertice);
		
		super.addQuad(rect, normalizedOrigin, uv, matrix, r, g, b, a);
		
		indices[indexPos++] = prevVerticesNumber + 2;
		indices[indexPos++] = prevVerticesNumber + 1;
		indices[indexPos++] = prevVerticesNumber + 0;
		indices[indexPos++] = prevVerticesNumber + 3;
		indices[indexPos++] = prevVerticesNumber + 2;
		indices[indexPos++] = prevVerticesNumber + 0;
	}
	
	public function addTriangles(vertices:Vector<Float>, indices:Vector<Int> = null, uvtData:Vector<Float> = null, colors:Vector<Int> = null, position:Point = null):Void
	{
		var numIndices:Int = indices.length;
		var numVertices:Int = Std.int(vertices.length / 2);
		
		var prevVerticesNumber:Int = Std.int(vertexPos / dataPerVertice);
		
		var vertexIndex:Int = 0;
		var vColor:Int;
		
		var colored:Bool = (isRGB || isAlpha);
		
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
			this.indices[indexPos++] = prevVerticesNumber + indices[i];
		}
		
		this.numVertices += numVertices;
		this.numIndices += numIndices;
	}
	#else
	public function addQuad(rect:Rectangle, normalizedOrigin:Point, uv:Rectangle, matrix:Matrix, r:Float = 1, g:Float = 1, b:Float = 1, a:Float = 1):Void
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
		
		//top right
		px = imgWidth - centerX;
		py = -centerY;
		
		vertices[vertexPos++] = px * matrix.a + py * matrix.c + matrix.tx; //top right x
		vertices[vertexPos++] = px * matrix.b + py * matrix.d + matrix.ty; //top right y
		
		//bottom right
		px = imgWidth - centerX;
		py = imgHeight - centerY;
		
		vertices[vertexPos++] = px * matrix.a + py * matrix.c + matrix.tx; //bottom right x
		vertices[vertexPos++] = px * matrix.b + py * matrix.d + matrix.ty; //bottom right y
		
		//bottom left
		px = -centerX;
		py = imgHeight - centerY;
		
		vertices[vertexPos++] = px * matrix.a + py * matrix.c + matrix.tx; //bottom left x
		vertices[vertexPos++] = px * matrix.b + py * matrix.d + matrix.ty; //bottom left y
		
		this.uvtData[uvtPos++] = uv.x;
		this.uvtData[uvtPos++] = uv.y;
		
		this.uvtData[uvtPos++] = uv.width;
		this.uvtData[uvtPos++] = uv.y;
		
		this.uvtData[uvtPos++] = uv.width;
		this.uvtData[uvtPos++] = uv.height;
		
		this.uvtData[uvtPos++] = uv.x;
		this.uvtData[uvtPos++] = uv.height;
		
		indices[indexPos++] = prevVerticesNumber + 2;
		indices[indexPos++] = prevVerticesNumber + 1;
		indices[indexPos++] = prevVerticesNumber + 0;
		indices[indexPos++] = prevVerticesNumber + 3;
		indices[indexPos++] = prevVerticesNumber + 2;
		indices[indexPos++] = prevVerticesNumber + 0;
		
		#if !flash
		if (isRGB || isAlpha)
		{
			var color = ((Std.int(a * 255) << 24) | (Std.int(r * 255) << 16) | (Std.int(g * 255) << 8) | Std.int(b * 255));
			colors[colorPos++] = color;
			colors[colorPos++] = color;
			colors[colorPos++] = color;
			colors[colorPos++] = color;
		}		
		#end
		
		this.numVertices += 4;
		this.numIndices += 6;
	}
	
	public function addTriangles(vertices:Vector<Float>, indices:Vector<Int> = null, uvtData:Vector<Float> = null, colors:Vector<Int> = null, position:Point = null):Void
	{
		var numIndices:Int = indices.length;
		var numVertices:Int = Std.int(vertices.length / 2);
		
		var prevVerticesNumber:Int = Std.int(vertexPos / dataPerVertice);
		
		var vertexIndex:Int = 0;
		
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
			
			#if !flash
			if (colors != null)
				this.colors[colorPos++] = colors[i];
			#end
		}
		
		var uvtDataLength:Int = uvtData.length;
		for (i in 0...uvtDataLength)
		{
			this.uvtData[uvtPos++] = uvtData[i];
		}
		
		for (i in 0...numIndices)
		{
			this.indices[indexPos++] = prevVerticesNumber + indices[i];
		}
		
		this.numVertices += numVertices;
		this.numIndices += numIndices;
	}
	
	override public function render(context:Sprite = null, colored:Bool = false):Void 
	{
		context.graphics.beginBitmapFill(tilesheet.bitmap, null, true, isSmooth);
		#if flash
		context.graphics.drawTriangles(vertices, indices, uvtData, TriangleCulling.NONE);
		#else
		var blendInt:Int = 0;
		
		if (blendMode == BlendMode.ADD)
		{
			blendInt = Tilesheet.TILE_BLEND_ADD;
		}
		else if (blendMode == BlendMode.MULTIPLY)
		{
			blendInt = Tilesheet.TILE_BLEND_MULTIPLY;
		}
		else if (blendMode == BlendMode.SCREEN)
		{
			blendInt = Tilesheet.TILE_BLEND_SCREEN;
		}
		
		context.graphics.drawTriangles(vertices, indices, uvtData, TriangleCulling.NONE, (colors.length > 0) ? colors : null, blendInt);
		#end
		context.graphics.endFill();
	}
	
	override function initData():Void 
	{
		#if flash
		vertices = new Vector<Float>();
		indices = new Vector<Int>();
		uvtData = new Vector<Float>();
		#else
		vertices = new Array<Float>();
		indices = new Array<Int>();
		uvtData = new Array<Float>();
		colors = new Array<Int>();
		#end
	}
	
	override public function reset():Void 
	{
		super.reset();
		
		uvtPos = 0;
		
		vertices.splice(0, vertices.length);
		indices.splice(0, indices.length);
		uvtData.splice(0, uvtData.length);
		
		#if !flash
		colors.splice(0, colors.length);
		#end
	}
	#end
	
	public function set(tilesheet:TilesheetStage3D, isRGB:Bool, isAlpha:Bool, isSmooth:Bool, blend:BlendMode):Void
	{
		this.tilesheet = tilesheet;
		this.isRGB = isRGB;
		this.isAlpha = isAlpha;
		this.isSmooth = isSmooth;
		this.blendMode = blend;
		
		var dataPerVertice:Int = 4;
		if (isRGB)
		{
			dataPerVertice += 3;
		}
		if (isAlpha)
		{
			dataPerVertice++;
		}
		
		this.dataPerVertice = dataPerVertice;
	}
}