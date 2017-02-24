package entities;

import flixel.FlxSprite;
import flixel.group.FlxGroup;

class Entity extends FlxTypedGroup<FlxSprite> {

	private var x: Int;
	private var y: Int;
	private var sprite: FlxSprite;

	public function new(x: Int, y: Int) {
		super();

		this.x = x;
		this.y = y;

		sprite = new FlxSprite(x, y);
		add(sprite);
	}

	public function move(newX: Int, newY: Int) {
		var offsetX: Int = newX - x;
		var offsetY: Int = newY - y;

		for (member in members) {
			member.x += offsetX;
			member.y += offsetY;
		}

		x = newX;
		y = newY;
	}

}
