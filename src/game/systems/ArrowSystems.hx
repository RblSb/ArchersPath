package game.systems;

import kha.graphics2.Graphics;
import kha.Assets;
import edge.ISystem;
import edge.Entity;
import edge.View;
import game.Components;
import Types.Point;

class UpdateArrowCollision implements ISystem {
	
	var tsize(get, never):Int;
	function get_tsize() return Game.lvl.tsize;
	var targets:View<{body:Body, pos:Position, size:Size, life:Life}>;
	var entity:Entity;
	
	function update(arrow:Arrow, pos:Position, size:Size, speed:Speed, life:Life):Void {
		if (pos.fixed) return;
		if (!life.alive) {
			entity.destroy();
			return;
		}
		
		var sx = Math.abs(speed.x);
		var sy = Math.abs(speed.y);
		var vx = sx / speed.x;
		var vy = sy / speed.y;
		var min = tsize / 4;
		var oldX = pos.x;
		var oldY = pos.y;
		
		while(sx > min || sy > min) {
			if (sx > min) {
				pos.x += min * vx;
				sx -= min;
			}
			if (sy > min) {
				pos.y += min * vy;
				sy -= min;
			}
			if (collision(arrow, pos, size, speed, life)) return;
		}
		if (sx > 0) pos.x += sx * vx;
		if (sy > 0) pos.y += sy * vy;
		if (collision(arrow, pos, size, speed, life)) return;
		
		pos.x = oldX;
		pos.y = oldY;
	}
	
	function collision(arrow:Arrow, pos:Position, size:Size, speed:Speed, life:Life):Bool {
		var ofPlayer:Entity = null;
		for (item in targets) {
			if (entity == item.entity) continue;
			var e = item.data;
			if (!Utils.AABB(
				{x: pos.x, y: pos.y, w: size.w, h: size.h},
				{x: e.pos.x, y: e.pos.y, w: e.size.w, h: e.size.h}
			)) continue;
			
			if (arrow.player == item.entity) {
				ofPlayer = arrow.player; //dont damage player
				continue;
			}
			if (e.life.alive) {
				if (item.entity.existsType(AI)) {
					var dmg = 5;
					switch (arrow.type) {
					case 1: item.entity.get(AI).frozen = 4 * 60;
					case 2: item.entity.get(AI).shocked = 2 * 60; dmg += 5;
					item.entity.get(AI).shockedAnim = true;
					case 3: item.entity.get(AI).blown = true; dmg += 10;
					}
					e.life.damage(dmg);
					entity.destroy();
					return true;
				} else if (item.entity.existsType(Player)) {
					e.life.damage(5);
					entity.destroy();
					return true;
				}
			}
		}
		//if arrow still in player
		arrow.player = ofPlayer;
		return false;
	}
	
}

class UpdateArrows implements ISystem {
	
	var tsize(get, never):Int;
	function get_tsize() return Game.lvl.tsize;
	var lvl(get, never):Lvl;
	function get_lvl() return Game.lvl;
	var targets:View<{pos:Position, size:Size}>;
	
	function update(arrow:Arrow, coll:Collision, pos:Position, speed:Speed, gr:Gravity):Void {
		if (pos.fixed) return;
		if (coll.state) {
			pos.fixed = true;
			arrow.ang = Math.atan2(arrow.lastSpeedY, arrow.lastSpeedX);
			if (arrow.lastSpeedX > 0) pos.x++;
			if (arrow.lastSpeedY < 0) pos.y--;
		} else {
			arrow.lastSpeedX = speed.x;
			arrow.lastSpeedY = speed.y;
		}
	}
	
}

class RenderArrows implements ISystem {
	
	var g(get, never):Graphics;
	function get_g() return Screen.frame.g2;
	var camera(get, never):Point;
	function get_camera() return Game.lvl.camera;
	var arrowLen = Assets.images.arrows.width - 1;
	static inline var h = 3;
	
	public function before():Void {
		g.color = 0xFFFFFFFF;
	}
	
	public function update(arrow:Arrow, pos:Position, size:Size, speed:Speed):Void {
		if (!arrow.visible) return;
		var x = pos.x + camera.x;
		var y = pos.y + camera.y;
		var sx = arrow.lastSpeedX;
		var sy = arrow.lastSpeedY;
		if (!pos.fixed) arrow.ang = Math.atan2(sy, sx);
		
		var length = Math.sqrt(sx * sx + sy * sy);
		var sx = sx / length * arrowLen;
		var sy = sy / length * arrowLen;
		
		drawArrow(arrow, x - sx, y - sy);
		
		/*g.color = 0xFF000000;
		g.drawLine(x, y, x - sx, y - sy);
		g.color = 0xFFFF0000;
		g.fillRect(x, y, size.w, size.h);*/
	}
	
	inline function drawArrow(arrow:Arrow, x:Float, y:Float):Void {
		var img = Assets.images.arrows;
		g.rotate(arrow.ang, x, y + h/2);
		g.drawSubImage(
			img,
			x, y,
			0, arrow.type * h,
			img.width, h
		);
		g.transformation = Utils.matrix();
	} 
	
}
