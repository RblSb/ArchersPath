package game;

import khm.tilemap.Tileset.TSTransformation;
import khm.tilemap.Tileset.TSProps;
import khm.tilemap.Tilemap.GameObject;
import khm.tilemap.Data;

typedef TileProps = {
	?id:Int,
	?collide:Bool,
	?type:Slope
}

class CustomData {

	public static function init():Void {
		Data.initProps = function(tile:TSProps):Void {
			if (tile.collide == null) tile.collide = false;
			if (tile.type == null) tile.type = tile.collide ? "FULL" : "NONE";
			else tile.type = Slope.fromString(cast tile.type);
		}

		Data.onTransformedProps = function(tile:Props, type:TSTransformation):Void {
			switch (type) {
				case Rotate90: tile.type = Slope.rotate(tile.type);
				case Rotate180: for (i in 0...2) tile.type = Slope.rotate(tile.type);
				case Rotate270: for (i in 0...3) tile.type = Slope.rotate(tile.type);
				case FlipX: tile.type = Slope.flipX(tile.type);
				case FlipY: tile.type = Slope.flipY(tile.type);
			}
		}

		Data.objectTemplate = function(layer:Int, tile:Int):GameObject {
			return switch (layer) {
				case 0: null;
				case 1:
					switch (tile) {
						default: null;
					}
				case 2:
					switch (tile) {
						case 1: obj("player", layer);
						case 2: obj("end", layer);
						case 3: obj("death", layer);
						case 4: obj("chest", layer, {reward: "LIFE"});
						case 5: obj("enemy", layer, {type: "Imp"});
						default: null;
					}
				default: null;
			}
		}
	}

	static inline function obj(type:String, layer:Int, ?data:Any):GameObject {
		return {type: type, layer: layer, x: -1, y: -1, data: data};
	}

}
