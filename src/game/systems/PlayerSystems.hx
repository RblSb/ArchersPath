package game.systems;

import kha.graphics2.Graphics;
import kha.input.KeyCode;
import kha.Assets;
import edge.ISystem;
import edge.Entity;
import edge.View;
import khm.Screen;
import khm.Screen.Pointer;
import khm.tilemap.Tilemap;
import khm.utils.MathExtension;
import khm.Types.Point;
import khm.Types.Rect;
import game.Components;

class UpdatePlayerControl implements ISystem {

	function update(player:Player, life:Life, body:Body, speed:Speed, coll:Collision, control:Control):Void {
		if (!life.alive) return;
		if (coll.down) player.jump = 0;
		var airJump = player.jump < player.maxJump;

		var keys = control.keys;
		var sx = coll.down ? body.landSX : body.airSX;
		if ((keys[KeyCode.Left] || keys[KeyCode.A]) && speed.x > -body.maxRunSX) speed.x -= sx;
		if ((keys[KeyCode.Right] || keys[KeyCode.D]) && speed.x < body.maxRunSX) speed.x += sx;
		if ((keys[KeyCode.Up] || keys[KeyCode.W] || keys[KeyCode.Space]) && (coll.down || airJump)) {
			coll.down = false;
			speed.y = body.jump;
			player.jump++;
			keys[KeyCode.Up] = keys[KeyCode.W] = keys[KeyCode.Space] = false;
		}
		#if debug
		/*if (keys[KeyCode.Q]) {
			player.arrowType--;
			keys[KeyCode.Q] = false;
			if (player.arrowType == -1) player.arrowType = BLOWN;

		} else if (keys[KeyCode.E]) {
			player.arrowType++;
			keys[KeyCode.E] = false;
			if (player.arrowType == BLOWN + 1) player.arrowType = NORMAL;
		}*/
		#end
	}

}

class UpdatePlayerCollision implements ISystem {

	var tileSize(get, never):Int;
	function get_tileSize():Int return Game.lvl.tileSize;
	var lvl(get, never):Tilemap;
	function get_lvl():Tilemap return Game.lvl;
	var game:Game;

	public function new(game:Game) {
		this.game = game;
	}

	function update(player:Player, life:Life, coll:Collision, pos:Position, size:Size, speed:Speed):Void {
		if (!life.alive) return;
		collision(coll, pos, size);
	}

	function collision(coll:Collision, pos:Position, size:Size):Void {
		var rect:Rect = {
			x: pos.x,
			y: pos.y,
			w: size.w,
			h: size.h
		};
		var x = Std.int(rect.x / tileSize);
		var y = Std.int(rect.y / tileSize);
		var maxX = Math.ceil((rect.x + rect.w) / tileSize);
		var maxY = Math.ceil((rect.y + rect.h) / tileSize);

		for (iy in y...maxY)
			for (ix in x...maxX) {
				var id = lvl.getTile(2, ix, iy).id;
				switch (id) {
					case 2: game.levelComplete();
					default:
				}
			}
	}

}

class UpdatePlayerAnimation implements ISystem {

	var lvl(get, never):Tilemap;
	function get_lvl():Tilemap return Game.lvl;
	var camera(get, never):Point;
	function get_camera():Point return Game.lvl.camera;
	static inline var animCounterMax = 500;

