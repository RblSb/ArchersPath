package editor;

import kha.Canvas;
import kha.graphics2.Graphics;
import kha.input.KeyCode;
import kha.Assets;
import kha.Image;
import editor.ui.Button;
import game.Game;
import editor.Interfaces.Tool;
import Screen.Pointer;
import Lvl.GameMap;
import Types.IPoint;
import Types.Point;
import Types.ISize;
import Types.Rect;
import haxe.Json;

class Editor extends Screen {
	
	var lvl:Lvl;
	var tsize(get, never):Int;
	function get_tsize() return lvl.tsize;
	static inline var BTN_SIZE = 48;
	var tilePanel:TilePanel;
	var buttons:Array<Button>;
	var arrow:Arrow;
	var brush:Brush;
	var fillRect:FillRect;
	var pipette:Pipette;
	var hand:Hand;
	var toolName:String;
	var tool(default, set):Tool;
	function set_tool(tool) {
		this.tool = tool;
		var arr = Type.getClassName(Type.getClass(tool)).split(".");
		toolName = arr[arr.length-1];
		return tool;
	}
	public var layer = 1;
	public var tile(get, set):Int;
	function get_tile() return tiles[layer];
	function set_tile(tile) return tiles[layer] = tile;
	var tiles:Array<Int> = [];
	var cursor:IPoint = {x: 0, y: 0};
	var layerOffsets:Array<Int>;
	var x = 0;
	var y = 0;
	var eraserMode = {tile: 0, layer: 0};
	
	public function new() {
		super();
	}
	
	public function init():Void {
		#if kha_html5
		var window = js.Browser.window;
		window.ondragenter = function(e) {
			e.preventDefault();
		};
		window.ondragover = function(e) {
			e.preventDefault();
		};
		window.ondrop = drop;
		#end
		
		lvl = new Lvl();
		lvl.init();
		//lvl.loadMap(0);
		var map = newMap({w: 10, h: 10});
		lvl.loadCustomMap(map);
		layerOffsets = lvl.getTilesOffset();
		
		tilePanel = new TilePanel(this, lvl);
		arrow = new Arrow(this, lvl);
		brush = new Brush(this, lvl);
		fillRect = new FillRect(this, lvl);
		pipette = new Pipette(this, lvl);
		hand = new Hand(this, lvl);
		tool = brush;
		
		for (i in layerOffsets) tiles.push(0);
		initButtons();
		onResize();
	}
	
	function initButtons():Void {
		var i = Assets.images;
		var h = BTN_SIZE;
		
		buttons = [
			new Button({x: 0, y: h, img: i.icons_arrow, keys: [KeyCode.M]}),
			new Button({x: 0, y: h * 2, img: i.icons_paint_brush, keys: [KeyCode.B]}),
			new Button({x: 0, y: h * 3, img: i.icons_assembly_area, keys: [KeyCode.R]}),
			new Button({x: 0, y: h * 4, img: i.icons_pipette, keys: [KeyCode.P]}),
			new Button({x: Screen.w - h - tilePanel.w * tsize, y: 0, img: i.icons_play, keys: [KeyCode.Zero]})
		];
		if (Screen.touch) buttons = buttons.concat([
			new Button({x: 0, y: h * 5, img: i.icons_hand, keys: [KeyCode.H]}),
			new Button({x: 0, y: Screen.h - h, img: i.icons_undo, keys: [KeyCode.Control, KeyCode.Z]}),
			new Button({x: h, y: Screen.h - h, img: i.icons_redo, keys: [KeyCode.Control, KeyCode.Y]})
		]);
		for (b in buttons) {
			b.rect.w *= lvl.scale;
			b.rect.h *= lvl.scale;
		}
	}
	
	//@:allow(Hand)
	public function moveCamera(speed:Point):Void {
		lvl.camera.x += speed.x;
		lvl.camera.y += speed.y;
		updateCamera();
	}
	
