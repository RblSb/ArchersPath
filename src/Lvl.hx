package;

import kha.graphics2.Graphics;
import kha.Image;
import kha.Assets;
import kha.Blob;
import Types.IPoint;
import Types.Point;
import Types.Rect;

private typedef Props = {
	id:Int,
	collide:Bool,
	type:Slope,
	permeable:Bool
}

@:enum
abstract Slope(Int) from Int to Int {
	
	var NONE = -1;
	var FULL = 0;
	var HALF_B = 1;
	var HALF_T = 2;
	var HALF_L = 3;
	var HALF_R = 4;
	var HALF_BL = 5;
	var HALF_BR = 6;
	var HALF_TL = 7;
	var HALF_TR = 8;
	var QUARTER_BL = 9;
	var QUARTER_BR = 10;
	var QUARTER_TL = 11;
	var QUARTER_TR = 12;
	
	public inline function new(type:Slope) this = type;
	
	@:from public static function fromString(type:String):Slope {
		return Macro.fromString(Slope);
	}
	
	public static function rotate(type:Slope):Slope {
		return new Slope(switch (type) {
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
		return new Slope(switch (type) {
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
		return new Slope(switch (type) {
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
	links:Array<Array<Int>>, //for objects
	objects:Array<GameObject>,
	floatObjects:Array<FloatObject>
}

enum GameObject { //TODO autogen
	Empty;
	Player;
	End;
	Death;
	Chest(reward:String);
	Enemy(type:String);
	Arr(arr:Array<GameObject>);
	//Float(rect:Types.Rect, obj:GameObject);
	Err();
}

enum FloatObject {
	Rect(rect:Types.Rect);
}

class Lvl {
	
	var origTileset:Image;
	var origTsize:Int; //for rescaling
	
	var tilesOffset:Array<Int>;
	var spritesLink:Array<Array<Int>>;
	var spritesOffset:Array<Array<Int>>;
	var layersOffset:Array<Int>;
	public var layersNum:Int;
	public var tilesNum:Int;
	var props:Array<Array<Props>>;
	
	public var map(default, null):GameMap;
	public var w(get, never):Int;
	public var h(get, never):Int;
	inline function get_w() return map.w;
	inline function get_h() return map.h;
	
	var screenW(get, never):Int;
	var screenH(get, never):Int;
	inline function get_screenW() return Math.ceil(Screen.w / tsize) + 1;
	inline function get_screenH() return Math.ceil(Screen.h / tsize) + 1;
	public var tileset(default, null):Image;
	public var tilesetW(default, null):Int;
	public var tilesetH(default, null):Int;
	public var tsize(default, null) = 0; //tile size
	public var scale(default, null) = 1.0; //TODO remove
	public var camera = {x: 0.0, y: 0.0};
	
	public function new() {}
	
	public function init():Void {
		initTiles();
	}
	
	function initTiles():Void {
		var text = Assets.blobs.tiles_json.toString();
		var json:TSTiles = haxe.Json.parse(text);
		
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
		initMap(map);
	}
	
	public function loadCustomMap(map:GameMap):Void {
		this.map = copyMap(map);
		initMap(this.map);
	}
	
	inline function initMap(map:GameMap):Void { //TODO del
		/*if (map.objects == null) map.objects = {
			players: [],
			enemys: [],
			chests: []
		};*/
	}
	
	public function copyMap(map:GameMap):GameMap {
		var layers:Array<Array<Array<Int>>> = [
			for (l in map.layers) [
				for (iy in 0...l.length) l[iy].copy()
			]
		];
		var links:Array<Array<Int>> = [
			for (iy in 0...map.links.length) map.links[iy].copy()
		];
		var copy:GameMap = {
			name: map.name,
			w: map.w,
			h: map.h,
			layers: layers,
			links: links,
			objects: map.objects.copy(),
			floatObjects: map.floatObjects.copy()
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
				
			if (id > 0) {
				g.drawSubImage(
					tileset,
					ix * tsize + camX,
					iy * tsize + camY,
					(id % tilesetW) * tsize,
					Std.int(id / tilesetW) * tsize,
					tsize, tsize
				);
			}
		}
		
		
		#if debug
		/*if (layer != 1) return;
		var s = 1; //0.5;
		var x = Screen.w - origTileset.width*s;
		g.drawScaledImage(origTileset, x, 0,
			origTileset.width*s, origTileset.height*s
		);*/
		#end
	}
	
	public function drawLayers(g:Graphics):Void {
		for (l in 0...layersNum) drawLayer(g, l);
	}
	
	public function drawLinks(g:Graphics):Void {
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
		g.color = 0x77FFFFFF;
		
		for (iy in sy...ey)
		for (ix in sx...ex) {
			var id = map.links[iy][ix];
			if (id != 0) id = Type.enumIndex(map.objects[id]) + layersOffset[layersNum-1];
			
			if (id > 0) {
				g.drawSubImage(
					tileset,
					ix * tsize + camX - 4,
					iy * tsize + camY - 4,
					(id % tilesetW) * tsize,
					Std.int(id / tilesetW) * tsize,
					tsize, tsize
				);
			}
		}
	}
	
	function _rescale(scale:Float):Void {
		tsize = Std.int(origTsize * scale);
		this.scale = scale;
		var w = Std.int(origTileset.width * scale);
		var h = Std.int(origTileset.height * scale);
		
		tileset = Image.createRenderTarget(w, h);
		var g = tileset.g2;
		g.begin(true, 0x0);
		g.drawScaledImage(origTileset, 0, 0, w, h);
		g.end();
		
		var fix = Image.createRenderTarget(1, 1); //fix
	}
	
	public function rescale(scale:Float):Void {
		_rescale(scale);
	}
	
	public inline function getObject(x:Int, y:Int):GameObject {
		return getObjects(x, y);
	}
	
	public inline function getObjects(x:Int, y:Int):GameObject {
		var id = map.links[y][x];
		return map.objects[id];
	}
	
	public inline function setObject(layer:Int, x:Int, y:Int, tile:Int, obj:GameObject):Void {
		if (obj == null) {
			delObject(layer, x, y, tile);
			return;
		}
		//TODO not only one object on layer
		var id = map.links[y][x];
		if (id > 0) map.objects[id] = obj;
		else map.links[y][x] = map.objects.push(obj) - 1;
	}
	
	public inline function delObject(layer:Int, x:Int, y:Int, tile:Int):Void {
		if (emptyObject(layer, tile) == null) return;
		//TODO not only one object on layer
		delObjects(x, y);
	}
	
	public inline function setObjects(x:Int, y:Int, obj:GameObject):Void {
		if (obj == null) {
			delObjects(x, y);
			return;
		}
		var id = map.links[y][x];
		if (id > 0) map.objects[id] = obj;
		else map.links[y][x] = map.objects.push(obj) - 1;
	}
	
	public inline function delObjects(x:Int, y:Int):Void {
		var id = map.links[y][x];
		map.links[y][x] = 0;
		if (map.objects[id] != null) {
			map.objects.remove(map.objects[id]);
			recountLinks(id);
		}
	}
	
	inline function recountLinks(id:Int):Void {
		for (iy in 0...map.links.length)
			for (ix in 0...map.links[iy].length)
				if (map.links[iy][ix] > id) map.links[iy][ix]--;
	}
	
	public function emptyObject(layer:Int, tile:Int):GameObject {
		switch (layer) { //TODO autogen
			case 2:
				switch (tile) {
				case 0: return null; //Empty;
				case 1: return Player;
				case 4: return Chest("LIFE");
				case 5: return Enemy("Imp");
				default: return null;
				}
			default: return null;
		}
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

private typedef TSTiles = { //tiles.json
	tsize:Int,
	scale:Float,
	layers:Array<Array<TSProps>>
}

private typedef TSProps = {
	?id:Int,
	?collide:Bool,
	?type:String,
	?permeable:Bool,
	?file:String,
	?add:Array<String>,
	?frames:Array<TSProps>
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
	
	public function new(json:TSTiles):Void {
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
		props = []; //props for every tile/sprite
		
		tilesetW = Math.ceil(Math.sqrt(tilesNum));
		tilesetH = Math.ceil(tilesNum / tilesetW);
		tileset = Image.createRenderTarget(tilesetW * tsize, tilesetH * tsize);
		var g = tileset.g2;
		g.begin(true, 0x0);
		pushOffset();
		
		for (l in 0...layersNum) {
			var layer = layers[l];
			//empty tile properties for every layer
			props.push([emptyProps]);
			var tilesN = 0;
			
			for (tile in layer) {
				var bmd = loadTile(l, tile.file);
				drawTile(g, bmd, 0);
				addProps(l, tile);
				tilesN++;
				
				for (add in tile.add) switch (add) {
				case "rotate":
					for (i in 1...4) {
						drawRotatedTile(g, bmd, 0, i * 90);
						addSlopedProps(l, tile, add + (i * 90));
						tilesN++;
					}
				case "flipX":
					drawFlipXTile(g, bmd, 0);
					addSlopedProps(l, tile, add);
					tilesN++;
				case "flipY":
					drawFlipYTile(g, bmd, 0);
					addSlopedProps(l, tile, add);
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
				
				for (add in tile.add) switch (add) {
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
	
	inline function fillProps(tile:TSProps, id:Int):Void {
		if (tile.id == null) tile.id = id + 1; //skip id 0
		if (tile.file == null) tile.file = "" + tile.id;
		if (tile.add == null) tile.add = [];
		if (tile.collide == null) tile.collide = false;
		if (tile.type == null) tile.type = tile.collide ? "FULL" : "NONE";
		if (tile.permeable == null) tile.permeable = true;
	}
	
	inline function countTiles(layers:Array<Array<TSProps>>):Int {
		var count = 1;
		for (l in 0...layersNum) {
			var layer = layers[l];
			for (tile in layer) {
				var bmd = loadTile(l, tile.file);
				var num = Std.int(bmd.width / tsize);
				for (add in tile.add) switch (add) {
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
		//var ereg = ~/-/g;
		//file = ereg.replace(file, "_");
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
	
	inline function addProps(l:Int, tile:TSProps):Void {
		props[l].push({
			id: tile.id,
			collide: tile.collide,
			type: tile.type,
			permeable: tile.permeable
		});
	}
	
	inline function addSlopedProps(l:Int, tile:TSProps, type:String):Void {
		//var tile = Reflect.copy(tile);
		addProps(l, tile);
		var tile = props[l][props[l].length-1];
		switch (type) {
		case "rotate90": tile.type = Slope.rotate(tile.type);
		case "rotate180": for (i in 0...2) tile.type = Slope.rotate(tile.type);
		case "rotate270": for (i in 0...3) tile.type = Slope.rotate(tile.type);
		case "flipX": tile.type = Slope.flipX(tile.type);
		case "flipY": tile.type = Slope.flipY(tile.type);
		default: throw("incorrect sloped props: " + type);
		}
	}
	
	inline function addFrameProps(l:Int, sprite:TSProps, id:Int):Void {
		if (sprite.frames == null) addProps(l, sprite);
		else addProps(l, sprite.frames[id-1]);
	}
	
}
