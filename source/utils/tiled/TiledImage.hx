package utils.tiled;

import flash.geom.Rectangle;
import flash.utils.ByteArray;
import haxe.xml.Fast;

/**
 * Copyright (c) 2015 by Rafa de la Hoz
 */
class TiledImage
{
	public var gid:Int;
	public var sourceImage:String;
	public var imagePath:String;
	
	public var width:Int;
	public var height:Int;
	public var offsetX:Int;
	public var offsetY:Int;
	
	public var maskWidth:Int;
	public var maskHeight:Int;
	public var maskOffsetX:Int;
	public var maskOffsetY:Int;
	
	public var properties:TiledPropertySet;
	
	public function new(firstGID : Int, data : Dynamic)
	{
		var node:Fast, source:Fast;
		
		// Use the correct data format
		if (Std.is(data, Fast))
		{
			source = data;
		}
		else 
		{
			throw "Unknown TMX tileset format";
		}
		
		gid = firstGID + Std.parseInt(source.att.id);
		node = source.node.image;
		
		if (node.has.source)
		{
			sourceImage = node.att.source;
			
			// Fetch the actual filename
			sourceImage = sourceImage.substring(sourceImage.lastIndexOf("/")+1);
			imagePath = sourceImage;
			
			width = Std.parseInt(node.att.width);
			height = Std.parseInt(node.att.height);
			offsetX = 0;
			offsetY = 0;
			maskOffsetX = 0;
			maskOffsetY = 0;
			maskWidth = width;
			maskHeight = height;
		}
		
		// read properties
		properties = new TiledPropertySet();
		for (prop in source.nodes.properties) 
		{
			properties.extend(prop);
		}
		
		if (properties.contains("size"))
		{
			var size : Pair = parsePair(properties.get("size"));
			width = size.x;
			height = size.y;
		}
		
		if (properties.contains("offset"))
		{
			var offset : Pair = parsePair(properties.get("offset"));
			offsetX = offset.x;
			offsetY = offset.y;
		}
		
		if (properties.contains("mask"))
		{
			var maskSize : Pair = parsePair(properties.get("mask"));
			maskWidth = maskSize.x;
			maskHeight = maskSize.y;
		}
		
		if (properties.contains("maskOffset"))
		{
			var maskOffset : Pair = parsePair(properties.get("maskOffset"));
			maskOffsetX = maskOffset.x;
			maskOffsetY = maskOffset.y;
		}
	}
	
	public static function parsePair(src : String) : Pair
	{
		var commaIndex : Int = src.indexOf(",");
		
		var x : String = src.substring(0, commaIndex);
		var y : String = src.substring(commaIndex+1);
		
		var pair : Pair = {
			x: Std.parseInt(x),
			y: Std.parseInt(y)
		};
		
		return pair;
	}
}

typedef Pair = {
	x : Int,
	y : Int
};
