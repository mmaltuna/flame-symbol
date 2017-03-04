package utils;

import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.group.FlxGroup;

import utils.data.TilePoint;

class Utils {

	public static function max(a: Int, b: Int): Int {
		return a >= b ? a : b;
	}

	public static function min(a: Int, b: Int): Int {
		return a <= b ? a : b;
	}

	public static function sign(a: Int): Int {
		return a >= 0 ? 1 : -1;
	}

	public static function sign0(a: Int): Int {
		return a >= 0 ? (a > 0 ? 1 : 0) : -1;
	}

	public static function abs(a: Int): Int {
		return a < 0 ? -a : a;
	}

	public static function boolToInt(b: Bool): Int {
		return b ? 1 : 0;
	}

	public static function clearSpriteGroup(group: FlxTypedGroup<FlxSprite>) {
		group.forEach(function(member) { member.destroy(); });
	}

	public static function clearSpriteArray(array: Array<FlxSprite>) {
		while (array.length > 0) {
			var sprite: FlxSprite = array.pop();
			sprite.destroy();
		}
	}

	public static function clearTextArray(array: Array<FlxText>) {
		while (array.length > 0) {
			var sprite: FlxText = array.pop();
			sprite.destroy();
		}
	}

	public static function clearPointArray(array: Array<TilePoint>) {
		while (array.length > 0) {
			var point: TilePoint = array.pop();
			point = null;
		}
	}
}
