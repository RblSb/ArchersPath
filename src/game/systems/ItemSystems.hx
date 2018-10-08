package game.systems;

import kha.graphics2.Graphics;
import kha.Assets;
import edge.ISystem;
import edge.Entity;
import edge.View;
import khm.utils.Collision as Coll;
import khm.tilemap.Tilemap;
import khm.Types.Point;
import game.Components;

class UpdateCoinCollision implements ISystem {

	var targets:View<{player:Player, moneybar:Moneybar, body:Body, pos:Position, size:Size, life:Life}>;
	var entity:Entity;

	function update(coin:Coin, pos:Position, size:Size, speed:Speed, life:Life):Void {
		if (!life.alive) {
			entity.destroy();
			return;
		}
		for (item in targets) {
			if (entity == item.entity) continue;
			var e = item.data;
			if (!Coll.aabb(
				{x: pos.x, y: pos.y, w: size.w, h: size.h},
				{x: e.pos.x, y: e.pos.y, w: e.size.w, h: e.size.h}
			)) continue;

			if (e.life.alive) {
				e.player.money++;
				entity.destroy();
			}
		}
	}

}

class UpdateHpCollision implements ISystem {

	var targets:View<{player:Player, body:Body, pos:Position, size:Size, life:Life}>;
	var entity:Entity;

	function update(hp:Hp, pos:Position, size:Size, speed:Speed, life:Life):Void {
		if (!life.alive) {
			entity.destroy();
			return;
		}
		for (item in targets) {
			if (entity == item.entity) continue;
			var e = item.data;
			if (!Coll.aabb(
				{x: pos.x, y: pos.y, w: size.w, h: size.h},
				{x: e.pos.x, y: e.pos.y, w: e.size.w, h: e.size.h}
			)) continue;

			if (e.life.alive) {
				e.life.heal(10);
				entity.destroy();
			}
		}
	}

}

class UpdateItems implements ISystem {

	var tileSize(get, never):Int;
	function get_tileSize():Int return Game.lvl.tileSize;
	var lvl(get, never):Tilemap;
	function get_lvl():Tilemap return Game.lvl;

	function update(coin:Item, sprite:Sprite, coll:Collision, pos:Position, speed:Speed, gr:Gravity):Void {
		var max = Math.abs(speed.x) > Math.abs(speed.y) ? Math.abs(speed.x) : Math.abs(speed.y);
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
