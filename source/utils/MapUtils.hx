package utils;

import flixel.FlxSprite;
import flixel.tile.FlxTilemap;

import entities.Unit;
import states.BattleState;
import utils.data.Set;
import utils.data.TilePoint;
import utils.tiled.TiledPropertySet;

class ViewPort {
	public static inline var widthInTiles: Float = 15;
	public static inline var heightInTiles: Float = 10;
	public static inline var width: Float = 240;
	public static inline var height: Float = 160;
	public static inline var tileSize: Float = 16;
}

class MapUtils {
	public static inline var TERRAIN_COST_NOGROUND = 99;
	public static inline var TERRAIN_COST_ENEMY = 99;

	public static var mapWidth: Int;
	public static var mapHeight: Int;

	public static function findPathOptions(battle: BattleState, unit: Unit): PathOptions {
		var openPaths: Array<Path> = new Array<Path>();
		var pathOptions: PathOptions = new PathOptions(mapWidth);
		var startPoint = unit.pos;

		var currentPath: Path = new Path();
		currentPath.path.push(startPoint);
		openPaths.push(currentPath);
		pathOptions.nodes.add(startPoint);

		var neighbours = getNeighbours(battle, unit, unit.pos, currentPath);

		// Another step while there are unvisited neighbours
		while (neighbours.length > 0 || openPaths.length > 0) {

			// Visit each one of the neighbours
			if (neighbours.length > 0) {
				var assignedCurrentPath = false;
				var newStep = null;
				var newStepCost = 0;

				for (neighbour in neighbours) {
					var costToNeighbour = getMovementCost(battle, unit, neighbour);

					// Add the first neighbour to the current path if it's reachable
					if (!assignedCurrentPath && currentPath.cost + costToNeighbour <= unit.cs.mov) {
						newStepCost = costToNeighbour;
						currentPath.cost += newStepCost;
						currentPath.path.push(neighbour);
						pathOptions.nodes.add(neighbour);
						pathOptions.addToBestPaths(currentPath);

						assignedCurrentPath = true;
						newStep = neighbour;
					} else if (assignedCurrentPath) {
						// For the rest of the neighbours, clone the previous path and add the next neighbour to it if it's reachable
						// Store these alternative paths so they can be followed later
						var openPath = Path.clone(currentPath);
						openPath.path.pop();
						openPath.cost -= newStepCost;

						if (openPath.cost + costToNeighbour <= unit.cs.mov) {
							openPath.cost += costToNeighbour;
							openPath.path.push(neighbour);
							pathOptions.nodes.add(neighbour);
							openPaths.push(openPath);
							pathOptions.addToBestPaths(openPath);
						}
					}
				}

				// Calculate the neighbours for the new position
				if (newStep != null) {
					neighbours = getNeighbours(battle, unit, new TilePoint(newStep.x, newStep.y), currentPath);
				} else {
					neighbours.splice(0, neighbours.length);
				}

			} else {	// No new neighbours, continue with the next open path
				pathOptions.paths.push(currentPath);
				openPaths.remove(currentPath);

				if (openPaths.length > 0) {
					currentPath = openPaths[0];
					var lastStep = currentPath.path[currentPath.path.length - 1];
					neighbours.splice(0, neighbours.length);
					neighbours = getNeighbours(battle, unit, new TilePoint(lastStep.x, lastStep.y), currentPath);
				}
			}
		}

		return pathOptions;
	}

	// Returns a list with the possible neighbours for the last step of the current path
	private static function getNeighbours(battle: BattleState, unit: Unit, tile: TilePoint, currentPath: Path): Array<TilePoint> {
		var neighbours = new Array<TilePoint>();

		if (tile.x > 0 && !currentPath.contains(tile.x - 1, tile.y) && !battle.enemy.exists(coordsToIndex(tile.x - 1, tile.y))) {
			neighbours.push(new TilePoint(tile.x - 1, tile.y));
		}

		if (tile.x < mapWidth - 1 && !currentPath.contains(tile.x + 1, tile.y) && !battle.enemy.exists(coordsToIndex(tile.x + 1, tile.y))) {
			neighbours.push(new TilePoint(tile.x + 1, tile.y));
		}

		if (tile.y > 0 && !currentPath.contains(tile.x, tile.y - 1) && !battle.enemy.exists(coordsToIndex(tile.x, tile.y - 1))) {
			neighbours.push(new TilePoint(tile.x, tile.y - 1));
		}

		if (tile.y < mapHeight - 1 && !currentPath.contains(tile.x, tile.y + 1) && !battle.enemy.exists(coordsToIndex(tile.x, tile.y + 1))) {
			neighbours.push(new TilePoint(tile.x, tile.y + 1));
		}

		neighbours.sort(function(elemA, elemB) {
			return getMovementCost(battle, unit, elemA) - getMovementCost(battle, unit, elemB);
		});

		return neighbours;
	}

