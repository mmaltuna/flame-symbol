package entities;

import flixel.FlxSprite;
import flixel.group.FlxGroup;

class Entity extends FlxTypedGroup<FlxSprite> {

	public var x: Int;
	public var y: Int;
	public var sprite: FlxSprite;

	public function new(x: Int, y: Int) {
		super();

		this.x = x;
		this.y = y;

		sprite = new FlxSprite(x, y);
		add(sprite);
	}

	public function move(newX: Int, newY: Int) {
		var offsetX: Int = newX - Std.int(sprite.x);
		var offsetY: Int = newY - Std.int(sprite.y);

		for (member in members) {
			member.x += offsetX;
			member.y += offsetY;
		}

		x = newX;
		y = newY;
	}

}
