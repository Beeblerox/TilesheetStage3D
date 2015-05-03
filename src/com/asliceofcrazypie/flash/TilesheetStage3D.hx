package com.asliceofcrazypie.flash;

import openfl.display.BitmapData;
import openfl.display.Tilesheet;
import openfl.events.Event;
import openfl.geom.Matrix;

#if flash11
import com.asliceofcrazypie.flash.jobs.RenderJob;
import com.asliceofcrazypie.flash.jobs.QuadRenderJob;
import com.asliceofcrazypie.flash.jobs.TriangleRenderJob;

import flash.Vector;
import haxe.Timer;
import flash.errors.Error;
import flash.display3D.Context3D;
import flash.display3D.Context3DRenderMode;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.textures.Texture;
import flash.display.Stage;
import flash.display.Graphics;
import flash.display.BlendMode;
import flash.display.TriangleCulling;
import flash.errors.ArgumentError;
import flash.events.ErrorEvent;
import flash.geom.Point;
import flash.geom.Rectangle;

import flash.utils.ByteArray;
import flash.utils.Endian;
#end

/**
 * ...
 * @author Paul M Pepper
 */
class TilesheetStage3D extends Tilesheet
{
	public function new(inImage:BitmapData, premultipliedAlpha:Bool = true) 
	{
		#if flash11
		inImage = TilesheetStage3D.fixTextureSize(inImage.clone(), true);
		#end
		
		super(inImage);
		
		#if flash11
		this.premultipliedAlpha = premultipliedAlpha;
		fallbackMode = FallbackMode.ALLOW_FALLBACK;
		
		if (!_isInited && !Type.enumEq(fallbackMode, FallbackMode.NO_FALLBACK))
		{
			throw new Error('Attemping to create TilesheetStage3D object before Stage3D has initialised.');
		}
		
		if (context != null && context.context3D != null)
		{
			onResetTexture(null);
			context.addEventListener(ContextWrapper.RESET_TEXTURE, onResetTexture);
		}
		#end
	}
	
	#if flash11
	private function onResetTexture(e:Event):Void 
	{
		texture = context.uploadTexture(__bitmap);
	}
	
	public var premultipliedAlpha(default, null):Bool;
	
	private var texture:Texture;
	
	//static vars
	private static var context:ContextWrapper;
	private static var _isInited:Bool;
	
	//config
	public var fallbackMode:FallbackMode;
	
	//internal
	private static var _stage:Stage;
	private static var _stage3DLevel:Int;
	private static var _initCallback:String->Void;
	
	public static inline var MAX_INDICES_PER_BUFFER:Int = 98298;
	public static inline var MAX_VERTEX_PER_BUFFER:Int = 65532;		// (MAX_INDICES_PER_BUFFER * 4 / 6)
	public static inline var MAX_QUADS_PER_BUFFER:Int = 16383;		// (MAX_VERTEX_PER_BUFFER / 4)
	public static inline var MAX_TRIANGLES_PER_BUFFER:Int = 21844;	// (MAX_VERTEX_PER_BUFFER / 3)
	
	// TODO: make batch size settable (this means adding static vars like VERTEX_PER_BUFFER, QUADS_PER_BUFFER and INDICES_PER_BUFFER)
	
	// TODO: use these static vars (and document them)...
	public static var vertexPerBuffer(default, null):Int;
	public static var quadsPerBuffer(default, null):Int;
	public static var trianglesPerBuffer(default, null):Int;
	public static var indicesPerBuffer(default, null):Int;
	
	private static var matrix:Matrix = new Matrix();
	
