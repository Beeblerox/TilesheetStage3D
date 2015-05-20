package com.asliceofcrazypie.flash;

#if flash11
import com.asliceofcrazypie.flash.jobs.RenderJob;
import com.asliceofcrazypie.flash.jobs.QuadRenderJob;
import com.asliceofcrazypie.flash.jobs.TriangleRenderJob;

import flash.display3D.Context3DRenderMode;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.Context3D;
import flash.display3D.Program3D;
import flash.display3D.textures.Texture;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Stage;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.utils.ByteArray;
import flash.utils.Endian;
import flash.Vector;

/**
 * ...
 * @author Paul M Pepper
 */
class ContextWrapper extends EventDispatcher
{
	public static inline var RESET_TEXTURE:String = 'resetTexture';
	
	public var presented:Bool;
	public var context3D:Context3D;
	public var depth(default, null):Int;
	
	public var renderCallback:Void->Void;
	
	private var stage:Stage;
	private var antiAliasLevel:Int;
	private var baseTransformMatrix:Matrix3D;
	
	public var programRGBASmooth:Program3D;
	public var programRGBSmooth:Program3D;
	public var programASmooth:Program3D;
	public var programSmooth:Program3D;
	public var programRGBA:Program3D;
	public var programRGB:Program3D;
	public var programA:Program3D;
	public var program:Program3D;
	
	private var vertexDataRGBA:ByteArray;
	private var vertexData:ByteArray;
	
	private var fragmentDataRGBASmooth:ByteArray;
	private var fragmentDataRGBSmooth:ByteArray;
	private var fragmentDataASmooth:ByteArray;
	private var fragmentDataSmooth:ByteArray;
	private var fragmentDataRGBA:ByteArray;
	private var fragmentDataRGB:ByteArray;
	private var fragmentDataA:ByteArray;
	private var fragmentData:ByteArray;
	
	private var _initCallback:Void->Void;
	
	private var currentRenderJobs:Vector<RenderJob>;
	private var quadRenderJobs:Vector<QuadRenderJob>;
	private var triangleRenderJobs:Vector<TriangleRenderJob>;
	
	private var numCurrentRenderJobs:Int = 0;
	
	//avoid unneeded context changes
	private var currentTexture:Texture;
	private var currentProgram:Program3D;
	
