package entities;

class Weapon extends Item {

	public var might: Int;
	public var weight: Int;
	public var hitRate: Int;
	public var crtRate: Int;

	public var minRange: Int;
	public var maxRange: Int;

	public var rank: Int;		// 5 = E, 4 = D, 3 = C, 2 = B, 1 = A, 0 = S
	public var maxUses: Int;
	public var currentUses: Int;

	public var name: String;
	public var weaponClass: String;

	public function new(x: Int, y: Int) {
		super(x, y);
	}

	public static function getDamageBonus(weaponA: Weapon, weaponB: Weapon): Int {
		var damageBonus: Int = 0;

		if (weaponA.weaponClass == "sword" && weaponB.weaponClass == "lance") {
			damageBonus = -1;
		} else if (weaponA.weaponClass == "sword" && weaponB.weaponClass == "axe") {
			damageBonus = 1;
		} else if (weaponA.weaponClass == "lance" && weaponB.weaponClass == "sword") {
			damageBonus = 1;
		} else if (weaponA.weaponClass == "lance" && weaponB.weaponClass == "axe") {
			damageBonus = -1;
		} else if (weaponA.weaponClass == "axe" && weaponB.weaponClass == "sword") {
			damageBonus = -1;
		} else if (weaponA.weaponClass == "axe" && weaponB.weaponClass == "lance") {
			damageBonus = 1;
		}

		return damageBonus;
	}

	public static function getAccuracyBonus(weaponA: Weapon, weaponB: Weapon): Int {
		var accuracyBonus: Int = 0;

		if (weaponA.weaponClass == "sword" && weaponB.weaponClass == "lance") {
			accuracyBonus = -15;
		} else if (weaponA.weaponClass == "sword" && weaponB.weaponClass == "axe") {
			accuracyBonus = 15;
		} else if (weaponA.weaponClass == "lance" && weaponB.weaponClass == "sword") {
			accuracyBonus = 15;
		} else if (weaponA.weaponClass == "lance" && weaponB.weaponClass == "axe") {
			accuracyBonus = -15;
		} else if (weaponA.weaponClass == "axe" && weaponB.weaponClass == "sword") {
			accuracyBonus = -15;
		} else if (weaponA.weaponClass == "axe" && weaponB.weaponClass == "lance") {
			accuracyBonus = 15;
		}

		return accuracyBonus;
	}
}
