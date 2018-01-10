package game.systems;

import kha.graphics2.Graphics;
import kha.input.KeyCode;
import kha.Assets;
import edge.ISystem;
import edge.Entity;
import edge.View;
import game.Components;
import Types.Point;

class UpdatePlayerControl implements ISystem {
	
	function update(player:Player, body:Body, speed:Speed, coll:Collision, control:Control):Void {
		var airHack = false;
		
		var keys = control.keys;
		var sx = coll.down ? body.landSX : body.airSX;
		if ((keys[KeyCode.Left] || keys[KeyCode.A]) && speed.x > -body.maxRunSX) speed.x -= sx;
		if ((keys[KeyCode.Right] || keys[KeyCode.D]) && speed.x < body.maxRunSX) speed.x += sx;
		if ((keys[KeyCode.Up] || keys[KeyCode.W] || keys[KeyCode.Space]) && (coll.down || airHack)) {
			coll.down = false;
			speed.y = body.jump;
		}
	}
	
}

class UpdatePlayerAnimation implements ISystem {
	
	var lvl(get, never):Lvl;
	function get_lvl() return Game.lvl;
	var camera(get, never):Point;
	function get_camera() return Game.lvl.camera;
	static inline var animCounterMax = 500;
	
	function update(player:Player, control:Control, sprite:Sprite, pos:Position, size:Size, speed:Speed, body:Body,  coll:Collision):Void {
		var left = false, right = false, up = false;
		var keys = control.keys;
		if (keys[KeyCode.Left] || keys[KeyCode.A]) left = true;
		if (keys[KeyCode.Right] || keys[KeyCode.D]) right = true;
		if (keys[KeyCode.Up] || keys[KeyCode.W]) up = true;
		if (left != right) sprite.dir = left ? 0 : 1;
		
		var pointer = control.pointers[0];
		if (pointer.isDown && speed.x == 0) {
			var ang = Math.atan2(
				pointer.y - pos.y - size.h/2 - 3 - camera.y,
				pointer.x - pos.x - size.w/2 - camera.x
			);
			ang = Utils.MathExtension.toDeg(ang) + 90;
			if (ang < 0 || ang > 180) {
				if (ang < 0) ang = - ang;
				if (ang > 180) ang = 360 - ang;
				sprite.dir = 0;
			} else sprite.dir = 1;
			sprite.setAnimType("attack");
			sprite.setAnimFrame(Std.int((180-ang-1) / 20));
			return;
		}
		
		if (coll.down) {
			if (left == right) {
				if (speed.x != 0) {
					sprite.setAnimType("brake");
					if (speed.x < -body.maxRunSX/2) sprite.dir = 0;
					else if (speed.x > body.maxRunSX/2) sprite.dir = 1;
				} else {
					if (sprite.animCounter == animCounterMax) {
						sprite.setAnimType("standAnim");
						sprite.setAnimFrame(1);
						sprite.animCounter = 0;
					} else sprite.animCounter++;
					
					if (sprite.frameType == "standAnim") {
						if (sprite.frameTypeId == 0) sprite.setAnimType("stand");
					} else sprite.setAnimType("stand");
				}
			} else {
				if (Math.abs(speed.x) > body.landSX) sprite.setAnimType("run");
				else sprite.setAnimType("stand");
			}
		} else {
			if (speed.y < -lvl.scale) sprite.setAnimType("jump");
			else if (speed.y > lvl.scale) sprite.setAnimType("fall");
			else sprite.setAnimType("soar");
		}
		sprite.playAnimType();
	}
	
}

class UpdatePlayerAim implements ISystem {
	
	var camera(get, never):Point;
	function get_camera() return Game.lvl.camera;
	var game:Game;
	var entity:Entity;
	
	public function new(game:Game) {
		this.game = game;
	}
	
