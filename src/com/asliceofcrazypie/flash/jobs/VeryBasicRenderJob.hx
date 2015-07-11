package com.asliceofcrazypie.flash.jobs;

import flash.display.BlendMode;
import openfl.display.Sprite;

/**
 * ...
 * @author Zaphod
 */
class VeryBasicRenderJob
{
	public static inline var NUM_JOBS_TO_POOL:Int = 25;
	
	public var tilesheet:TilesheetStage3D;
	
	public var isRGB:Bool;
	public var isAlpha:Bool;
	public var isSmooth:Bool;
	
	public var blendMode:BlendMode;
	
	public var type(default, null):RenderJobType;
	
	private function new() 
	{
		initData();
	}
	
	private function initData():Void
	{
		
	}
	
	#if flash11
	public function render(context:ContextWrapper = null, colored:Bool = false):Void
	{
		
	}
	#else
	public function render(context:Sprite = null, colored:Bool = false):Void
	{
		
	}
	#end
	
	public function canAddQuad():Bool
	{
		return false;
	}
	
	public function reset():Void
	{
		blendMode = null;
		tilesheet = null;
	}
	
}

enum RenderJobType
{
	QUAD;
	TRIANGLE;
	NO_IMAGE;
}