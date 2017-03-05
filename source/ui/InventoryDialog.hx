package ui;

import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.util.FlxColor;

import entities.Item;
import entities.Weapon;
import entities.Unit;
import utils.Utils;

class InventoryDialog extends BattleDialog {

	private static inline var lineHeight: Int = 16;
	private static inline var marginTop: Int = 4;
	private static inline var marginTopText: Int = 2;
	private static inline var marginLeft: Int = 22;

	private static var bgPath: String = "assets/images/ui/bg-inventory.png";

	private var unit: Unit;
	private var selected: Int;
	private var itemNames: Array<FlxText>;
	private var remainingUses: Array<FlxText>;
	private var enabledEntries: Array<Bool>;
	private var items: Array<Item>;
	private var arrow: FlxSprite;

	private var width: Int;
	private var height: Int;

	public function new(quadrant: Int) {
		width = 96;
		height = 72;

		super(width, height, 4, quadrant);

		itemNames = new Array<FlxText>();
		remainingUses = new Array<FlxText>();
		enabledEntries = new Array<Bool>();
		items = new Array<Item>();

		loadBackground(bgPath, width, height);

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
		if (pos >= 0 && pos < items.length) {
			if (arrow.facing == FlxObject.RIGHT)
				arrow.x = vpX + x - 12;
			else
				arrow.x = vpX + x + width + 2;
			arrow.y = vpY + y + marginTop + pos * lineHeight + 1;
			selected = pos;
		}
	}

	public function nextItem() {
		var newPos = (selected + 1) % items.length;
		highlight(newPos);
	}

	public function prevItem() {
		var newPos = selected - 1;
		if (newPos == -1)
			newPos = items.length - 1;

		highlight(newPos);
	}

	public function select(): Bool {
		var item: Item = items[selected];
		if (enabledEntries[selected]) {
			unit.useItem(item);
			refresh();
			highlight(0);
		}

		return enabledEntries[selected];
	}

	public function getHighlighted(): Item {
		return items[selected];
	}

	override public function show() {
		highlight(0);
		super.show();
	}

	public function setUnit(unit: Unit) {
		this.unit = unit;
		refresh();
		highlight(0);
	}

	public function refresh() {
		var i: Int = 0;
		while (i < members.length) {
			var member = members[i];
			if (member != background && member != arrow) {
				members.splice(i, 1);
			} else {
				i++;
			}
		}

		Utils.clearTextArray(itemNames);
		Utils.clearTextArray(remainingUses);
		enabledEntries.splice(0, enabledEntries.length);
		items.splice(0, items.length);

		var index = 0;
		for (item in unit.items) {
			if (unit.status == UnitStatus.STATUS_ON_INVENTORY ||
				(unit.status == UnitStatus.STATUS_ON_SELECT_WEAPON && Weapon.isWeapon(item) &&
				battle.getUnitsInAttackRange(unit, cast(item, Weapon)).length > 0)) {

				enabledEntries.push(true);

				var itemText = new FlxText(bgX + marginLeft, bgY + marginTopText + index * lineHeight, item.name);
				itemText.setFormat("assets/fonts/font-pixel-7.ttf", 16, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				itemNames.push(itemText);
				add(itemText);

				var usesText = new FlxText(bgX + marginLeft + 56, bgY + marginTopText + index * lineHeight,
					12, Std.string(item.currentUses));
				usesText.alignment = FlxTextAlign.RIGHT;
				usesText.setFormat("assets/fonts/font-pixel-7.ttf", 16, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				remainingUses.push(usesText);
				add(usesText);

				item.move(Std.int(bgX + 4), Std.int(bgY + marginTop + index * lineHeight));
				for (member in item.members) {
					add(member);
				}
				items.push(item);

				index++;
			}
		}
	}
}
