package game.systems;

import kha.graphics2.Graphics;
import kha.input.KeyCode;
import edge.ISystem;
import game.Components;
import edge.View;
import Types.Point;

class UpdateAIControl implements ISystem {
	
	var lvl(get, never):Lvl;
	function get_lvl() return Game.lvl;
	var tsize(get, never):Int;
	function get_tsize() return Game.lvl.tsize;
	
	function update(ai:AI, control:Control, body:Body, pos:Position, size:Size, speed:Speed, coll:Collision):Void {
		var keys = control.keys;
		
		if (ai.frozen > 0) {
			ai.frozen--;
			return;
		}
		if (ai.shocked > 0) {
			startMove(keys);
			if (Std.random(5) == 0) invertMoveDirection(keys);
			ai.shocked--;
		}
		if (ai.blown && coll.down) {
			speed.y -= 3;
			speed.x = -speed.x;
			coll.down = false;
		}
		
		if (Std.random(30) == 0) startMove(keys);
		if (Std.random(100) == 0) startJump(keys);
		if (Std.random(150) == 0) stopMove(keys);
		
		var side = 0;
		if (coll.left) side = -1;
		else if (coll.right) side = 1;
		var dir = Std.int(speed.x / Math.abs(speed.x));
		
		if (coll.down) { //on ground
			if (side == 0) { //no tile collision
				var sizeW = dir == 1 ? size.w : 0;
				
				if (dir != 0 && !canFallDown(pos.x + sizeW + speed.x, pos.y, 2)) {
					setMoveDirection(keys, dir);
				}
				
			} else if (side != 0) { //tile collision
				var sizeW = side == 1 ? size.w : 0;
				if (canJumpOver(pos.x + sizeW + side, pos.y)) startJump(keys);
				else setMoveDirection(keys, side);
			}
		
		} else { //in air
			var sizeW = dir == 1 ? size.w * 2 : -size.w;
			
			if (side == 0) {
				if (dir != 0 && !canFallDown(pos.x + sizeW + speed.x, pos.y + size.h, 3)) {
					setMoveDirection(keys, dir);
				}
				
			} else if (!canJumpOver(pos.x + side * tsize, pos.y)) {
				setMoveDirection(keys, side);
			}
		}
		
		if (keys[KeyCode.Space]) {
			keys[KeyCode.A] = !keys[KeyCode.A];
			keys[KeyCode.D] = !keys[KeyCode.D];
			keys[KeyCode.W] = false;
		}
		
		if (pos.x + speed.x < 1) setMoveDirection(keys, -1);
		if (pos.x + size.w + speed.x > lvl.w * tsize - 1) setMoveDirection(keys, 1);
		
		var sx = coll.down ? body.landSX : body.airSX;
		if (keys[KeyCode.A] && speed.x > -body.maxRunSX) speed.x -= sx;
		if (keys[KeyCode.D] && speed.x < body.maxRunSX) speed.x += sx;
		if (keys[KeyCode.W] && coll.down) {
			keys[KeyCode.W] = false;
			//coll.down = false;
			speed.y = body.jump;
		}
	}
	
	inline function startMove(keys:Map<Int, Bool>):Void {
		if (keys[KeyCode.A] == keys[KeyCode.D]) {
			var side = Std.random(2) == 0;
			keys[KeyCode.A] = side;
			keys[KeyCode.D] = !side;
		}
	}
	
	inline function stopMove(keys:Map<Int, Bool>):Void {
		keys[KeyCode.A] = false;
		keys[KeyCode.D] = false;
	}
	
	inline function startJump(keys:Map<Int, Bool>):Void {
		keys[KeyCode.W] = true;
	}
	
	inline function setMoveDirection(keys:Map<Int, Bool>, side:Int):Void {
		keys[KeyCode.A] = side == 1;
		keys[KeyCode.D] = side == -1;
	}
	
	inline function invertMoveDirection(keys:Map<Int, Bool>):Void {
		keys[KeyCode.A] = !keys[KeyCode.A];
		keys[KeyCode.D] = !keys[KeyCode.D];
	}
	
	inline function block(x:Float, y:Float):Bool {
		var ix = Std.int(x / tsize);
		var iy = Std.int(y / tsize);
		return lvl.getProps(1, ix, iy).collide;
	}
	
	inline function canFallDown(x:Float, y:Float, n:Int):Bool {
		var safe = false;
		for (i in 1...1+n) {
			if (block(x, y + tsize * i)) {
				safe = true;
				break;
			};
		}
		return safe;
	}
	
	inline function canJumpOver(x:Float, y:Float):Bool {
		return !block(x, y - tsize);
	}
	
	inline function canJumpTo(x:Float, y:Float):Bool {
		return !block(x, y);
	}
	
}

class UpdateAIAnimation implements ISystem {
	
	var lvl(get, never):Lvl;
	function get_lvl() return Game.lvl;
	var camera(get, never):Point;
	function get_camera() return Game.lvl.camera;
	
	function update(ai:AI, control:Control, sprite:Sprite, pos:Position, size:Size, speed:Speed, body:Body, coll:Collision):Void {
		if (ai.frozen > 0) return;
		var keys = control.keys;
		if (keys[KeyCode.Space]) {
			sprite.setAnimType("attack");
			sprite.playAnimType();
			if (sprite.frameTypeId == 0) keys[KeyCode.Space] = false;
			return;
		}
		if (keys[KeyCode.A] != keys[KeyCode.D]) sprite.dir = keys[KeyCode.A] ? 0 : 1;
		
		if (coll.down) {
			if (Math.abs(speed.x) > body.landSX) sprite.setAnimType("run");
			else {
				if (speed.x == 0) sprite.setAnimType("stand");
				else sprite.setAnimType("brake");
			}
		} else {
			if (speed.y < -lvl.scale) sprite.setAnimType("jump");
			else if (speed.y > lvl.scale) sprite.setAnimType("fall");
			else sprite.setAnimType("soar");
		}
		sprite.playAnimType();
	}
	
}
