package states;

import flixel.FlxG;
//import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.tile.FlxTilemap;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxPath;
import openfl.Assets;
import haxe.Timer;

import entities.Unit;
import ui.BattleDialog;
import ui.BattleCursor;
import ui.BattleMenu;
import ui.ActionBattleDialog;
import ui.InventoryDialog;
import ui.CombatBattleDialog;
import ui.TerrainBattleDialog;
import ui.UnitBattleDialog;
import ui.BattleHud;

import utils.MapUtils;
import utils.Utils;
import utils.KeyboardUtils;
import utils.data.TilePoint;
import utils.data.Set;
import utils.Level;

import entities.Weapon;

class BattleState extends FlxTransitionableState {
	public var army1: Map<Int, Unit>;
	public var army2: Map<Int, Unit>;

	public var army: Map<Int, Unit>;	// reference to current army
	public var enemy: Map<Int, Unit>;	// reference to current enemy army

	public var armyIterator: Iterator<Unit>;	// iterator on current army's units

	public var cursor: BattleCursor;
	public var unitInfo: UnitBattleDialog;
	public var terrainInfo: TerrainBattleDialog;
	public var actionDialog: ActionBattleDialog;
	public var inventoryDialog: InventoryDialog;
	public var combatDialog: CombatBattleDialog;
	public var menu: BattleMenu;
	public var battleHud: BattleHud;

	public var level: Level;

	public var turn: Int;
	public var selectedUnit: Unit;

	public var activePath: FlxTypedGroup<FlxSprite>;
	public var movementRange: FlxTypedGroup<FlxSprite>;
	public var attackRange: FlxTypedGroup<FlxSprite>;
	public var pathOptions: utils.PathOptions;
	public var tilesInAttackRange: Set<TilePoint>;
	public var unitsInAttackRange: Array<Unit>;

	private var oldPos: TilePoint;

	private static var instance: BattleState;

