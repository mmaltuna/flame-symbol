package utils;

import utils.tiled.TiledMap;
import utils.tiled.TiledTileSet;
import utils.tiled.TiledLayer;

import flixel.group.FlxGroup;
import flixel.tile.FlxTilemap;

class Level extends TiledMap {

	public var backgroundTiles : FlxGroup;
	public var tileMap: FlxTilemap;

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
	}

	public static function obtainTileSet(map: TiledMap, layer: TiledLayer): TiledTileSet {
		var tilesetName: String = layer.properties.get("tileset");
		if (tilesetName == null || !map.tilesets.exists(tilesetName))
			throw "'tileset' property not defined for the " + layer.name + " layer. Please, add the property to the layer.";

		return map.tilesets.get(tilesetName);
	}
}
