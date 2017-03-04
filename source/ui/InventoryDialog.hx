package ui;

import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.util.FlxColor;

import entities.Item;
import utils.Utils;

class InventoryDialog extends BattleDialog {

	private static inline var lineHeight: Int = 16;
	private static inline var marginTop: Int = 4;
	private static inline var marginTopText: Int = 2;
	private static inline var marginLeft: Int = 22;

	private static var bgPath: String = "assets/images/ui/bg-inventory.png";

	private var selected: Int;
	private var items: Array<Item>;
	private var itemNames: Array<FlxText>;
	private var remainingUses: Array<FlxText>;
	private var enabledEntries: Array<String>;
	private var arrow: FlxSprite;

	private var width: Int;
	private var height: Int;

	public function new(quadrant: Int, items: Array<Item>) {
		width = 96;
		height = 72;

		super(width, height, 4, quadrant);

		itemNames = new Array<FlxText>();
		remainingUses = new Array<FlxText>();
		enabledEntries = new Array<String>();

		loadBackground(bgPath, width, height);
		setItems(items);

		arrow = new FlxSprite(x, y);
		arrow.loadGraphic("assets/images/ui/arrow.png", true, 12, 12);
		arrow.animation.add("default", [0, 1], 2, true);
		arrow.animation.play("default");
		arrow.setFacingFlip(FlxObject.RIGHT, false, false);
		arrow.setFacingFlip(FlxObject.LEFT, true, false);
		add(arrow);

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
			arrow.y = vpY + y + marginTop + pos * lineHeight + 1;
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

		while (index < itemNames.length) {
			if (itemNames[index].text == entry && !itemNames[index].alive) {
				entryIndex = index;
				itemNames[index].revive();
				enabledEntries.insert(index, entry);
			}

			if (index > entryIndex) {
				itemNames[index].y += lineHeight;
			}

			index++;
		}

		highlight(0);
	}

	public function disableEntry(entry: String) {
		var entryIndex = 99;
		var index = 0;

		while (index < itemNames.length) {
			if (itemNames[index].text == entry && itemNames[index].alive) {
				entryIndex = index;
				itemNames[index].kill();
				enabledEntries.remove(entry);
			}

			if (index > entryIndex) {
				itemNames[index].y -= lineHeight;
			}

			index++;
		}

		highlight(0);
	}

	public function setItems(items: Array<Item>) {
		var i: Int = 0;
		while (i < members.length) {
			var member = members[i];
			if (member != background && member != arrow) {
				members.splice(i, 1);
			} else {
				i++;
			}
		}

		this.items = items;
		Utils.clearTextArray(itemNames);
		Utils.clearTextArray(remainingUses);
		enabledEntries.splice(0, enabledEntries.length);

		var bgX = background.x;
		var bgY = background.y;

		var index = 0;
		for (item in items) {
			enabledEntries.push(item.type);

			var itemText = new FlxText(bgX + marginLeft, bgY + marginTopText + index * lineHeight, item.name);
			itemText.setFormat("assets/fonts/font-pixel-7.ttf", 16, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			itemNames.push(itemText);
			add(itemText);

			var usesText = new FlxText(bgX + marginLeft + 56, bgY + marginTopText + index * lineHeight,
				Std.string(item.currentUses));
			usesText.setFormat("assets/fonts/font-pixel-7.ttf", 16, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			usesText.alignment = FlxTextAlign.RIGHT;
			remainingUses.push(usesText);
			add(usesText);

			item.sprite.x = Std.int(bgX + 4);
			item.sprite.y = Std.int(bgY + marginTop + index * lineHeight);
			item.visible = true;
			add(item.sprite);

			index++;
		}

		highlight(0);
	}
}
