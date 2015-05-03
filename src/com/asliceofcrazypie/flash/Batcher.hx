package com.asliceofcrazypie.flash;

import openfl.geom.Point;
import openfl.geom.Rectangle;
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
	public static function addTriangles(tilesheet:TilesheetStage3D, vertices:Vector<Float>, indices:Vector<Int> = null, uvtData:Vector<Float> = null, culling:TriangleCulling = null, colors:Vector<Int> = null, smooth:Bool = false, blending:BlendMode = null):Void
	{
		
	}
	
	// TODO: implement it and document it...
	public function addQuad(tilesheet:TilesheetStage3D, tileRect:Rectangle, origin:Point = null, smooth:Bool = false, flags:Int = 0):Void
	{
		
	}
}