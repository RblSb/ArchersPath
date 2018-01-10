package game.systems;

import kha.graphics2.Graphics;
import edge.ISystem;
import edge.View;
import game.Components;
import Types.Point;
import Types.Rect;

class UpdateGravitation implements ISystem {
	
	function update(pos:Position, speed:Speed, gr:Gravity):Void {
		if (pos.fixed) return;
		speed.x += gr.x;
		speed.y += gr.y;
	}
	
}

class UpdateTileCollision implements ISystem {
	
	var tsize(get, never):Int;
	function get_tsize() return Game.lvl.tsize;
	var lvl(get, never):Lvl;
	function get_lvl() return Game.lvl;
	var targets:View<{coll:Collision, pos:Position, size:Size, speed:Speed, gr:Gravity}>;
	
	function update():Void {
		for (item in targets) {
			var e = item.data;
			if (e.pos.fixed) continue;
			var speed = e.speed;
			e.coll.state = false;
			
			e.coll.left = false;
			e.coll.right = false;
			e.pos.x += speed.x;
			collision(e, 0);
			
			e.coll.up = false;
			e.coll.down = false;
			e.pos.y += speed.y;
			collision(e, 1);
			
			e.pos.x -= speed.x;
			e.pos.y -= speed.y;
		}
	}
	
	function collision(e:{coll:Collision, pos:Position, size:Size, speed:Speed, gr:Gravity}, dir:Int):Bool {
		var collide = false;
		var rect:Rect = {
			x: e.pos.x,
			y: e.pos.y,
			w: e.size.w,
			h: e.size.h
		};
		var x = Std.int(rect.x / tsize);
		var y = Std.int(rect.y / tsize);
		var maxX = Math.ceil((rect.x + rect.w) / tsize);
		var maxY = Math.ceil((rect.y + rect.h) / tsize);
		
		for (iy in y...maxY)
		for (ix in x...maxX) {
			if (lvl.getProps(1, ix, iy).collide) {
				block(ix, iy, e, dir);
				e.coll.state = true;
				collide = true;
			}
		}
		
		return collide;
	}
	
	inline function block(ix:Int, iy:Int, e:{coll:Collision, pos:Position, size:Size, speed:Speed, gr:Gravity}, dir:Int):Void {
		var rect:Rect = {
			x: e.pos.x,
			y: e.pos.y,
			w: e.size.w,
			h: e.size.h
		};
		var speed = e.speed;
	
		if (dir == 0) { //x-motion
			if (speed.x > 0) { //right
				e.coll.right = true;
				rect.x = ix * tsize - rect.w;
				speed.x = 0;
			} else if (speed.x < 0) { //left
				e.coll.left = true;
				rect.x = ix * tsize + tsize;
				speed.x = 0;
			}
		} else if (dir == 1) { //y-motion
			if (speed.y > 0) { //down
				e.coll.down = true;
				rect.y = iy * tsize - rect.h;
				speed.y = 0;
			} else if (speed.y < 0) { //up
				e.coll.up = false;
				rect.y = iy * tsize + tsize;
				speed.y = 0;
			}
		}
		e.pos.x = rect.x;
		e.pos.y = rect.y;
		e.size.w = rect.w;
		e.size.h = rect.h;
	}
	
}

class UpdatePosition implements ISystem {
	
	var maxSpeed = Game.lvl.tsize;
	
	function update(pos:Position, speed:Speed):Void {
		if (pos.fixed) return;
		if (speed.x > maxSpeed) speed.x = maxSpeed;
		if (speed.x < -maxSpeed) speed.x = -maxSpeed;
		if (speed.y > maxSpeed) speed.y = maxSpeed;
		if (speed.y < -maxSpeed) speed.y = -maxSpeed;
		pos.x += speed.x;
		pos.y += speed.y;
	}
	
}

class UpdateCamera implements ISystem {
	
	var pos:Position;
	var size:Size;
	
	public function new(pos:Position, size:Size) {
		this.pos = pos;
		this.size = size;
	}
	
	function update():Void {
		var rect:Rect = {x: pos.x, y: pos.y, w: size.w, h: size.h};
		Game.lvl.setCamera(rect);
	}
	
}

class RenderBG implements ISystem {
	
	var g(get, never):Graphics;
	function get_g() return Screen.frame.g2;
	
	public function update():Void {
		g.color = 0xFFFFFFFF;
		//g.color = 0xFF9BF2EC;
		g.fillRect(0, 0, Screen.w, Screen.h);
	}
	
}

class RenderMapBG implements ISystem {
	
	var g(get, never):Graphics;
	function get_g() return Screen.frame.g2;
	
	public function update():Void {
		Game.lvl.drawLayer(g, 0);
	}
	
}

class RenderMapTG implements ISystem {
	
	var g(get, never):Graphics;
	function get_g() return Screen.frame.g2;
	
	public function update():Void {
		Game.lvl.drawLayer(g, 1);
	}
	
}
