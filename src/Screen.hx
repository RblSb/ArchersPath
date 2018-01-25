package;

import kha.Framebuffer;
import kha.graphics2.Graphics;
import kha.Image;
import kha.Scaler;
import kha.input.Keyboard;
import kha.input.KeyCode;
import kha.input.Surface;
import kha.input.Mouse;
import kha.Scheduler;
import kha.System;
import kha.Assets;
import edge.Engine;
import edge.Phase;
#if kha_g4
import kha.Shaders;
import kha.graphics4.BlendingFactor;
import kha.graphics4.PipelineState;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;
#end

//Сlass to unify mouse/touch events and setup game screens

typedef Pointer = {
	id:Int,
	startX:Int,
	startY:Int,
	x:Int,
	y:Int,
	moveX:Int,
	moveY:Int,
	type:Int,
	isDown:Bool,
	used:Bool
}

class Screen {
	
	public static var screen:Screen; //current screen
	public static var w(default, null):Int; //for resize event
	public static var h(default, null):Int;
	public static var touch(default, null) = false;
	public static var frame:Image;
	static var fps = new FPS();
	static var taskId:Int;
	
	public var engine:Engine; //ECS
	public var updatePhase:Phase;
	public var renderPhase:Phase;
	
	public var scale(default, null) = 1.0;
	var backbuffer = Image.createRenderTarget(1, 1);
	public var keys:Map<Int, Bool> = new Map();
	public var pointers:Map<Int, Pointer> = [
		for (i in 0...10) i => {id: i, startX: 0, startY: 0, x: 0, y: 0, moveX: 0, moveY: 0, type: 0, isDown: false, used: false}
	];
	#if kha_g4
	static var _pipeline:PipelineState;
	static var _struct:VertexStructure;
	#end
	
	public function new() {}
	
	public static function _init(?touchMode:Bool):Void {
		w = System.windowWidth();
		h = System.windowHeight();
		#if kha_html5
		touch = untyped __js__('"ontouchstart" in window');
		#elseif (kha_android || kha_ios)
		touch = true;
		#end
		if (touchMode != null) touch = touchMode;
		
		setupPipeline();
	}
	
	static inline function setupPipeline():Void {
		#if kha_g4
		_struct = new VertexStructure();
		_struct.add("vertexPosition", VertexData.Float3);
		_struct.add("texPosition", VertexData.Float2);
		_struct.add("vertexColor", VertexData.Float4);
		
		_pipeline = new PipelineState();
		_pipeline.inputLayout = [_struct];
		_pipeline.vertexShader = Shaders.painter_image_vert;
		_pipeline.fragmentShader = Shaders.painter_image_frag;
		_pipeline.blendSource = BlendingFactor.BlendOne;
		_pipeline.blendDestination = BlendingFactor.BlendZero;
		_pipeline.alphaBlendSource = BlendingFactor.BlendOne;
		_pipeline.alphaBlendDestination = BlendingFactor.BlendZero;
		_pipeline.compile();
		#end
	}
	
	public static inline function pipeline(g:Graphics):Void {
		#if kha_g4
		g.pipeline = _pipeline;
		#end
	}
	
	public function show():Void {
		if (screen != null) screen.hide();
		screen = this;
		
		engine = new Engine();
		updatePhase = engine.createPhase();
		renderPhase = engine.createPhase();
		
		taskId = Scheduler.addTimeTask(_onUpdate, 0, 1/60);
		System.notifyOnRender(_onRender);
		backbuffer = Image.createRenderTarget(Std.int(w/scale), Std.int(h/scale));
		
		if (Keyboard.get() != null) Keyboard.get().notify(_onKeyDown, _onKeyUp);
		
		if (touch && Surface.get() != null) {
			Surface.get().notify(_onTouchDown, _onTouchUp, _onTouchMove);
		} else if (Mouse.get() != null) {
			Mouse.get().notify(_onMouseDown, _onMouseUp, _onMouseMove, null);
		}
		for (k in keys) k = false;
		for (p in pointers) p.isDown = false;
	}
	
	public function hide():Void {
		Scheduler.removeTimeTask(taskId);
		System.removeRenderListener(_onRender);
		
		if (Keyboard.get() != null) Keyboard.get().remove(_onKeyDown, _onKeyUp, null);
		
		if (touch && Surface.get() != null) {
			Surface.get().remove(_onTouchDown, _onTouchUp, _onTouchMove);
		} else if (Mouse.get() != null) {
			Mouse.get().remove(_onMouseDown, _onMouseUp, _onMouseMove, null);
		}
	}
	
	inline function _onUpdate():Void {
		updatePhase.update(1/60);
		fps.update();
	}
	