	function update(player:Player, life:Life, control:Control, sprite:Sprite, pos:Position, size:Size, speed:Speed, body:Body,  coll:Collision):Void {
		if (!life.alive) return;
		var left = false;
		var right = false;
		var up = false;
		var keys = control.keys;
		if (keys[KeyCode.Left] || keys[KeyCode.A]) left = true;
		if (keys[KeyCode.Right] || keys[KeyCode.D]) right = true;
		if (keys[KeyCode.Up] || keys[KeyCode.W]) up = true;
		if (left != right) sprite.dir = left ? 0 : 1;

		var pointer = control.pointers[0];
		if (pointer.isDown && coll.down && speed.x == 0) {
			var ang = Math.atan2(
				pointer.y - pos.y - size.h / 2 - 3 - camera.y,
				pointer.x - pos.x - size.w / 2 - camera.x
			);
			ang = MathExtension.toDeg(ang) + 90;
			if (ang < 0 || ang > 180) {
				if (ang < 0) ang = - ang;
				if (ang > 180) ang = 360 - ang;
				sprite.dir = 0;
			} else sprite.dir = 1;
			sprite.setAnimType("attack");
			sprite.setAnimFrame(Std.int((180 - ang - 1) / 20));
			return;
		}

		if (coll.down) {
			if (left == right) {
				if (speed.x != 0) {
					sprite.setAnimType("brake");
					if (speed.x < -body.maxRunSX / 2) sprite.dir = 0;
					else if (speed.x > body.maxRunSX / 2) sprite.dir = 1;
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
	function get_camera():Point return Game.lvl.camera;
	var game:Game;
	var entity:Entity;

	public function new(game:Game) {
		this.game = game;
	}

	function update(player:Player, life:Life, sprite:Sprite, pos:Position, size:Size, speed:Speed, gr:Gravity, bow:Bow, control:Control):Void {
		if (!life.alive) return;
		var pointer = control.pointers[0];
		var reset = true;
		if (pointer.isDown) {
			var x = pointer.x - pos.x - size.w / 2 - camera.x;
			var y = pointer.y - pos.y - size.h / 2 - 3 - camera.y;
			bow.ang = Math.atan2(y, x);
			if (bow.arrow == null) bow.arrow = game.engine.create([
				new Arrow(player.arrowType, entity),
				new Collision(),
				new Position(0, 0, true),
				new Size(1, 1),
				new Speed(0, 0),
				new Gravity(0, 0.1),
				new Life(true)
			]);

			if (bow.tension < bow.tensionMin) bow.tension = bow.tensionMin;
			if (bow.tension < bow.tensionMax) bow.tension += bow.tensionSpeed;
			var sx = Math.cos(bow.ang) * bow.tension;
			var sy = Math.sin(bow.ang) * bow.tension;
			var sp = bow.arrow.get(Speed);
			sp.x = sx;
			sp.y = sy;

			var sx = Math.cos(bow.ang) * 15;
			var sy = Math.sin(bow.ang) * 15;

			var p = bow.arrow.get(Position);
			p.x = pos.x + size.w / 2 + sx;
			p.y = pos.y + size.h / 2 - 3 + sy;

			// arrow sprite rotation edits
			var ang:Float = sprite.frameTypeId * 25;
			var side = sprite.dir == 0 ? -1 : 1;
			switch (sprite.frameTypeId) {
				case 0, 1:
					ang += 5;
					p.x += 2 * side;
					p.y -= 4;
				case 8:
					ang -= 20;
				default:
			}
			ang = MathExtension.toRad(90 - ang * side);

			var arrow = bow.arrow.get(Arrow);
			arrow.lastSpeedX = sx;
			arrow.lastSpeedY = sy;
			arrow.type = player.arrowType;
			arrow.ang = ang;
			arrow.visible = sprite.frameType == "attack";

			reset = false;
		}

		if (reset) {
			if (bow.tension == 0) return;
			bow.arrow.get(Position).fixed = false;
			bow.arrow.get(Arrow).visible = true;
			bow.arrow = null;
			bow.tension = 0;
		}
	}

}

class RenderAimLine implements ISystem {

	var g(get, never):Graphics;
	function get_g():Graphics return Screen.frame.g2;
	var camera(get, never):Point;
	function get_camera():Point return Game.lvl.camera;

	public function before():Void {
		g.color = 0xFFFF0000;
	}

	public function update(player:Player, life:Life, control:Control, pos:Position, size:Size, gr:Gravity, bow:Bow):Void {
		if (!life.alive) return;
		if (bow.tension == 0) return;

		var p = bow.arrow.get(Position);
		var x = p.x + camera.x;
		var y = p.y + camera.y;
		var s = bow.arrow.get(Speed);
		var sx = s.x;
		var sy = s.y;
		var gr = bow.arrow.get(Gravity);
		var gx = gr.x;
		var gy = gr.y;

		for (i in 0...bow.aimLine) {
			sx += gx;
			sy += gy;
			x += sx;
			y += sy;
			if (i % 2 != 0) continue;
			g.drawLine(x, y, x + sx, y + sy);
		}
	}

}

class RenderPlayerLifebar implements ISystem {

	var g(get, never):Graphics;
	function get_g():Graphics return Screen.frame.g2;
	static inline var w = 31;
	var h = Assets.images.gui_hp.height;

	public function before():Void {
		g.color = 0xFFFFFFFF;
	}

	function update(player:Player, control:Control, lifebar:Lifebar, life:Life):Void {
		var x = 10;
		var y = 10;
		for (i in 0...Std.int(life.hp / 10)) {
			g.drawSubImage(Assets.images.gui_hp, x, y, 0, 0, w, h);
			x += w - 1;
		}
		if (life.hp % 10 != 0) {
			g.drawSubImage(Assets.images.gui_hp, x, y, w, 0, w, h);
			x += w - 1;
		}
		for (i in 0...Std.int((life.maxHp - life.hp) / 10)) {
			g.drawSubImage(Assets.images.gui_hp, x, y, w * 2, 0, w, h);
			x += w - 1;
		}
	}

}

class RenderPlayerMoneybar implements ISystem {

	var g(get, never):Graphics;
	function get_g():Graphics return Screen.frame.g2;
	var img = Assets.images.gui_coin;
	var h = Assets.images.gui_coin.height;

	public function before():Void {
		g.color = 0xFFFFFFFF;
	}

	function update(player:Player, control:Control, moneybar:Moneybar, life:Life):Void {
		var x = 10;
		var y = 40;
		g.drawImage(img, x, y);
		// g.font = Assets.fonts.OpenSans_Regular;
		// g.fontSize = 24;
		// g.drawString("" + player.money, x + img.width, y);
		drawNumber(player.money, x + img.width + 3, y + 3);
	}

	function drawNumber(n:Int, x:Int, y:Int):Void { // only uints
		var w = [0, 12, 22, 34, 46, 58, 70, 82, 94, 106, 118, 131, 144];
		var h = 17;
		var img = Assets.images.gui_number_font;
		var offx = 0;
		var num = n;
		while (num > 0) {
			var digit = num % 10;
			offx += w[digit + 1] - w[digit];
			num = Std.int(num / 10);
		}

		if (n == 0) g.drawSubImage(img, x, y, 0, 0, w[1], h);
		else while (n > 0) {
			var digit = n % 10;
			offx -= w[digit + 1] - w[digit];
			g.drawSubImage(img, x + offx, y, w[digit], 0, w[digit + 1] - w[digit], h);
			n = Std.int(n / 10);
		}
	}

}
