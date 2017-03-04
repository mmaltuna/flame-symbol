package entities;

class Item extends Entity {

	public var maxUses: Int;
	public var currentUses: Int;

	public var name: String;
	public var type: String;

	public function new(x: Int, y: Int) {
		super(x, y);
	}
}
