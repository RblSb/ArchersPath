package;

import kha.graphics2.Graphics;
import kha.Image;
import kha.Assets;
import kha.Blob;
import kha.System;
import Types.IPoint;
import Types.Point;
import Types.Rect;

private typedef Tiles = { //tiles.json
	tsize:Int,
	scale:Float,
	layers:Array<Array<Props>>
}

private typedef Props = {
	id:Int,
	collide:Bool,
	type:Slope,
	permeable:Bool,
	?file:String,
	?add:Array<String>,
	?frames:Array<Props>
}

@:enum
abstract Slope(Int) from Int to Int {
	
	public static inline var NONE = -1;
	public static inline var FULL = 0;
	public static inline var HALF_B = 1;
	public static inline var HALF_T = 2;
	public static inline var HALF_L = 3;
	public static inline var HALF_R = 4;
	public static inline var HALF_BL = 5;
	public static inline var HALF_BR = 6;
	public static inline var HALF_TL = 7;
	public static inline var HALF_TR = 8;
	public static inline var QUARTER_BL = 9;
	public static inline var QUARTER_BR = 10;
	public static inline var QUARTER_TL = 11;
	public static inline var QUARTER_TR = 12;
	
	@:from public static function fromString(type:String):Slope {
		return new Slope(switch(type) {
		case "NONE": NONE;
		case "FULL": FULL;
		case "HALF_B": HALF_B;
		case "HALF_T": HALF_T;
		case "HALF_L": HALF_L;
		case "HALF_R": HALF_R;
		case "HALF_BL": HALF_BL;
		case "HALF_BR": HALF_BR;
		case "HALF_TL": HALF_TL;
		case "HALF_TR": HALF_TR;
		case "QUARTER_BL": QUARTER_BL;
		case "QUARTER_BR": QUARTER_BR;
		case "QUARTER_TL": QUARTER_TL;
		case "QUARTER_TR": QUARTER_TR;
		default: NONE;
		});
	}
	
	public inline function new(type:Slope) {
		this = type;
	}
	
	public static function rotate(type:Slope):Slope {
		return new Slope(switch(type) {
			case HALF_B: HALF_L;
			case HALF_T: HALF_R;
			case HALF_L: HALF_T;
			case HALF_R: HALF_B;
			case HALF_BL: HALF_TL;
			case HALF_BR: HALF_BL;
			case HALF_TL: HALF_TR;
			case HALF_TR: HALF_BR;
			case QUARTER_BL: QUARTER_TL;
			case QUARTER_BR: QUARTER_BL;
			case QUARTER_TL: QUARTER_TR;
			case QUARTER_TR: QUARTER_BR;
			default: type;
		});
	}
	
	public static function flipX(type:Slope):Slope {
		return new Slope(switch(type) {
			case HALF_L: HALF_R;
			case HALF_R: HALF_L;
			case HALF_BL: HALF_BR;
			case HALF_BR: HALF_BL;
			case HALF_TL: HALF_TR;
			case HALF_TR: HALF_TL;
			case QUARTER_BL: QUARTER_BR;
			case QUARTER_BR: QUARTER_BL;
			case QUARTER_TL: QUARTER_TR;
			case QUARTER_TR: QUARTER_TL;
			default: type;
		});
	}
	
	public static function flipY(type:Slope):Slope {
		return new Slope(switch(type) {
			case HALF_B: HALF_T;
			case HALF_T: HALF_B;
			case HALF_BL: HALF_TL;
			case HALF_BR: HALF_TR;
			case HALF_TL: HALF_BL;
			case HALF_TR: HALF_BR;
			case QUARTER_BL: QUARTER_TL;
			case QUARTER_BR: QUARTER_TR;
			case QUARTER_TL: QUARTER_BL;
			case QUARTER_TR: QUARTER_BR;
			default: type;
		});
	}
	
}

