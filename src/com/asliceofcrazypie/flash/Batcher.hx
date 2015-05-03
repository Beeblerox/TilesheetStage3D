package com.asliceofcrazypie.flash;

import openfl.Vector;
import flash.display.TriangleCulling;
import flash.display.BlendMode;

/**
 * ...
 * @author Zaphod
 */
class Batcher
{

	// TODO: implement it and document it...
	public static function batchTriangles(tilesheet:TilesheetStage3D, vertices:Vector<Float>, indices:Vector<Int> = null, uvtData:Vector<Float> = null, culling:TriangleCulling = null, colors:Vector<Int> = null, smooth:Bool = false, blending:BlendMode = null):Void
	{
		
	}
	
	// TODO: move this into batcher class, implement it and document it...
	public function batchQuads(tilesheet:TilesheetStage3D, tileData:Array<Float>, smooth:Bool = false, flags:Int = 0):Void
	{
		
	}
}