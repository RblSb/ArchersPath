package editor;

import kha.graphics2.Graphics;
import Screen.Pointer;

class TilePanel {
	
	var tsize(get, never):Int;
	function get_tsize() return lvl.tsize;
	var editor:Editor;
	var lvl:Lvl;
	public var y = 0;
	public var x = 0;
	public var w = 0;
	public var h = 0;
	static inline var OVER = 0xAA000000;
	static inline var OUT = 0x77000000;
	var color = OUT;
	var len = 0;
	
	public function new(editor:Editor, lvl:Lvl) {
		this.editor = editor;
		this.lvl = lvl;
		resize();
	}
	
	public function onDown(p:Pointer, layer:Int):Bool {
		var result = false;
		if (check(p.x, p.y)) {
			setTile(p, layer);
			result = true;
		}
		return result;
	}
	
	inline function setTile(p:Pointer, defLayer:Int):Void {
		var layerOffsets = lvl.getTilesOffset();
		//trace(layerOffsets);
		var tx = Std.int((p.x - x) / tsize);
		var ty = Std.int((p.y - y) / tsize);
		var layer = 0;
		var tile = ty * w + tx;
		//trace(tile);
		for (off in layerOffsets) {
			if (tile > off) {
				tile -= off;
				layer++;
			} else break;
		}
		//trace(layer, tile);
		if (layer == layerOffsets.length) return;
		if (tile == 0) layer = defLayer;
		editor.pipetteSet(layer, tile);
	}
	
	public function onMove(p:Pointer):Bool {
		var result = false;
		if (check(p.x, p.y)) {
			color = OVER;
			result = true;
		} else color = OUT;
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
		len = lvl.tilesetW * lvl.tilesetH;
		w = 2;
		for (i in 0...5) if (y + len / w * tsize > Screen.h) w++;
		h = Math.ceil(len / w);
		x = Screen.w - tsize * w;
	}
	
	public function render(g:Graphics):Void {
		drawBg(g, x, y, w, h);
		var offX = 0;
		var tx = 0;
		var ty = 0;
		var ix = 0;
		var iy = 0;
		g.color = 0xFFFFFFFF;
		for (i in 0...len) {
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
		drawGrid(g, x, y, w, h);
	}
	
	inline function drawBg(g:Graphics, x:Int, y:Int, w:Int, h:Int):Void {
		g.color = color;
		g.fillRect(x, y, w * tsize, h * tsize);
	}
	
	inline function drawGrid(g:Graphics, x:Int, y:Int, w:Int, h:Int):Void {
		var len = w * h;
		var offX = 0;
		var ix = 0;
		var iy = 0;
		g.color = color;
		for (i in 0...len) {
			g.drawRect(x + ix, y + iy, tsize, tsize);
			offX += tsize;
			ix = offX % (w * tsize);
			iy = Std.int(offX / (w * tsize)) * tsize;
		}
		g.drawLine(x, y, x, y + iy);
	}
	
}
