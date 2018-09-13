package editor;

import kha.graphics2.Graphics;
import Screen.Pointer;

class TilePanel {
	
	var tsize(get, never):Int;
	function get_tsize() return lvl.tsize;
	var editor:Editor;
	var lvl:Lvl;
	public var x = 0;
	public var y = 0;
	public var w = 0;
	public var h = 0;
	var minW = 2;
	var maxW = 6;
	var tiles = 0;
	static inline var bgColor = 0xAA000000;
	static inline var gridColor = 0x50000000;
	static inline var selectColor = 0xAAFFFFFF;
	static inline var OVER_ALPHA = 1;
	static inline var OUT_ALPHA = 0.5;
	var opacity = OUT_ALPHA;
	var current = 0;
	
	public function new(editor:Editor, lvl:Lvl) {
		this.editor = editor;
		this.lvl = lvl;
		resize();
	}
	
	public function onDown(p:Pointer):Bool {
		var result = false;
		if (check(p.x, p.y)) {
			setTile(p);
			result = true;
		}
		return result;
	}
	
	inline function setTile(p:Pointer):Void {
		var layerOffsets = lvl.getTilesOffset();
		var tx = Std.int((p.x - x) / tsize);
		var ty = Std.int((p.y - y) / tsize);
		var layer = 0;
		var tile = ty * w + tx;
		for (off in layerOffsets) {
			if (tile > off) {
				tile -= off;
				layer++;
			} else break;
		}
		if (layer == layerOffsets.length) return;
		if (tile != 0) editor.layer = layer;
		editor.tile = tile;
	}
	
	public function onMove(p:Pointer):Bool {
		var result = false;
		if (check(p.x, p.y)) {
			opacity = OVER_ALPHA;
			result = true;
		} else opacity = OUT_ALPHA;
		return result;
	}
	
	public function onUp(p:Pointer):Bool {
		var result = false;
		if (check(p.x, p.y)) {
			result = true;
		}
		return result;
	}
	
	inline function check(x:Int, y:Int):Bool {
		if (x < this.x || x >= this.x + w * tsize || y < this.y || y >= this.y + h * tsize) return false;
		return true;
	}
	
	public function resize():Void {
		update();
	}
	
	public function update():Void {
		current = currentTile();
		tiles = 1;
		var offs = lvl.getTilesOffset();
		for (i in offs) tiles += i;
		
		w = minW;
		for (i in 0...maxW-minW) {
			h = Math.ceil(tiles / w);
			if (y + h * tsize > Screen.h) w++;
		}
		h = Math.ceil(tiles / w);
		x = Screen.w - tsize * w;
	}
	
	inline function currentTile():Int {
		var id = editor.tile;
		var layerOffsets = lvl.getTilesOffset();
		for (i in 0...editor.layer) id += layerOffsets[i];
		return id;
	}
	
	public function render(g:Graphics):Void {
		g.opacity = opacity;
		drawBg(g, x, y, w, h);
		drawGrid(g, x, y, w, h);
		drawTiles(g, x, y, w, h);
		drawSelected(g, x, y, w, h);
		g.opacity = 1;
	}
	
	inline function drawBg(g:Graphics, x:Int, y:Int, w:Int, h:Int):Void {
		g.color = bgColor;
		g.fillRect(x - 1, y, w * tsize + 1, h * tsize);
	}
	
	inline function drawTiles(g:Graphics, x:Int, y:Int, w:Int, h:Int):Void {
		var offX = 0;
		var tx = 0;
		var ty = 0;
		var ix = 0;
		var iy = 0;
		g.color = 0xFFFFFFFF;
		for (i in 0...tiles) {
			g.drawSubImage(
				lvl.tileset,
				x + tx, y + ty,
				ix, iy, tsize, tsize
			);
			offX += tsize;
			tx = offX % (w * tsize);
			ty = Std.int(offX / (w * tsize)) * tsize;
			ix = offX % (lvl.tilesetW * tsize);
			iy = Std.int(offX / (lvl.tilesetW * tsize)) * tsize;
		}
	}
	
	inline function drawGrid(g:Graphics, x:Int, y:Int, w:Int, h:Int):Void {
		var tiles = w * h;
		var offX = 0;
		var ix = 0;
		var iy = 0;
		g.color = gridColor;
		for (i in 0...tiles) {
			g.drawRect(x + ix, y + iy, tsize, tsize);
			offX += tsize;
			ix = offX % (w * tsize);
			iy = Std.int(offX / (w * tsize)) * tsize;
		}
		g.drawLine(x, y, x, y + iy);
	}
	
	inline function drawSelected(g:Graphics, x:Int, y:Int, w:Int, h:Int):Void {
		var offX = editor.tile == 0 ? 0 : current * tsize;
		var ix = offX % (w * tsize);
		var iy = Std.int(offX / (w * tsize)) * tsize;
		g.color = selectColor;
		g.drawRect(x + ix, y + iy, tsize, tsize);
	}
	
}
