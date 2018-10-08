package game;

import khm.Macro.EnumAbstractTools;

@:enum
abstract Slope(Int) from Int to Int {

	var NONE = -1;
	var FULL = 0;
	var HALF_B = 1;
	var HALF_T = 2;
	var HALF_L = 3;
	var HALF_R = 4;
	var HALF_BL = 5;
	var HALF_BR = 6;
	var HALF_TL = 7;
	var HALF_TR = 8;
	var QUARTER_BL = 9;
	var QUARTER_BR = 10;
	var QUARTER_TL = 11;
	var QUARTER_TR = 12;

	public inline function new(type:Slope) this = type;

	@:from public static function fromString(type:String):Slope {
		return new Slope(EnumAbstractTools.fromString(type, Slope));
	}

	public static function rotate(type:Slope):Slope {
		return new Slope(switch (type) {
			case HALF_B: HALF_L;
			case HALF_T: HALF_R;
			case HALF_L: HALF_T;
			case HALF_R: HALF_B;
			case HALF_BL: HALF_TL;
			case HALF_BR: HALF_BL;
			case HALF_TL: HALF_TR;
			case HALF_TR: HALF_BR;
			case QUARTER_BL: QUARTER_TL;
			case QUARTER_BR: QUARTER_BL;
			case QUARTER_TL: QUARTER_TR;
			case QUARTER_TR: QUARTER_BR;
			default: type;
		});
	}

	public static function flipX(type:Slope):Slope {
		return new Slope(switch (type) {
			case HALF_L: HALF_R;
			case HALF_R: HALF_L;
			case HALF_BL: HALF_BR;
			case HALF_BR: HALF_BL;
			case HALF_TL: HALF_TR;
			case HALF_TR: HALF_TL;
			case QUARTER_BL: QUARTER_BR;
			case QUARTER_BR: QUARTER_BL;
			case QUARTER_TL: QUARTER_TR;
			case QUARTER_TR: QUARTER_TL;
			default: type;
		});
	}

	public static function flipY(type:Slope):Slope {
		return new Slope(switch (type) {
			case HALF_B: HALF_T;
			case HALF_T: HALF_B;
			case HALF_BL: HALF_TL;
			case HALF_BR: HALF_TR;
			case HALF_TL: HALF_BL;
			case HALF_TR: HALF_BR;
			case QUARTER_BL: QUARTER_TL;
			case QUARTER_BR: QUARTER_TR;
			case QUARTER_TL: QUARTER_BL;
			case QUARTER_TR: QUARTER_BR;
			default: type;
		});
	}

}
