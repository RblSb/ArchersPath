package editor;

import Types.IRect;
import Lvl.GameObject;

typedef History = {
	layer:Int,
	x:Int,
	y:Int,
	tile:Int,
	?obj:GameObject
}

typedef ArrHistory = {
	layer:Int,
	rect:IRect,
	tiles:Array<Array<Int>>
}
