package game.systems;

import kha.graphics2.Graphics;
import kha.Assets;
import edge.ISystem;
import edge.Entity;
import edge.View;
import game.Components;
import Types.Point;

class UpdateCoinCollision implements ISystem {
	
	var targets:View<{player:Player, body:Body, pos:Position, size:Size, life:Life}>;
	var entity:Entity;
	
	function update(coin:Coin, pos:Position, size:Size, speed:Speed, life:Life):Void {
		if (!life.alive) {
			entity.destroy();
			return;
		}
		for (item in targets) {
			if (entity == item.entity) continue;
			var e = item.data;
			if (!Utils.AABB(
				{x: pos.x, y: pos.y, w: size.w, h: size.h},
				{x: e.pos.x, y: e.pos.y, w: e.size.w, h: e.size.h}
			)) continue;
			
			if (e.life.alive) {
				//TODO add to player money
				entity.destroy();
			}
		}
	}
	
}

class UpdateCoins implements ISystem {
	
	var tsize(get, never):Int;
	function get_tsize() return Game.lvl.tsize;
	var lvl(get, never):Lvl;
	function get_lvl() return Game.lvl;
	
	function update(coin:Coin, sprite:Sprite, coll:Collision, pos:Position, speed:Speed, gr:Gravity):Void {
		//coin.frame++;
		//if (coin.frame > 5) coin.frame = 0;
		var max = Math.abs(speed.x) > Math.abs(speed.y) ? Math.abs(speed.x) : Math.abs(speed.y);
		//if (max < Math.abs(speed.y)) max = Math.abs(speed.y);
		for (i in 0...Std.int(max)) sprite.playAnimType();
		sprite.playAnimType();
		
		if (coll.state) {
			if (coll.down || coll.up) speed.y = -coin.lastSpeed.y / 2;
			if (coll.right || coll.left) speed.x = -coin.lastSpeed.x / 2;
		} else {
			coin.lastSpeed.x = speed.x;
			coin.lastSpeed.y = speed.y;
		}
	}
	
}

/*class RenderCoins implements ISystem {

	var g(get, never):Graphics;
	function get_g() return Screen.frame.g2;
	var camera(get, never):Point;
	function get_camera() return Game.lvl.camera;
	static inline var w = 15;
	static inline var h = 15;

	public function before():Void {
		g.color = 0xFFFFFFFF;
	}

	public function update(coin:Coin, pos:Position, size:Size, speed:Speed):Void {
		var img = Assets.images.coins;
		g.drawSubImage(
			img,
			pos.x + camera.x, pos.y + camera.y,
			coin.frame * w, 0,
			size.w, size.h
		);
	}

}*/