typedef GameMap = { //map format
	?name:String,
	w:Int,
	h:Int,
	layers:Array<Array<Array<Int>>>,
	?objects:Objects
}

typedef Objects = {
	?buttons:Array<Object>,
	?panels:Array<Object>,
	?texts:Array<Object>,
}

typedef Object = {
	>IPoint,
	?speed:Point,
	?doors:Array<IPoint>,
	?text:{
		?en:TField,
		?ru:TField
	}
}

typedef TField = {
	text:String,
	author:String
}

class Lvl {
	
	var origTileset:Image;
	var origTsize:Int; //for rescaling
	
	var tilesOffset:Array<Int>;
	var spritesLink:Array<Array<Int>>;
	var spritesOffset:Array<Array<Int>>;
	var layersOffset:Array<Int>;
	var layersNum:Int;
	var tilesNum:Int;
	var props:Array<Array<Props>>;
	
	public var map(default, null):GameMap;
	public var w(get, never):Int;
	public var h(get, never):Int;
	function get_w():Int return map.w;
	function get_h():Int return map.h;
	
	var screenW = 0; //size of screen in tiles
	var screenH = 0;
	var tileset:Image;
	var tilesetW:Int;
	var tilesetH:Int;
	public var tsize(default, null) = 0; //tile size
	public var scale(default, null) = 1.0; //tile scale
	public var camera = {x: 0.0, y: 0.0};
	
	public function new() {}
	
	public function init():Void {
		initTiles();
		resize();
	}
	
	function initTiles():Void {
		var text = Assets.blobs.tiles_json.toString();
		var json:Tiles = haxe.Json.parse(text);
		
		var ts = new TilesetGenerator(json);
		origTsize = tsize = ts.tsize;
		layersNum = ts.layersNum;
		tilesNum = ts.tilesNum;
		tilesOffset = ts.tilesOffset;
		spritesLink = ts.spritesLink;
		spritesOffset = ts.spritesOffset;
		layersOffset = ts.layersOffset;
		props = ts.props;
		
		origTileset = ts.tileset;
		tilesetW = ts.tilesetW;
		tilesetH = ts.tilesetH;
		
		_rescale(json.scale);
	}
	
	public static function exists(id:Int):Bool {
		var data = Reflect.field(Assets.blobs, "maps_"+id+"_json");
		//var data = Reflect.field(Assets.blobs, "maps_"+id+"_lvl");
		if (data == null) return false;
		return true;
	}
	
	public function loadMap(id:Int):Void {
		var data = Reflect.field(Assets.blobs, "maps_"+id+"_json");
		map = haxe.Json.parse(data.toString());
	}
	
	public function loadCustomMap(map:GameMap):Void {
		this.map = copyMap(map);
	}
	
	public function copyMap(map:GameMap):GameMap {
		var layers:Array<Array<Array<Int>>> = [
			for (l in map.layers) [
				for (iy in 0...l.length) l[iy].copy()
			]
		];
		var copy:GameMap = {
			name: map.name,
			w: map.w,
			h: map.h,
			layers: layers,
			objects: map.objects
		}
		return copy;
	}
	
	public function getTile(layer:Int, x:Int, y:Int):Int {
		if (x > -1 && y > -1 && x < map.w && y < map.h) {
			return map.layers[layer][y][x];
			var id = map.layers[layer][y][x];
			return id == 0 ? 0 : id - layersOffset[layer];
		}
		return 0;
	}
	
	public function setTile(layer:Int, x:Int, y:Int, id:Int):Void {
		if (x > -1 && y > -1 && x < map.w && y < map.h) {
			map.layers[layer][y][x] = id;
		}
	}
	
	public function setTileAnim(layer:Int, x:Int, y:Int, type:Int, id:Int):Void {
		if (x > -1 && y > -1 && x < map.w && y < map.h) {
			if (id == 0) map.layers[layer][y][x] = type;
			else {
				var type = spritesLink[layer][type];
				map.layers[layer][y][x] = tilesOffset[layer] + spritesOffset[layer][type] + id;
			}
		}
	}
	
