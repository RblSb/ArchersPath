package editor;

import kha.graphics2.Graphics;
import editor.Interfaces.Tool;
import Screen.Pointer;
import Lvl.Object;
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
		var obj = lvl.getObject(2, x, y);
		if (obj != null) {
			if (obj.reward != null) editChest(obj);
			if (obj.type != null) editEnemy(obj);
			return;
		}
	}
	
	inline function editChest(obj:Object):Void {
		#if kha_html5
		var prompt = js.Browser.window.prompt;
		var upd = Json.parse(prompt('Reward:', Json.stringify(obj.reward)));
		if (upd != null) obj.reward = upd;
		#end
	}
	
	inline function editEnemy(obj:Object):Void {
		#if kha_html5
		var prompt = js.Browser.window.prompt;
		var upd = Json.parse(prompt('Enemy type:', Json.stringify(obj.type)));
		if (upd != null) obj.type = upd;
		#end
	}
	
}
