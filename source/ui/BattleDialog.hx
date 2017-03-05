package ui;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

import states.BattleState;
import utils.Utils;
import utils.MapUtils;

class BattleDialog extends FlxTypedGroup<FlxSprite> {
	public static inline var QUADRANT_TOP_LEFT: Int = 0;
	public static inline var QUADRANT_TOP_RIGHT: Int = 1;
	public static inline var QUADRANT_BOTTOM_LEFT: Int = 2;
	public static inline var QUADRANT_BOTTOM_RIGHT: Int = 3;

	public static inline var bgTileSize: Int = 8;

	public var bgColour: Int = 0xCC000088;

	public var bgWidth: Int;
	public var bgHeight: Int;
	public var x: Int;
	public var y: Int;
	public var originalX: Int;
	public var originalY: Int;
	public var vpX: Int;
	public var vpY: Int;
	public var bgX: Int;
	public var bgY: Int;

	public var quadrant: Int;
	public var background: FlxSprite;

	private var battle: BattleState;
	private var w: Int;
	private var h: Int;
	private var m: Int;

	public function new(w: Int, h: Int, m: Int, quadrant: Int) {
		super();

		battle = BattleState.getInstance();

		bgWidth = w;
		bgHeight = h;

		this.m = m;
		this.quadrant = quadrant;

		vpX = 0;
		vpY = 0;
		x = 0;
		y = 0;
		bgX = 0;
		bgY = 0;

		moveToQuadrant(this.quadrant);

		originalX = x;
		originalY = y;
	}

	public function loadBackground(path: String, width: Int, height: Int) {}

	public function covers(posX: Float, posY: Float): Bool {
		var a1x = posX * ViewPort.tileSize;
		var a1y = posY * ViewPort.tileSize;
		var d1x = (posX + 1) * ViewPort.tileSize;
		var d1y = (posY + 1) * ViewPort.tileSize;

		var a2x = vpX + originalX;
		var a2y = vpY + originalY;
		var d2x = a2x + 2 * m + bgWidth;
		var d2y = a2y + 2 * m + bgHeight;

		var sx = Math.max(0, Math.min(d1x, d2x) - Math.max(a1x, a2x));
		var sy = Math.max(0, Math.min(d1y, d2y) - Math.max(a1y, a2y));

		return sx > 0 && sy > 0;
	}

	public function moveToQuadrant(quadrant: Int) {
		switch quadrant {
			case QUADRANT_TOP_LEFT:
				x = m;
				y = m;
			case QUADRANT_TOP_RIGHT:
				x = ViewPort.width - bgWidth - m;
				y = m;
			case QUADRANT_BOTTOM_LEFT:
				x = m;
				y = ViewPort.height - bgHeight - m;
			case QUADRANT_BOTTOM_RIGHT:
				x = ViewPort.width - bgWidth - m;
				y = ViewPort.height - bgHeight - m;
		}

		move(vpX + x, vpY + y);
	}

	public function move(x: Int, y: Int) {
		var offsetX = x - bgX;
		var offsetY = y - bgY;

		for (s in members) {
			s.x += offsetX;
			s.y += offsetY;
		}

		bgX = x;
		bgY = y;
	}

	public function setSize(w: Int, h: Int) {
		this.w = w;
		this.h = h;
	}

	public function restorePosition() {
		moveToQuadrant(quadrant);
	}

	public function setOffset(offsetX: Int, offsetY: Int) {
		vpX = offsetX;
		vpY = offsetY;
		move(vpX + x, vpY + y);
	}

	public function show() {
		visible = true;
	}

	public function hide() {
		visible = false;
	}
}
