package game.systems;

import kha.graphics2.Graphics;
import edge.ISystem;
import edge.View;
import game.Components;
import Lvl.Slope;
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
	
	function update(coll:Collision, pos:Position, size:Size, speed:Speed, gr:Gravity):Void {
		if (pos.fixed) return;
		coll.state = false;
			
		coll.left = false;
		coll.right = false;
		pos.x += speed.x;
		collision(coll, pos, size, speed, 0);
			
		coll.up = false;
		coll.down = false;
		pos.y += speed.y;
		collision(coll, pos, size, speed, 1);
			
		pos.x -= speed.x;
		pos.y -= speed.y;
	}
	
	function collision(coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int):Void {
		var rect:Rect = {
			x: pos.x,
			y: pos.y,
			w: size.w,
			h: size.h
		};
		var x = Std.int(rect.x / tsize);
		var y = Std.int(rect.y / tsize);
		var maxX = Math.ceil((rect.x + rect.w) / tsize);
		var maxY = Math.ceil((rect.y + rect.h) / tsize);
		
		for (iy in y...maxY)
		for (ix in x...maxX) {
			var tile = lvl.getProps(1, ix, iy);
			if (tile.collide) block(ix, iy, coll, pos, size, speed, dir, tile.type);
		}
	}
	
	inline function block(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int, slope:Slope):Void {
		switch (slope) {
		case Slope.FULL: FULL(ix, iy, coll, pos, size, speed, dir);
		case Slope.HALF_BOTTOM: HALF_BOTTOM(ix, iy, coll, pos, size, speed, dir);
		case Slope.HALF_TOP: HALF_TOP(ix, iy, coll, pos, size, speed, dir);
		case Slope.HALF_LEFT: HALF_LEFT(ix, iy, coll, pos, size, speed, dir);
		case Slope.HALF_RIGHT: HALF_RIGHT(ix, iy, coll, pos, size, speed, dir);
		case HALF_BOTTOM_LEFT: HALF_BOTTOM_LEFT(ix, iy, coll, pos, size, speed, dir);
		case HALF_BOTTOM_RIGHT: HALF_BOTTOM_RIGHT(ix, iy, coll, pos, size, speed, dir);
		case HALF_TOP_LEFT: HALF_TOP_LEFT(ix, iy, coll, pos, size, speed, dir);
		case HALF_TOP_RIGHT: HALF_TOP_RIGHT(ix, iy, coll, pos, size, speed, dir);
		default: trace(slope);
		}
	}
	
	inline function tileLeft(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed) {
		coll.state = true;
		coll.left = true;
		pos.x = ix * tsize + tsize;
		speed.x = 0;
	}
	
	inline function tileRight(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed) {
		coll.state = true;
		coll.right = true;
		pos.x = ix * tsize - size.w;
		speed.x = 0;
	}
	
	inline function tileBottom(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed) {
		coll.state = true;
		coll.down = true;
		pos.y = iy * tsize - size.h;
		speed.y = 0;
	}
	
	inline function tileTop(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed) {
		coll.state = true;
		coll.up = true;
		pos.y = iy * tsize + tsize;
		speed.y = 0;
	}
	
	inline function FULL(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
		if (dir == 0) {
			if (speed.x < 0) tileLeft(ix, iy, coll, pos, size, speed);
			else if (speed.x > 0) tileRight(ix, iy, coll, pos, size, speed);
		} else if (dir == 1) {
			if (speed.y > 0) tileBottom(ix, iy, coll, pos, size, speed);
			else if (speed.y < 0) tileTop(ix, iy, coll, pos, size, speed);
		}
	}
	
	inline function HALF_BOTTOM(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
		if (pos.y + size.h > iy * tsize + tsize/2)
		if (dir == 0) {
			if (speed.x < 0) tileLeft(ix, iy, coll, pos, size, speed);
			else if (speed.x > 0) tileRight(ix, iy, coll, pos, size, speed);
		} else if (dir == 1) {
			if (speed.y > 0) {
				coll.state = true;
				coll.down = true;
				pos.y = iy * tsize + tsize/2 - size.h;
				speed.y = 0;
			} else if (speed.y < 0) tileTop(ix, iy, coll, pos, size, speed);
		}
	}
	
	inline function HALF_TOP(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
		if (pos.y < iy * tsize + tsize/2)
		if (dir == 0) {
			if (speed.x < 0) tileLeft(ix, iy, coll, pos, size, speed);
			else if (speed.x > 0) tileRight(ix, iy, coll, pos, size, speed);
		} else if (dir == 1) {
			if (speed.y > 0) tileBottom(ix, iy, coll, pos, size, speed);
			else if (speed.y < 0) {
				coll.state = true;
				coll.up = true;
				pos.y = iy * tsize + tsize/2;
				speed.y = 0;
			}
		}
	}
	
	inline function HALF_LEFT(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
		if (pos.x < ix * tsize + tsize/2)
		if (dir == 0) {
			if (speed.x < 0) {
				coll.state = true;
				coll.left = true;
				pos.x = ix * tsize + tsize/2;
				speed.x = 0;
			} else if (speed.x > 0) tileRight(ix, iy, coll, pos, size, speed);
		} else if (dir == 1) {
			if (speed.y > 0) tileBottom(ix, iy, coll, pos, size, speed);
			else if (speed.y < 0) tileTop(ix, iy, coll, pos, size, speed);
		}
	}
	
	inline function HALF_RIGHT(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
		if (pos.x + size.w > ix * tsize + tsize/2)
		if (dir == 0) {
			if (speed.x < 0) tileLeft(ix, iy, coll, pos, size, speed);
			else if (speed.x > 0) {
				coll.state = true;
				coll.right = true;
				pos.x = ix * tsize + tsize/2 - size.w;
				speed.x = 0;
			}
		} else if (dir == 1) {
			if (speed.y > 0) tileBottom(ix, iy, coll, pos, size, speed);
			else if (speed.y < 0) tileTop(ix, iy, coll, pos, size, speed);
		}
	}
	
	inline function HALF_BOTTOM_LEFT(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
	}
	
	inline function HALF_BOTTOM_RIGHT(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
	}
	
	inline function HALF_TOP_LEFT(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
	}
	
	inline function HALF_TOP_RIGHT(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
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