	public function getSpriteEnd(layer:Int, type:Int):Int {
		var type = spritesLink[layer][type] + 1;
		return tilesOffset[layer] + spritesOffset[layer][type];
	}
	
	public function getSpriteLength(layer:Int, type:Int):Int {
		var type = spritesLink[layer][type] + 1;
		return spritesOffset[layer][type] - spritesOffset[layer][type-1];
	}
	
	public function getProps(layer:Int, x:Int, y:Int):Props {
		if (x > -1 && y > -1 && x < map.w && y < map.h) {
			var id = map.layers[layer][y][x];
			return props[layer][id];
		}
		return props[layer][0];
	}
	
	public function drawTile(g:Graphics, layer:Int, x:Int, y:Int, id:Int):Void {
		if (id != 0) id += layersOffset[layer];
		if (id > 0) {
			var tx = (id % tilesetW) * tsize;
			var ty = Std.int(id / tilesetW) * tsize;
			
			g.drawSubImage(
				tileset,
				x * tsize + camera.x,
				y * tsize + camera.y,
				tx, ty, tsize, tsize
			);
		}
	}
	
	public function drawLayer(g:Graphics, layer:Int):Void {
		//camera in tiles
		var ctx = -Std.int(camera.x / tsize);
		var cty = -Std.int(camera.y / tsize);
		var ctw = ctx + screenW;
		var cth = cty + screenH;
		var camX = Std.int(camera.x);
		var camY = Std.int(camera.y);
		
		//tiles offset
		var sx = ctx < 0 ? 0 : ctx;
		var sy = cty < 0 ? 0 : cty;
		var ex = ctw > map.w ? map.w : ctw;
		var ey = cth > map.h ? map.h : cth;
		g.color = 0xFFFFFFFF;
		
		for (iy in sy...ey)
			for (ix in sx...ex) {
				var id = map.layers[layer][iy][ix];
				if (id != 0) id += layersOffset[layer];
				//var id = getTile(layer, ix, iy);
						
				if (id > 0) {
					
					var x = (id % tilesetW) * tsize;
					var y = Std.int(id / tilesetW) * tsize;
					
					g.drawSubImage(
						tileset,
						ix * tsize + camX,
						iy * tsize + camY,
						x, y, tsize, tsize
					);
				}
			}
		
		
		#if debug
		/*if (layer != 0) return;
		var s = 1; //0.5;
		var x = System.windowWidth() - origTileset.width*s;
		g.drawScaledImage(origTileset, x, 0,
			origTileset.width*s, origTileset.height*s
		);*/
		#end
	}
	
	public function drawLayers(g:Graphics):Void {
		for (l in 0...layersNum) drawLayer(g, l);
	}
	
	public function resize():Void {
		screenW = Math.ceil(Screen.w / tsize) + 1;
		screenH = Math.ceil(Screen.h / tsize) + 1;
	}
	
	function _rescale(scale:Float):Void {
		tsize = Std.int(origTsize * scale);
		this.scale = scale;
		var w = Std.int(origTileset.width * scale);
		var h = Std.int(origTileset.height * scale);
		
		tileset = Image.createRenderTarget(w, h);
		var g = tileset.g2;
		g.begin(true, 0x0);
		Screen.pipeline(g);
		g.drawScaledImage(origTileset, 0, 0, w, h);
		g.end();
		
		var fix = Image.createRenderTarget(1, 1); //fix
	}
	
	public function rescale(scale:Float):Void {
		_rescale(scale);
		resize();
	}
	
	public function getObject(layer:Int, x:Int, y:Int):Object {
		var id = getTile(layer, x, y);
		switch(layer) {
		case 1:
			if (id == 6 || id == getSpriteEnd(layer, 6)) {
				return _getObject(map.objects.buttons, x, y);
			} else if (id == 8 || id == 9 || id == 10 || id == 11) {
				return _getObject(map.objects.panels, x, y);
			}
		case 2:
			if (id == 5) return _getObject(map.objects.texts, x, y);
		}
		
		return null;
	}
	
