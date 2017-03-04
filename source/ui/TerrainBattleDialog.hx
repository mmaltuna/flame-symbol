package ui;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.util.FlxColor;

import utils.MapUtils;
import utils.tiled.TiledPropertySet;

class TerrainBattleDialog extends BattleDialog {
	private var terrainName: FlxText;
	private var terrainDef: FlxText;
	private var terrainAvd: FlxText;

	public function new(quadrant: Int) {
		super(40, 32, 4, quadrant);

		loadBackground("assets/images/ui/bg-terrain-dialog.png", 40, 34);

		terrainName = new FlxText(x + 4, y - 2, "");
		terrainName.setFormat("assets/fonts/font-pixel-7.ttf", 16, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(terrainName);

		terrainDef = new FlxText(x + 4, y + 7, "Def: 0");
		terrainDef.setFormat("assets/fonts/font-pixel-7.ttf", 16, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(terrainDef);

		terrainAvd = new FlxText(x + 4, y + 16, "Avd: 0");
		terrainAvd.setFormat("assets/fonts/font-pixel-7.ttf", 16, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(terrainAvd);
	}

	override public function update(elapsed: Float) {
		setTerrain(MapUtils.pointToIndex(battle.cursor.pos));

		if (covers(battle.cursor.pos.x, battle.cursor.pos.y))
			moveToQuadrant(BattleDialog.QUADRANT_TOP_RIGHT);
		else
			restorePosition();

		super.update(elapsed);
	}

	override public function loadBackground(path: String, width: Int, height: Int) {
		background = new FlxSprite(bgX, bgY);
		background.loadGraphic(path, width, height);
		background.replaceColor(FlxColor.WHITE, bgColour);
		add(background);
	}

	public function setTerrain(tileIndex: Int) {
		var properties: TiledPropertySet = MapUtils.getTopTileProperties(battle, tileIndex);
		terrainName.text = properties.get("displayName");
		terrainDef.text = "Def: " + properties.get("defense");
		terrainAvd.text = "Avd: " + properties.get("avoid");
	}
}