	override function onKeyDown(key:KeyCode):Void {
		//trace(Std.random(100));
		//trace(keys[KeyCode.Control], keys[KeyCode.S]);
		if (keys[KeyCode.Control] || keys[KeyCode.Meta]) {
			
			if (key == KeyCode.Z) {
				if (!keys[KeyCode.Shift]) tool.undo();
				else tool.redo();
			}
			if (key == KeyCode.Y) tool.redo();
			
			if (key == KeyCode.S) {
				keys[KeyCode.S] = false;
				keys[KeyCode.Control] = keys[KeyCode.Meta] = false;
				save(lvl.map);
			}
		}
		
		if (key == KeyCode.Space) {
			eraserMode.layer = layer;
			eraserMode.tile = tile;
			tile = 0;
			
		} else if (key == KeyCode.M) {
			tool = arrow;
			
		} else if (key == KeyCode.B) {
			tool = brush;
			
		} else if (key == KeyCode.R) {
			tool = fillRect;
			
		} else if (key == KeyCode.P) {
			tool = pipette;
			
		} else if (key == KeyCode.H) {
			tool = hand;
			
		} else if (key == KeyCode.O) {
			browse();
			
		} else if (key == KeyCode.N) {
			createMap();
			
		} else if (key == KeyCode.Nine) {
			resizeMap();
			
		} else if (key == KeyCode.Q) {
			prevTile();
			
		} else if (key == KeyCode.E) {
			nextTile();
			
		} else if (key == KeyCode.Zero) {
			hide();
			var game = new Game();
			game.show();
			game.init(this);
			game.playCustomLevel(lvl.map);
			
		} else if (key == KeyCode.One) {
			layer = 0;
		} else if (key == KeyCode.Two) {
			layer = 1;
		} else if (key == KeyCode.Three) {
			layer = 2;
			
		} else if (key == 189 || key == KeyCode.HyphenMinus) {
			if (scale > 1) setScale(scale - 1);
			
		} else if (key == 187 || key == KeyCode.Equals) {
			if (scale < 9) setScale(scale + 1);
			
		} else if (key == KeyCode.Escape) {
			#if kha_html5
			var confirm = js.Browser.window.confirm;
			if (!confirm(Lang.get("reset_warning")+" "+Lang.get("are_you_sure"))) return;
			#end
			//var menu = new Menu();
			//menu.show();
			//menu.init(); //2
		}
	}
	
	override function onKeyUp(key:KeyCode):Void {
		if (key == KeyCode.Space) {
			layer = eraserMode.layer;
			tile = eraserMode.tile;
		}
	}
	
	inline function prevTile():Void {
		tile--;
		if (tile < 0) tile = layerOffsets[layer];
		if (tile > layerOffsets[layer]) tile = 0;
	}
	
	inline function nextTile():Void {
		tile++;
		if (tile < 0) tile = layerOffsets[layer];
		if (tile > layerOffsets[layer]) tile = 0;
	}
	
	function createMap():Void {
		#if kha_html5
		var prompt = js.Browser.window.prompt;
		var newSize = Json.stringify({w: 20, h: 20});
		var size:ISize = Json.parse(prompt("Map Size:", newSize));
		if (size == null) return;
		var map = newMap(size);
		onMapLoad(map);
		#end
	}
	
	function newMap(size:ISize):GameMap {
		var map:GameMap = {
			w: size.w,
			h: size.h,
			layers: [
				for (l in 0...lvl.layersNum) [
					for (iy in 0...size.h) [
						for (ix in 0...size.w) 0
					]
				]
			],
			links: [
				for (iy in 0...size.h) [
					for (ix in 0...size.w) 0
				]
			],
			objects: [null], //zero id unused
			floatObjects: []
		}
		return map;
	}
	
	function resizeMap():Void {
		#if kha_html5
		var prompt = js.Browser.window.prompt;
		var addSize = Json.stringify([0, 1, 0, 1]);
		var size:Array<Int> = Json.parse(prompt("Add Size [SX, EX, SY, EY]:", addSize));
		if (size == null) return;
		var map = lvl.map;
		var sx = size[0];
		var ex = size[1];
		var sy = size[2];
		var ey = size[3];
		
		for (iy in 0...map.links.length) {
			for (ix in 0...map.links[iy].length) {
				if (iy < -sy) lvl.delObjects(ix, iy);
				if (ix < -sx) lvl.delObjects(ix, iy);
				if (iy > map.links.length-1 + ey) lvl.delObjects(ix, iy);
				if (ix > map.links[iy].length-1 + ex) lvl.delObjects(ix, iy);
			}
		}
		
		//TODO remove object layer, draw links layer
		//for (layer in map.layers) resizeLayer(layer, size, true);
		var len = map.layers.length - 1;
		for (i in 0...len) resizeLayer(map.layers[i], size, true);
		resizeLayer(map.layers[len], size, false);
		resizeLayer(map.links, size, false);
		
		map.h += sy + ey;
		map.w += sx + ex;
		
		onMapLoad(map);
		#end
	}
	
