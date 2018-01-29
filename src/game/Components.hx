package game;

import kha.Image;
import edge.IComponent;
import edge.Entity;
import Screen.Pointer;
import Types.Point;
import Types.Rect;

class Camera implements IComponent {}

class Body implements IComponent {
	var friction = 0.25;
	//var gravity = 0.2;
	var jump = -4.2;
	var landSX = 0.6;
	var airSX = 0.20;
	var maxRunSX = 3;
	//var maxSpeed = 50;
	public function new(maxRunSX=3) {
		this.maxRunSX = maxRunSX;
	}
}

class Position implements IComponent {
	var x:Float;
	var y:Float;
	var fixed:Bool;
	
	public function new(x:Float, y:Float, fixed=false) {
		this.x = x;
		this.y = y;
		this.fixed = fixed;
	}
}

class Size implements IComponent {
	var w:Float;
	var h:Float;
}

class Speed implements IComponent {
	var x:Float;
	var y:Float;
}

class Gravity implements IComponent {
	var x:Float;
	var y:Float;
	
	public function new(x:Float, y:Float) {
		this.x = x;
		this.y = y;
	}
}

class Collision implements IComponent {
	public function new() {}
	var state = false;
	var up = false;
	var down = false;
	var left = false;
	var right = false;
}

class Life implements IComponent {
	var alive:Bool;
	var hp:Int;
	var maxHp:Int;
	static inline var damageSkipMax = 60;
	var damageSkip = 0;
	
	public function new(alive=true, hp=100) {
		this.alive = alive;
		this.hp = hp;
		maxHp = hp;
	}
	
	public inline function damage(dmg:Int):Void {
		if (damageSkip != 0) return;
		hp -= dmg;
		if (hp <= 0) alive = false;
		else damageSkip = damageSkipMax;
	}
	
	public inline function heal(add:Int):Void {
		hp += add;
		if (hp > maxHp) hp = maxHp;
	}
}

class Lifebar implements IComponent {}

class Moneybar implements IComponent {}

class Player implements IComponent {
	var arrowType:ArrowType = NORMAL;
	var money = 0;
	var jump = 0;
	var maxJump = 1;
	public function new() {};
}

class AI implements IComponent {
	var frozen = 0;
	var shocked = 0;
	var shockedAnim = false;
	var blown = false;
	public function new() {};
}

class Control implements IComponent {
	var keys:Map<Int, Bool>;
	var pointers:Map<Int, Pointer>;
}

class Bow implements IComponent {
	var tension:Float = 0;
	var tensionMin:Float;
	var tensionMax:Float;
	var tensionSpeed:Float;
	var aimLine = 5;
	var ang:Float;
	var arrow:Entity;
	
	public function new(ang:Float=0, tMin:Float=5, tMax:Float=20, tSpeed:Float=0.5) {
		this.ang = ang;
		this.tensionMin = tMin;
		this.tensionMax = tMax;
		this.tensionSpeed = tSpeed;
	}
}

@:enum
abstract ArrowType(Int) from Int to Int {
	var NORMAL = 0;
	var FROZEN = 1;
	var SHOCKED = 2;
	var BLOWN = 3;
}

class Arrow implements IComponent {
	var visible = true;
	var player:Entity;
	var lastSpeedX:Float;
	var lastSpeedY:Float;
	var ang:Float;
	var type:ArrowType;
	
	public function new(type=0, ?player:Entity) {
		this.player = player;
		this.type = type;
	}
}

class Item implements IComponent {
	var lastSpeed:Point = {x: 0, y: 0};
	public function new() {}
}

class Coin extends Item {
	
	public function new() {
		super();
	}
}

class Hp extends Item {
	
	public function new() {
		super();
	}
}

@:enum
abstract ChestReward(Int) from Int to Int {
	var LIFE = 0;
	var AIM = 1;
	var JUMP = 2;
	var FROZEN_ARROWS = 3;
	var SHOCKED_ARROWS = 4;
	var BLOWN_ARROWS = 5;
	var END = 6;
	
	public inline function new(type:ChestReward) this = type;
	
	@:from public static function fromString(type:String):ChestReward {
		return Macro.fromString(ChestReward);
	}
}

@:enum
abstract ChestState(Int) from Int to Int {
	var CLOSED = 1;
	var OPENING = 2;
	var REWARD = 3;
	var OPENED = 4;
}

class Chest implements IComponent {
	var reward:ChestReward;
	var state:ChestState = CLOSED;
	var animY = 0;
	var maxAnimY = 70;
	var player:Entity;
	
	public function new(reward:ChestReward) {
		this.reward = reward;
	}
}

class Anim implements IComponent {
	var repeat:Int;
	
	public function new(repeat=1) {
		this.repeat = repeat;
	}
}

class Sprite implements IComponent {
	var img:Image;
	var setW:Int;
	var w:Int;
	var h:Int;
	var frame = 0;
	var sets:Map<String, Array<Int>>;
	
	var dir = 1;
	var frameDelay = 0;
	var frameDelayMax:Int;
	var frameType:String;
	var frameTypeId:Int;
	var animCounter = 0;
	
	public function new(img:Image, w:Int, h:Int, frameDelayMax=5, ?sets) {
		this.img = img;
		this.w = w;
		this.h = h;
		this.frameDelayMax = frameDelayMax;
		this.setW = Std.int(img.width / w);
		if (sets != null) this.sets = sets;
		else {
			var setH = Std.int(img.height / h);
			var type = "anim";
			this.sets = [
				type => [for (i in 0...setW*setH) i]
			];
			setAnimType(type);
		}
	}
	
	public inline function setAnimType(type:String):Void {
		if (frameType == type) return;
		frameType = type;
		frameTypeId = 0;
		frame = sets[type][0];
		frameDelay = 0;
	}
	
	public inline function setAnimFrame(id:Int):Void {
		frameTypeId = id;
		frame = sets[frameType][id];
		frameDelay = 0;
	}
	
	public inline function playAnimType():Void {
		frameDelay++;
		if (frameDelay < frameDelayMax) return;
		frameTypeId++;
		var len = sets[frameType].length;
		if (frameTypeId == len) frameTypeId = 0;
		frame = sets[frameType][frameTypeId];
		frameDelay = 0;
	}
}
