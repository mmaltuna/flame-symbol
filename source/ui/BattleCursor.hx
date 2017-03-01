package ui;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.tile.FlxTilemap;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.Assets;

import entities.Unit;
import states.BattleState;

import utils.MapUtils;
import utils.Utils;
import utils.KeyboardUtils;
import utils.data.TilePoint;

class BattleCursor extends FlxSprite {
	public static inline var STATUS_HIDDEN: Int = 0;
	public static inline var STATUS_FREE: Int = 1;
	public static inline var STATUS_CHOOSE: Int = 2;

	private static inline var moveViewportThreshold: Int = 2;

	public var battle: BattleState;
	public var pos: TilePoint;
	public var hasMoved: Bool;
	public var frozen: Bool;
	public var status: Int;
	public var activeTiles: Array<TilePoint>;

	private var keyboard: KeyboardUtils;
	private var selectedTile: Int;

	public function new(posX: Int, posY: Int) {
		super(posX * ViewPort.tileSize - 2, posY * ViewPort.tileSize - 2);
		loadGraphic("assets/images/cursor20.png", true, 20, 20);
		animation.add("idle", [0, 1], 2, true);
		deselect();

		battle = BattleState.getInstance();
		pos = new TilePoint(posX, posY);
		hasMoved = false;
		frozen = false;
		status = STATUS_FREE;

		selectedTile = 0;
		activeTiles = new Array<TilePoint>();

		keyboard = KeyboardUtils.getInstance();
	}

	override public function update(elapsed: Float) {
		var up: Bool = keyboard.isPressed(KeyboardUtils.KEY_UP);
		var down: Bool = keyboard.isPressed(KeyboardUtils.KEY_DOWN);
		var left: Bool = keyboard.isPressed(KeyboardUtils.KEY_LEFT);
		var right: Bool = keyboard.isPressed(KeyboardUtils.KEY_RIGHT);

		if (status == STATUS_FREE) {
			var newPos = new TilePoint(pos.x, pos.y);

			// Move the cursor
			if (up || down || left || right) {
				if (up && !down) {
					newPos.y = Utils.max(0, pos.y - 1);
				}

				if (down && !up) {
					newPos.y = Utils.min(battle.level.height - 1, pos.y + 1);
				}

				if (left && !right) {
					newPos.x = Utils.max(0, pos.x - 1);
				}

				if (right && !left) {
					newPos.x = Utils.min(battle.level.width - 1, pos.x + 1);
				}
			}

			hasMoved = newPos.x != pos.x || newPos.y != pos.y;

			// Determine if it's necessary to move the viewport
			if (hasMoved) {
				var moveViewport: Bool = false;
				var cameraPosX = Std.int(FlxG.camera.scroll.x / ViewPort.tileSize);
				var cameraPosY = Std.int(FlxG.camera.scroll.y / ViewPort.tileSize);

				if (newPos.x != pos.x && newPos.x - cameraPosX >= (ViewPort.widthInTiles - moveViewportThreshold)) {
					cameraPosX = Utils.min(battle.level.width - ViewPort.widthInTiles, cameraPosX + 1);
					moveViewport = true;
				}

				if (newPos.x != pos.x && newPos.x - cameraPosX < moveViewportThreshold) {
					cameraPosX = Utils.max(0, cameraPosX - 1);
					moveViewport = true;
				}

				if (newPos.y != pos.y && newPos.y - cameraPosY >= (ViewPort.heightInTiles - moveViewportThreshold)) {
					cameraPosY = Utils.min(battle.level.height - ViewPort.heightInTiles, cameraPosY + 1);
					moveViewport = true;
				}

				if (newPos.y != pos.y && newPos.y - cameraPosY < moveViewportThreshold) {
					cameraPosY = Utils.max(0, cameraPosY - 1);
					moveViewport = true;
				}

				if (moveViewport) {
					battle.moveViewport(cameraPosX * ViewPort.tileSize, cameraPosY * ViewPort.tileSize);
				}
			}

			// Calculate unit movement
			if (hasMoved && battle.selectedUnit != null && battle.pathOptions != null) {
				var path = battle.pathOptions.bestPaths.get(MapUtils.pointToIndex(newPos));
				MapUtils.drawPath(path, battle);
			}

			pos.x = newPos.x;
			pos.y = newPos.y;
			newPos = null;
		}

		// Cursor movement over a set of available tiles
		if (status == STATUS_CHOOSE && activeTiles != null && activeTiles.length > 0) {
			if (up || right) {
				selectedTile = (selectedTile + 1) % activeTiles.length;
			}

			if (left || down) {
				selectedTile--;
				if (selectedTile == -1)
					selectedTile = activeTiles.length - 1;
			}

			pos = activeTiles[selectedTile];

			if (up || down || left || right)
				battle.onCursorChoose();
		}

		x = pos.x * ViewPort.tileSize - 2;
		y = pos.y * ViewPort.tileSize - 2;

		keyboard.update();
		super.update(elapsed);
	}

	public function show(status: Int = STATUS_FREE) {
		frozen = false;
		visible = true;
		selectedTile = 0;
		this.status = status;
	}

	public function hide() {
		frozen = true;
		visible = false;
		status = STATUS_HIDDEN;
	}

	public function select() {
		animation.finish();
	}

	public function deselect() {
		animation.play("idle");
	}

	public function getSelectedActiveTile(): TilePoint {
		return activeTiles[selectedTile];
	}

	public function getSelectedTile(): Int {
		return selectedTile;
	}
}
