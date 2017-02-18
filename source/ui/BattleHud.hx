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
	public var hpBar1: ProgressBar;
	public var hpBar2: ProgressBar;
	public var name1: FlxText;
	public var name2: FlxText;

	public function new() {
		super();

		battle = BattleState.getInstance();

		loadBackground("assets/images/bg-battlehud.png", 140, 24);

		x = marginLeft;
		y = marginTop;

		hpBar1 = new ProgressBar(x + 10, y + 14, 40, 0, 100, 2);
		for (member in hpBar1.members)
			add(member);

		hpBar2 = new ProgressBar(x + 80, y + 14, 40, 0, 100, 2);
		for (member in hpBar2.members)
			add(member);

		name1 = new FlxText(x + 10, y + 3, 50, Std.string("name1"));
		name1.setFormat("assets/fonts/pixelmini.ttf", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		name1.alignment = FlxTextAlign.CENTER;
		add(name1);

		name2 = new FlxText(x + 80, y + 3, 50, Std.string("name2"));
		name2.setFormat("assets/fonts/pixelmini.ttf", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		name2.alignment = FlxTextAlign.CENTER;
		add(name2);

		hide();
	}

	override public function update(elapsed: Float) {
		hpBar1.update(elapsed);
		hpBar2.update(elapsed);
		super.update(elapsed);
	}

	public function loadBackground(path: String, width: Int, height: Int) {
		this.width = width;
		this.height = height;

		marginLeft = Std.int((ViewPort.width - width) / 2);
		marginTop = Std.int(3 * (ViewPort.height - height) / 4);

		if (background == null) {
			background = new FlxSprite(marginLeft, marginTop);
			add(background);
		}

		background.loadGraphic(path, width, height);
		background.replaceColor(FlxColor.BLUE, 0xCC000088);
		background.replaceColor(FlxColor.RED, 0xCC880000);
	}

	private function updatePos() {
		var cameraX = Std.int(FlxG.camera.scroll.x);
		var cameraY = Std.int(FlxG.camera.scroll.y);

		marginLeft = cameraX + Std.int((ViewPort.width - width) / 2);
		marginTop = cameraY + Std.int(3 * (ViewPort.height - height) / 4);

		var offsetX = marginLeft - background.x;
		var offsetY = marginTop - background.y;

		for (member in members) {
			member.x += offsetX;
			member.y += offsetY;
		}

		background.x = marginLeft;
		background.y = marginTop;
	}

	public function show() {
		updatePos();
		visible = true;
	}

	public function hide() {
		visible = false;
	}

	public function setUnits(unit1: Unit, unit2: Unit) {
		name1.text = unit1.name;
		hpBar1.minValue = 0;
		hpBar1.maxValue = unit1.os.hp;
		hpBar1.currentValue = unit1.cs.hp;
		hpBar1.updateParams();

		name2.text = unit2.name;
		hpBar2.minValue = 0;
		hpBar2.maxValue = unit2.os.hp;
		hpBar2.currentValue = unit2.cs.hp;
		hpBar2.updateParams();
	}
}