	function resizeLayer(layer:Array<Array<Int>>, size:Array<Int>, fill:Bool):Void {
		var sx = size[0];
		var ex = size[1];
		var sy = size[2];
		var ey = size[3];
		
		var len = Std.int(Math.abs(sy));
		for (i in 0...len) {
			if (sy < 0) layer.shift();
			else {
				var id = fill ? layer[0].copy() : [for (i in layer[0]) 0];
				layer.unshift(id);
			}
		}
		
		var len = Std.int(Math.abs(ey));
		for (i in 0...len) {
			if (ey < 0) layer.pop();
			else {
				var h = layer.length - 1;
				var id = fill ? layer[h].copy() : [for (i in layer[h]) 0];
				layer.push(id);
			}
		}
		
		var len = Std.int(Math.abs(sx));
		for (i in 0...len)
		for (iy in 0...layer.length) {
			if (sx < 0) layer[iy].shift();
			else {
				var id = fill ? layer[iy][0] : 0;
				layer[iy].unshift(id);
			}
		}
		
		var len = Std.int(Math.abs(ex));
		for (i in 0...len)
		for (iy in 0...layer.length) {
			if (ex < 0) layer[iy].pop();
			else {
				var w = layer[iy].length - 1;
				var id = fill ? layer[iy][w] : 0;
				layer[iy].push(id);
			}
		}
	}
	
	function save(map:GameMap, name="map"):Void {
		var json = haxe.Json.stringify(map);
		#if kha_html5
		var blob = new js.html.Blob([json], {
			type: "application/json"
		});
		var url = js.html.URL.createObjectURL(blob);
		var a = js.Browser.document.createElement("a");
		name = map.name == null ? name : map.name;
		untyped a.download = name+".json";
		untyped a.href = url;
		a.onclick = function(e) {
			e.cancelBubble = true;
			e.stopPropagation();
		}
		js.Browser.document.body.appendChild(a);
		a.click();
		js.Browser.document.body.removeChild(a);
		js.html.URL.revokeObjectURL(url);
		#else
		//TODO select path and write file
		#end
	}
	
	function browse():Void {
		#if kha_html5
		var input = js.Browser.document.createElement("input");
		input.style.visibility = "hidden";
		input.setAttribute("type", "file");
		input.id = "browse";
		input.onclick = function(e) {
			e.cancelBubble = true;
			e.stopPropagation();
		}
		input.onchange = function() {
			untyped var file:Dynamic = input.files[0];
			var name = file.name.split(".")[0];
			var ext = file.name.split(".").pop();
			var reader = new js.html.FileReader();
			reader.onload = function(e) {
				if (ext == "lvl") onFileLoad(e.target.result);
				else onMapLoad(haxe.Json.parse(e.target.result), name);
				js.Browser.document.body.removeChild(input);
			}
			if (ext == "lvl") reader.readAsArrayBuffer(file);
			else reader.readAsText(file);
		}
		js.Browser.document.body.appendChild(input);
		input.click();
		#else
		#end
	}
	
	#if kha_html5
	function drop(e:js.html.DragEvent):Void {
		var file = e.dataTransfer.files[0];
		var name = file.name.split(".")[0];
		var ext = file.name.split(".").pop();
		var reader = new js.html.FileReader();
		reader.onload = function(event) {
			if (ext == "lvl") onFileLoad(event.target.result);
			else onMapLoad(haxe.Json.parse(event.target.result), name);
		}
		e.preventDefault();
		if (ext == "lvl") reader.readAsArrayBuffer(file);
		else reader.readAsText(file);
	}
	
	inline function onFileLoad(file:Dynamic):Void {
		/*var bytes = haxe.io.Bytes.ofData(file);
		var blob = kha.Blob.fromBytes(bytes);
		var map = Old.loadMap(blob);
		onMapLoad(map);*/
	}
	#end
	
	inline function onMapLoad(map:GameMap, ?name:String):Void {
		if (name != null) map.name = name;
		lvl.loadCustomMap(map);
		clearHistory();
	}
	
	inline function clearHistory():Void {
		arrow.clearHistory();
		brush.clearHistory();
		fillRect.clearHistory();
		pipette.clearHistory();
		hand.clearHistory();
	}
	
	inline function updateCursor(pointer):Void {
		cursor.x = pointer.x;
		cursor.y = pointer.y;
		x = Std.int(cursor.x / tsize - lvl.camera.x / tsize);
		y = Std.int(cursor.y / tsize - lvl.camera.y / tsize);
		if (x < 0) x = 0;
		if (y < 0) y = 0;
		if (x > lvl.w - 1) x = lvl.w - 1;
		if (y > lvl.h - 1) y = lvl.h - 1;
	}
	
