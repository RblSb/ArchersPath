package game;

private typedef Spriteset = {
	sets:Array<{
		id:String,
		?from:Int,
		?to:Int,
		?frames:Array<Int>,
	}>
};

class SpritesetParser {
	
	public function new() {}
	
	public function parse(json:Spriteset):Map<String, Array<Int>> {
		var map = new Map<String, Array<Int>>();
		
		for (set in json.sets) {
			map[set.id] = [];
			if (set.frames != null) {
				map[set.id] = set.frames;
				continue;
			}
			var from = set.from == null ? 0 : set.from;
			var to = set.to == null ? 0 : set.to + 1;
			map[set.id] = [for (i in from...to) i];
		}
		return map;
	}
	
}
