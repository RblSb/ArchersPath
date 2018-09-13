package editor;

import kha.graphics2.Graphics;
import editor.Interfaces.Tool;
import editor.Types.History;
import Screen.Pointer;

class Brush implements Tool {
	
	var undo_h:Array<History> = [];
	var redo_h:Array<History> = [];
	var HISTORY_MAX = 50;
	var editor:Editor;
	var lvl:Lvl;
	
	public function new(editor:Editor, lvl:Lvl) {
		this.editor = editor;
		this.lvl = lvl;
	}
	
	function addHistory(h:History):Void {
		undo_h.push(h);
		if (undo_h.length > HISTORY_MAX) undo_h.shift();
		redo_h = [];
	}
	
	public function clearHistory():Void {
		undo_h = [];
		redo_h = [];
	}
	
	inline function history(h1:Array<History>, h2:Array<History>):Void {
		var hid = h1.length - 1;
		if (hid == -1) return;
		var h = h1[hid];
		
		h2.push({ //save current state
			layer: h.layer,
			x: h.x,
			y: h.y,
			tile: lvl.getTile(h.layer, h.x, h.y),
			obj: lvl.getObjects(h.x, h.y)
		});
		
		//return previous state
		lvl.setTile(h.layer, h.x, h.y, h.tile);
		lvl.setObject(h.layer, h.x, h.y, h.tile, h.obj);
		
		//trace(h.obj);
		h1.pop();
	}
	
	public function undo():Void {
		history(undo_h, redo_h);
	}
	
	public function redo():Void {
		history(redo_h, undo_h);
	}
	
	public function onMouseDown(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		action(p, layer, x, y, tile);
	}
	
	public function onMouseMove(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		if (!p.isDown) return;
		action(p, layer, x, y, tile);
	}
	
	public function onMouseUp(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		action(p, layer, x, y, tile);
	}
	
	public function onUpdate():Void {}
	
	public function onRender(g:Graphics):Void {}
	
	function action(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		var old = lvl.getTile(layer, x, y);
		if (old == tile) return;
		
		if (p.type == 1) { //pipette
			editor.tile = old;
			return;
		}
		
		var obj = lvl.getObjects(x, y);
		addHistory({layer: layer, x: x, y: y, tile: old, obj: obj});
		
		lvl.setTile(layer, x, y, tile);
		var newObj = lvl.emptyObject(layer, tile);
		lvl.setObject(layer, x, y, tile, newObj);
		//if (newObj != null) lvl.setObject(layer, x, y, tile, newObj);
	}
	
}