	inline function _getObject(arr:Array<Object>, x:Int, y:Int):Object {
		var obj:Object = null;
		if (arr != null) for (o in arr)
			if (o.x == x && o.y == y) {
				obj = o;
				break;
			}
		return obj;
	}
	
	public function setObject(layer:Int, x:Int, y:Int, id:Int, obj:Object):Void {
		switch(layer) {
		case 1:
			switch(id) {
			case 6: _setObject(map.objects.buttons, x, y, obj);
			case 8, 9, 10, 11: _setObject(map.objects.panels, x, y, obj);
			}
		case 2:
			switch(id) {
			case 5: _setObject(map.objects.texts, x, y, obj);
			}
		}
	}
	
	inline function _setObject(arr:Array<Object>, x:Int, y:Int, obj:Object) {
		var isNew = true;
		if (arr != null) for (o in arr)
			if (o.x == x && o.y == y) {
				if (obj == null) arr.remove(o);
				else o = obj;
				isNew = false;
			}
		if (isNew) arr.push(obj);
	}
	
	/*public function isObject(layer:Int, tile:Int):Bool {
		switch(layer) {
		case 1:
			switch(tile) {
				case 6: return true;
				case 8, 9, 10, 11: return true;
			}
		case 2:
			switch(tile) {
				case 5: return true;
			}
		}
		return false;
	}*/
	
	public function emptyObject(layer:Int, tile:Int, x:Int, y:Int):Object {
		switch(layer) {
		case 1:
			switch(tile) {
				case 6: return {x: x, y: y, doors:[]};
				case 8, 9, 10, 11: return {x: x, y: y, speed:{x:0, y:0}};
			}
		case 2:
			switch(tile) {
				case 5: return {x: x, y: y, text:{}};
			}
		}
		return null;
	}
	
	public function countObjects(layer:Int):Int {
		switch(layer) {
		case 1:
			return map.objects.buttons.length + map.objects.panels.length;
		case 2:
			return map.objects.texts.length;
		}
		return 0;
	}
	
	public function getPlayer():IPoint {
		for (iy in 0...map.h)
		for (ix in 0...map.w) {
			if (getTile(2, ix, iy) == 1) return {x: ix, y: iy};
		}
		return {x: 0, y: 0};
	}
	
	public function updateCamera():Void {
		var w = Screen.w;
		var h = Screen.h;
		var pw = map.w * tsize;
		var ph = map.h * tsize;
		
		if (camera.x > 0) camera.x = 0;
		if (camera.x < w - pw) camera.x = w - pw;
		if (camera.y > 0) camera.y = 0;
		if (camera.y < h - ph) camera.y = h - ph;
		if (pw < w) camera.x = w/2 - pw/2;
		if (ph < h) camera.y = h/2 - ph/2;
	}
	
	public function setCamera(rect:Rect):Void {
		var w = Screen.w;
		var h = Screen.h;
		var centerX = rect.x - w/2 + rect.w/2;
		var centerY = rect.y - h/2 + rect.h/2;
		var centerX = w/2 - rect.x - rect.w/2;
		var centerY = h/2 - rect.y - rect.h/2;
		var pw = map.w * tsize;
		var ph = map.h * tsize;
		
		if (pw < w) camera.x = w/2 - pw/2;
		else if (camera.x != centerX) {
			camera.x = centerX;
			if (camera.x > 0) camera.x = 0;
			if (camera.x < w - pw) camera.x = w - pw;
		}
		if (ph < h) camera.y = h/2 - ph/2;
		else if (camera.y != centerY) {
			camera.y = centerY;
			if (camera.y > 0) camera.y = 0;
			if (camera.y < h - ph) camera.y = h - ph;
		}
	}
	
