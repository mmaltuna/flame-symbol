package entities;

class Weapon extends Item {

	public var might: Int;
	public var weight: Int;
	public var hitRate: Int;
	public var critRate: Int;

	public var minRange: Int;
	public var maxRange: Int;

	public var rank: String;

	public function new(x: Int, y: Int) {
		super(x, y);
	}
}
