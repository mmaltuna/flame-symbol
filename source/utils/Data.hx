package utils;

import sys.io.File;
import haxe.Json;

class Data {

	private static var instance: Data = null;

	public var weaponList: Dynamic;
	public var itemList: Dynamic;

	private function new() {
		weaponList = loadJSONFromFile("assets/data/weapons.json");
	}

	public static function getInstance(): Data {
		if (instance == null)
			instance = new Data();

		return instance;
	}

	public static function loadJSONFromFile(path: String): Dynamic {
		return Json.parse(File.getContent(path));
	}
}