	public function getTilesOffset():Array<Int> {
		return tilesOffset;
	}
	
}

private class TilesetGenerator {
	
	public var tilesOffset:Array<Int>;
	public var spritesLink:Array<Array<Int>>;
	public var spritesOffset:Array<Array<Int>>;
	public var layersOffset:Array<Int>;
	public var layersNum:Int;
	public var tilesNum:Int;
	public var props:Array<Array<Props>>;
	var emptyProps:Props = {id: 0, collide: false, type: Slope.NONE, permeable: true};
	public var tileset:Image;
	public var tilesetW:Int;
	public var tilesetH:Int;
	public var tsize:Int;
	var offx = 0;
	var x = 0;
	var y = 0;
	
	public function new(json:Tiles):Void {
		var layers = json.layers;
		for (layer in layers)
			for (id in 0...layer.length)
				fillProps(layer[id], id);
		
		tsize = json.tsize;
		layersNum = layers.length;
		tilesNum = countTiles(layers);
		tilesOffset = []; //offsets in tiles range
		spritesLink = []; //tile to first frame links
		spritesOffset = []; //offsets in sprites range 
		layersOffset = [0]; //offsets in layers range
		props = []; //json props for every tile/sprite
		
		tilesetW = Math.ceil(Math.sqrt(tilesNum));
		tilesetH = Math.ceil(tilesNum / tilesetW);
		tileset = Image.createRenderTarget(tilesetW * tsize, tilesetH * tsize);
		var g = tileset.g2;
		g.begin(true, 0x0);
		Screen.pipeline(g);
		pushOffset();
		
		for (l in 0...layersNum) {
			var layer = layers[l];
			//empty tile properties for every layer
			props.push([emptyProps]);
			var tilesN = 0;
			
			for (tile in layer) {
				var bmd = loadTile(l, tile.file);
				drawTile(g, bmd, 0);
				props[l].push(tile);
				tilesN++;
				
				for (add in tile.add) switch(add) {
				case "rotate":
					for (i in 1...4) {
						drawRotatedTile(g, bmd, 0, i * 90);
						addSlopedProps(l, tile, add + (i * 90));
						//props[l].push(tile);
						tilesN++;
					}
				case "flipX":
					drawFlipXTile(g, bmd, 0);
					addSlopedProps(l, tile, add);
					//props[l].push(tile);
					tilesN++;
				case "flipY":
					drawFlipYTile(g, bmd, 0);
					addSlopedProps(l, tile, add);
					//props[l].push(tile);
					tilesN++;
				default:
				}
					
			}
			
			//draw sprite frames after
			spritesOffset[l] = [0];
			spritesLink[l] = [];
			var spritesN = 0;
			
			for (tile in layer) {
				var bmd = loadTile(l, tile.file);
				var frames = Std.int(bmd.width / tsize);
				if (frames < 2) continue;
				
				saveSpriteOffset(l, tile.id, frames);
				for (i in 1...frames) {
					drawTile(g, bmd, i);
					addFrameProps(l, layer[tile.id-1], i);
					spritesN++;
				}
				
				for (add in tile.add) switch(add) {
				case "rotate":
					for (i2 in 1...4) {
						saveSpriteOffset(l, tile.id + i2, frames);
						for (i in 1...frames) {
							drawRotatedTile(g, bmd, i, i2 * 90);
							addFrameProps(l, layer[tile.id-1], i);
							spritesN++;
						}
					}
				case "flipX":
					saveSpriteOffset(l, tile.id + 1, frames);
					for (i in 1...frames) {
						drawFlipXTile(g, bmd, i);
						addFrameProps(l, layer[tile.id-1], i);
						spritesN++;
					}
				case "flipY":
					saveSpriteOffset(l, tile.id + 1, frames);
					for (i in 1...frames) {
						drawFlipXTile(g, bmd, i);
						addFrameProps(l, layer[tile.id-1], i);
						spritesN++;
					}
				default:
				}
			}
			
			//save layer offset
			tilesOffset.push(tilesN);
			var prev = layersOffset[layersOffset.length-1];
			layersOffset.push(prev + tilesN + spritesN);
		}
		g.end();
	}
	
