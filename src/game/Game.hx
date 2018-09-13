package game;

import kha.Canvas;
import kha.input.KeyCode;
import kha.Assets;
import edge.Engine;
import edge.Phase;
import edge.Entity;
import game.systems.BasicSystems;
import game.systems.BodySystems;
import game.systems.PlayerSystems;
import game.systems.AISystems;
import game.systems.ArrowSystems;
import game.systems.ItemSystems;
import game.systems.ChestSystems;
import game.Components;
import editor.Editor;

class Game extends Screen {
	
	public var engine:Engine;
	public var updatePhase:Phase;
	public var renderPhase:Phase;
	
	public static var lvl:Lvl;
	public var save:Player;
	public var startLife:Life;
	public var startPlayer:Player;
	public var player:Entity;
	var editor:Editor;
	var currentLevel:Int;
	var levelProgress:Int;
	
	public function new() {
		super();
	}
	
	public function init(?editor:Editor):Void {
		engine = new Engine();
		
		this.editor = editor;
		lvl = new Lvl();
		lvl.init();
		lvl.loadMap(1);
		
		#if debug
		Settings.reset();
		#end
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
	
	public function levelComplete():Void {
		if (editor != null) {
			showEditor();
			return;
		}
		
		if (player != null) {
			var life = player.get(Life);
			startLife = new Life(true, life.maxHp);
			startLife.hp = life.hp;
				
			var p = player.get(Player);
			startPlayer = new Player();
			startPlayer.arrowType = p.arrowType;
			startPlayer.maxJump = p.maxJump;
			startPlayer.money = p.money;
		}
		
		currentLevel++;
		if (currentLevel > levelProgress && Lvl.exists(currentLevel)) {
			//autoSave = null;
			levelProgress = currentLevel;
			Settings.set({
				levelProgress: levelProgress
			});
			//setScale(1);
			playCompany();
			return;
		}
		
		trace("game over here");
	}
	
	public function gameComplete():Void {
		player.remove(player.get(Camera));
		player = null;
	}
	
	/*public function killPlayer(entity:Entity):Void {
		var p = entity.get(Player);
		save = new Player();
		save.arrowType = p.arrowType;
		save.maxJump = p.maxJump;
		//save.money = p.money;
		entity.remove(p);
	}*/
	
	public function newGame():Void {
		/*engine.clear();
		var text = Assets.blobs.player_json.toString();
		var json = haxe.Json.parse(text);
		var sp = new SpritesetParser();
		var frameSets = sp.parse(json);
		var objects = lvl.map.objects;

		var spawn = objects.players[0];
		if (spawn != null) {
			if (startLife == null) startLife = new Life(true, 30);
			if (startPlayer == null) startPlayer = new Player();

			var sLife = new Life(true, startLife.maxHp);
			sLife.hp = startLife.hp;

			var sPlayer = new Player();
			sPlayer.arrowType = startPlayer.arrowType;
			sPlayer.maxJump = startPlayer.maxJump;
			sPlayer.money = startPlayer.money;

			var p = engine.create([
				sPlayer,
				sLife,
				new Control(keys, pointers),
				new Camera(),
				new Body(),
				new Collision(),
				new Sprite(Assets.images.player, 32, 32, frameSets),
				new Position(spawn.x * lvl.tsize, spawn.y * lvl.tsize),
				new Size(Std.int(lvl.tsize/2), lvl.tsize - 1),
				new Speed(0, 0),
				new Gravity(0, 0.2),
				new Lifebar(),
				new Moneybar(),
				new Bow()
			]);

			player = p;
		}

		for (enemy in objects.enemys) {
			switch(enemy.type) {
			case "Imp":
				engine.create([
					new AI(),
					new Control(new Map(), new Map()),
					new Body(),
					new Collision(),
					new Sprite(Assets.images.Imp, 32, 32, frameSets),
					new Position(enemy.x * lvl.tsize, enemy.y * lvl.tsize),
					new Size(Std.int(lvl.tsize/2), 18),
					new Speed(0, 0),
					new Gravity(0, 0.2),
					new Life(true, 5)
				]);
			case "GreyMinotaur":
				engine.create([
					new AI(),
					new Control(new Map(), new Map()),
					new Body(2),
					new Collision(),
					new Sprite(Assets.images.GreyMinotaur, 48, 48, frameSets),
					new Position(enemy.x * lvl.tsize, enemy.y * lvl.tsize),
					new Size(Std.int(lvl.tsize/1.5), lvl.tsize),
					new Speed(0, 0),
					new Gravity(0, 0.2),
					new Life(true, 20)
				]);
			case "HunterOrc":
				engine.create([
					new AI(),
					new Control(new Map(), new Map()),
					new Body(),
					new Collision(),
					new Sprite(Assets.images.HunterOrc, 32, 32, frameSets),
					new Position(enemy.x * lvl.tsize, enemy.y * lvl.tsize),
					new Size(Std.int(lvl.tsize/2), lvl.tsize),
					new Speed(0, 0),
					new Gravity(0, 0.2),
					new Life(true, 15)
				]);
			}
		}

		for (chest in objects.chests) {
			engine.create([
				new Chest(chest.reward),
				new Body(),
				new Collision(),
				new Sprite(Assets.images.chest, 32, 40, 2),
				new Position(chest.x * lvl.tsize, chest.y * lvl.tsize - 8),
				new Size(32, 40),
			]);
		}*/
		
		updatePhase = engine.createPhase();
		renderPhase = engine.createPhase();
		
		updatePhase.add(new UpdateGravitation());
		updatePhase.add(new UpdateTileCollision());
		updatePhase.add(new UpdateBodyCollision(this));
		updatePhase.add(new UpdateArrowCollision());
		updatePhase.add(new UpdateCoinCollision());
		updatePhase.add(new UpdateHpCollision());
		updatePhase.add(new UpdatePlayerCollision(this));
		
		updatePhase.add(new UpdatePlayerAnimation());
		updatePhase.add(new UpdateAIAnimation());
		updatePhase.add(new UpdatePosition());
		
		updatePhase.add(new UpdateBodyPhysic());
		updatePhase.add(new UpdateArrows());
		updatePhase.add(new UpdateItems());
		updatePhase.add(new UpdateChests(this));
		updatePhase.add(new UpdatePlayerControl());
		updatePhase.add(new UpdateAIControl());
		updatePhase.add(new UpdatePlayerAim(this));
		updatePhase.add(new UpdateCamera());
		
		renderPhase.add(new RenderBG());
		//renderPhase.add(new RenderMapBG());
		renderPhase.add(new RenderMapTG());
		
		renderPhase.add(new RenderChests());
		renderPhase.add(new RenderBodies(this));
		renderPhase.add(new RenderAnimations());
		renderPhase.add(new RenderArrows());
		renderPhase.add(new RenderAimLine());
		
		renderPhase.add(new RenderPlayerLifebar());
		renderPhase.add(new RenderPlayerMoneybar());
		renderPhase.add(new RenderGameEnd(this));
	}
	
	override function onUpdate():Void {
		updatePhase.update(1/60);
	}
	
	override function onRender(frame:Canvas):Void {
		renderPhase.update(1/60);
	}
	
	override function onKeyDown(key:KeyCode):Void {
		if (key == KeyCode.Zero) {
			setScale(1);
			
		} else if (key == 189 || key == KeyCode.HyphenMinus) {
			if (scale > 1) setScale(scale - 1);
			
		} else if (key == 187 || key == KeyCode.Equals) {
			if (scale < 9) setScale(scale + 1);
			
		} else if (key == KeyCode.R) {
			newGame();
			
		} else if (key == KeyCode.Escape) {
			/*if (editor == null) {
				editor = new Editor();
				showEditor();
				editor.init();
				return;
			}*/
			if (editor != null) showEditor();
		}
	}
	
	public function showEditor():Void {
		player = null;
		editor.show();
	}
	
}
