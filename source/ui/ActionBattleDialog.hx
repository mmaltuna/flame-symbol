package ui;

import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.util.FlxColor;

class ActionBattleDialog extends BattleDialog {

	private static inline var lineHeight: Int = 10;
	private static inline var marginTop: Int = 4;
	private static inline var marginLeft: Int = 4;

	private static var bgPaths: Map<Int, String> = [
		2 => "assets/images/ui/bg-action-menu-2.png",
		3 => "assets/images/ui/bg-action-menu-3.png"
	];

	private var selected: Int;
	private var menuItems: Array<FlxText>;
	private var enabledEntries: Array<String>;
	private var arrow: FlxSprite;

	private var width: Int;
	private var height: Int;
	private var rows: Int;

	public function new(quadrant: Int, menu: Array<String>) {
		width = 42;
		height = 8 + menu.length * 11;
		rows = menu.length;

		super(width, height, 4, quadrant);

		menuItems = new Array<FlxText>();
		enabledEntries = new Array<String>();

		loadBackground(bgPaths.get(menu.length), 42, 42);

		var index = 0;
		for (item in menu) {
			enabledEntries.push(item);

			var itemText = new FlxText(x + marginLeft, y + index * lineHeight, item);
			itemText.setFormat("assets/fonts/font-pixel-7.ttf", 16, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			menuItems.push(itemText);
			add(itemText);
			index++;
		}

		arrow = new FlxSprite(x, y);
		arrow.loadGraphic("assets/images/ui/arrow.png", true, 12, 12);
		arrow.animation.add("default", [0, 1], 2, true);
		arrow.animation.play("default");
		arrow.setFacingFlip(FlxObject.RIGHT, false, false);
		arrow.setFacingFlip(FlxObject.LEFT, true, false);
		add(arrow);

		highlight(0);
		visible = false;
	}

	override public function loadBackground(path: String, width: Int, height: Int) {
		if (background == null) {
			background = new FlxSprite(bgX, bgY);
			add(background);
		}

		background.loadGraphic(path, width, height);
		background.replaceColor(FlxColor.WHITE, bgColour);
	}

	override public function update(elapsed: Float) {
		if (covers(battle.cursor.pos.x, battle.cursor.pos.y)) {
			arrow.facing = FlxObject.LEFT;
			moveToQuadrant(BattleDialog.QUADRANT_TOP_LEFT);
		} else {
			arrow.facing = FlxObject.RIGHT;
			restorePosition();
		}

		super.update(elapsed);
	}

	private function highlight(pos: Int) {
		if (pos >= 0 && pos < enabledEntries.length) {
			if (arrow.facing == FlxObject.RIGHT)
				arrow.x = vpX + x - 12;
			else
				arrow.x = vpX + x + width + 2;
			arrow.y = vpY + y + marginTop + pos * lineHeight - 1;
			selected = pos;
		}
	}

	public function nextItem() {
		var newPos = (selected + 1) % enabledEntries.length;
		highlight(newPos);
	}

	public function prevItem() {
		var newPos = selected - 1;
		if (newPos == -1)
			newPos = enabledEntries.length - 1;

		highlight(newPos);
	}

	public function select(): String {
		return enabledEntries[selected];
	}

	override public function show() {
		highlight(0);
		selected = 0;
		super.show();
	}

	public function enableEntry(entry: String) {
		var entryIndex = 99;
		var index = 0;

		while (index < menuItems.length) {
			if (menuItems[index].text == entry && !menuItems[index].alive) {
				entryIndex = index;
				menuItems[index].revive();
				enabledEntries.insert(index, entry);
				rows = enabledEntries.length;

				if (bgPaths.exists(rows)) {
					loadBackground(bgPaths.get(rows), 56, 12 + lineHeight * rows);
				}
			}

			if (index > entryIndex) {
				menuItems[index].y += lineHeight;
			}

			index++;
		}

		highlight(0);
	}

	public function disableEntry(entry: String) {
		var entryIndex = 99;
		var index = 0;

		while (index < menuItems.length) {
			if (menuItems[index].text == entry && menuItems[index].alive) {
				entryIndex = index;
				menuItems[index].kill();
				enabledEntries.remove(entry);
				rows = enabledEntries.length;

				if (bgPaths.exists(rows)) {
					loadBackground(bgPaths.get(rows), 56, 12 + lineHeight * rows);
				}
			}

			if (index > entryIndex) {
				menuItems[index].y -= lineHeight;
			}

			index++;
		}

		highlight(0);
	}
}