	// TODO: document it and don't forget to use new batchSize argument...
	/**
	 * 
	 * 
	 * @param	stage
	 * @param	stage3DLevel
	 * @param	antiAliasLevel
	 * @param	initCallback
	 * @param	renderMode
	 * @param	batchSize
	 */
	public static function init(stage:Stage, stage3DLevel:Int = 0, antiAliasLevel:Int = 5, initCallback:String->Void = null, renderMode:Context3DRenderMode = null, batchSize:Int = 0):Void
	{
		if (!_isInited)
		{
			TilesheetStage3D.quadsPerBuffer = (MAX_QUADS_PER_BUFFER < batchSize || batchSize <= 0) ? MAX_QUADS_PER_BUFFER : batchSize;
			TilesheetStage3D.vertexPerBuffer = TilesheetStage3D.quadsPerBuffer * 4;
			TilesheetStage3D.indicesPerBuffer = TilesheetStage3D.quadsPerBuffer * 6;
			TilesheetStage3D.trianglesPerBuffer = Std.int(TilesheetStage3D.vertexPerBuffer / 3);
			
			if (stage3DLevel < 0 || stage3DLevel >= Std.int(stage.stage3Ds.length))
			{
				throw new ArgumentError('stage3D depth of ' + stage3DLevel + ' out of bounds 0-' + (stage.stage3Ds.length - 1));
			}
			
			antiAliasing = antiAliasLevel;
			_isInited = true;
			
			context = new ContextWrapper(stage3DLevel);
			
			_stage = stage;
			_stage3DLevel = stage3DLevel;
			_initCallback = initCallback;
			
			context.init(stage, onContextInit, renderMode);
		}
	}
	
	private static function onContextInit():Void 
	{
		if (_initCallback != null)
		{
			//really not sure why this delay is needed
			Timer.delay(function() {
				_initCallback(context.context3D == null ? 'failure' : 'success');
				_initCallback = null;
			},
			50);
		}
	}
	
	public static inline function clear():Void
	{
		if (context != null)
		{
			context.clear();
		}
	}
	
	// TODO: document it...
	// TODO: support culling...
	/**
	 * 
	 * 
	 * @param	vertices
	 * @param	indices
	 * @param	uvtData
	 * @param	culling
	 * @param	colors
	 * @param	blending
	 */
	public function drawTriangles(graphics:Graphics, vertices:Vector<Float>, indices:Vector<Int> = null, uvtData:Vector<Float> = null, culling:TriangleCulling = null, colors:Vector<Int> = null, smooth:Bool = false, blending:BlendMode = null):Void
	{
		if (context != null && context.context3D != null && !Type.enumEq(fallbackMode, FallbackMode.FORCE_FALLBACK))
		{
			var isColored:Bool = (colors != null && colors.length > 0);
			
			var dataPerVertice:Int = (isColored) ? 8 : 4;
			
			var numIndices:Int = indices.length;
			var numVertices:Int = Std.int(vertices.length / 2);
			
			var renderJob:TriangleRenderJob = TriangleRenderJob.getJob();
			
			if (numIndices + renderJob.numIndices > MAX_INDICES_PER_BUFFER)
			{
				throw ("Number of indices shouldn't be more than " + MAX_INDICES_PER_BUFFER);
			}
			
			if (numVertices + renderJob.numIndices > MAX_VERTEX_PER_BUFFER)
			{
				throw ("Number of vertices shouldn't be more than " + MAX_VERTEX_PER_BUFFER);
			}
			
			renderJob.texture = texture;
			renderJob.isRGB = isColored;
			renderJob.isAlpha = isColored;
			renderJob.isSmooth = smooth;
			renderJob.dataPerVertice = dataPerVertice;
			renderJob.numVertices = numVertices;
			renderJob.premultipliedAlpha = this.premultipliedAlpha;
			
			if (blending == BlendMode.ADD)
			{
				renderJob.blendMode = RenderJob.BLEND_ADD;
			}
			else if (blending == BlendMode.MULTIPLY)
			{
				renderJob.blendMode = RenderJob.BLEND_MULTIPLY;
			}
			else if (blending == BlendMode.SCREEN)
			{
				renderJob.blendMode = RenderJob.BLEND_SCREEN;
			}
			else
			{
				renderJob.blendMode = RenderJob.BLEND_NORMAL;
			}
			
			var vertexPos:Int = renderJob.vertexPos;
			var indexPos:Int = renderJob.indexPos;
			var prevVerticesNumber:Int = Std.int(renderJob.vertexPos / dataPerVertice);
			
			var vertexIndex:Int = 0;
			var vColor:Int;
			
			var jobVertices:Vector<Float> = renderJob.vertices;
			var jobIndices:Vector<UInt> = renderJob.indicesVector;
			
			for (i in 0...numVertices)
			{
				vertexIndex = 2 * i;
				
				jobVertices[vertexPos++] = vertices[vertexIndex];
				jobVertices[vertexPos++] = vertices[vertexIndex + 1];
				
				jobVertices[vertexPos++] = uvtData[vertexIndex];
				jobVertices[vertexPos++] = uvtData[vertexIndex + 1];
				
				if (isColored)
				{
					vColor = colors[i];
					jobVertices[vertexPos++] = ((vColor >> 16) & 0xff) / 255;
					jobVertices[vertexPos++] = ((vColor >> 8) & 0xff) / 255;
					jobVertices[vertexPos++] = (vColor & 0xff) / 255;
					jobVertices[vertexPos++] = ((vColor >> 24) & 0xff) / 255;	
				}
			}
			renderJob.vertexPos = vertexPos;
			
			for (i in 0...numIndices)
			{
				jobIndices[indexPos++] = prevVerticesNumber + indices[i];
			}
			renderJob.indexPos = indexPos;
			
			renderJob.numVertices += numVertices;
			renderJob.numIndices += numIndices;
			
			context.addTriangleJob(renderJob);
		}
		else if(!Type.enumEq(fallbackMode, FallbackMode.NO_FALLBACK))
		{
			graphics.drawTriangles(vertices, indices, uvtData, culling);
		}
	}
	
