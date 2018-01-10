package game.systems;

import kha.graphics2.Graphics;
import kha.Assets;
import edge.ISystem;
import edge.Entity;
import edge.View;
import game.Components;
import Types.Point;

class UpdateArrowCollision implements ISystem {
	
	var targets:View<{body:Body, pos:Position, size:Size, life:Life}>;
	var entity:Entity;
	
	function update(arrow:Arrow, pos:Position, size:Size, speed:Speed, life:Life):Void {
		if (pos.fixed) return;
		if (!life.alive) {
			entity.destroy();
			return;
		}
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
				e.life.damage(5);
				entity.destroy();
			}
		}
		//if arrow still in player
		arrow.player = ofPlayer;
	}
	
}

class UpdateArrows implements ISystem {
	
	var targets:View<{pos:Position, size:Size}>;
	
	function update(arrow:Arrow, coll:Collision, pos:Position, speed:Speed, gr:Gravity):Void {
		if (pos.fixed) return;
		if (coll.state) {
			pos.x -= speed.x;
			pos.y -= speed.y;
			/*speed.x = 0;
			speed.y = 0;
			gr.x = 0;
			gr.y = 0;*/
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
	
	public function before():Void {
		g.color = 0xFFFFFFFF;
	}
	
	public function update(arrow:Arrow, pos:Position, size:Size, speed:Speed):Void {
		var x = pos.x + camera.x;
		var y = pos.y + camera.y;
		//var sx = pos.fixed ? arrow.lastSpeedX : speed.x;
		//var sy = pos.fixed ? arrow.lastSpeedY : speed.y;
		var sx = arrow.lastSpeedX;
		var sy = arrow.lastSpeedY;
		if (!pos.fixed) arrow.ang = Math.atan2(sy, sx);
		
		var length = Math.sqrt(sx * sx + sy * sy);
		var sx = sx / length * arrowLen;
		var sy = sy / length * arrowLen;
		
		drawArrow(arrow.ang, x - sx, y - sy);
		
		/*g.color = 0xFF000000;
		g.drawLine(x, y, x - sx, y - sy);
		g.color = 0xFFFF0000;
		g.fillRect(x, y, size.w, size.h);*/
	}
	
	inline function drawArrow(ang:Float, x:Float, y:Float):Void {
		var img = Assets.images.arrows;
		g.rotate(ang, x, y + img.height/2);
		g.drawSubImage(
			img,
			x, y,
			0, 0,
			img.width, img.height
		);
		g.transformation = Utils.matrix();
	} 
	
}
