package com.asliceofcrazypie.flash;

import openfl.geom.Matrix3D;
import openfl.geom.Rectangle;

/**
 * ...
 * @author Zaphod
 */
class Viewport
{
	public var matrix(default, null):Matrix3D;
	
	public var scissor(default, null):Rectangle;
	
	public var x(default, set):Float;
	public var y(default, set):Float;
	
	public var width(default, set):Float;
	public var height(default, set):Float;
	
	public var scaleX(default, set):Float;
	public var scaleY(default, set):Float;
	
	public function new(x:Float, y:Float, width:Float, height:Float, scaleX:Float, scaleY:Float) 
	{
		scissor = new Rectangle();
		matrix = new Matrix3D();
		
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}
	
	public function dispose():Void
	{
		
	}
	
	private function set_x(value:Float):Float
	{
		return x = value;
	}
	
	private function set_y(value:Float):Float
	{
		return y = value;
	}
	
	private function set_width(value:Float):Float
	{
		return width = value;
	}
	
	private function set_height(value:Float):Float
	{
		return height = value;
	}
	
	private function set_scaleX(value:Float):Float
	{
		return scaleX = value;
	}
	
	private function set_scaleY(value:Float):Float
	{
		return scaleY = value;
	}
}