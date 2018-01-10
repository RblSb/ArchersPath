package game;

import kha.input.KeyCode;
import kha.Assets;
import edge.Entity;
import game.systems.BasicSystems;
import game.systems.BodySystems;
import game.systems.PlayerSystems;
import game.systems.AISystems;
import game.systems.ArrowSystems;
import game.Components;
import editor.Editor;

class Game extends Screen {
	
	public static var lvl:Lvl;
	public static var player:Entity;
	public static var arrows:Array<Entity> = [];
	var editor:Editor;
	var currentLevel:Int;
	var levelProgress:Int;
	
	public function new() {
		super();
	}
	
	public function init(?editor:Editor):Void {
		this.editor = editor;
		lvl = new Lvl();
		lvl.init();
		lvl.loadMap(1);
		
		var sets = Settings.read();
		currentLevel = -1;
		levelProgress = sets.levelProgress;
	}
	
	public function playCompany():Void {
		currentLevel = levelProgress;
		lvl.loadMap(levelProgress);
		newGame();
	}
	
	public function playLevel(id:Int):Void {
		currentLevel = id;
		lvl.loadMap(id);
		newGame();
	}
	
	public function playCustomLevel(map:Lvl.GameMap):Void {
		lvl.loadCustomMap(map);
		newGame();
	}
	
	public function newGame():Void {
		var spawn = lvl.getPlayer();
		
		var text = Assets.blobs.player_json.toString();
		var json = haxe.Json.parse(text);
		var sp = new SpritesetParser();
		var frameSets = sp.parse(json);
		
		player = engine.create([
			new Player(),
			new Control(keys, pointers),
			new Body(),
			new Collision(),
			new Sprite(Assets.images.player, 32, 32, 0, frameSets),
			new Position(spawn.x * lvl.tsize+lvl.tsize*18, spawn.y * lvl.tsize),
			new Size(Std.int(lvl.tsize/2), lvl.tsize - 1),
			new Speed(0, 0),
			new Gravity(0, 0.2),
			new Life(true, 30),
			new Lifebar(),
			new Bow()
		]);
		
		engine.create([
			new AI(),
			new Control(new Map(), new Map()),
			new Body(),
			new Collision(),
			new Sprite(Assets.images.Imp, 32, 32, 0, frameSets),
			new Position((spawn.x+10) * lvl.tsize, spawn.y * lvl.tsize),
			new Size(Std.int(lvl.tsize/2), 18),
			new Speed(0, 0),
			new Gravity(0, 0.2),
			new Life(true, 5)
		]);
		
		engine.create([
			new AI(),
			new Control(new Map(), new Map()),
			new Body(),
			new Collision(),
			new Sprite(Assets.images.GreyMinotaur, 48, 48, 0, frameSets),
			new Position((spawn.x+6) * lvl.tsize, spawn.y * lvl.tsize),
			new Size(Std.int(lvl.tsize/1.5), lvl.tsize),
			new Speed(0, 0),
			new Gravity(0, 0.2),
			new Life(true, 5)
		]);
		
		/*engine.create([
			new AI(),
			new Control(new Map(), new Map()),
			new Body(),
			new Collision(),
			new Sprite(Assets.images.HunterOrc, 32, 32, 0, frameSets),
			new Position((spawn.x+6) * lvl.tsize, spawn.y * lvl.tsize),
			new Size(Std.int(lvl.tsize/2), lvl.tsize),
			new Speed(0, 0),
			new Gravity(0, 0.2),
			new Life(true, 5)
		]);*/
		
		updatePhase.add(new UpdateGravitation());
		updatePhase.add(new UpdateTileCollision());
		updatePhase.add(new UpdateBodyCollision());
		updatePhase.add(new UpdateArrowCollision());
		updatePhase.add(new UpdatePlayerAnimation());
		updatePhase.add(new UpdateAIAnimation());
		updatePhase.add(new UpdatePosition());
		
		updatePhase.add(new UpdateBodyPhysic());
		updatePhase.add(new UpdateArrows());
		updatePhase.add(new UpdatePlayerControl());
		updatePhase.add(new UpdateAIControl());
		updatePhase.add(new UpdatePlayerAim(this));
		updatePhase.add(new UpdateCamera(player.get(Position), player.get(Size)));
		
		renderPhase.add(new RenderBG());
		renderPhase.add(new RenderMapBG());
		//renderPhase.add(new RenderArrows());
		renderPhase.add(new RenderMapTG());
		renderPhase.add(new RenderBodies());
		renderPhase.add(new RenderArrows());
		renderPhase.add(new RenderAimLine());
		
		renderPhase.add(new RenderPlayerLifebar());
	}
	
	override function onKeyDown(key:KeyCode):Void {
		if (key == KeyCode.Zero) {
			setScale(1);
			
		} else if (key == 189 || key == KeyCode.HyphenMinus) {
			if (scale > 1) setScale(scale - 1);
			
		} else if (key == KeyCode.Equals) {
			if (scale < 9) setScale(scale + 1);
			
		} else if (key == KeyCode.Escape) {
			if (editor == null) {
				hide();
				editor = new Editor();
				editor.show();
				editor.init();
				return;
			}
			hide();
			editor.show();
		}
	}
	
}