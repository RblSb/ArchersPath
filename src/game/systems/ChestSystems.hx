package game.systems;

import kha.graphics2.Graphics;
import kha.Assets;
import edge.ISystem;
import edge.Entity;
import edge.View;
import game.Components;
import Types.Point;

class UpdateChests implements ISystem {
	
	var targets:View<{player:Player, pos:Position, size:Size}>;
	var entity:Entity;
	
	function update(chest:Chest, sprite:Sprite, pos:Position, size:Size):Void {
		if (chest.state == OPENED) return;
		
		if (chest.state == OPENING) {
			sprite.playAnimType();
			if (sprite.frameTypeId == sprite.sets[sprite.frameType].length-1) {
				chest.state = REWARD;
				reward(chest);
			}
			return;
		}
		
		if (chest.state == REWARD) {
			if (chest.animY < chest.maxAnimY) chest.animY++;
			else chest.state = OPENED;
			return;
		}
		
		for (item in targets) {
			var e = item.data;
			if (!Utils.AABB(
				{x: pos.x, y: pos.y, w: size.w, h: size.h},
				{x: e.pos.x, y: e.pos.y, w: e.size.w, h: e.size.h}
			)) continue;
			chest.player = item.entity;
			chest.state = OPENING;
		}
	}
	
	inline function reward(chest:Chest):Void {
		if (chest.player == null) return;
		switch (chest.reward) {
		case LIFE:
			chest.player.get(Life).hp += 10;
			chest.player.get(Life).maxHp += 10;
		case JUMP:
			chest.player.get(Player).maxJump++;
		case AIM:
			chest.player.get(Bow).aimLine += 5;
		case FROZEN_ARROWS:
			chest.player.get(Player).arrowType = FROZEN;
		case SHOKED_ARROWS:
			chest.player.get(Player).arrowType = SHOCKED;
		case BLOWN_ARROWS:
			chest.player.get(Player).arrowType = BLOWN;
		}
	}
	
}

class RenderChests implements ISystem {
	
	var g(get, never):Graphics;
	function get_g() return Screen.frame.g2;
	var camera(get, never):Point;
	function get_camera() return Game.lvl.camera;
	static inline var itemW = 19;
	static inline var itemH = 19;
	
	function update(chest:Chest, sprite:Sprite, pos:Position, size:Size):Void {
		var x = (sprite.frame % sprite.setW) * sprite.w;
		var y = Std.int(sprite.frame / sprite.setW) * sprite.h;
		g.drawSubImage(
			sprite.img,
			Math.round(pos.x + camera.x),
			Math.round(pos.y + camera.y),
			x, y, sprite.w, sprite.h
		);
		
		if (chest.state == REWARD) {
			#if kha_webgl
			g.opacity = 3 - chest.animY / chest.maxAnimY * 3;
			#else
			g.opacity = 1 - chest.animY / chest.maxAnimY;
			#end
			g.drawSubImage(
				Assets.images.store_items,
				Math.round(pos.x + size.w/2 - itemW/2 + camera.x),
				Math.round(pos.y - chest.animY + camera.y),
				chest.reward * itemW, 0, itemW, itemH
			);
			g.opacity = 1;
		}
	}
	
}
