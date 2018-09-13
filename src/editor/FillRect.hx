package editor;

import kha.graphics2.Graphics;
import editor.Interfaces.Tool;
import editor.Types.ArrHistory;
import Screen.Pointer;
import Types.IPoint;
import Types.IRect;

class FillRect implements Tool {
	
	var undo_h:Array<ArrHistory> = [];
	var redo_h:Array<ArrHistory> = [];
	var HISTORY_MAX = 10;
	var editor:Editor;
	var lvl:Lvl;
	var start:IPoint;
	var end:IPoint;
	
	public function new(editor:Editor, lvl:Lvl) {
		this.editor = editor;
		this.lvl = lvl;
	}
	
	function addHistory(h:ArrHistory):Void {
		undo_h.push(h);
		if (undo_h.length > HISTORY_MAX) undo_h.shift();
		redo_h = [];
	}
	
	public function clearHistory():Void {
		undo_h = [];
		redo_h = [];
	}
	
	inline function history(h1:Array<ArrHistory>, h2:Array<ArrHistory>):Void {
		var hid = h1.length - 1;
		if (hid == -1) return;
		var h = h1[hid];
		
		var olds = copyRect(h.rect, h.layer);
		fillTiles(h.rect, h.layer, h.tiles);
		
		h2.push({
			layer: h.layer,
			rect: h.rect,
			tiles: olds
		});
		h1.pop();
	}
	
	public function undo():Void {
		history(undo_h, redo_h);
	}
	
	public function redo():Void {
		history(redo_h, undo_h);
	}
	
	public function onMouseDown(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		start = {
			x: x,
			y: y
		};
		end = start;
	}
	
	public function onMouseMove(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		if (!p.isDown) return;
		end = {
			x: x,
			y: y
		};
	}
	
	public function onMouseUp(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		if (p.type == 1) {
			if (x == start.x && y == start.y) {
				editor.tile = lvl.getTile(layer, x, y);
				start = end = null;
				return;
			}
			//else clear area
			tile = 0;
		}
		end = {
			x: x,
			y: y
		};
		fill(layer, tile);
		start = end = null;
	}
	
	public function onUpdate():Void {}
	
	inline function makeRect(p:IPoint, p2:IPoint):IRect {
		var sx = p.x < p2.x ? p.x : p2.x;
		var sy = p.y < p2.y ? p.y : p2.y;
		var ex = p.x < p2.x ? p2.x : p.x;
		var ey = p.y < p2.y ? p2.y : p.y;
		return {x: sx, y: sy, w: ex - sx, h: ey - sy};
	}
	
	public function onRender(g:Graphics):Void {
		if (start == null || end == null) return;
		g.color = 0xFFFF00FF;
		var rect = makeRect(start, end);
		var tsize = lvl.tsize;
		g.drawRect(
			rect.x * tsize + lvl.camera.x - 1,
			rect.y * tsize + lvl.camera.y - 1,
			(rect.w+1) * tsize+3, (rect.h+1) * tsize+3
		);
	}
	
	inline function fill(layer:Int, tile:Int):Void {
		if (start == null || end == null) return;
		var rect = makeRect(start, end);
		
		var newObj = lvl.emptyObject(layer, tile);
		if (newObj != null) return;
		
		var olds = copyRect(rect, layer);
		fillRect(rect, layer, tile);
		
		addHistory({layer: layer, rect: rect, tiles: olds});
	}
	
	inline function copyRect(rect:IRect, layer:Int):Array<Array<Int>> {
		var arr:Array<Array<Int>> = [];
		for (iy in rect.y...rect.y+rect.h+1) {
			var ty = iy - rect.y;
			arr[ty] = [];
			for (ix in rect.x...rect.x+rect.w+1) {
				var tx = ix - rect.x;
				arr[ty][tx] = lvl.getTile(layer, ix, iy);
			}
		}
		return arr;
	}
	
	inline function fillRect(rect:IRect, layer:Int, tile:Int):Void {
		for (iy in rect.y...rect.y+rect.h+1)
		for (ix in rect.x...rect.x+rect.w+1) {
			lvl.setTile(layer, ix, iy, tile);
		}
	}
	
	inline function fillTiles(rect:IRect, layer:Int, tiles:Array<Array<Int>>):Void {
		for (iy in rect.y...rect.y+rect.h+1) {
			var ty = iy - rect.y;
			for (ix in rect.x...rect.x+rect.w+1) {
				var tx = ix - rect.x;
				lvl.setTile(layer, ix, iy, tiles[ty][tx]);
			}
		}
	}
	
}
