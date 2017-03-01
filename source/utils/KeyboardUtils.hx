package utils;

import flash.events.KeyboardEvent;

import flixel.FlxG;
import flixel.input.FlxInput;

import utils.data.Set;

class KeyboardUtils {

	private var keyMap: Map<Int, Int>;
	private var forbiddenKeys: Set<Int>;
	private static var instance: KeyboardUtils = null;

	public static inline var KEY_LEFT: Int = 37;
	public static inline var KEY_UP: Int = 38;
	public static inline var KEY_RIGHT: Int = 39;
	public static inline var KEY_DOWN: Int = 40;

	public static var REPEAT_THRESHOLD: Int = 5;

	private function new() {
		keyMap = new Map<Int, Int>();
		forbiddenKeys = new Set<Int>(function(a: Int, b: Int) {
			return a == b;
		});
		forbiddenKeys.add(15);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
	}

	public static function getInstance() {
		if (instance == null)
			instance = new KeyboardUtils();

		return instance;
	}

	public function update() {
		for (key in keyMap.keys()) {
			if (!forbiddenKeys.contains(key) && FlxG.keys.checkStatus(key, FlxInputState.PRESSED)) {
				keyMap.set(key, keyMap.get(key) + 1);
			}
		}
	}

	private function onKeyDown(event: KeyboardEvent) {
		if (!keyMap.exists(event.keyCode)) {
			keyMap.set(event.keyCode, 0);
		}
	}

	private function onKeyUp(event: KeyboardEvent) {
		if (keyMap.exists(event.keyCode)) {
			keyMap.remove(event.keyCode);
		}

	}

	public function isPressed(key: Int): Bool {
		if (FlxG.keys.checkStatus(key, FlxInputState.JUST_PRESSED))
			return true;

		if (FlxG.keys.checkStatus(key, FlxInputState.JUST_RELEASED) || FlxG.keys.checkStatus(key, FlxInputState.RELEASED))
			return false;

		if (!keyMap.exists(key))
			return false;

		if (keyMap.get(key) >= REPEAT_THRESHOLD)
			return true;

		return false;
	}
}