	public function new(depth:Int, antiAliasLevel:Int = 1)
	{
		super();
		
		this.depth = depth;
		this.antiAliasLevel = antiAliasLevel;
		
		//vertex shader data
		var vertexRawDataRGBA:Array<Int> = 	[ -96, 1, 0, 0, 0, -95, 0, 24, 0, 0, 0, 0, 0, 15, 3, 0, 0, 0, -28, 0, 0, 0, 0, 0, 0, 0, -28, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 4, 1, 0, 0, -28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 15, 4, 2, 0, 0, -28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		var vertexRawData:Array<Int> = 		[ -96, 1, 0, 0, 0, -95, 0, 24, 0, 0, 0, 0, 0, 15, 3, 0, 0, 0, -28, 0, 0, 0, 0, 0, 0, 0, -28, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 4, 1, 0, 0, -28, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		
		//fragment shaders
		var fragmentRawDataRGBASmooth:Array<Int> = 	[ -96, 1, 0, 0, 0, -95, 1, 40, 0, 0, 0, 1, 0, 15, 2, 0, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 16, 3, 0, 0, 0, 2, 0, 15, 2, 1, 0, 0, -28, 2, 0, 0, 0, 1, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 3, 2, 0, 0, -28, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		var fragmentRawDataRGBSmooth:Array<Int> = 	[ -96, 1, 0, 0, 0, -95, 1, 40, 0, 0, 0, 1, 0, 15, 2, 0, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 16, 3, 0, 0, 0, 1, 0, 15, 2, 1, 0, 0, -28, 2, 0, 0, 0, 1, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 3, 1, 0, 0, -28, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		var fragmentRawDataASmooth:Array<Int> = 	[ -96, 1, 0, 0, 0, -95, 1, 40, 0, 0, 0, 1, 0, 15, 2, 0, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 16, 3, 0, 0, 0, 1, 0, 8, 2, 1, 0, 0, -1, 2, 0, 0, 0, 1, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 3, 1, 0, 0, -28, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		var fragmentRawDataSmooth:Array<Int> = 		[ -96, 1, 0, 0, 0, -95, 1, 40, 0, 0, 0, 1, 0, 15, 2, 0, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 16, 0, 0, 0, 0, 0, 0, 15, 3, 1, 0, 0, -28, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		var fragmentRawDataRGBA:Array<Int> = 		[ -96, 1, 0, 0, 0, -95, 1, 40, 0, 0, 0, 1, 0, 15, 2, 0, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 3, 0, 0, 0, 2, 0, 15, 2, 1, 0, 0, -28, 2, 0, 0, 0, 1, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 3, 2, 0, 0, -28, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		var fragmentRawDataRGB:Array<Int> = 		[ -96, 1, 0, 0, 0, -95, 1, 40, 0, 0, 0, 1, 0, 15, 2, 0, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 3, 0, 0, 0, 2, 0, 15, 2, 1, 0, 0, -28, 2, 0, 0, 0, 1, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 3, 2, 0, 0, -28, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		var fragmentRawDataA:Array<Int> = 			[ -96, 1, 0, 0, 0, -95, 1, 40, 0, 0, 0, 1, 0, 15, 2, 0, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 3, 0, 0, 0, 1, 0, 8, 2, 1, 0, 0, -1, 2, 0, 0, 0, 1, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 3, 1, 0, 0, -28, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		var fragmentRawData:Array<Int> = 			[ -96, 1, 0, 0, 0, -95, 1, 40, 0, 0, 0, 1, 0, 15, 2, 0, 0, 0, -28, 4, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 3, 1, 0, 0, -28, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
		
		vertexDataRGBA = 	rawDataToBytes(vertexRawDataRGBA);
		vertexData = 		rawDataToBytes(vertexRawData);
		
		fragmentDataRGBASmooth = 	rawDataToBytes(fragmentRawDataRGBASmooth);
		fragmentDataRGBSmooth = 	rawDataToBytes(fragmentRawDataRGBSmooth);
		fragmentDataASmooth = 		rawDataToBytes(fragmentRawDataASmooth);
		fragmentDataSmooth = 		rawDataToBytes(fragmentRawDataSmooth);
		fragmentDataRGBA = 			rawDataToBytes(fragmentRawDataRGBA);
		fragmentDataRGB = 			rawDataToBytes(fragmentRawDataRGB);
		fragmentDataA = 			rawDataToBytes(fragmentRawDataA);
		fragmentData = 				rawDataToBytes(fragmentRawData);
		
		currentRenderJobs = new Vector<RenderJob>();
		quadRenderJobs = new Vector<QuadRenderJob>();
		triangleRenderJobs = new Vector<TriangleRenderJob>();
	}
	
	public inline function setTexture(texture:Texture):Void
	{
		if (context3D != null)
		{
			if (texture != currentTexture)
			{
				context3D.setTextureAt(0, texture);
				currentTexture = texture;
			}
		}
	}
	
	public inline function init(stage:Stage, initCallback:Void->Void = null, renderMode:Dynamic):Void
	{
		if (context3D == null)
		{
			if (renderMode == null)
			{
				renderMode = Context3DRenderMode.AUTO;
			}
			
			this.stage = stage;
			this._initCallback = initCallback;
			stage.stage3Ds[depth].addEventListener(Event.CONTEXT3D_CREATE, initStage3D);
			stage.stage3Ds[depth].addEventListener(ErrorEvent.ERROR, initStage3DError);
			stage.stage3Ds[depth].requestContext3D(Std.string(renderMode));
			
			stage.addEventListener(Event.EXIT_FRAME, onRender, false, -0xFFFFFE);
		}
		else
		{
			if (initCallback != null)
			{
				initCallback();
			}
		}
	}
	
	private function onRender(e:Event):Void 
	{
		render();
		
		if (renderCallback != null)
		{
			renderCallback();
		}
		
		present();
	}
	
	public inline function render():Void
	{
		if (context3D != null && !presented)
		{
			setMatrix(baseTransformMatrix);
			setScissor(null);
			
			for (job in currentRenderJobs)
			{
				renderJob(job);
			}
		}
	}
	
	public inline function renderJob(job:RenderJob):Void
	{
		if (context3D != null && !presented)
		{
			job.render(this);
		}
	}
	
	public inline function present():Void
	{
		if (context3D != null && !presented)
		{
			presented = true;
			context3D.present();
		}
	}
	
	private function initStage3D(e:Event):Void 
	{
		if (context3D != null)
		{
			if (stage.stage3Ds[depth].context3D != context3D)
			{
				context3D = null; //this context has been lost, get new context
			}
		}
		
		if (context3D == null)
		{
			context3D = stage.stage3Ds[depth].context3D;			
			
			if (context3D != null)
			{
				context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
				
				baseTransformMatrix = new Matrix3D();
				
				stage.addEventListener(Event.RESIZE, onStageResize); //listen for future stage resize events
				
				//init programs
				programRGBASmooth = context3D.createProgram();
				programRGBASmooth.upload(vertexDataRGBA, fragmentDataRGBASmooth);
				
				programRGBSmooth = context3D.createProgram();
				programRGBSmooth.upload(vertexDataRGBA, fragmentDataRGBSmooth);
				
				programASmooth = context3D.createProgram();
				programASmooth.upload(vertexDataRGBA, fragmentDataASmooth);
				
				programSmooth = context3D.createProgram();
				programSmooth.upload(vertexData, fragmentDataSmooth);
				
				programRGBA = context3D.createProgram();
				programRGBA.upload(vertexDataRGBA, fragmentDataRGBA);
				
				programRGB = context3D.createProgram();
				programRGB.upload(vertexDataRGBA, fragmentDataRGB);
				
				programA = context3D.createProgram();
				programA.upload( vertexDataRGBA, fragmentDataA);
				
				program = context3D.createProgram();
				program.upload(vertexData, fragmentData);
				
				onStageResize(null); //init the base transform matrix
				
				clear();
				
				//upload textures
				dispatchEvent(new Event(RESET_TEXTURE));
			}
		}
		
		if (this._initCallback != null)
		{
			this._initCallback();
			this._initCallback = null; //only call once
		}
	}
	
	private function initStage3DError(e:Event):Void 
	{
		
	}
	
	public function onStageResize(e:Event):Void 
	{
		if (context3D != null)
		{
			context3D.configureBackBuffer(stage.stageWidth, stage.stageHeight, TilesheetStage3D.antiAliasing, false);
			
			baseTransformMatrix.identity();
			baseTransformMatrix.appendTranslation( -stage.stageWidth * 0.5, -stage.stageHeight * 0.5, 0);
			baseTransformMatrix.appendScale(2 / stage.stageWidth, -2 / stage.stageHeight, 1);
			setMatrix(baseTransformMatrix);
		}
	}
	
	public inline function clear():Void
	{
		clearJobs();
		
		if (context3D != null)
		{
			context3D.clear(0, 0, 0, 1);
		}
		
		presented = false;
	}
	
	private inline function clearJobs():Int
	{
		for (renderJob in quadRenderJobs)
		{
			renderJob.reset();
			QuadRenderJob.returnJob(renderJob);
		}
		
		for (renderJob in triangleRenderJobs)
		{
			renderJob.reset();
			TriangleRenderJob.returnJob(renderJob);
		}
		
		var numJobs:Int = currentRenderJobs.length;
		untyped currentRenderJobs.length = 0;
		untyped quadRenderJobs.length = 0;
		untyped triangleRenderJobs.length = 0;
		
		numCurrentRenderJobs = 0;
		
		return numJobs;
	}
	
	public function uploadTexture(image:BitmapData, mipmap:Bool = true):Texture
	{
		return TextureUtil.uploadTexture(image, context3D, mipmap);
	}
	
	private inline function doSetProgram(program:Program3D):Void
	{
		if (context3D != null && program != currentProgram)
		{
			context3D.setProgram(program);
			currentProgram = program;
		}
	}
	
	public function setProgramNoGlobalColor(isRGB:Bool, isAlpha:Bool, smooth:Bool, mipmap:Bool = true):Void
	{
		if (smooth)
		{
			if (isRGB && isAlpha)
			{
				doSetProgram(programRGBASmooth);
			}
			else if (isRGB)
			{
				doSetProgram(programRGBSmooth);
			}
			else if (isAlpha)
			{
				doSetProgram(programASmooth);
			}
			else
			{
				doSetProgram(programSmooth);
			}
		}
		else
		{
			if (isRGB && isAlpha)
			{
				doSetProgram(programRGBA);
			}
			else if (isRGB)
			{
				doSetProgram(programRGB);
			}
			else if (isAlpha)
			{
				doSetProgram(programA);
			}
			else
			{
				doSetProgram(program);
			}
		}
	}
	
	public function setProgramWithGlobalColor(isRGB:Bool, isAlpha:Bool, smooth:Bool, mipmap:Bool = true):Void
	{
		
	}
	
	/*
	private function getProgram(tinted:Bool):Program3D
	{
		var programName:String = QUAD_PROGRAM_NAME;
		
		if (mTexture != null) {
			programName = getImageProgramName(tinted, mTexture.mipMapping, mTexture.repeat, mTexture.format, mSmoothing);
		}
		
		var program:Program3D = target.getProgram(programName);
		
		if (program == null)
		{
			// this is the input data we'll pass to the shaders:
			// 
			// va0 -> position
			// va1 -> color
			// va2 -> texCoords
			// vc0 -> alpha
			// vc1 -> mvpMatrix
			// fs0 -> texture
			
			var vertexShader:String;
			var fragmentShader:String;

			if (mTexture == null) // Quad-Shaders
			{
				vertexShader =
					"m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace
					"mul v0, va1, vc0 \n";  // multiply alpha (vc0) with color (va1)
				
				fragmentShader =
					"mov oc, v0       \n";  // output color
			}
			else // Image-Shaders
			{
				vertexShader = tinted ?
					"m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace
					"mul v0, va1, vc0 \n" + // multiply alpha (vc0) with color (va1)
					"mov v1, va2      \n"   // pass texture coordinates to fragment program
					:
					"m44 op, va0, vc1 \n" + // 4x4 matrix transform to output clipspace
					"mov v1, va2      \n";  // pass texture coordinates to fragment program
				
				fragmentShader = tinted ?
					"tex ft1,  v1, fs0 <???> \n" + // sample texture 0
					"mul  oc, ft1,  v0       \n"   // multiply color with texel color
					:
					"tex  oc,  v1, fs0 <???> \n";  // sample texture 0
				
				fragmentShader = StringTools.replace(fragmentShader, "<???>",
					RenderSupport.getTextureLookupFlags(
						mTexture.format, mTexture.mipMapping, mTexture.repeat, smoothing));
			}
			
			program = target.registerProgramFromSource(programName,
				vertexShader, fragmentShader);
		}
		
		return program;
	}
	*/
	
	/*
	private static const VERTEX_SHADER:Array = [
			// va0 = [x, y, , ]
			// va1 = [u, v, , ]
			// va2 = [r, g, b, a]
			// vc0 = transform matrix
			"mov v1, va1",			// move uv to fragment shader
			"mov v2, va2",			// move color transform to fragment shader
			"m44 op, va0, vc0"		// multiply position by transform matrix 
		];
		
		private static const FRAGMENT_SHADER:Array = [
			// ft0 = tilemap texture
			// v1  = uv
			// v2  = rgba
			// fs0 = something
			// fc0 = color
			"tex ft0, v1, fs0 <2d,nearest,mipnone>",	// sample texture
			"mul ft1, v2, fc0",						// multiple sprite color by global color
			"mul oc, ft0, ft1",							// multiply texture by color
		];
		
		Ax.context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix, true);
		Ax.context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, colorTransform);
	*/
		
	/*
	private static function getImageProgramName(tinted:Bool, mipMap:Bool, 
												repeat:Bool, smoothing:TextureSmoothing):String
	{
		var format = Context3DTextureFormat.BGRA;
		var bitField:UInt = 0;
		
		if (tinted) bitField |= 1;
		if (mipMap) bitField |= 1 << 1;
		if (repeat) bitField |= 1 << 2;
		
		if (smoothing == TextureSmoothing.NONE)
			bitField |= 1 << 3;
		else if (smoothing == TextureSmoothing.TRILINEAR)
			bitField |= 1 << 4;
		
		var name:String = sProgramNameCache[bitField];
		
		if (name == null)
		{
			name = "QB_i." + StringTools.hex(bitField);
			sProgramNameCache[bitField] = name;
		}
		
		return name;
	}
	
	public function isStateChange(tinted:Bool, parentAlpha:Float, texture:Texture, smoothing:String, blendMode:String, numQuads:Int=1):Bool
	{
		if (mNumQuads == 0) return false;
		else if (mNumQuads + numQuads > MAX_NUM_QUADS) return true; // maximum buffer size
		else if (mTexture == null && texture == null) 
			return this.blendMode != blendMode;
		else if (mTexture != null && texture != null)
			return mTexture.base != texture.base ||
				   mTexture.repeat != texture.repeat ||
				   mSmoothing != smoothing ||
				   mTinted != (tinted || parentAlpha != 1.0) ||
				   this.blendMode != blendMode;
		else return true;
	}
	
	public static function assembleAgal(vertexShader:String, fragmentShader:String,
										resultProgram:Program3D = null):Program3D
	{
		if (resultProgram == null) 
		{
			var context:Context3D = Starling.Context;
			if (context == null) throw new MissingContextError();
			resultProgram = context.createProgram();
		}
		
		var vertexByteCode = AGLSLShaderUtils.createShader(Context3DProgramType.VERTEX, vertexShader);
		var fragmentByteCode = AGLSLShaderUtils.createShader(Context3DProgramType.FRAGMENT, fragmentShader);
		
		resultProgram.upload(vertexByteCode, fragmentByteCode);
		
		return resultProgram;
	}
	
	public static function getTextureLookupFlags(mipMapping:Bool,
												 repeat:Bool,
												 smoothing:TextureSmoothing):String
	{
		var options:Array<Dynamic> = ["2d", repeat ? "repeat" : "clamp"];
		
		if (smoothing == TextureSmoothing.NONE) {
			options.push("nearest");
			options.push(mipMapping ? "mipnearest" : "mipnone");
		}
		else {
			options.push("linear");
			options.push(mipMapping ? "miplinear" : "mipnone");
		}
		
		return "<" + options.join("") + ">";
	}
	*/
	
	public function setMatrix(matrix:Matrix3D):Void
	{
		if (context3D != null)
		{
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, matrix, true);
		}
	}
	
	public function setScissor(rect:Rectangle):Void
	{
		if (context3D != null)
		{
			context3D.setScissorRectangle(rect);
		}
	}
	
	public function addQuadJob(job:QuadRenderJob):Void
	{
		currentRenderJobs.push(job);
		quadRenderJobs.push(job);
		
		numCurrentRenderJobs++;
	}
	
	public function addTriangleJob(job:TriangleRenderJob):Void
	{
		currentRenderJobs.push(job);
		triangleRenderJobs.push(job);
		
		numCurrentRenderJobs++;
	}
	
	private static inline function rawDataToBytes(rawData:Array<Int>):ByteArray 
	{
		var bytes:ByteArray = new ByteArray();
		bytes.endian = Endian.LITTLE_ENDIAN;
		
		for (n in rawData)
		{
			bytes.writeByte(n);
		}
		
		return bytes;
	}
	
	//misc methods
	public static inline function clearArray<T>(array:Array<T>):Void
	{
		#if cpp
           array.splice(0, array.length);
        #else
           untyped array.length = 0;
        #end
	}
}
#end