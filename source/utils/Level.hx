package utils;

import utils.tiled.TiledMap;
import utils.tiled.TiledTileSet;
import utils.tiled.TiledLayer;
import utils.tiled.TiledObject;

import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.tile.FlxTilemap;

import entities.Unit;
import entities.Item;
import entities.Weapon;
import utils.MapUtils;
import utils.Data;

class Level extends TiledMap {

	public var backgroundTiles : FlxGroup;
	public var tileMap: FlxTilemap;

	public var army1: Map<Int, Unit>;
	public var army2: Map<Int, Unit>;

	public function new(level: Dynamic) {
		super(level);

		backgroundTiles = new FlxGroup();

		for (layer in layers) {
			var tileset = obtainTileSet(this, layer);

			if (tileset == null)
				throw "Tileset could not be found. Check the name in the layer 'tileset' property or something.";

			var tileMapPath: String = "assets/images/basictiles.png";
			var tilemap: FlxTilemap = new FlxTilemap();
			tilemap.loadMapFromArray(layer.tileArray, width, height, tileMapPath, tileset.tileWidth, tileset.tileHeight, 1, 1, 1);

			backgroundTiles.add(tilemap);
		}

		MapUtils.mapWidth = width;
		MapUtils.mapHeight = height;

		parseUnits();
	}

	private function parseUnits() {
		army1 = new Map<Int, Unit>();
		army2 = new Map<Int, Unit>();

		for (objectGroup in objectGroups) {
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
				var unit: Unit = parseUnit(object, selectedColour);
				selectedArmy.set(MapUtils.pointToIndex(unit.pos), unit);
			}
		}
	}

	private static function parseUnit(object: TiledObject, colour: FlxColor): Unit {
		var posX: Int = Std.int(object.x / ViewPort.tileSize);
		var posY: Int = Std.int(object.y / ViewPort.tileSize);
		var unit: Unit = new Unit(posX, posY, colour);

		unit.os.hp = Std.parseInt(object.custom.get("hp"));
		unit.os.str = Std.parseInt(object.custom.get("str"));
		unit.os.mgc = Std.parseInt(object.custom.get("mgc"));
		unit.os.skl = Std.parseInt(object.custom.get("skl"));
		unit.os.spd = Std.parseInt(object.custom.get("spd"));
		unit.os.lck = Std.parseInt(object.custom.get("lck"));
		unit.os.def = Std.parseInt(object.custom.get("def"));
		unit.os.res = Std.parseInt(object.custom.get("res"));
		unit.os.mov = Std.parseInt(object.custom.get("mov"));
		unit.name = object.name;
		unit.type = object.type;
		unit.resetStats();

		unit.hpBar.maxValue = unit.os.hp;
		unit.hpBar.currentValue = unit.os.hp;
		unit.hpBar.updateParams();

		var itemList: String = object.custom.get("items");
		for (itemType in itemList.split(";")) {
			if (Reflect.hasField(Data.getInstance().weaponList, itemType)) {
				unit.items.push(createWeapon(itemType));
				if (unit.equippedWeapon == null)
					unit.equipWeapon(cast(unit.items[unit.items.length - 1], Weapon));
			} else if (Reflect.hasField(Data.getInstance().itemList, itemType)) {
				unit.items.push(createItem(itemType));
			}
		}

		return unit;
	}

	private static function createWeapon(weaponType: String): Weapon {
		var weaponData: Dynamic = Reflect.field(Data.getInstance().weaponList, weaponType);
		var weapon: Weapon = new Weapon(0, 0);

		weapon.might = Reflect.field(weaponData, "might");
		weapon.weight = Reflect.field(weaponData, "weight");
		weapon.hitRate = Reflect.field(weaponData, "hitRate");
		weapon.crtRate = Reflect.field(weaponData, "crtRate");
		weapon.minRange = Reflect.field(weaponData, "minRange");
		weapon.maxRange = Reflect.field(weaponData, "maxRange");
		weapon.rank = Reflect.field(weaponData, "rank");
		weapon.maxUses = Reflect.field(weaponData, "uses");
		weapon.currentUses = weapon.maxUses;
		weapon.name = Reflect.field(weaponData, "name");
		weapon.type = Reflect.field(weaponData, "class");

		weapon.sprite.loadGraphic(Reflect.field(weaponData, "gfx-path"), 16, 16);

		return weapon;
	}

	private static function createItem(itemType: String): Item {
		var itemData: Dynamic = Reflect.field(Data.getInstance().itemList, itemType);
		var item = new Item(0, 0);

		item.name = Reflect.field(itemData, "name");
		item.type = Reflect.field(itemData, "type");
		item.maxUses = Reflect.field(itemData, "uses");
		item.currentUses = item.maxUses;
		item.power = Reflect.field(itemData, "power");

		item.sprite.loadGraphic(Reflect.field(itemData, "gfx-path"), 16, 16);

		return item;
	}

	public static function obtainTileSet(map: TiledMap, layer: TiledLayer): TiledTileSet {
		var tilesetName: String = layer.properties.get("tileset");
		if (tilesetName == null || !map.tilesets.exists(tilesetName))
			throw "'tileset' property not defined for the " + layer.name + " layer. Please, add the property to the layer.";

		return map.tilesets.get(tilesetName);
	}
}
