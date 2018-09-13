package game.systems;

import kha.graphics2.Graphics;
import kha.Assets;
import kha.Image;
import edge.ISystem;
import edge.Entity;
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
		coll.up = false;
		coll.down = false;
		
		var sx = Math.abs(speed.x);
		var sy = Math.abs(speed.y);
		var vx = sx / speed.x;
		var vy = sy / speed.y;
		var min = tsize / 4;
		
		while(sx > min || sy > min) {
			if (sx > min) {
				pos.x += min * vx;
				sx -= min;
				collision(coll, pos, size, speed, 0);
				if (coll.state) sx = 0;
			}
			
			if (sy > min) {
				pos.y += min * vy;
				sy -= min;
				collision(coll, pos, size, speed, 1);
				if (coll.state) sy = 0;
			}
		}
		
		if (sx > 0) {
			pos.x += sx * vx;
			collision(coll, pos, size, speed, 0);
		}
		
		if (sy > 0) {
			pos.y += sy * vy;
			collision(coll, pos, size, speed, 1);
		}
		
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
		case FULL: FULL(ix, iy, coll, pos, size, speed, dir);
		case HALF_B: HALF_B(ix, iy, coll, pos, size, speed, dir);
		case HALF_T: HALF_T(ix, iy, coll, pos, size, speed, dir);
		case HALF_L: HALF_L(ix, iy, coll, pos, size, speed, dir);
		case HALF_R: HALF_R(ix, iy, coll, pos, size, speed, dir);
		case HALF_BL: HALF_BL(ix, iy, coll, pos, size, speed, dir);
		case HALF_BR: HALF_BR(ix, iy, coll, pos, size, speed, dir);
		case HALF_TL: HALF_TL(ix, iy, coll, pos, size, speed, dir);
		case HALF_TR: HALF_TR(ix, iy, coll, pos, size, speed, dir);
		case QUARTER_BL: QUARTER_BL(ix, iy, coll, pos, size, speed, dir);
		case QUARTER_BR: QUARTER_BR(ix, iy, coll, pos, size, speed, dir);
		case QUARTER_TL: QUARTER_TL(ix, iy, coll, pos, size, speed, dir);
		case QUARTER_TR: QUARTER_TR(ix, iy, coll, pos, size, speed, dir);
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
	
	inline function HALF_B(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
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
	
	inline function HALF_T(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
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
	
	inline function HALF_L(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
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
	
	inline function HALF_R(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
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
	//TODO implement triangle collision
	inline function HALF_BL(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
	}
	
	inline function HALF_BR(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
	}
	
	inline function HALF_TL(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
	}
	
	inline function HALF_TR(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
	}
	
	inline function QUARTER_BL(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
		if (pos.x < ix * tsize + tsize/2)
		if (pos.y + size.h > iy * tsize + tsize/2)
		if (dir == 0) {
			if (speed.x < 0) {
				coll.state = true;
				coll.left = true;
				pos.x = ix * tsize + tsize/2;
				speed.x = 0;
			} else if (speed.x > 0) tileRight(ix, iy, coll, pos, size, speed);
		} else if (dir == 1) {
			if (speed.y > 0) {
				coll.state = true;
				coll.down = true;
				pos.y = iy * tsize + tsize/2 - size.h;
				speed.y = 0;
			} else if (speed.y < 0) tileTop(ix, iy, coll, pos, size, speed);
		}
	}
	
	inline function QUARTER_BR(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
		if (pos.x + size.w > ix * tsize + tsize/2)
		if (pos.y + size.h > iy * tsize + tsize/2)
		if (dir == 0) {
			if (speed.x < 0) tileLeft(ix, iy, coll, pos, size, speed);
			else if (speed.x > 0) {
				coll.state = true;
				coll.right = true;
				pos.x = ix * tsize + tsize/2 - size.w;
				speed.x = 0;
			}
		} else if (dir == 1) {
			if (speed.y > 0) {
				coll.state = true;
				coll.down = true;
				pos.y = iy * tsize + tsize/2 - size.h;
				speed.y = 0;
			} else if (speed.y < 0) tileTop(ix, iy, coll, pos, size, speed);
		}
	}
	
	inline function QUARTER_TL(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
		if (pos.x < ix * tsize + tsize/2)
		if (pos.y < iy * tsize + tsize/2)
		if (dir == 0) {
			if (speed.x < 0) {
				coll.state = true;
				coll.left = true;
				pos.x = ix * tsize + tsize/2;
				speed.x = 0;
			} else if (speed.x > 0) tileRight(ix, iy, coll, pos, size, speed);
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
	
	inline function QUARTER_TR(ix:Int, iy:Int, coll:Collision, pos:Position, size:Size, speed:Speed, dir:Int) {
		if (pos.x + size.w > ix * tsize + tsize/2)
		if (pos.y < iy * tsize + tsize/2)
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
			else if (speed.y < 0) {
				coll.state = true;
				coll.up = true;
				pos.y = iy * tsize + tsize/2;
				speed.y = 0;
			}
		}
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
	
	function update(camera:Camera, pos:Position, size:Size):Void {
		var rect:Rect = {x: pos.x, y: pos.y, w: size.w, h: size.h};
		Game.lvl.setCamera(rect);
	}
	
}

class RenderBG implements ISystem {
	
	var g(get, never):Graphics;
	function get_g() return Screen.frame.g2;
	var lvl(get, never):Lvl;
	function get_lvl() return Game.lvl;
	var camera(get, never):Point;
	function get_camera() return Game.lvl.camera;
	var cloudsX = 0.0;
	
	public function update():Void {
		var max = lvl.h * lvl.tsize - Screen.h;
		var offY = -max;
		if (max > 0) {
			//var cy = camera.y > 0 ? max : -camera.y;
			var cy = -camera.y;
			var size = Std.int(max / 5);
			offY = -Math.round(size * 1.5 - cy / max * size);
		}
		
		g.color = 0xFF9BF2EC;
		g.fillRect(0, 0, Screen.w, Screen.h - offY);
		g.color = 0xFF6BBAAB;
		g.fillRect(0, Screen.h - offY, Screen.w, offY);
		g.color = 0xFFFFFFFF;
		
		var sea = Assets.images.bg_sea;
		var y = Screen.h - sea.height - offY;
		fillPatternX(sea, -Math.round(cloudsX), y);
		
		var sky = Assets.images.bg_sky;
		y -= sky.height;
		fillPatternX(sky, 0, y);
		
		var clouds = Assets.images.bg_clouds;
		var y = Screen.h - sea.height - clouds.height - offY;
		fillPatternX(clouds, Math.round(cloudsX), y);
		cloudsX -= 0.1;
		
		/*g.font = Assets.fonts.OpenSans_Regular;
		g.fontSize = 30;
		g.drawString(""+offY, 0, 30);
		g.drawString(""+camera.y, 0, 60);
		g.drawString(""+lvl.h*lvl.tsize, 0, 90);*/
	}
	
	inline function fillPatternX(img:Image, x:Int, y:Int) {
		var len = Math.ceil(Screen.w / img.width);
		var sx = -Math.ceil(x / img.width);
		var ex = -Math.floor(x / img.width);
		for (i in sx...len+ex) g.drawImage(img, x + i * img.width, y);
		/*if (img == Assets.images.bg_clouds) {
			g.color = 0xFFFF0000;
			var n = 0;
			for (i in sx...len+ex) {g.fillRect(n*12, 0, 10, 10);n++;}
			g.font = Assets.fonts.OpenSans_Regular;
			g.fontSize = 30;
			g.drawString(""+sx, 0, 30);
			g.drawString(""+ex, 0, 60);
			g.drawString(""+(len+ex), 0, 90);
			g.color = 0xFFFFFFFF;
		}*/
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

class RenderAnimations implements ISystem {
	
	var g(get, never):Graphics;
	function get_g() return Screen.frame.g2;
	var camera(get, never):Point;
	function get_camera() return Game.lvl.camera;
	var entity:Entity;
	
	public function update(anim:Anim, sprite:Sprite, pos:Position, size:Size):Void {
		var x = (sprite.frame % sprite.setW) * sprite.w;
		var y = Std.int(sprite.frame / sprite.setW) * sprite.h;
		var offx = size.w/2 - sprite.w/2;
		
		g.drawSubImage(
			sprite.img,
			Math.round(pos.x + camera.x + offx),
			Math.round(pos.y + camera.y) - (sprite.h - size.h),
			x, y, sprite.w, sprite.h
		);
		sprite.playAnimType();
		if (sprite.frame == 0 && sprite.frameDelay == 0) {
			anim.repeat--;
			if (anim.repeat == 0) entity.destroy();
		}
	}
	
}

class RenderGameEnd implements ISystem {
	
	var g(get, never):Graphics;
	function get_g() return Screen.frame.g2;
	var lvl(get, never):Lvl;
	function get_lvl() return Game.lvl;
	var camera(get, never):Point;
	function get_camera() return Game.lvl.camera;
	var game:Game;
	var animY = 500;
	
	public function new(game:Game) {
		this.game = game;
	}
	
	function update():Void {
		if (game.player != null) {
			if (game.player.get(Life).alive) return;
			g.color = 0x50000000;
			g.fillRect(0, 0, Screen.w, Screen.h);
			g.color = 0xFFFFFFFF;
			g.font = Assets.fonts.OpenSans_Regular;
			g.fontSize = 24;
			var s = "Press R to Restart";
			g.drawString(s,
				Screen.w/2 - g.font.width(g.fontSize, s)/2,
				Screen.h/2 - g.font.height(g.fontSize)/2
			);
			return;
		}
		
		var nobody = true;
		for (o in lvl.map.objects)
		switch (o) {
		case Player:
			nobody = false;
			break;
		default:
		}
		
		if (nobody) return;
		camera.y++;
		if (animY > 0) animY--;
		if (animY < 200) {
			var color:kha.Color = 0xFFFFFFFF;
			color.A = 1 - (animY / 200);
			g.color = color;
			g.font = Assets.fonts.OpenSans_Regular;
			g.fontSize = 24;
			var s = "Game Over";
			g.drawString(s,
				Screen.w/2 - g.font.width(g.fontSize, s)/2,
				Screen.h/2 - g.font.height(g.fontSize)/2
			);
		}
	}
	
}
