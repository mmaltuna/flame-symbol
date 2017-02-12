package entities;

import flixel.FlxObject;
import flixel.util.FlxColor;
import flixel.util.FlxPath;
import flixel.math.FlxPoint;

import utils.MapUtils;
import utils.MapUtils.Path;
import utils.Utils;

import entities.Item;
import entities.Weapon;
import utils.data.TilePoint;
import utils.tiled.TiledObject;

class Unit extends Entity {

	public var cs: UnitStats;	// current stats
	public var os: UnitStats;	// original stats

	public var lvl: Int;
	public var exp: Int;

	public var pos: TilePoint;
	public var offsetX: Int;	// horizontal offset from the upper left corner of the tile
	public var offsetY: Int;	// vertical offset from the upper left corner of the tile

	public var atkRangeMin: Int;
	public var atkRangeMax: Int;
	public var defenseBonus: Int;
	public var avoidBonus: Int;

	public var name: String;
	public var type: String;

	public var status: UnitStatus;
	public var movementType: UnitMovementType;

	public var items: Array<Item>;
	public var equippedWeapon: Weapon;

	public var activePath: Path;

	public function new(posX: Int, posY: Int, colour: FlxColor) {
		offsetX = -2;
		offsetY = -4;

		super(posX * ViewPort.tileSize + offsetX, posY * ViewPort.tileSize + offsetY);
		if (colour == FlxColor.BLUE)
			loadGraphic("assets/images/sword-warrior-blue.png", true, 20, 20);
		else
			loadGraphic("assets/images/sword-warrior-red.png", true, 20, 20);

		setFacingFlip(FlxObject.LEFT, false, false);
		setFacingFlip(FlxObject.RIGHT, true, false);

		animation.add("idle", [12, 13], 2, true);
		animation.add("walk-down", [0, 1, 2, 3], 6, true);
		animation.add("walk-lr", [4, 5, 6, 7], 6, true);
		animation.add("walk-up", [8, 9, 10, 11], 6, true);
		animation.add("selected", [14, 15, 16, 15], 6, true);

		cs = new UnitStats();
		os = new UnitStats();

		pos = new TilePoint(posX, posY);

		atkRangeMin = 1;
		atkRangeMax = 1;
		defenseBonus = 0;
		avoidBonus = 0;

		items = new Array<Item>();
		equippedWeapon = null;

		enable();
		movementType = UnitMovementType.ONFOOT;

		//makeGraphic(ViewPort.tileSize, ViewPort.tileSize, colour);
	}

	public function useItem(item: Item) {
		// TODO: check syntax
		trace("Type.getClass(item) = " + Type.getClass(item));
		if (true) {
			equipWeapon(cast(item, Weapon));
		} else {

		}
	}

	public function equipWeapon(weapon: Weapon) {
		equippedWeapon = weapon;
		atkRangeMin = weapon.minRange;
		atkRangeMax = weapon.maxRange;
	}

	public function select(): Bool {
		if (status == UnitStatus.STATUS_AVAILABLE || status == UnitStatus.STATUS_MOVED) {
			animation.play("selected");
			status = UnitStatus.STATUS_SELECTED;
			return true;
		}
		return false;
	}

	public function deselect() {
		if (status == UnitStatus.STATUS_SELECTED) {
			animation.play("idle");
			status = UnitStatus.STATUS_AVAILABLE;
		}
	}

	public function enable() {
		animation.play("idle");
		status = UnitStatus.STATUS_AVAILABLE;
		color = 0xffffff;
	}

	public function disable() {
		animation.finish();
		animation.frameIndex = 12;
		status = UnitStatus.STATUS_DONE;
		color = 0x555555;
	}

	public function move(posX: Int, posY: Int, path: Path, callback: FlxPath -> Void = null) {
		pos.x = posX;
		pos.y = posY;

		if (path != null) {
			status = UnitStatus.STATUS_MOVING;

			if (activePath != null)
				activePath.destroy();

			activePath = path;

			if (this.path != null) {
				for (step in this.path.nodes)
					step.destroy();
			}

			var pathArray = new Array<FlxPoint>();
			for (step in path.path)
				pathArray.push(new FlxPoint(step.x * ViewPort.tileSize + ViewPort.tileSize / 2 + offsetX,
					step.y * ViewPort.tileSize + ViewPort.tileSize / 2 + offsetY));

			this.path = new FlxPath(pathArray);

			if (callback != null)
				this.path.onComplete = callback;

			animation.play("walk-lr");
			this.path.start(200);

			for (step in pathArray)
				step.destroy();

		} else {
			this.x = pos.x * ViewPort.tileSize + offsetX;
			this.y = pos.y * ViewPort.tileSize + offsetY;

			if (callback != null)
				callback(null);
		}
	}

	override public function update(elapsed: Float) {
		if (status == UnitStatus.STATUS_MOVING) {
			var nodeIndex = this.path.nodeIndex;
			var changedFacing = false;

			if (nodeIndex > 0 && nodeIndex < activePath.path.length) {
				if (facing != activePath.facing[nodeIndex - 1]) {
					facing = activePath.facing[nodeIndex - 1];
					changedFacing = true;
				}
			} else if (nodeIndex == 0) {
				facing = activePath.facing[nodeIndex];
				changedFacing = true;
			}

			if (changedFacing && (facing == FlxObject.LEFT || facing == FlxObject.RIGHT)) {
				animation.play("walk-lr");
			} else if (changedFacing && facing == FlxObject.UP) {
				animation.play("walk-up");
			} else if (changedFacing && facing == FlxObject.DOWN) {
				animation.play("walk-down");
			}
		}

		super.update(elapsed);
	}

