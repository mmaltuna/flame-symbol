package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.text.FlxText;

import states.BattleState;
import utils.MapUtils;

class BattleMenu extends FlxTypedGroup<FlxSprite> {
	public static inline var bgTileSize: Int = 8;
	public static inline var lineHeight: Int = 10;
	public static inline var margin: Int = 2;

	private var x: Int;
	private var y: Int;
	private var width: Int;
	private var height: Int;
	private var marginLeft: Int;
	private var marginTop: Int;
	private var battle: BattleState;

	public var overlay: FlxSprite;
	public var arrow: FlxSprite;
	public var background: FlxSprite;
	public var menuEntries: Array<FlxText>;

	public var menu: Array<BattleMenuEntry>;
	private var selected: Int;

	public function new() {
		super();

		battle = BattleState.getInstance();

		menu = [
			new BattleMenuEntry("End Turn", "end-turn")
		];

		overlay = new FlxSprite(0, 0);
		overlay.makeGraphic(ViewPort.width, ViewPort.height, 0x55000000);
		add(overlay);

		loadBackground("assets/images/bg-menu-1.png", 70, 18);

		x = marginLeft;
		y = marginTop;

		menuEntries = new Array<FlxText>();
		for (index in 0 ... menu.length) {
			var textItem = new FlxText(x + 14, y + marginTop + index * lineHeight, menu[index].entryLabel);
			textItem.setFormat("assets/fonts/pixelmix.ttf", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			menuEntries.push(textItem);
			add(textItem);
		}

		arrow = new FlxSprite(x, y);
		arrow.loadGraphic("assets/images/arrow12.png", true, 12, 12);
		arrow.animation.add("default", [0, 1], 2, true);
		arrow.animation.play("default");
		add(arrow);

		highlight(0);
		visible = false;
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

	override public function update(elapsed: Float) {
		if (FlxG.keys.justPressed.Z) {
			var posX = battle.cursor.pos.x;
			var posY = battle.cursor.pos.y;

			if (battle.selectedUnit == null && !this.visible &&
				!battle.army.exists(MapUtils.coordsToIndex(posX, posY)) &&
				!battle.enemy.exists(MapUtils.coordsToIndex(posX, posY))) {

				updatePos();
				battle.cursor.hide();
				this.show();
			} else if (battle.selectedUnit == null && this.visible) {
				this.select();
				this.hide();
				battle.cursor.show(BattleCursor.STATUS_FREE);
			}
		}

		if (FlxG.keys.justPressed.X && this.visible) {
			this.hide();
			battle.cursor.show(BattleCursor.STATUS_FREE);
		}

		super.update(elapsed);
	}

	private function updatePos() {
		var cameraX = Std.int(FlxG.camera.scroll.x);
		var cameraY = Std.int(FlxG.camera.scroll.y);

		overlay.x = cameraX;
		overlay.y = cameraY;

		marginLeft = cameraX + Std.int((ViewPort.width - width) / 2);
		marginTop = cameraY + Std.int((ViewPort.height - height) / 2);
		highlight(selected);

		for (i in 0 ... menuEntries.length) {
			menuEntries[i].x = marginLeft + 14;
			menuEntries[i].y = marginTop + margin + i * lineHeight;
		}

		background.x = marginLeft;
		background.y = marginTop;
	}

	private function highlight(pos: Int) {
		if (pos >= 0 && pos < menu.length) {
			arrow.x = marginLeft + 2;
			arrow.y = marginTop + margin + pos * lineHeight;
			selected = pos;
		}
	}

	public function nextItem() {
		var newPos = (selected + 1) % menu.length;
		highlight(newPos);
	}

	public function prevItem() {
		var newPos = selected - 1;
		if (newPos == -1)
			newPos = menu.length - 1;

		highlight(newPos);
	}

	public function show() {
		visible = true;
	}

	public function hide() {
		visible = false;
	}

	public function select() {
		switch menu[selected].entryValue {
			case "end-turn":
				battle.onTurnEnd();
		}
	}
}

class BattleMenuEntry {
	public var entryLabel: String;
	public var entryValue: String;

	public function new(label: String, value: String) {
		entryLabel = label;
		entryValue = value;
	}
}