	inline function fillProps(tile:Props, id:Int):Void {
		tile.id = id + 1;
		if (tile.file == null) tile.file = "" + tile.id;
		if (tile.add == null) tile.add = [];
		if (tile.collide == null) tile.collide = false;
		if (tile.type == null) {
			tile.type = tile.collide ? Slope.FULL : Slope.NONE;
		} else tile.type = cast(tile.type, String); //fix separate props
		if (tile.permeable == null) tile.permeable = true;
	}
	
	inline function countTiles(layers:Array<Array<Props>>):Int {
		var count = 1;
		for (l in 0...layersNum) {
			var layer = layers[l];
			for (tile in layer) {
				var bmd = loadTile(l, tile.file);
				var num = Std.int(bmd.width / tsize);
				for (add in tile.add) switch(add) {
				case "rotate": count += num * 3;
				case "flipX", "flipY": count += num;
				default:
				}
				count += num;
			}
		}
		return count;
	}
	
	inline function loadTile(layer:Int, file:String):Image {
		var ereg = ~/-/g;
		file = ereg.replace(file, "_");
		return Reflect.field(Assets.images, "tiles_"+layer+"_"+file);
	}
	
	inline function drawTile(g:Graphics, bmd:Image, i:Int):Void {
		g.drawSubImage(bmd, x, y, i * tsize, 0, tsize, tsize);
		pushOffset();
	}
	
	inline function drawRotatedTile(g:Graphics, bmd:Image, i:Int, ang:Int):Void {
		g.rotate(ang * Math.PI/180, x + tsize/2, y + tsize/2);
		g.drawSubImage(bmd, x, y, i * tsize, 0, tsize, tsize);
		g.transformation = Utils.matrix();
		pushOffset();
	}
	
	inline function drawFlipXTile(g:Graphics, bmd:Image, i:Int):Void {
		g.transformation = Utils.matrix(-1, 0, x*2 + tsize);
		g.drawSubImage(bmd, x, y, i * tsize, 0, tsize, tsize);
		g.transformation = Utils.matrix();
		pushOffset();
	}
	
	inline function drawFlipYTile(g:Graphics, bmd:Image, i:Int):Void {
		g.transformation = Utils.matrix(1, 0, 0, -1, 0, y*2 + tsize);
		g.drawSubImage(bmd, x, y, i * tsize, 0, tsize, tsize);
		g.transformation = Utils.matrix();
		pushOffset();
	}
	
	inline function pushOffset():Void {
		offx += tsize;
		x = offx % (tilesetW * tsize);
		y = Std.int(offx / (tilesetW * tsize)) * tsize;
	}
	
	inline function saveSpriteOffset(l:Int, id:Int, frames:Int):Void {
		var len = spritesOffset[l].length - 1;
		spritesLink[l][id] = len;
		spritesOffset[l].push(spritesOffset[l][len] + frames - 1);
	}
	
	inline function addSlopedProps(l:Int, tile:Props, type:String):Void {
		var tile = Reflect.copy(tile);
		props[l].push(tile);
		switch(type) {
		case "rotate90": tile.type = Slope.rotate(tile.type);
		case "rotate180": for (i in 0...2) tile.type = Slope.rotate(tile.type);
		case "rotate270": for (i in 0...3) tile.type = Slope.rotate(tile.type);
		case "flipX": tile.type = Slope.flipX(tile.type);
		case "flipY": tile.type = Slope.flipY(tile.type);
		default: throw("incorrect sloped props: " + type);
		}
	}
	
	inline function addFrameProps(l:Int, sprite:Props, id:Int):Void {
		if (sprite.frames == null) props[l].push(sprite);
		else props[l].push(sprite.frames[id-1]);
	}
	
}
