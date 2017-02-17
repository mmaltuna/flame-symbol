package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.text.FlxText;

import entities.Unit;
import states.BattleState;
import utils.MapUtils;
import ui.ProgressBar;

class BattleHud extends FlxTypedGroup<FlxSprite> {
	public static inline var lineHeight: Int = 10;
	public static inline var margin: Int = 2;

	private var x: Int;
	private var y: Int;
	private var width: Int;
	private var height: Int;
	private var marginLeft: Int;
	private var marginTop: Int;
	private var battle: BattleState;

	public var background: FlxSprite;
	public var hpBar: ProgressBar;

	public function new() {
		super();

		battle = BattleState.getInstance();

		loadBackground("assets/images/bg-menu-1.png", 70, 18);

		x = marginLeft;
		y = marginTop;

		hpBar = new ProgressBar(x + 10, y + 7, 50, 0, 100);
		for (member in hpBar.members)
			add(member);

		hide();
	}

	override public function update(elapsed: Float) {
		hpBar.update(elapsed);
		super.update(elapsed);
	}

	public function loadBackground(path: String, width: Int, height: Int) {
		this.width = width;
		this.height = height;

		marginLeft = Std.int((ViewPort.width - width) / 2);
		marginTop = Std.int((ViewPort.height - height) / 2);

		if (background == null) {
			background = new FlxSprite(marginLeft, marginTop);
			add(background);
		}

		background.loadGraphic(path, width, height);
		background.replaceColor(FlxColor.WHITE, 0xCC000088);
	}

	private function updatePos() {
		var cameraX = Std.int(FlxG.camera.scroll.x);
		var cameraY = Std.int(FlxG.camera.scroll.y);

		marginLeft = cameraX + Std.int((ViewPort.width - width) / 2);
		marginTop = cameraY + Std.int((ViewPort.height - height) / 2);

		background.x = marginLeft;
		background.y = marginTop;

		hpBar.move(marginLeft + 10, marginTop + 7);
	}

	public function show() {
		updatePos();
		visible = true;
	}

	public function hide() {
		visible = false;
	}

	public function setUnit(unit: Unit) {
		hpBar.minValue = 0;
		hpBar.maxValue = unit.os.hp;
		hpBar.currentValue = unit.cs.hp;
		hpBar.updateParams();

		trace("hpBar.maxValue = " + hpBar.maxValue);
		trace("hpBar.currentValue = " + hpBar.currentValue);
		trace("hpBar.maxValue = " + hpBar.maxValue);
	}
}
