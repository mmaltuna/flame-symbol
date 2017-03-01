package ui;

import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.util.FlxColor;

import entities.Unit;

class CombatBattleDialog extends BattleDialog {

	public var atkUnit: Unit;
	public var defUnit: Unit;

	private var atkName: FlxText;
	private var atkHP: FlxText;
	private var atkDmg: FlxText;
	private var atkHitR: FlxText;
	private var atkCrtR: FlxText;

	private var defName: FlxText;
	private var defHP: FlxText;
	private var defDmg: FlxText;
	private var defHitR: FlxText;
	private var defCrtR: FlxText;

	public function new(quadrant: Int) {
		var width = 72;
		var height = 72;
		var lineHeight = 10;
		var nameLineHeight = 14;
		var statsWidth = 26;
		var labelsWidth = 20;
		var paddingLeft = -4;
		var paddingTop = 2;

		atkUnit = null;
		defUnit = null;

		super(Std.int(width / 8), Std.int(height / 8), 4, quadrant);

		loadBackground("assets/images/bg-combat-dialog.png", 72, 72);

		atkName = new FlxText(x, y + paddingTop, width, "");
		atkName.alignment = FlxTextAlign.CENTER;
		atkName.setFormat("assets/fonts/pixelmix.ttf", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(atkName);

		atkHP = new FlxText(x + labelsWidth + statsWidth + paddingLeft, y + nameLineHeight, statsWidth, "");
		atkHP.alignment = FlxTextAlign.RIGHT;
		atkHP.setFormat("assets/fonts/pixelmini.ttf", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(atkHP);

		atkDmg = new FlxText(x + labelsWidth + statsWidth + 2 + paddingLeft, y + nameLineHeight + lineHeight, statsWidth - 2, "");
		atkDmg.alignment = FlxTextAlign.RIGHT;
		atkDmg.setFormat("assets/fonts/pixelmini.ttf", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(atkDmg);

		atkHitR = new FlxText(x + labelsWidth + statsWidth + paddingLeft, y + nameLineHeight + 2 * lineHeight, statsWidth, "");
		atkHitR.alignment = FlxTextAlign.RIGHT;
		atkHitR.setFormat("assets/fonts/pixelmini.ttf", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(atkHitR);

		atkCrtR = new FlxText(x + labelsWidth + statsWidth + paddingLeft, y + nameLineHeight + 3 * lineHeight, statsWidth, "");
		atkCrtR.alignment = FlxTextAlign.RIGHT;
		atkCrtR.setFormat("assets/fonts/pixelmini.ttf", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(atkCrtR);

		defName = new FlxText(x, y + nameLineHeight + 4 * lineHeight, width, "");
		defName.alignment = FlxTextAlign.CENTER;
		defName.setFormat("assets/fonts/pixelmix.ttf", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(defName);

		defHP = new FlxText(x, y + nameLineHeight, statsWidth, "");
		defHP.alignment = FlxTextAlign.RIGHT;
		defHP.setFormat("assets/fonts/pixelmini.ttf", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(defHP);

		defDmg = new FlxText(x, y + nameLineHeight +  lineHeight, statsWidth, "");
		defDmg.alignment = FlxTextAlign.RIGHT;
		defDmg.setFormat("assets/fonts/pixelmini.ttf", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(defDmg);

		defHitR = new FlxText(x, y + nameLineHeight + 2 * lineHeight, statsWidth, "");
		defHitR.alignment = FlxTextAlign.RIGHT;
		defHitR.setFormat("assets/fonts/pixelmini.ttf", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(defHitR);

		defCrtR = new FlxText(x, y + nameLineHeight + 3 * lineHeight, statsWidth, "");
		defCrtR.alignment = FlxTextAlign.RIGHT;
		defCrtR.setFormat("assets/fonts/pixelmini.ttf", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(defCrtR);

		var labelHP = new FlxText(x + statsWidth, y + nameLineHeight, labelsWidth, "HP");
		labelHP.setFormat("assets/fonts/pixelmini.ttf", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		labelHP.alignment = FlxTextAlign.CENTER;
		add(labelHP);

		var labelDmg = new FlxText(x + statsWidth, y + nameLineHeight + lineHeight, labelsWidth + 2, "Dmg");
		labelDmg.setFormat("assets/fonts/pixelmini.ttf", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		labelDmg.alignment = FlxTextAlign.CENTER;
		add(labelDmg);

		var labelHitRate = new FlxText(x + statsWidth, y + nameLineHeight + 2 * lineHeight, labelsWidth, "Hit");
		labelHitRate.setFormat("assets/fonts/pixelmini.ttf", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		labelHitRate.alignment = FlxTextAlign.CENTER;
		add(labelHitRate);

		var labelCritRate = new FlxText(x + statsWidth, y + nameLineHeight + 3 * lineHeight, labelsWidth, "Crt");
		labelCritRate.setFormat("assets/fonts/pixelmini.ttf", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		labelCritRate.alignment = FlxTextAlign.CENTER;
		add(labelCritRate);

		hide();
	}

	override public function loadBackground(path: String, width: Int, height: Int) {
		background = new FlxSprite(bgX, bgY);
		background.loadGraphic(path, width, height);
		background.replaceColor(FlxColor.RED, 0xCC880000);
		background.replaceColor(FlxColor.BLUE, bgColour);
		add(background);
	}

	override public function show() {
		if (atkUnit != null && defUnit != null) {
			refresh();
			super.show();
		}
	}

	override public function update(elapsed: Float) {
		if (covers(battle.cursor.pos.x, battle.cursor.pos.y))
			moveToQuadrant(BattleDialog.QUADRANT_TOP_LEFT);
		else
			restorePosition();

		super.update(elapsed);
	}

	public function refresh() {
		atkName.text = atkUnit.name;
		atkHP.text = Std.string(atkUnit.cs.hp);
		atkDmg.text = Std.string(atkUnit.calcPhysicalDamage(defUnit));
		atkHitR.text = Std.string(atkUnit.getAccuracy(defUnit));
		atkCrtR.text = Std.string(0);

		defName.text = defUnit.name;
		defHP.text = Std.string(defUnit.cs.hp);
		if (defUnit.canCounterattack(atkUnit)) {
			defDmg.text = Std.string(defUnit.calcPhysicalDamage(atkUnit));
			defHitR.text = Std.string(defUnit.getAccuracy(atkUnit));
			defCrtR.text = Std.string(0);
		} else {
			defDmg.text = "-";
			defHitR.text = "-";
			defCrtR.text = "-";
		}

		if (atkUnit.repeatsAttack(defUnit)) {
			atkDmg.text += "x2";
		} else if (defUnit.canCounterattack(atkUnit) && defUnit.repeatsAttack(atkUnit)) {
			defDmg.text += "x2";
		}
	}
}
