package com.asliceofcrazypie.flash;
import haxe.ds.IntMap;

#if flash11
import com.asliceofcrazypie.flash.jobs.RenderJob;
import com.asliceofcrazypie.flash.jobs.QuadRenderJob;
import com.asliceofcrazypie.flash.jobs.TriangleRenderJob;

import openfl.display3D._shaders.AGLSLShaderUtils;

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
	
	private var imagePrograms:IntMap<Program3D>;
	
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
		
		initPrograms();
		
		currentRenderJobs = new Vector<RenderJob>();
		quadRenderJobs = new Vector<QuadRenderJob>();
		triangleRenderJobs = new Vector<TriangleRenderJob>();
	}
	
	private function initPrograms():Void
	{
		imagePrograms = new IntMap<Program3D>();
		
		//rgb:Bool, alpha:Bool, mipMap:Bool, smoothing:Bool, repeat:Bool = true, globalColor:Bool = false
		
		//vertex shader data
		var vertexStringRGBA:String =	"mov v0, va1      \n" +		// move uv to fragment shader
										"mov v1, va2      \n" +		// move color transform to fragment shader
										"m44 op, va0, vc0 \n";		// multiply position by transform matrix 
		
		var vertexString:String =		"m44 op, va0, vc0 \n" + 	// 4x4 matrix transform to output clipspace
										"mov v0, va1      \n";  	// pass texture coordinates to fragment program
		
		vertexData = AGLSLShaderUtils.createShader(Context3DProgramType.VERTEX, vertexString);
		vertexDataRGBA = AGLSLShaderUtils.createShader(Context3DProgramType.VERTEX, vertexStringRGBA);
		
		//fragment shaders data
		
		// programs without global color multiplier
		var mipmap:Bool = true;
		var smoothing:Bool = false;
		var fragmentStringA:String = 	"tex ft0, v0, fs0 <???>	\n"+
										"mul oc, ft0, v1.zzzz	\n";
		fragmentStringA = StringTools.replace(fragmentStringA, "<???>", getTextureLookupFlags(mipmap, smoothing));
		
		fragmentDataA = AGLSLShaderUtils.createShader(Context3DProgramType.FRAGMENT, fragmentStringA);				
		
		smoothing = true;
		var fragmentStringASmooth:String = 	"tex ft0, v0, fs0 <???> \n"+
											"mul oc, ft0, v1.zzzz	\n";
		fragmentStringASmooth = StringTools.replace(fragmentStringASmooth, "<???>", getTextureLookupFlags(mipmap, smoothing));
		
		fragmentDataASmooth = AGLSLShaderUtils.createShader(Context3DProgramType.FRAGMENT, fragmentStringASmooth);
		
		smoothing = false;
		var fragmentString:String = "tex oc, v0, fs0 <???> \n"; // sample texture 0
		fragmentString = StringTools.replace(fragmentString, "<???>", getTextureLookupFlags(mipmap, smoothing));
		
		fragmentData = AGLSLShaderUtils.createShader(Context3DProgramType.FRAGMENT, fragmentString);
		
		smoothing = true;
		var fragmentStringSmooth:String = "tex oc, v0, fs0 <???> \n"; // sample texture 0
		fragmentStringSmooth = StringTools.replace(fragmentStringSmooth, "<???>", getTextureLookupFlags(mipmap, smoothing));
		
		fragmentDataSmooth = AGLSLShaderUtils.createShader(Context3DProgramType.FRAGMENT, fragmentStringSmooth);
		
		smoothing = false;
		var fragmentStringRGBA:String = "tex ft0, v0, fs0 <???> \n"+
										"mul oc, ft0, v1		\n";
		fragmentStringRGBA = StringTools.replace(fragmentStringRGBA, "<???>", getTextureLookupFlags(mipmap, smoothing));
		
		fragmentDataRGBA = AGLSLShaderUtils.createShader(Context3DProgramType.FRAGMENT, fragmentStringRGBA);
		fragmentDataRGB = fragmentDataRGBA;
		
		smoothing = true;
		var fragmentStringRGBASmooth:String = 	"tex ft0, v0, fs0 <???> \n"+
												"mul oc, ft0, v1		\n";
		fragmentStringRGBASmooth = StringTools.replace(fragmentStringRGBASmooth, "<???>", getTextureLookupFlags(mipmap, smoothing));
		
		fragmentDataRGBASmooth = AGLSLShaderUtils.createShader(Context3DProgramType.FRAGMENT, fragmentStringRGBASmooth);
		fragmentDataRGBSmooth = fragmentDataRGBASmooth;
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
			stage.stage3Ds[depth].requestContext3D(renderMode);
			
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
	*/
	
	// TODO: add globalColor argument
	private function getImageProgramName(rgb:Bool, alpha:Bool, mipMap:Bool, 
												smoothing:Bool, globalColor:Bool = false):UInt
	{
		var repeat:Bool = true;
		var bitField:UInt = 0;
		
		if (rgb) bitField |= 1;
		if (alpha) bitField |= 1 << 1;
		if (mipMap) bitField |= 1 << 2;
		if (repeat) bitField |= 1 << 3;
		if (smoothing) bitField |= 1 << 4;
		if (globalColor) bitField |= 1 << 5;
		
		return bitField;
	}
	
	private function getTextureLookupFlags(mipMapping:Bool, smoothing:Bool):String
	{
		var repeat:Bool = true; // making it default for now (to make things simpler)
		
		var options:Array<String> = ["2d", repeat ? "repeat" : "clamp"];
		
		if (smoothing == false) {
			options.push("nearest");
			options.push(mipMapping ? "mipnearest" : "mipnone");
		}
		else {
			options.push("linear");
			options.push(mipMapping ? "miplinear" : "mipnone");
		}
		
		return "<" + options.join("") + ">";
	}
	
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