	override function onMouseDown(p:Pointer):Void {
		if (tilePanel.onDown(p)) return;
		if (Button.onDown(this, buttons, p)) return;
		updateCursor(p);
		tool.onMouseDown(p, layer, x, y, tile);
	}
	
	override function onMouseMove(p:Pointer):Void {
		if (tilePanel.onMove(p)) return;
		if (Button.onMove(this, buttons, p)) return;
		updateCursor(p);
		tool.onMouseMove(p, layer, x, y, tile);
	}
	
	override function onMouseUp(p:Pointer):Void {
		if (tilePanel.onUp(p)) return;
		if (Button.onUp(this, buttons, p)) return;
		tool.onMouseUp(p, layer, x, y, tile);
	}
	
	override function onMouseWheel(delta:Int):Void {
		if (delta == 1) prevTile();
		else if (delta == -1) nextTile();
	}
	
	override function onResize():Void {
		/*var newScale = Std.int(Utils.getScale());
		if (newScale < 1) newScale = 1;
		
		if (newScale != scale) setScale(newScale);
		else {
			lvl.resize();
		}*/
		tilePanel.resize();
		initButtons();
	}
	
	/*override function onRescale(scale:Float):Void {
		lvl.rescale(scale);
	}*/
	
	override function onUpdate():Void {
		tilePanel.update();
		tool.onUpdate();
		
		var sx = 0.0, sy = 0.0, s = tsize / 5;
		if (keys[KeyCode.Left] || keys[KeyCode.A]) sx += s;
		if (keys[KeyCode.Right] || keys[KeyCode.D]) sx -= s;
		if (keys[KeyCode.Up] || keys[KeyCode.W]) sy += s;
		if (keys[KeyCode.Down] || keys[KeyCode.S]) sy -= s;
		if (keys[KeyCode.Shift]) {
			sx *= 2; sy *= 2;
		}
		if (sx != 0) lvl.camera.x += sx;
		if (sy != 0) lvl.camera.y += sy;
		updateCamera();
	}
	
	inline function updateCamera():Void {
		var w = Screen.w;
		var h = Screen.h;
		var pw = lvl.map.w * tsize;
		var ph = lvl.map.h * tsize;
		var camera = lvl.camera;
		var offset = BTN_SIZE;
		var maxW = w - pw - offset - tilePanel.w * tsize;
		var maxH = h - ph - offset;
		
		if (camera.x > offset) camera.x = offset;
		if (camera.x < maxW) camera.x = maxW;
		if (camera.y > offset) camera.y = offset;
		if (camera.y < maxH) camera.y = maxH;
		if (pw < w - offset * 2 - tilePanel.w * tsize) camera.x = w/2 - pw/2;
		if (ph < h - offset * 2) camera.y = h/2 - ph/2;
		camera.x = Std.int(camera.x);
		camera.y = Std.int(camera.y);
	}
	
	override function onRender(frame:Canvas):Void {
		var g = frame.g2;
		g.begin(true, 0xFFBDC3CD);
		g.color = 0x50000000;
		g.drawRect(lvl.camera.x, lvl.camera.y - 1,
			lvl.map.w * tsize + 1,
			lvl.map.h * tsize + 1
		);
		lvl.drawLayers(g);
		lvl.drawLinks(g);
		
		tool.onRender(g);
		drawCursor(g);
		for (b in buttons) b.draw(g);
		tilePanel.render(g);
		
		g.color = 0xFF000000;
		g.font = Assets.fonts.OpenSans_Regular;
		g.fontSize = 24;
		var s = "Layer: " + (layer+1) + " | Tile: " + tile + " | Objects: " + (lvl.map.objects.length-1);
		g.drawString(s, 0, 0);
		var fh = g.font.height(g.fontSize);
		g.drawString(toolName + " | " + x + ", " + y, 0, fh);
		
		g.end();
	}
	
	inline function drawCursor(g:Graphics):Void {
		if (tool == hand) return;
		g.color = 0x88000000;
		var px = x * tsize + lvl.camera.x;
		var py = y * tsize + lvl.camera.y - 1;
		g.drawRect(px, py, tsize + 1, tsize + 1);
		if (tool == arrow) return;
		
		if (tile == 0) {
			g.color = 0x88FF0000;
			g.drawLine(px, py + 1, px + tsize, py + tsize + 1);
			g.drawLine(px + tsize, py + 1, px, py + tsize + 1);
		}
		if (tile < 1) return;
		g.color = 0xFFFFFFFF;
		lvl.drawTile(g, layer, x, y, tile);
	}
	
}
