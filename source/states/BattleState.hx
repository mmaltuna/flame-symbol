package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.tile.FlxTilemap;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxPath;
import openfl.Assets;

import entities.Unit;
import ui.BattleDialog;
import ui.BattleCursor;
import ui.BattleMenu;
import ui.ActionBattleDialog;
import ui.CombatBattleDialog;
import ui.TerrainBattleDialog;
import ui.UnitBattleDialog;

import utils.MapUtils;
import utils.Utils;
import utils.KeyboardUtils;
import utils.data.TilePoint;
import utils.Level;

import entities.Weapon;

class BattleState extends FlxState {
	public var army1: Map<Int, Unit>;
	public var army2: Map<Int, Unit>;

	public var army: Map<Int, Unit>;	// reference to current army
	public var enemy: Map<Int, Unit>;	// reference to current enemy army

	public var armyIterator: Iterator<Unit>;	// iterator on current army's units

	public var cursor: BattleCursor;
	public var unitInfo: UnitBattleDialog;
	public var terrainInfo: TerrainBattleDialog;
	public var actionDialog: ActionBattleDialog;
	public var combatDialog: CombatBattleDialog;
	public var menu: BattleMenu;

	public var background: FlxTilemap;
	public var tileMap: FlxTilemap;
	public var level: Level;

	public var turn: Int;
	public var selectedUnit: Unit;

	public var activePath: FlxTypedGroup<FlxSprite>;
	public var movementRange: FlxTypedGroup<FlxSprite>;
	public var attackRange: FlxTypedGroup<FlxSprite>;
	public var pathOptions: utils.PathOptions;
	public var tilesInAttackRange: Array<TilePoint>;
	public var unitsInAttackRange: Array<Unit>;

	private var oldPos: TilePoint;

	private static var instance: BattleState;

	override public function create() {
		super.create();
		instance = this;

		FlxG.camera.bgColor = FlxColor.WHITE;

		turn = 1;
		oldPos = new TilePoint(0, 0);

		level = new Level("assets/data/stage1.tmx");
		add(level.backgroundTiles);

		MapUtils.mapWidth = level.width;
		MapUtils.mapHeight = level.height;

		FlxG.camera.setSize(level.width * ViewPort.tileSize, level.height * ViewPort.tileSize);

		movementRange = new FlxTypedGroup<FlxSprite>();
		add(movementRange);

		attackRange = new FlxTypedGroup<FlxSprite>();
		add(attackRange);

		activePath = new FlxTypedGroup<FlxSprite>();
		add(activePath);

		army1 = new Map<Int, Unit>();
		army2 = new Map<Int, Unit>();

		for (objectGroup in level.objectGroups) {
			var selectedArmy: Map<Int, Unit> = null;
			var selectedColour: FlxColor = FlxColor.TRANSPARENT;

			if (objectGroup.name == "Army 1") {
				selectedArmy = army1;
				selectedColour = FlxColor.BLUE;
			} else if (objectGroup.name == "Army 2") {
				selectedArmy = army2;
				selectedColour = FlxColor.RED;
			}

			for (object in objectGroup.objects) {
				var unit: Unit = Unit.createUnit(object, selectedColour);
				selectedArmy.set(MapUtils.pointToIndex(unit.pos), unit);
				add(unit);
			}
		}

		/*var unit1: Unit = new Unit(7, 3, 1);
		unit1.os.hp = 26;
		unit1.os.str = 7;
		unit1.os.mgc = 1;
		unit1.os.skl = 9;
		unit1.os.spd = 8;
		unit1.os.lck = 3;
		unit1.os.def = 5;
		unit1.os.res = 2;
		unit1.os.mov = 6;
		unit1.name = "Roger";
		unit1.type = "Great Lord";
		unit1.resetStats();
		army1.set(MapUtils.coordsToIndex(unit1.pos.x, unit1.pos.y), unit1);
		add(unit1);*/

		var ironSword = new Weapon(0, 0);
		ironSword.hitRate = 90;
		ironSword.might = 5;
		ironSword.weight = 5;
		ironSword.minRange = 1;
		ironSword.maxRange = 1;

		var ironBow = new Weapon(0, 0);
		ironBow.hitRate = 85;
		ironBow.might = 6;
		ironBow.weight = 5;
		ironBow.minRange = 2;
		ironBow.maxRange = 2;

		/*unit1.items.push(ironSword);
		unit1.equippedWeapon = ironSword;

		var unit2: Unit = new Unit(4, 4, 2);
		unit2.os.hp = 30;
		unit2.os.str = 7;
		unit2.os.mgc = 1;
		unit2.os.skl = 6;
		unit2.os.spd = 8;
		unit2.os.lck = 3;
		unit2.os.def = 5;
		unit2.os.res = 2;
		unit2.os.mov = 5;
		unit2.name = "Pferv";
		unit2.type = "General";
		unit2.resetStats();
		army2.set(MapUtils.coordsToIndex(unit2.pos.x, unit2.pos.y), unit2);
		add(unit2);

		unit2.items.push(ironSword);
		unit2.equippedWeapon = ironSword;

		var unit3: Unit = new Unit(5, 5, 2);
		unit3.os.hp = 23;
		unit3.os.str = 7;
		unit3.os.mgc = 1;
		unit3.os.skl = 10;
		unit3.os.spd = 8;
		unit3.os.lck = 3;
		unit3.os.def = 5;
		unit3.os.res = 2;
		unit3.os.mov = 7;
		unit3.name = "Peferovu";
		unit3.type = "Archer";
		unit3.atkRangeMin = 2;
		unit3.atkRangeMax = 2;
		unit3.resetStats();
		army2.set(MapUtils.coordsToIndex(unit3.pos.x, unit3.pos.y), unit3);
		add(unit3);

		unit3.items.push(ironBow);
		unit3.equippedWeapon = ironBow;*/

		army = army1;
		enemy = army2;

		cursor = new BattleCursor(6, 4);
		add(cursor);

		unitInfo = new UnitBattleDialog(BattleDialog.QUADRANT_TOP_LEFT);
		unitInfo.hide();
		add(unitInfo);

		terrainInfo = new TerrainBattleDialog(BattleDialog.QUADRANT_BOTTOM_RIGHT);
		add(terrainInfo);

		actionDialog = new ActionBattleDialog(BattleDialog.QUADRANT_TOP_RIGHT, ["Attack", "Wait", "Cancel"]);
		add(actionDialog);

		combatDialog = new CombatBattleDialog(BattleDialog.QUADRANT_TOP_RIGHT);
		add(combatDialog);

		menu = new BattleMenu();
		add(menu);

		cursorOnFirstUnit();
	}