	override public function drawTiles(graphics:Graphics, tileData:Array<Float>, smooth:Bool = false, flags:Int = 0, count:Int = -1):Void
	{
		if (context != null && context.context3D != null && !Type.enumEq(fallbackMode, FallbackMode.FORCE_FALLBACK))
		{
			//parse flags
			var isMatrix:Bool = (flags & Tilesheet.TILE_TRANS_2x2) > 0;
			var isScale:Bool = (flags & Tilesheet.TILE_SCALE) > 0;
			var isRotation:Bool = (flags & Tilesheet.TILE_ROTATION) > 0;
			var isRGB:Bool = (flags & Tilesheet.TILE_RGB) > 0;
			var isAlpha:Bool = (flags & Tilesheet.TILE_ALPHA) > 0;
			var isBlendAdd:Bool = (flags & Tilesheet.TILE_BLEND_ADD) > 0;
			var isBlendMultiply:Bool = (flags & Tilesheet.TILE_BLEND_MULTIPLY) > 0;
			var isBlendScreen:Bool = (flags & Tilesheet.TILE_BLEND_SCREEN) > 0;
			var isRect:Bool = (flags & Tilesheet.TILE_RECT) > 0;
			var isOrigin:Bool = (flags & Tilesheet.TILE_ORIGIN) > 0;
			
			var scale:Float = 1;
			var rotation:Float = 0;
			var cosRotation:Float = 1;
			var sinRotation:Float = 0;
			var r:Float = 1;
			var g:Float = 1;
			var b:Float = 1;
			var a:Float = 1;
			
			var rect:Rectangle;
			var origin:Point;
			var uv:Rectangle;
			var tileId:Int;
			
			//determine data structure based on flags
			var tileDataPerItem:Int = 3;
			var dataPerVertice:Int = 4;
			
			var xOff:Int = 0;
			var yOff:Int = 1;
			var tileIdOff:Int = 2;
			var scaleOff:Int = 0;
			var rotationOff:Int = 0;
			var matrixOff:Int = 0;
			var matrixPos:Int = 0;
			var rOff:Int = 0;
			var gOff:Int = 0;
			var bOff:Int = 0;
			var aOff:Int = 0;
			
			if (isRect) { tileDataPerItem = isOrigin ? 8 : 6; }
			
			if (isMatrix) 
			{ 
				matrixOff = tileDataPerItem; tileDataPerItem += 4; 
			}
			else
			{
				if (isScale) { scaleOff = tileDataPerItem; tileDataPerItem++; }
				if (isRotation) { rotationOff = tileDataPerItem; tileDataPerItem++; }
			}
			
			if (isRGB) 
			{
				rOff = tileDataPerItem;
				gOff = tileDataPerItem + 1;
				bOff = tileDataPerItem + 2;
				tileDataPerItem += 3;
				dataPerVertice += 3;
			}
			
			if (isAlpha) 
			{
				aOff = tileDataPerItem; 
				tileDataPerItem++;
				dataPerVertice++;
			}
			
			var totalCount = count;
			
			if (count < 0) 
			{	
				totalCount = tileData.length;
			}
			
			var numItems:Int = Std.int(totalCount / tileDataPerItem);
			
			if (numItems == 0)
			{
				return;
			}
			
			if (totalCount % tileDataPerItem != 0)
			{
				throw new ArgumentError('tileData length must be a multiple of ' + tileDataPerItem);
			}
			
			var renderJob:QuadRenderJob;
			
			var tileDataPos:Int = 0;
			
			var transform_tx:Float, transform_ty:Float, transform_a:Float, transform_b:Float, transform_c:Float, transform_d:Float;
			
			///////////////////
			// for each item //
			///////////////////
			var maxNumItems:Int = MAX_QUADS_PER_BUFFER;
			var startItemPos:Int = 0;
			var numItemsThisLoop:Int = 0;
			
			while (tileDataPos < totalCount)
			{
				numItemsThisLoop = numItems > maxNumItems ? maxNumItems : numItems;
				numItems -= numItemsThisLoop;
				
				renderJob = QuadRenderJob.getJob();
				renderJob.texture = texture;
				renderJob.isRGB = isRGB;
				renderJob.isAlpha = isAlpha;
				renderJob.isSmooth = smooth;
				renderJob.dataPerVertice = dataPerVertice;
				renderJob.premultipliedAlpha = this.premultipliedAlpha;
				
				if (isBlendAdd)
				{
					renderJob.blendMode = RenderJob.BLEND_ADD;
				}
				else if (isBlendMultiply)
				{
					renderJob.blendMode = RenderJob.BLEND_MULTIPLY;
				}
				else if (isBlendScreen)
				{
					renderJob.blendMode = RenderJob.BLEND_SCREEN;
				}
				else
				{
					renderJob.blendMode = RenderJob.BLEND_NORMAL;
				}
				
				for (i in 0...numItemsThisLoop)
				{
					rect = null;
					origin = null;
					uv = null;
					
					r = g = b = a = 1.0;
					
					if (isRect) 
					{ 
						rect = __rectTile;
						origin = __point;
						
						rect.setTo(	tileData[tileDataPos + 2], 
									tileData[tileDataPos + 3], 
									tileData[tileDataPos + 4], 
									tileData[tileDataPos + 5]);
						
						if (isOrigin)
						{
							origin.setTo(	tileData[tileDataPos + 6] / rect.width, 
											tileData[tileDataPos + 7] / rect.height);
						}
						else
						{
							origin.setTo(0, 0);
						}
						
						uv = __rectUV;
						uv.setTo(rect.left / __bitmapWidth, rect.top / __bitmapHeight, rect.right / __bitmapWidth, rect.bottom / __bitmapHeight);
					}
					else
					{
						tileId = Std.int(tileData[tileDataPos + tileIdOff]);
						origin = __centerPoints[tileId];
						uv = __tileUVs[tileId];
						rect = __tileRects[tileId];
					}
					
					//calculate transforms
					transform_tx = tileData[tileDataPos + xOff];
					transform_ty = tileData[tileDataPos + yOff];
					
					if (isMatrix)
					{
						matrixPos = tileDataPos + matrixOff;
						transform_a = tileData[matrixPos++];
						transform_b = tileData[matrixPos++];
						transform_c = tileData[matrixPos++];
						transform_d = tileData[matrixPos++];
					}
					else
					{
						if (isScale)
						{
							scale = tileData[tileDataPos + scaleOff];
						}
						
						if (isRotation)
						{
							rotation = -tileData[tileDataPos + rotationOff];
							cosRotation = Math.cos(rotation);
							sinRotation = Math.sin(rotation);
						}
						
						transform_a = scale * cosRotation;
						transform_c = scale * -sinRotation;
						transform_b = scale * sinRotation;
						transform_d = scale * cosRotation;
					}
					
					if (isRGB)
					{
						r = tileData[tileDataPos + rOff];
						g = tileData[tileDataPos + gOff];
						b = tileData[tileDataPos + bOff];
					}
					
					if (isAlpha)
					{
						a = tileData[tileDataPos + aOff];
					}
					
					matrix.setTo(transform_a, transform_b, transform_c, transform_d, transform_tx, transform_ty);
					
					renderJob.addQuad(rect, origin, uv, matrix, r, g, b, a);
					
					tileDataPos += tileDataPerItem;
				}
				
				//push vertices into jobs list
				context.addQuadJob(renderJob);		
			}//end while
		}
		else if(!Type.enumEq(fallbackMode, FallbackMode.NO_FALLBACK))
		{
			super.drawTiles(graphics, tileData, smooth, flags, count);
		}
	}
	
