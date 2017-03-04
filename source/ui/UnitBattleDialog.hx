package ui;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSprite;

import entities.Unit;
import utils.MapUtils;
import utils.Utils;
import states.BattleState;

class UnitBattleDialog extends BattleDialog {

	private var unitName: FlxText;
	private var unitHP: FlxText;
	private var unitMaxHP: FlxText;

	public function new(quadrant: Int) {
		super(56, 32, 4, quadrant);

		loadBackground("assets/images/ui/bg-unit-dialog.png", 56, 32);

		unitName = new FlxText(x + 4, y, "Unit name");
		unitName.setFormat("assets/fonts/font-pixel-7.ttf", 16, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(unitName);

		unitHP = new FlxText(x + 4, y + 11, 12, "0");
		unitHP.alignment = FlxTextAlign.RIGHT;
		unitHP.setFormat("assets/fonts/font-pixel-7.ttf", 16, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(unitHP);

		unitMaxHP = new FlxText(x + 12, y + 11, 30, "/0 HP");
		unitMaxHP.wordWrap = false;
		unitMaxHP.alignment = FlxTextAlign.RIGHT;
		unitMaxHP.setFormat("assets/fonts/font-pixel-7.ttf", 16, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(unitMaxHP);
	}

	override public function loadBackground(path: String, width: Int, height: Int) {
		background = new FlxSprite(bgX, bgY);
		background.loadGraphic(path, width, height);
		background.replaceColor(FlxColor.WHITE, bgColour);
		add(background);
	}

	public function setUnit(unit: Unit) {
		unitName.text = unit.name;
		unitHP.text = Std.string(unit.cs.hp);
		unitMaxHP.text = "/" + Std.string(unit.os.hp) + " HP";
	}

	override public function update(elapsed: Float) {
		var indexCoords = MapUtils.coordsToIndex(battle.cursor.pos.x, battle.cursor.pos.y);

		if (covers(battle.cursor.pos.x, battle.cursor.pos.y))
			moveToQuadrant(BattleDialog.QUADRANT_BOTTOM_LEFT);

		if (battle.selectedUnit == null && battle.army.exists(indexCoords)) {
			setUnit(battle.army.get(indexCoords));
			show();
		} else if (battle.selectedUnit == null && battle.enemy.exists(indexCoords)) {
			setUnit(battle.enemy.get(indexCoords));
			show();
		} else if (battle.selectedUnit == null) {
			hide();
		}

		if (!covers(battle.cursor.pos.x, battle.cursor.pos.y))
			restorePosition();

		super.update(elapsed);
	}
}