	override public function update(elapsed: Float) {
		// Select or open menu
		if (FlxG.keys.justPressed.Z) {
			onSelect(cursor.pos.x, cursor.pos.y);
		}

		// Cancel current selection
		if (FlxG.keys.justPressed.X) {
			onCancel();
		}

		// Select next available unit
		if (FlxG.keys.justPressed.A) {
			onNextUnit();
		}

		// Move the cursor in dialogs
		if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN) {
			onDialogNavigate(FlxG.keys.justPressed.UP);
		}

		if (hasTurnEnded())
			onTurnEnd();

		super.update(elapsed);
	}

	public static function getInstance(): BattleState {
		return instance;
	}

	public function moveViewport(x: Int, y: Int) {
		var offsetX = Std.int(x - FlxG.camera.scroll.x);
		var offsetY = Std.int(y - FlxG.camera.scroll.y);

		unitInfo.setOffset(x, y);
		terrainInfo.setOffset(x, y);
		actionDialog.setOffset(x, y);
		combatDialog.setOffset(x, y);

		FlxG.camera.scroll.x = x;
		FlxG.camera.scroll.y = y;
	}

	public function centerCamera(posX: Int, posY: Int) {
		var cameraPosX: Int = posX - Std.int(ViewPort.widthInTiles / 2);
		var cameraPosY: Int = posY - Std.int(ViewPort.heightInTiles / 2);

		cameraPosX = Utils.min(level.width - ViewPort.widthInTiles, Utils.max(0, cameraPosX));
		cameraPosY = Utils.min(level.height - ViewPort.heightInTiles, Utils.max(0, cameraPosY));

		moveViewport(cameraPosX * ViewPort.tileSize, cameraPosY * ViewPort.tileSize);
	}

	public function centerCameraOnCursor() {
		centerCamera(cursor.pos.x, cursor.pos.y);

		oldPos.x = cursor.pos.x;
		oldPos.y = cursor.pos.y;
	}

	public function onSelect(posX: Int, posY: Int) {
		var pos = new TilePoint(posX, posY);
		if (selectedUnit == null) {
			oldPos.x = cursor.pos.x;
			oldPos.y = cursor.pos.y;
		}

		if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_SELECTED &&
			isTileFree(posX, posY, selectedUnit) && pathOptions.nodes.contains(pos)) {

			Utils.clearSpriteGroup(activePath);
			Utils.clearSpriteGroup(movementRange);

			oldPos.x = selectedUnit.pos.x;
			oldPos.y = selectedUnit.pos.y;

			selectedUnit.status = UnitStatus.STATUS_MOVING;
			selectedUnit.move(posX, posY, pathOptions.bestPaths.get(MapUtils.coordsToIndex(posX, posY)), onMoveEnd);

		} else if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_MOVED) {

			switch actionDialog.select() {
				case "Attack":
					Utils.clearPointArray(cursor.activeTiles);
					combatDialog.atkUnit = selectedUnit;
					combatDialog.defUnit = unitsInAttackRange[0];

					for (enemy in unitsInAttackRange)
						cursor.activeTiles.push(new TilePoint(enemy.pos.x, enemy.pos.y));

					cursor.show(BattleCursor.STATUS_CHOOSE);

					actionDialog.hide();
					combatDialog.show();
					selectedUnit.status = UnitStatus.STATUS_ATTACKING;

				case "Wait":
					onWait();

				case "Cancel":
					onCancel();
			}

		} else if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_ATTACKING) {
			onAttack();
			onWait();

		} else if (selectedUnit == null && army.exists(MapUtils.coordsToIndex(posX, posY))) {
			terrainInfo.hide();
			unitInfo.hide();

			selectedUnit = army.get(MapUtils.coordsToIndex(posX, posY));
			if (selectedUnit != null && selectedUnit.select()) {
				cursor.select();
				drawMovementRange();
			}
		}

		pos = null;
	}

	public function onCancel() {
		if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_SELECTED) {
			pathOptions.destroy();
			Utils.clearSpriteGroup(movementRange);
			Utils.clearSpriteGroup(activePath);

			cursor.deselect();
			cursor.pos.x = oldPos.x;
			cursor.pos.y = oldPos.y;
			centerCameraOnCursor();

			selectedUnit.status = UnitStatus.STATUS_AVAILABLE;
			selectedUnit = null;

			terrainInfo.show();
			unitInfo.show();
		} else if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_MOVED) {
			Utils.clearSpriteGroup(activePath);
			Utils.clearSpriteGroup(attackRange);

			cursor.pos.x = oldPos.x;
			cursor.pos.y = oldPos.y;
			selectedUnit.move(oldPos.x, oldPos.y, null);
			selectedUnit.status = UnitStatus.STATUS_SELECTED;

			drawMovementRange();

			cursor.show(BattleCursor.STATUS_FREE);
			actionDialog.hide();
		} else if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_ATTACKING) {
			Utils.clearPointArray(cursor.activeTiles);
			Utils.clearSpriteGroup(attackRange);

			cursor.hide();
			combatDialog.hide();
			actionDialog.show();
			selectedUnit.status = UnitStatus.STATUS_MOVED;
		}
	}

	public function onAttack() {
		combatDialog.hide();

		var defUnit = enemy.get(MapUtils.pointToIndex(cursor.getSelectedActiveTile()));
		selectedUnit.attack(defUnit);

		Utils.clearSpriteGroup(attackRange);
		Utils.clearPointArray(cursor.activeTiles);

		cursor.pos.x = selectedUnit.pos.x;
		cursor.pos.y = selectedUnit.pos.y;

		if (defUnit.cs.hp == 0) {
			onDeath(defUnit, enemy);
		} else if (selectedUnit.cs.hp == 0) {
			onDeath(selectedUnit, army);
		}
	}

	public function onWait() {
		var oldTile: Int = MapUtils.coordsToIndex(oldPos.x, oldPos.y);
		var newTile: Int = MapUtils.coordsToIndex(selectedUnit.pos.x, selectedUnit.pos.y);

		army.remove(oldTile);
		army.set(newTile, selectedUnit);

		selectedUnit.defenseBonus = MapUtils.getTerrainDefenseBonus(this, newTile);
		selectedUnit.avoidBonus = MapUtils.getTerrainAvoidBonus(this, newTile);
		selectedUnit.disable();
		selectedUnit = null;

		pathOptions.destroy();
		pathOptions = null;

		Utils.clearSpriteGroup(movementRange);
		Utils.clearSpriteGroup(activePath);
		Utils.clearSpriteGroup(attackRange);

		cursor.deselect();
		cursor.show(BattleCursor.STATUS_FREE);
		actionDialog.hide();
		terrainInfo.show();
		unitInfo.show();
	}

	public function onDeath(unit: Unit, army: Map<Int, Unit>) {
		army.remove(MapUtils.pointToIndex(unit.pos));
		unit.destroy();
	}

	public function onDialogNavigate(goingUp: Bool) {
		if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_MOVED) {
			if (goingUp)
				actionDialog.prevItem();
			else
				actionDialog.nextItem();

			if (actionDialog.select() == "Attack")
				drawAttackRange();
			else
				Utils.clearSpriteGroup(attackRange);
		}

		if (menu.visible) {
			if (goingUp)
				menu.prevItem();
			else
				menu.nextItem();
		}
	}

	public function onCursorChoose() {
		if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_ATTACKING) {
			combatDialog.defUnit = unitsInAttackRange[cursor.getSelectedTile()];
			combatDialog.refresh();
		}
	}

	public function onMoveEnd(path: FlxPath) {
		selectedUnit.status = UnitStatus.STATUS_MOVED;
		unitsInAttackRange = getUnitsInAttackRange(selectedUnit);

		if (unitsInAttackRange.length > 0) {
			actionDialog.enableEntry("Attack");
			drawAttackRange();
		}
		else
			actionDialog.disableEntry("Attack");

		actionDialog.show();
		cursor.hide();
	}

	public function onNextUnit() {
		var unit: Unit = null;
		while (unit == null || unit.status != UnitStatus.STATUS_AVAILABLE) {
			unit = getNextUnitInArmy();
		}

		if (unit != null) {
			cursor.pos.x = unit.pos.x;
			cursor.pos.y = unit.pos.y;
			centerCameraOnCursor();
		}
	}

	public function drawMovementRange() {
		Utils.clearSpriteGroup(movementRange);

		pathOptions = MapUtils.findPathOptions(this, selectedUnit);
		for (tile in pathOptions.nodes.getAll()) {
			movementRange.add(new FlxSprite(tile.x * 16 + 1, tile.y * 16 + 1).makeGraphic(14, 14, 0x33FFFF00));
		}
	}

	public function drawAttackRange() {
		Utils.clearSpriteGroup(attackRange);

		for (tile in tilesInAttackRange) {
			attackRange.add(new FlxSprite(Std.int(tile.x) * ViewPort.tileSize + 1,
				Std.int(tile.y) * ViewPort.tileSize + 1)
				.makeGraphic(14, 14, 0x55FF0000));
		}
	}

	public function isTileFree(posX: Int, posY: Int, unit: Unit): Bool {
		return !army.exists(MapUtils.coordsToIndex(posX, posY)) || (posX == unit.pos.x && posY == unit.pos.y);
	}

	public function hasTurnEnded(): Bool {
		var ended = true;
		var units = army.iterator();

		while (ended && units.hasNext()) {
			ended = ended && units.next().status == UnitStatus.STATUS_DONE;
		}

		return ended;
	}

	public function onTurnEnd() {
		// Enable all units in army
		for (unit in army) {
			//unit.status = UnitStatus.STATUS_AVAILABLE;
			unit.enable();
		}

		// Swaps armies
		if (army == army1) {
			army = army2;
			enemy = army1;
		} else {
			army = army1;
			enemy = army2;
		}

		// Increment turn number
		if (army == army1) {
			turn++;
		}

		cursorOnFirstUnit();
	}

	public function cursorOnFirstUnit() {
		var unit: Unit = getFirstUnitInArmy();
		if (unit != null) {
			cursor.pos.x = unit.pos.x;
			cursor.pos.y = unit.pos.y;
			centerCameraOnCursor();
		}
	}

	public function getFirstUnitInArmy(): Unit {
		var unit: Unit = null;
		armyIterator = army.iterator();

		if (armyIterator.hasNext())
			unit = armyIterator.next();

		return unit;
	}

	public function getNextUnitInArmy(): Unit {
		var unit: Unit = null;

		if (armyIterator.hasNext())
			unit = armyIterator.next();
		else
			unit = getFirstUnitInArmy();

		return unit;
	}

	public function getAttackRange(unit: Unit): Array<TilePoint> {
		if (tilesInAttackRange == null)
			tilesInAttackRange = new Array<TilePoint>();

		Utils.clearPointArray(tilesInAttackRange);
		Utils.clearSpriteGroup(attackRange);

		for (i in -unit.atkRangeMax ... unit.atkRangeMax + 1) {
			for (j in -unit.atkRangeMax ... unit.atkRangeMax + 1) {
				var distance = Utils.abs(i) + Utils.abs(j);
				var newX = unit.pos.x + i;
				var newY = unit.pos.y + j;

				if (distance <= unit.atkRangeMax && distance >= unit.atkRangeMin &&
					newX >= 0 && newX < level.width && newY >= 0 && newY < level.height) {

					tilesInAttackRange.push(new TilePoint(newX, newY));
				}
			}
		}

		return tilesInAttackRange;
	}

	public function getUnitsInAttackRange(unit: Unit): Array<Unit> {
		var tilesInRange = getAttackRange(unit);
		var enemiesInRange = new Array<Unit>();

		for (tile in tilesInRange) {
			var index = MapUtils.coordsToIndex(Std.int(tile.x), Std.int(tile.y));
			if (enemy.exists(index))
				enemiesInRange.push(enemy.get(index));
		}

		return enemiesInRange;
	}
}
