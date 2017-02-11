package utils.tiled;

import flash.geom.Rectangle;
import flash.utils.ByteArray;
import haxe.xml.Fast;

/**
 * Copyright (c) 2015 by Rafa de la Hoz
 * (original by Samuel Batista vased on Matt Tuttle based on Thomas Jahn's.
 * Haxe port by Adrien Fischer)
 * This content is released under the MIT License.
 */
class TiledTileSet
{
	public var firstGID:Int;
	public var name:String;
	public var tileWidth:Int;
	public var tileHeight:Int;
	public var spacing:Int;
	public var margin:Int;
	public var imageSource:String;

	// Available only after immage has been assigned:
	public var numTiles:Int;
	public var numRows:Int;
	public var numCols:Int;

	public var properties:TiledPropertySet;

	public var tileProps:Array<TiledPropertySet>;

	public function new(data:Dynamic)
	{
		var node:Fast, source:Fast;
		numTiles = 0xFFFFFF;
		numRows = numCols = 1;

		// Use the correct data format
		var source : Fast = prepareFastData(data);

		firstGID = (source.has.firstgid) ? Std.parseInt(source.att.firstgid) : 1;

		// check for external source
		if (source.has.source)
		{

		}
		// internal
		else
		{
			var imgWidth = 8;
			var imgHeight = 8;

			var node:Fast = source.node.image;
			imageSource = node.att.source;

			imgWidth = Std.parseInt(node.att.width);
			imgHeight = Std.parseInt(node.att.height);

			name = source.att.name;

			if (source.has.tilewidth)
			{
				tileWidth = Std.parseInt(source.att.tilewidth);
			}
			if (source.has.tileheight)
			{
				tileHeight = Std.parseInt(source.att.tileheight);
			}
			if (source.has.spacing)
			{
				spacing = Std.parseInt(source.att.spacing);
			}
			if (source.has.margin)
			{
				margin = Std.parseInt(source.att.margin);
			}

			// read properties
			properties = new TiledPropertySet();
			for (prop in source.nodes.properties) {
				properties.extend(prop);
			}

			// read tiles properties
			tileProps = new Array<TiledPropertySet>();

			for (node in source.nodes.tile)
			{
				if (!node.has.id)
				{
					continue;
				}

				var id:Int = Std.parseInt(node.att.id);
				tileProps[id] = new TiledPropertySet();

				for (prop in node.nodes.properties)
				{
					tileProps[id].extend(prop);
				}
			}

			if (tileWidth > 0 && tileHeight > 0)
			{
				numRows = cast(imgWidth / tileWidth);
				numCols = cast(imgHeight / tileHeight);
				numTiles = numRows * numCols;
			}
		}
	}

	public inline function hasGid(Gid:Int):Bool
	{
		return (Gid >= firstGID) && Gid < (firstGID + numTiles);
	}

	public inline function fromGid(Gid:Int):Int
	{
		return Gid - (firstGID - 1);
	}

	public inline function toGid(ID:Int):Int
	{
		return firstGID + ID;
	}

	public function getPropertiesByGid(Gid:Int):TiledPropertySet
	{
		if (tileProps != null)
		{
			return tileProps[Gid - firstGID];
		}

		return null;
	}

public inline function getProperties(ID:Int):TiledPropertySet
	{
		return tileProps[ID];
	}

	public inline function getRect(ID:Int):Rectangle
	{
		// TODO: consider spacing & margin
		return new Rectangle((ID % numCols) * tileWidth, (ID / numCols) * tileHeight);
	}

	public static function prepareFastData(data:Dynamic) : Fast
	{
		var source : Fast;

		// Use the correct data format
		if (Std.is(data, Fast))
		{
			source = data;
		}
		else if (Std.is(data, ByteArray))
		{
			source = new Fast(Xml.parse(data.toString()));
			source = source.node.tileset;
		}
		else
		{
			throw "Unknown TMX tileset format";
		}

		return source;
	}

	public static inline function isTileset(data:Dynamic) : Bool
	{
		var source : Fast = prepareFastData(data);

		return (source.hasNode.image);
	}
}