	public function getPhysicalPower(): Int {
		// Physical Attack = Strength + (Weapon Might + Weapon Triangle Bonus) X Weapon effectiveness + Support Bonus
		var physicalPower: Int = cs.str;

		if (equippedWeapon != null) {
			physicalPower += (equippedWeapon.might + 0) * 1;
		}

		return physicalPower;
	}

	public function getMagicalPower(): Int {
		// Magical Attack = magic + (Magic Might + Trinity of Magic Bonus) X Magic Effectiveness + Support Bonus
		return 0;
	}

	public function getDefensePower(): Int {
		// DP = Terrain Bonus + Defense + Support Bonus
		return defenseBonus + cs.def + 0;
	}

	public function getResistancePower(): Int {
		return 0;
	}

	public function getAttackSpeed(): Int {
		// If WWT ≤ Strength, then AS = Speed
		// If WWT > Strength, then AS = Speed - (Weapon Weight - Strength)
		if (equippedWeapon != null && equippedWeapon.weight > cs.str)
			return cs.spd + cs.str - equippedWeapon.weight;

		return cs.spd;
	}

	public function getHitRate(): Int {
		// Hit Rate = Weapon Accuracy + Skill x 2 + Luck / 2 + Support Bonus + S-Rank Bonus
		var hitRate: Int = 100;

		if (equippedWeapon != null)
			hitRate = equippedWeapon.hitRate;

		return Std.int(hitRate + cs.skl * 2 + cs.lck / 2 + 0 + 0);
	}

	public function getEvasionRate(): Int {
		// Evade = Attack Speed x 2 + Luck + Terrain Bonus + Support Bonus
		return getAttackSpeed() * 2 + cs.lck + avoidBonus + 0;
	}

	public function repeatsAttack(enemy: Unit): Bool {
		var doubleAttackThreshold = 4;

		return (getAttackSpeed() - enemy.getAttackSpeed()) > doubleAttackThreshold;
	}

	public function getAccuracy(enemy: Unit): Int {
		// Accuracy = Hit Rate (Attacker) - Evade (Defender) + Triangle Bonus
		return Utils.min(100, Utils.max(0, getHitRate() - enemy.getEvasionRate() + 0));
	}

	public function calcPhysicalDamage(enemy: Unit): Int {
		return Utils.max(getPhysicalPower() - enemy.getDefensePower(), 0);
	}

	public function calcMagicalDamage(enemy: Unit): Int {
		return Utils.max(getMagicalPower() - enemy.getResistancePower(), 0);
	}

	public function attack(enemy: Unit) {
		if (getAccuracy(enemy) >= Std.random(100)) {
			trace(name + " attacks!");
			performAttack(enemy);
		} else {
			trace(name + " misses!");
		}

		if (enemy.isAlive() && enemy.canCounterattack(this) && enemy.getAccuracy(this) >= Std.random(100)) {
			trace(enemy.name + " counters!");
			enemy.performAttack(this);

			if (enemy.repeatsAttack(this) && enemy.getAccuracy(this) >= Std.random(100)) {
				trace(enemy.name + " counters again!");
				enemy.performAttack(this);
			}
		}

		if (isAlive() && repeatsAttack(enemy) && getAccuracy(enemy) >= Std.random(100)) {
			trace(name + " attacks again!");
			performAttack(enemy);
		}
	}

	private function performAttack(enemy: Unit) {
		enemy.cs.hp = Utils.max(0, enemy.cs.hp - calcPhysicalDamage(enemy));
	}

	public function canCounterattack(enemy: Unit): Bool {
		if (enemy != null) {
			var distance = MapUtils.calcDistance(pos, enemy.pos);
			return atkRangeMin >= distance && atkRangeMax <= distance;
		}

		return false;
	}

	public function isAlive(): Bool {
		return cs.hp > 0;
	}

	public function resetStats() {
		cs.hp = os.hp;
		cs.str = os.str;
		cs.mgc = os.mgc;
		cs.skl = os.skl;
		cs.spd = os.spd;
		cs.lck = os.lck;
		cs.def = os.def;
		cs.res = os.res;
		cs.mov = os.mov;
	}

	public static function createUnit(object: TiledObject, colour: FlxColor): Unit {
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

		return unit;
	}
}

class UnitStats {
	public var hp: Int;
	public var str: Int;
	public var mgc: Int;
	public var skl: Int;
	public var spd: Int;
	public var lck: Int;
	public var def: Int;
	public var res: Int;
	public var mov: Int;

	public function new() {}
}

enum UnitStatus {
	STATUS_AVAILABLE;
	STATUS_SELECTED;
	STATUS_MOVING;
	STATUS_MOVED;
	STATUS_ATTACKING;
	STATUS_DONE;
}

enum UnitMovementType {
	ONFOOT;
	RIDE;
	FLY;
}