	inline function _onRender(framebuffer:Framebuffer):Void {
		frame = backbuffer;
		var g = frame.g2;
		g.begin(false);
		if (Std.int(System.windowWidth() / scale) != w ||
			Std.int(System.windowHeight() / scale) != h) _onResize();
		//onRender(frame);
		renderPhase.update(1/60);
		g.end();
		
		var g = framebuffer.g2;
		g.begin();
		Scaler.scale(backbuffer, framebuffer, System.screenRotation);
		debugScreen(g);
		g.end();
		fps.addFrame();
	}
	
	inline function _onResize():Void {
		w = Std.int(System.windowWidth() / scale);
		h = Std.int(System.windowHeight() / scale);
		onResize();
		if (w != backbuffer.width || h != backbuffer.height)
			backbuffer = Image.createRenderTarget(w, h);
	}
	
	inline function _onKeyDown(key:KeyCode):Void {
		keys[key] = true;
		onKeyDown(key);
	}
	
	inline function _onKeyUp(key:KeyCode):Void {
		keys[key] = false;
		onKeyUp(key);
	}
	
	inline function _onMouseDown(button:Int, x:Int, y:Int):Void {
		x = Std.int(x / scale);
		y = Std.int(y / scale);
		pointers[0].startX = x;
		pointers[0].startY = y;
		pointers[0].x = x;
		pointers[0].y = y;
		pointers[0].type = button;
		pointers[0].isDown = true;
		pointers[0].used = true;
		onMouseDown(pointers[0]);
	}
	
	inline function _onMouseMove(x:Int, y:Int, mx:Int, my:Int):Void {
		x = Std.int(x / scale);
		y = Std.int(y / scale);
		pointers[0].x = x;
		pointers[0].y = y;
		pointers[0].moveX = mx;
		pointers[0].moveY = my;
		pointers[0].used = true;
		onMouseMove(pointers[0]);
	}
	
	inline function _onMouseUp(button:Int, x:Int, y:Int):Void {
		if (!pointers[0].used) return;
		x = Std.int(x / scale);
		y = Std.int(y / scale);
		pointers[0].x = x;
		pointers[0].y = y;
		pointers[0].type = button;
		pointers[0].isDown = false;
		onMouseUp(pointers[0]);
	}
	
	inline function _onTouchDown(id:Int, x:Int, y:Int):Void {
		if (id > 9) return;
		x = Std.int(x / scale);
		y = Std.int(y / scale);
		pointers[id].startX = x;
		pointers[id].startY = y;
		pointers[id].x = x;
		pointers[id].y = y;
		pointers[id].isDown = true;
		pointers[id].used = true;
		onMouseDown(pointers[id]);
	}
	
	inline function _onTouchMove(id:Int, x:Int, y:Int):Void {
		if (id > 9) return;
		x = Std.int(x / scale);
		y = Std.int(y / scale);
		pointers[id].moveX = x - pointers[id].x;
		pointers[id].moveY = y - pointers[id].y;
		pointers[id].x = x;
		pointers[id].y = y;
		onMouseMove(pointers[id]);
	}
	
	inline function _onTouchUp(id:Int, x:Int, y:Int):Void {
		if (id > 9) return;
		x = Std.int(x / scale);
		y = Std.int(y / scale);
		if (!pointers[id].used) return;
		pointers[id].x = x;
		pointers[id].y = y;
		pointers[id].isDown = false;
		onMouseUp(pointers[id]);
	}
	
	function debugScreen(g:Graphics):Void {
		g.color = 0xFFFFFFFF;
		g.font = Assets.fonts.OpenSans_Regular;
		g.fontSize = 24;
		var txt = fps.fps + " | " + System.windowWidth() + "x" + System.windowHeight() + " " + scale;
		var x = System.windowWidth() - g.font.width(g.fontSize, txt);
		var y = System.windowHeight() - g.font.height(g.fontSize);
		g.drawString(txt, x, y);
	}
	
	function setScale(scale:Float):Void {
		//onRescale(scale);
		this.scale = scale;
	}
	
	//functions to override
	
	//function onRescale(scale:Float):Void {}
	function onResize():Void {}
	function onUpdate():Void {}
	function onRender(framebuffer:Framebuffer):Void {}
	
	public function onKeyDown(key:KeyCode):Void {}
	public function onKeyUp(key:KeyCode):Void {}
	
	public function onMouseDown(p:Pointer):Void {}
	public function onMouseMove(p:Pointer):Void {}
	public function onMouseUp(p:Pointer):Void {}
	
}

private class FPS {
	
	public var fps = 0;
	public var _frames = 0;
	var time = 0.0;
	var lastTime = 0.0;
	
	public function new() {}
	
	public function update():Int {
		var deltaTime = (Scheduler.realTime() - lastTime);
		lastTime = Scheduler.realTime();
		time += deltaTime;
		
		if (time >= 1) {
			fps = _frames;
			_frames = 0;
			time = 0;
		}
		return fps;
	}
	
	public inline function addFrame() _frames++;
	
}