	function update(player:Player, sprite:Sprite, pos:Position, size:Size, speed:Speed, gr:Gravity, bow:Bow, control:Control):Void {
		var pointer = control.pointers[0];
		var reset = true;
		if (pointer.isDown) {
			var x = pointer.x - pos.x - size.w/2 - camera.x;
			var y = pointer.y - pos.y - size.h/2 - 3 - camera.y;
			bow.ang = Math.atan2(y, x);
			if (bow.arrow == null) bow.arrow = game.engine.create([
				new Arrow(entity),
				new Collision(),
				new Position(0, 0, true),
				new Size(1, 1),
				new Gravity(0, 0.1),
				new Life(true)
			]);
			
			if (bow.tension < bow.tensionMin) bow.tension = bow.tensionMin;
			if (bow.tension < bow.tensionMax) bow.tension += bow.tensionSpeed;
			var sx = Math.cos(bow.ang) * bow.tension;
			var sy = Math.sin(bow.ang) * bow.tension;
			bow.arrow.add(new Speed(sx, sy));
			bow.arrow.get(Arrow).lastSpeedX = sx;
			bow.arrow.get(Arrow).lastSpeedY = sy;
			
			var sx = Math.cos(bow.ang) * 15;
			var sy = Math.sin(bow.ang) * 15;
			bow.arrow.get(Position).x = pos.x + size.w/2 + sx;
			bow.arrow.get(Position).y = pos.y + size.h/2 - 3 + sy;
			
			//arrow sprite rotation edits
			var ang:Float = sprite.frameTypeId * 25;
			var side = sprite.dir == 0 ? -1 : 1;
			switch(sprite.frameTypeId) {
				case 0, 1: ang += 5;
				bow.arrow.get(Position).x += 2 * side;
				bow.arrow.get(Position).y -= 4;
				case 8: ang -= 20;
				default:
			}
			ang = Utils.MathExtension.toRad(90 - ang * side);
			bow.arrow.get(Arrow).ang = ang;
			
			reset = false;
		}
		
		if (reset) {
			if (bow.tension == 0) return;
			bow.arrow.get(Position).fixed = false;
			bow.arrow = null;
			bow.tension = 0;
		}
	}
	
}

class RenderAimLine implements ISystem {
	
	var g(get, never):Graphics;
	function get_g() return Screen.frame.g2;
	var camera(get, never):Point;
	function get_camera() return Game.lvl.camera;
	
	public function before() {
		g.color = 0xFFFF0000;
	}
	
	public function update(player:Player, control:Control, pos:Position, size:Size, gr:Gravity, bow:Bow) {
		if (bow.tension == 0) return;
		
		var x = bow.arrow.get(Position).x + camera.x;
		var y = bow.arrow.get(Position).y + camera.y;
		var sx = bow.arrow.get(Speed).x;
		var sy = bow.arrow.get(Speed).y;
		var gx = bow.arrow.get(Gravity).x;
		var gy = bow.arrow.get(Gravity).y;
		
		for (i in 0...Std.int(bow.tensionMin)*10) {
			sx += gx;
			sy += gy;
			x += sx;
			y += sy;
			if (i%2 != 0) continue;
			g.drawLine(x, y, x + sx, y + sy);
		}
	}
	
}

class RenderPlayerLifebar implements ISystem {
	
	var g(get, never):Graphics;
	function get_g() return Screen.frame.g2;
	static inline var w = 31;
	var h = Assets.images.hp.height;
	
	public function before():Void {
		g.color = 0xFFFFFFFF;
	}
	
	function update(player:Player, control:Control, lifebar:Lifebar, life:Life):Void {
		var x = 10;
		var y = 10;
		for (i in 0...Std.int(life.hp/10)) {
			g.drawSubImage(Assets.images.hp, x, y, 0, 0, w, h);
			x += w - 1;
		}
		if (life.hp % 10 != 0) {
			g.drawSubImage(Assets.images.hp, x, y, w, 0, w, h);
			x += w - 1;
		}
		for (i in 0...Std.int((life.maxHp - life.hp)/10)) {
			g.drawSubImage(Assets.images.hp, x, y, w*2, 0, w, h);
			x += w - 1;
		}
	}
	
}