	public static var antiAliasing(default, set):Int;
	
	private static inline function set_antiAliasing(value:Int):Int
	{
		antiAliasing = value > 0 ? value < 16 ? value : 16 : 0; //limit value to 0-16
		
		if (context != null && context.context3D != null)
		{
			context.onStageResize(null);
		}
		
		return antiAliasing;
	}
	
	public static var driverInfo(get, never):String;
	
	private static function get_driverInfo():String
	{
		if (context != null && context.context3D != null)
		{
			return context.context3D.driverInfo;
		}
		
		return '';
	}
	
	public function dispose():Void
	{
		this.fallbackMode = null;
		
		if (this.texture != null)
		{
			this.texture.dispose();
			this.texture = null;
		}
		
		if (this.__bitmap != null)
		{
			this.__bitmap.dispose();
			this.__bitmap = null;
		}
	}
	
	//helper methods
	public static inline function roundUpToPow2(number:Int):Int
	{
		number--;
		number |= number >> 1;
		number |= number >> 2;
		number |= number >> 4;
		number |= number >> 8;
		number |= number >> 16;
		number++;
		return number;
	}
	
	public static inline function isTextureOk(texture:BitmapData):Bool
	{
		return (roundUpToPow2(texture.width) == texture.width && roundUpToPow2(texture.height) == texture.height);
	}
	
	public static inline function fixTextureSize(texture:BitmapData, autoDispose:Bool = false):BitmapData
	{
		return if (isTextureOk(texture))
		{
			texture;
		}
		else
		{
			var newTexture:BitmapData = new BitmapData(roundUpToPow2(texture.width), roundUpToPow2(texture.height), true, 0);
			newTexture.copyPixels(texture, texture.rect, new Point(), null, null, true);
			
			if (autoDispose)
			{
				texture.dispose();
			}
			
			newTexture;
		}
	}
	#end
}

#if flash11
enum FallbackMode
{
	NO_FALLBACK;
	ALLOW_FALLBACK;
	FORCE_FALLBACK;
}
#end