package editor;

import kha.graphics2.Graphics;
import editor.Interfaces.Tool;
import Screen.Pointer;
import Lvl.GameObject;
import haxe.Json;

class Arrow implements Tool {
	
	var editor:Editor;
	var lvl:Lvl;
	var tsize(get, never):Int;
	function get_tsize() return lvl.tsize;
	var x = 0;
	var y = 0;
	
	public function new(editor:Editor, lvl:Lvl) {
		this.editor = editor;
		this.lvl = lvl;
	}
	
	public function clearHistory():Void {}
	public function undo():Void {}
	public function redo():Void {}
	
	public function onMouseDown(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		this.x = x;
		this.y = y;
		action(layer, x, y, tile);
	}
	
	public function onMouseMove(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		this.x = x;
		this.y = y;
	}
	
	public function onMouseUp(p:Pointer, layer:Int, x:Int, y:Int, tile:Int):Void {
		this.x = x;
		this.y = y;
	}
	
	public function onUpdate():Void {}
	
	public function onRender(g:Graphics):Void {}
	
	function action(layer:Int, x:Int, y:Int, tile:Int):Void {
		var obj = lvl.getObjects(x, y);
		if (obj == null) return;
		switch (obj) {
		case Chest(reward):
			#if kha_html5
			var prompt = js.Browser.window.prompt;
			var upd = Json.parse(prompt('Reward:', Json.stringify(reward)));
			if (upd != null) lvl.setObject(layer, x, y, tile, Chest(upd));
			#end
		case Enemy(type):
			#if kha_html5
			var prompt = js.Browser.window.prompt;
			var upd = Json.parse(prompt('Enemy type:', Json.stringify(type)));
			if (upd != null) lvl.setObject(layer, x, y, tile, Enemy(upd));
			#end
		default:
		}
	}
	
	/*inline function editChest(obj:GameObject):Void {
		#if kha_html5
		var prompt = js.Browser.window.prompt;
		var upd = Json.parse(prompt('Reward:', Json.stringify(obj.reward)));
		if (upd != null) obj.reward = upd;
		#end
	}

	inline function editEnemy(obj:GameObject):Void {
		#if kha_html5
		var prompt = js.Browser.window.prompt;
		var upd = Json.parse(prompt('Enemy type:', Json.stringify(obj.type)));
		if (upd != null) obj.type = upd;
		#end
	}*/
	
}
