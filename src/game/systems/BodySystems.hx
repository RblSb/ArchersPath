package game.systems;

import kha.graphics2.Graphics;
import kha.Assets;
import edge.ISystem;
import edge.Entity;
import edge.View;
import game.Components;
import Types.Point;

class UpdateBodyPhysic implements ISystem {
	
	var lvl(get, never):Lvl;
	function get_lvl() return Game.lvl;
	var tsize(get, never):Int;
	function get_tsize() return Game.lvl.tsize;
	
	function update(body:Body, pos:Position, size:Size, speed:Speed, coll:Collision) {
		if (pos.x + speed.x < 0) {
			pos.x = 0;
			speed.x = 0;
		}
		if (pos.x + size.w + speed.x > lvl.w * tsize) {
			pos.x = lvl.w * tsize - size.w;
			speed.x = 0;
		}
		if (coll.down) {
			if (speed.x >= body.friction) speed.x -= body.friction;
			if (speed.x <= 0.0-body.friction) speed.x += body.friction;
			if (Math.abs(speed.x) < body.friction) speed.x = 0;
		}
	}
	
}

class UpdateBodyCollision implements ISystem {
	
	var targets:View<{body:Body, coll:Collision, pos:Position, size:Size, life:Life}>;
	var entity:Entity;
	var game:Game;
	
	public function new(game:Game) {
		this.game = game;
	}
	
	function update(body:Body, coll:Collision, pos:Position, size:Size, speed:Speed, life:Life) {
		if (pos.fixed) return;
		if (life.damageSkip != 0) life.damageSkip--;
		if (!life.alive) {
			if (entity.existsType(AI)) {
				entity.remove(entity.get(AI));
				for (i in 0...3) createCoin(pos);
				createHp(pos);
			}
			if (entity.existsType(Player)) entity.remove(entity.get(Player));
			//entity.remove(ai);
			//entity.destroy();
			return;
		}
		for (item in targets) {
			if (entity == item.entity) continue;
			var e = item.data;
			if (!Utils.AABB(
				{x: pos.x, y: pos.y, w: size.w, h: size.h},
				{x: e.pos.x, y: e.pos.y, w: e.size.w, h: e.size.h}
			)) continue;
			
			if (entity.existsType(Player) && item.entity.existsType(AI)) life.damage(5);
			if (entity.existsType(AI) && item.entity.existsType(Player)) {
				var keys = entity.get(Control).keys;
				keys[kha.input.KeyCode.Space] = true;
			}
		}
	}
	
	inline function createCoin(pos:Position) {
		game.engine.create([
			new Coin(),
			new Body(),
			new Collision(),
			new Sprite(Assets.images.coins, 15, 15),
			new Position(pos.x, pos.y),
			new Size(15, 15),
			new Speed(1 - Math.random() * 2, Math.random() * -3),
			new Gravity(0, 0.1),
			new Life(true)
		]);
	}
	
	inline function createHp(pos:Position) {
		game.engine.create([
			new Hp(),
			new Body(),
			new Collision(),
			new Sprite(Assets.images.lifes, 14, 12),
			new Position(pos.x, pos.y),
			new Size(14, 12),
			new Speed(1 - Math.random() * 2, Math.random() * -3),
			new Gravity(0, 0.1),
			new Life(true)
		]);
	}
}

class RenderBodies implements ISystem {
	
	var g(get, never):Graphics;
	function get_g() return Screen.frame.g2;
	var camera(get, never):Point;
	function get_camera() return Game.lvl.camera;
	var entity:Entity;
	var game:Game;
	
	public function new(game:Game) {
		this.game = game;
	}
	
	inline function drawLightning(pos:Position, size:Size):Void {
		var w = 13;
		var h = 13;
		game.engine.create([
			new Anim(3),
			new Sprite(Assets.images.electric_sparks2, w, h, 3),
			new Position(pos.x + Math.random() * (size.w - w), pos.y + Math.random() * (size.h - h)),
			new Size(w, h)
		]);
	}
	
	inline function drawExplosion(pos:Position, size:Size):Void {
		var w = 18;
		var h = 18;
		game.engine.create([
			new Anim(),
			new Sprite(Assets.images.explosion, w, h),
			new Position(pos.x + size.w/2 - w/2, pos.y + size.h/2 - h/2),
			new Size(w, h)
		]);
	}
	
	public function update(sprite:Sprite, body:Body, pos:Position, size:Size, life:Life):Void {
		if (!life.alive) deathAnimation(sprite);
		g.color = 0xFFFFFFFF;
		
		if (entity.existsType(AI)) {
			var ai = entity.get(AI);
			if (ai.frozen > 0) {
				g.color = 0xFF88FFFF;
				if (ai.frozen < 0x88) {
					var color = g.color;
					color.R = (255 - ai.frozen) / 255;
					g.color = color;
				}
			}
			if (ai.shockedAnim) {
				for (i in 0...3) drawLightning(pos, size);
				ai.shockedAnim = false;
			}
			if (ai.blown) {
				drawExplosion(pos, size);
				ai.blown = false;
			}
		}
		
		var x = (sprite.frame % sprite.setW) * sprite.w;
		var y = Std.int(sprite.frame / sprite.setW) * sprite.h;
		var offx = size.w/2 - sprite.w/2;
		
		if (sprite.dir == 0) g.transformation = Utils.matrix(-1, 0, Math.round(pos.x + camera.x + offx)*2 + sprite.w);
		if (life.damageSkip % 16 > 8) g.opacity = 0.5;
		g.drawSubImage(
			sprite.img,
			Math.round(pos.x + camera.x + offx),
			Math.round(pos.y + camera.y) - (sprite.h - size.h),
			x, y, sprite.w, sprite.h
		);
		
		if (life.damageSkip % 16 > 8) g.opacity = 1;
		if (sprite.dir == 0) g.transformation = Utils.matrix();
	}
	
	inline function deathAnimation(sprite:Sprite):Void {
		if (sprite.frameType != "death" || sprite.frameTypeId != sprite.sets["death"].length-1) {
			sprite.setAnimType("death");
			sprite.playAnimType();
		}
	}
	
	inline function drawRect(pos:Position, size:Size):Void {
		g.drawRect(pos.x + camera.x + 1, pos.y + camera.y, size.w - 1, size.h);
	}
	
}
