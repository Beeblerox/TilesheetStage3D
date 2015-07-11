package com.asliceofcrazypie.flash.jobs;

import flash.display.BlendMode;
import flash.Vector;
import openfl.display.Sprite;

/**
 * ...
 * @author Zaphod
 */
class BaseRenderJob extends VeryBasicRenderJob
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
	
	public var dataPerVertice:Int = 0;
	public var numVertices:Int = 0;
	public var numIndices:Int = 0;
	
	#if flash11
	public var vertices(default, null):Vector<Float>;
	public var indices(default, null):Vector<UInt>;
	#end
	
	public var vertexPos:Int = 0;
	public var indexPos:Int = 0;
	public var colorPos:Int = 0;
	
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
		
		QuadRenderJob.init();
		TriangleRenderJob.init();
		ColorRenderJob.init();
	}
	
	private function new() 
	{
		super();
	}
	
	override private function initData():Void
	{
		#if flash11
		this.vertices = new Vector<Float>(BaseRenderJob.vertexPerBuffer >> 2);
		this.indices = new Vector<UInt>();
		#end
	}
	
	override public function canAddQuad():Bool
	{
		return (numVertices + 4) <= BaseRenderJob.vertexPerBuffer;
	}
	
	public inline function canAddTriangles(numVertices:Int):Bool
	{
		return (numVertices + this.numVertices) <= BaseRenderJob.vertexPerBuffer;
	}
	
	public static inline function checkMaxTrianglesCapacity(numVertices:Int):Bool
	{
		return numVertices <= BaseRenderJob.vertexPerBuffer;
	}
	
	override public function reset():Void
	{
		super.reset();
		
		vertexPos = 0;
		indexPos = 0;
		colorPos = 0;
		numVertices = 0;
		numIndices = 0;
	}
}