	override public function create() {
		super.create();
		instance = this;

		transIn = new TransitionData(TransitionType.TILES, FlxColor.BLACK, 1.0);
		transOut = new TransitionData(TransitionType.TILES, FlxColor.BLACK, 1.0);

		turn = 1;
		oldPos = new TilePoint(0, 0);

		level = new Level("assets/data/stage1.tmx");
		add(level.backgroundTiles);

		FlxG.camera.bgColor = FlxColor.WHITE;
		FlxG.camera.setSize(level.width * ViewPort.tileSize, level.height * ViewPort.tileSize);

		movementRange = new FlxTypedGroup<FlxSprite>();
		add(movementRange);

		attackRange = new FlxTypedGroup<FlxSprite>();
		add(attackRange);

		activePath = new FlxTypedGroup<FlxSprite>();
		add(activePath);

		army1 = level.army1;
		army2 = level.army2;
		army = army1;
		enemy = army2;

		for (unit in army1)
			add(unit);

		for (unit in army2)
			add(unit);

		cursor = new BattleCursor(6, 4);
		add(cursor);

		unitInfo = new UnitBattleDialog(BattleDialog.QUADRANT_TOP_LEFT);
		unitInfo.hide();
		add(unitInfo);

		terrainInfo = new TerrainBattleDialog(BattleDialog.QUADRANT_BOTTOM_RIGHT);
		add(terrainInfo);

		actionDialog = new ActionBattleDialog(BattleDialog.QUADRANT_TOP_RIGHT, ["Attack", "Items", "Wait"]);
		add(actionDialog);

		inventoryDialog = new InventoryDialog(BattleDialog.QUADRANT_TOP_RIGHT);
		add(inventoryDialog);

		combatDialog = new CombatBattleDialog(BattleDialog.QUADRANT_TOP_RIGHT);
		add(combatDialog);

		menu = new BattleMenu();
		add(menu);

		battleHud = new BattleHud();
		add(battleHud);

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
		inventoryDialog.setOffset(x, y);
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
			Utils.clearSpriteGroup(attackRange);

			oldPos.x = selectedUnit.pos.x;
			oldPos.y = selectedUnit.pos.y;

			selectedUnit.hpBar.hide();
			selectedUnit.moveUnit(posX, posY, pathOptions.bestPaths.get(MapUtils.coordsToIndex(posX, posY)), onMoveEnd);

		} else if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_MOVED) {

			switch actionDialog.select() {
				case "Attack":
					selectedUnit.status = UnitStatus.STATUS_ON_SELECT_WEAPON;

					actionDialog.hide();
					inventoryDialog.setUnit(selectedUnit);
					updateAttackRange(cast(inventoryDialog.getHighlighted(), Weapon));
					inventoryDialog.show();

				case "Wait":
					onWait();

				case "Items":
					selectedUnit.status = UnitStatus.STATUS_ON_INVENTORY;

					actionDialog.hide();
					inventoryDialog.setUnit(selectedUnit);
					inventoryDialog.show();
			}

		} else if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_ATTACK_READY) {
			selectedUnit.status = UnitStatus.STATUS_ATTACKING;
			Utils.clearSpriteGroup(attackRange);

			onAttack(function() {
				cursor.show();
				battleHud.hide();
				onWait();
			});

		} else if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_ON_INVENTORY) {
			inventoryDialog.select();

		} else if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_ON_SELECT_WEAPON) {
			if (inventoryDialog.select()) {
				Utils.clearPointArray(cursor.activeTiles);
				combatDialog.atkUnit = selectedUnit;
				combatDialog.defUnit = unitsInAttackRange[0];

				for (enemy in unitsInAttackRange)
					cursor.activeTiles.push(new TilePoint(enemy.pos.x, enemy.pos.y));

				cursor.show(BattleCursor.STATUS_CHOOSE);

				actionDialog.hide();
				inventoryDialog.select();
				inventoryDialog.hide();
				combatDialog.show();
				selectedUnit.status = UnitStatus.STATUS_ATTACK_READY;
			}

		} else if (selectedUnit == null && army.exists(MapUtils.coordsToIndex(posX, posY)) && !menu.visible) {
			var unit: Unit = army.get(MapUtils.coordsToIndex(posX, posY));
			if (unit.select()) {
				selectedUnit = unit;
				terrainInfo.hide();
				unitInfo.hide();

				cursor.select();
				drawMovementRange();
			} else {
				cursor.hide();
				menu.show();
			}
		} else if (selectedUnit == null && !menu.visible) {
			cursor.hide();
			menu.show();
		} else if (menu.visible) {
			menu.select();
			cursor.show(BattleCursor.STATUS_FREE);
		}

		pos = null;
	}

	public function onCancel() {
		if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_SELECTED) {
			pathOptions.destroy();
			Utils.clearSpriteGroup(movementRange);
			Utils.clearSpriteGroup(activePath);
			Utils.clearSpriteGroup(attackRange);

			cursor.deselect();
			cursor.pos.x = oldPos.x;
			cursor.pos.y = oldPos.y;
			centerCameraOnCursor();

			selectedUnit.deselect();
			selectedUnit = null;

			terrainInfo.show();
			unitInfo.show();
		} else if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_MOVED) {
			Utils.clearSpriteGroup(activePath);
			Utils.clearSpriteGroup(attackRange);

			cursor.pos.x = oldPos.x;
			cursor.pos.y = oldPos.y;
			selectedUnit.moveUnit(oldPos.x, oldPos.y, null);
			selectedUnit.select();

			drawMovementRange();

			cursor.show(BattleCursor.STATUS_FREE);
			actionDialog.hide();
		} else if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_ATTACK_READY) {
			Utils.clearPointArray(cursor.activeTiles);
			Utils.clearSpriteGroup(attackRange);

			cursor.hide();
			combatDialog.hide();
			inventoryDialog.show();
			selectedUnit.status = UnitStatus.STATUS_ON_SELECT_WEAPON;
			updateAttackRange(selectedUnit.equippedWeapon);
		} else if (selectedUnit != null && (selectedUnit.status == UnitStatus.STATUS_ON_INVENTORY ||
			selectedUnit.status == UnitStatus.STATUS_ON_SELECT_WEAPON)) {

			updateAttackRange();
			if (unitsInAttackRange.length > 0)
				actionDialog.enableEntry("Attack");
			else
				actionDialog.disableEntry("Attack");

			inventoryDialog.hide();
			actionDialog.show();
			selectedUnit.status = UnitStatus.STATUS_MOVED;
		} else if (menu.visible) {
			menu.hide();
			cursor.show(BattleCursor.STATUS_FREE);
		}
	}

	public function onAttack(callback: Void -> Void) {
		var defUnit = enemy.get(MapUtils.pointToIndex(cursor.getSelectedActiveTile()));

		combatDialog.hide();
		cursor.hide();
		battleHud.setUnits(selectedUnit, defUnit);
		battleHud.show();

		selectedUnit.attack(defUnit, function() {
			Utils.clearSpriteGroup(attackRange);
			Utils.clearPointArray(cursor.activeTiles);

			cursor.pos.x = selectedUnit.pos.x;
			cursor.pos.y = selectedUnit.pos.y;

			if (!defUnit.isAlive()) {
				onDeath(defUnit, enemy);
			} else if (!selectedUnit.isAlive()) {
				onDeath(selectedUnit, army);
				selectedUnit = null;
			}

			Timer.delay(callback, 600);
		});
	}

	public function onWait() {
		var oldTile: Int = MapUtils.coordsToIndex(oldPos.x, oldPos.y);
		army.remove(oldTile);

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

		if (selectedUnit != null) {
			var newTile: Int = MapUtils.coordsToIndex(selectedUnit.pos.x, selectedUnit.pos.y);
			army.set(newTile, selectedUnit);

			selectedUnit.defenseBonus = MapUtils.getTerrainDefenseBonus(this, newTile);
			selectedUnit.avoidBonus = MapUtils.getTerrainAvoidBonus(this, newTile);
			selectedUnit.disable();
			selectedUnit = null;
		}
	}

	public function onDeath(unit: Unit, army: Map<Int, Unit>) {
		unit.die(function() {
			army.remove(MapUtils.pointToIndex(unit.pos));
			unit.destroy();
		});
	}

	public function onDialogNavigate(goingUp: Bool) {
		if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_MOVED) {
			if (goingUp)
				actionDialog.prevItem();
			else
				actionDialog.nextItem();

			if (actionDialog.select() == "Attack") {
				drawAttackRange();
			} else {
				Utils.clearSpriteGroup(attackRange);
			}
		}

		if (selectedUnit != null && (selectedUnit.status == UnitStatus.STATUS_ON_INVENTORY ||
			selectedUnit.status == UnitStatus.STATUS_ON_SELECT_WEAPON)) {
			if (goingUp)
				inventoryDialog.prevItem();
			else
				inventoryDialog.nextItem();

			if (selectedUnit.status == UnitStatus.STATUS_ON_SELECT_WEAPON) {
				var selectedWeapon: Weapon = cast(inventoryDialog.getHighlighted(), Weapon);
				updateAttackRange(selectedWeapon);
			}
		}

		if (menu.visible) {
			if (goingUp)
				menu.prevItem();
			else
				menu.nextItem();
		}
	}

	public function onCursorChoose() {
		if (selectedUnit != null && selectedUnit.status == UnitStatus.STATUS_ATTACK_READY) {
			combatDialog.defUnit = unitsInAttackRange[cursor.getSelectedTile()];
			combatDialog.refresh();
		}
	}

	public function onMoveEnd(path: FlxPath) {
		selectedUnit.moveElems(selectedUnit.pos.x, selectedUnit.pos.y);
		selectedUnit.hpBar.showBar();
		selectedUnit.status = UnitStatus.STATUS_MOVED;
		updateAttackRange();

		if (unitsInAttackRange.length > 0)
			actionDialog.enableEntry("Attack");
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
			var tileGraphic = new FlxSprite(tile.x * 16, tile.y * 16);
			tileGraphic.loadGraphic("assets/images/area-tiles-blue.png", true, 16, 16);

			var neighbour: TilePoint = new TilePoint(tile.x, tile.y - 1);
			var hasTileUp: Int = Utils.boolToInt(!pathOptions.nodes.contains(neighbour));
			neighbour.y = tile.y + 1;
			var hasTileDown: Int = Utils.boolToInt(!pathOptions.nodes.contains(neighbour));
			neighbour.x = tile.x - 1;
			neighbour.y = tile.y;
			var hasTileLeft: Int = Utils.boolToInt(!pathOptions.nodes.contains(neighbour));
			neighbour.x = tile.x + 1;
			var hasTileRight: Int = Utils.boolToInt(!pathOptions.nodes.contains(neighbour));

			var frameIndex: Int = 0;
			frameIndex |= hasTileRight;
			frameIndex |= hasTileLeft << 1;
			frameIndex |= hasTileDown << 2;
			frameIndex |= hasTileUp << 3;

			tileGraphic.animation.frameIndex = frameIndex;
			tileGraphic.alpha = 0.6;
			movementRange.add(tileGraphic);
		}

		getAttackRange(selectedUnit, pathOptions.nodes);
		drawAttackRange();
	}

	public function drawAttackRange() {
		Utils.clearSpriteGroup(attackRange);

		for (tile in tilesInAttackRange.getAll()) {
			var tileGraphic = new FlxSprite(tile.x * 16, tile.y * 16);
			tileGraphic.loadGraphic("assets/images/area-tiles-red.png", true, 16, 16);

			var neighbour: TilePoint = new TilePoint(tile.x, tile.y - 1);
			var hasTileUp: Int = Utils.boolToInt(!tilesInAttackRange.contains(neighbour));
			neighbour.y = tile.y + 1;
			var hasTileDown: Int = Utils.boolToInt(!tilesInAttackRange.contains(neighbour));
			neighbour.x = tile.x - 1;
			neighbour.y = tile.y;
			var hasTileLeft: Int = Utils.boolToInt(!tilesInAttackRange.contains(neighbour));
			neighbour.x = tile.x + 1;
			var hasTileRight: Int = Utils.boolToInt(!tilesInAttackRange.contains(neighbour));

			var frameIndex: Int = 0;
			frameIndex |= hasTileRight;
			frameIndex |= hasTileLeft << 1;
			frameIndex |= hasTileDown << 2;
			frameIndex |= hasTileUp << 3;

			tileGraphic.animation.frameIndex = frameIndex;
			tileGraphic.alpha = 0.6;
			attackRange.add(tileGraphic);
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

		transitionOut(function() {
			transitionIn();
		});
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

	public function getAttackRange(unit: Unit, reachableTiles: Set<TilePoint> = null, weapon: Weapon = null): Set<TilePoint> {
		if (tilesInAttackRange == null) {
			tilesInAttackRange = new Set<TilePoint>(TilePoint.equals);
		}

		if (reachableTiles == null) {
			reachableTiles = new Set<TilePoint>(TilePoint.equals);
			reachableTiles.add(unit.pos);
		}

		var atkRangeMax = 0;
		var atkRangeMin = 99;

		if (weapon == null) {
			for (item in unit.items) {
				if (Weapon.isWeapon(item)) {
					var w: Weapon = cast(item, Weapon);
					atkRangeMax = Utils.max(atkRangeMax, w.maxRange);
					atkRangeMin = Utils.min(atkRangeMin, w.minRange);
				}
			}
		} else {
			atkRangeMax = weapon.maxRange;
			atkRangeMin = weapon.minRange;
		}

		tilesInAttackRange.clear();

		for (tile in reachableTiles.getAll()) {
			for (i in -1 * atkRangeMax ... atkRangeMax + 1) {
				for (j in -1 * atkRangeMax ... atkRangeMax + 1) {
					var tileIndex = MapUtils.pointToIndex(tile);

					if (!army.exists(tileIndex) || TilePoint.equals(tile, selectedUnit.pos)) {
						var distance = Utils.abs(i) + Utils.abs(j);
						var newTile: TilePoint = new TilePoint(tile.x + i, tile.y + j);

						if (distance <= atkRangeMax && distance >= atkRangeMin &&
							newTile.x >= 0 && newTile.x < level.width && newTile.y >= 0 &&
							newTile.y < level.height && !reachableTiles.contains(newTile)) {

							tilesInAttackRange.add(newTile);
						}
					}
				}
			}
		}

		return tilesInAttackRange;
	}

	public function getUnitsInAttackRange(unit: Unit, weapon: Weapon = null): Array<Unit> {
		var tilesInRange = getAttackRange(unit, weapon);
		var enemiesInRange = new Array<Unit>();

		for (tile in tilesInRange.getAll()) {
			var index = MapUtils.coordsToIndex(Std.int(tile.x), Std.int(tile.y));
			if (enemy.exists(index))
				enemiesInRange.push(enemy.get(index));
		}

		return enemiesInRange;
	}

	public function updateAttackRange(weapon: Weapon = null) {
		unitsInAttackRange = getUnitsInAttackRange(selectedUnit, weapon);

		if (unitsInAttackRange.length > 0) {
			drawAttackRange();
		} else {
			Utils.clearSpriteGroup(attackRange);
		}
	}
}
