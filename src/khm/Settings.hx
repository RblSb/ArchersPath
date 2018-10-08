package khm;

import kha.Storage;
import kha.StorageFile;

private typedef Data = Dynamic;

class Settings {

	static inline var VERSION = 1;
	static var defaults:Data = {
		version: VERSION
	};

	public static function init(def:Data):Void {
		defaults = def;
		if (defaults.version == null) defaults.version = VERSION;
	}

	public static function read():Data {
		var file = Storage.defaultFile();
		var data:Data = file.readObject();
		data = checkData(data);
		return data;
	}

	public static function set(sets:Data):Void {
		var data = read();

		var fields = Reflect.fields(sets);
		for (field in fields) {
			var value = Reflect.field(sets, field);
			Reflect.setField(data, field, value);
		}

		write(data);
	}

	public static function write(data:Data):Void {
		var file:StorageFile = Storage.defaultFile();
		if (data.version == null) data.version = defaults.version;
		file.writeObject(data);
	}

	public static function reset():Void {
		write(defaults);
	}

	static inline function checkData(data:Data):Data {
		if (data != null && data.version == defaults.version) return data;
		return defaults;
	}

}