	public static function getMovementCost(battle: BattleState, unit: Unit, tile: TilePoint): Int {
		var cost = 1;
		var tileIndex = pointToIndex(tile);
		if (battle.enemy.exists(tileIndex))
			return TERRAIN_COST_ENEMY;

		var properties: TiledPropertySet = getTopTileProperties(battle, tileIndex);
		if (unit.movementType == UnitMovementType.ONFOOT) {
			cost = Std.parseInt(properties.get("footCost"));
		}

		return cost;
	}

	public static function getTerrainDefenseBonus(battle: BattleState, tile: Int): Int {
		return Std.parseInt(getTopTileProperties(battle, tile).get("defense"));
	}

	public static function getTerrainAvoidBonus(battle: BattleState, tile: Int): Int {
		return Std.parseInt(getTopTileProperties(battle, tile).get("avoid"));
	}

	public static function getTopTileProperties(battle: BattleState, tileIndex: Int): TiledPropertySet {
		var properties: TiledPropertySet = null;

		var i = battle.level.layers.length - 1;
		var found = false;
		while (!found && i >= 0) {
			var layer = battle.level.layers[i];
			var tileSet = Level.obtainTileSet(battle.level, layer);
			var tileId = layer.tileArray[tileIndex];

			if (tileId > 0) {
				properties = tileSet.getProperties(tileId - 1);
				found = properties.get("isDecoration") == "false";
			}

			i--;
		}

		return properties;
	}

	public static function coordsToIndex(posX: Float, posY: Float): Int {
		return Std.int(posY) * mapWidth + Std.int(posX);
	}

	public static function pointToIndex(point: TilePoint): Int {
		return coordsToIndex(point.x, point.y);
	}

	public static function indexToPoint(index: Int): TilePoint {
		return new TilePoint(Std.int(index % mapWidth), Std.int(index / mapWidth));
	}

	public static function getPathGraphic(x: Float, y: Float, from: PathDirection, to: PathDirection): FlxSprite {
		var graphic: FlxSprite = new FlxSprite(x, y);
		graphic.loadGraphic("assets/images/path.png", true, 16, 16);

		if (from == PathDirection.START) {
			if (to == PathDirection.UP)
				graphic.animation.frameIndex = 10;
			else if (to == PathDirection.DOWN)
				graphic.animation.frameIndex = 11;
			else if (to == PathDirection.LEFT)
				graphic.animation.frameIndex = 12;
			else if (to == PathDirection.RIGHT)
				graphic.animation.frameIndex = 13;
		} else if (from == PathDirection.UP) {
			if (to == PathDirection.DOWN)
				graphic.animation.frameIndex = 4;
			else if (to == PathDirection.LEFT)
				graphic.animation.frameIndex = 8;
			else if (to == PathDirection.RIGHT)
				graphic.animation.frameIndex = 6;
			else if (to == PathDirection.STOP)
				graphic.animation.frameIndex = 1;
		} else if (from == PathDirection.DOWN) {
			if (to == PathDirection.UP)
				graphic.animation.frameIndex = 4;
			else if (to == PathDirection.LEFT)
				graphic.animation.frameIndex = 7;
			else if (to == PathDirection.RIGHT)
				graphic.animation.frameIndex = 9;
			else if (to == PathDirection.STOP)
				graphic.animation.frameIndex = 0;
		} else if (from == PathDirection.LEFT) {
			if (to == PathDirection.UP)
				graphic.animation.frameIndex = 8;
			else if (to == PathDirection.DOWN)
				graphic.animation.frameIndex = 7;
			else if (to == PathDirection.RIGHT)
				graphic.animation.frameIndex = 5;
			else if (to == PathDirection.STOP)
				graphic.animation.frameIndex = 3;
		} else if (from == PathDirection.RIGHT) {
			if (to == PathDirection.UP)
				graphic.animation.frameIndex = 6;
			else if (to == PathDirection.DOWN)
				graphic.animation.frameIndex = 9;
			else if (to == PathDirection.LEFT)
				graphic.animation.frameIndex = 5;
			else if (to == PathDirection.STOP)
				graphic.animation.frameIndex = 2;
		}

		return graphic;
	}

