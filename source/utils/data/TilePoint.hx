package utils.data;

import flixel.math.FlxPoint;

class TilePoint {

	public var x: Int;
	public var y: Int;

	public function new(x: Int, y: Int) {
		this.x = x;
		this.y = y;
	}

	public static function toFlxPoint(tilePoint: TilePoint): FlxPoint {
		return new FlxPoint(tilePoint.x, tilePoint.y);
	}

	public static function fromFlxPoint(point: FlxPoint): TilePoint {
		return new TilePoint(Std.int(point.x), Std.int(point.y));
	}
}