	public static function drawPath(path: Path, battle: BattleState) {
		if (path != null) {
			Utils.clearSpriteGroup(battle.activePath);

			var prevStep: TilePoint = null;
			var from = PathDirection.START;
			var to = null;

			for (i in 0...path.path.length) {
				var step = path.path[i];
				var nextStep = null;
				var deltaX: Float = 0;
				var deltaY: Float = 0;

				if ((i + 1) < path.path.length) {
					nextStep = path.path[i + 1];
					deltaX = step.x - nextStep.x;
					deltaY = step.y - nextStep.y;
				}

				if (deltaX > 0) {
					to = PathDirection.LEFT;
				} else if (deltaX < 0) {
					to = PathDirection.RIGHT;
				} else if (deltaY > 0) {
					to = PathDirection.UP;
				} else if (deltaY < 0) {
					to = PathDirection.DOWN;
				} else {
					to = PathDirection.STOP;
				}

				battle.activePath.add(getPathGraphic(step.x * ViewPort.tileSize, step.y * ViewPort.tileSize, from, to));

				if (to == PathDirection.UP)
					from = PathDirection.DOWN;
				else if (to == PathDirection.DOWN)
					from = PathDirection.UP;
				else if (to == PathDirection.LEFT)
					from = PathDirection.RIGHT;
				else if (to == PathDirection.RIGHT)
					from = PathDirection.LEFT;
			}
		}
	}

	public static function calcDistance(a: TilePoint, b: TilePoint): Int {
		return Utils.abs(a.x - b.x) + Utils.abs(a.y - b.y);
	}

	public static function getTile(battle: BattleState, x: Int, y: Int): Int {
		var tile = 0;
		for (tm in battle.level.backgroundTiles) {
			var tileMap: FlxTilemap = cast(tm, FlxTilemap);
			var newTile = tileMap.getTile(x, y);
			if (newTile > 0)
				tile = newTile;
		}

		return tile;
	}
}

class PathOptions {
	public var paths: Array<Path>;
	public var nodes: Set<TilePoint>;
	public var bestPaths: Map<Int, Path>;

	private var width: Int;

	public function new(mapWidth: Int) {
		paths = new Array<Path>();
		nodes = new Set<TilePoint>(function(a: TilePoint, b: TilePoint) {
			return a.x == b.x && a.y == b.y;
		});
		bestPaths = new Map<Int, Path>();
		width = mapWidth;
	}

	public function destroy() {
		for (path in paths)
			path.destroy();

		nodes.forEach(function(node) { node = null; });

		for (path in bestPaths)
			path.destroy();
	}

	public function addToBestPaths(path: Path) {
		var index = MapUtils.pointToIndex(path.path[path.path.length - 1]);
		var oldPath = bestPaths.get(index);
		if (oldPath == null || path.cost < oldPath.cost) {
			bestPaths.set(index, Path.clone(path));
		}
	}
}

class Path {
	public var path: Array<TilePoint>;
	public var cost: Int;

	public function new() {
		path = new Array<TilePoint>();
		cost = 0;
	}

	public function destroy() {
		for (step in path)
			step = null;
	}

	private function containsInt(posX: Int, posY: Int): Bool {
		var found = false;
		var i = 0;
		while (!found && i < path.length) {
			var point = path[i];
			found = point.x == posX && point.y == posY;
			i++;
		}
		return found;
	}

	public function contains(posX: Float, posY: Float): Bool {
		return containsInt(Std.int(posX), Std.int(posY));
	}

	public static function clone(path: Path) {
		var p: Path = new Path();
		for (step in path.path)
			p.path.push(new TilePoint(step.x, step.y));
		p.cost = path.cost;

		return p;
	}
}

enum PathDirection {
	START;
	STOP;
	UP;
	DOWN;
	LEFT;
	RIGHT;
}
