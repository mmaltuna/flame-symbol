package entities;

import flixel.FlxSprite;
import utils.MapUtils;

class Weapon extends Item {

	public var might: Int;
	public var weight: Int;
	public var hitRate: Int;
	public var crtRate: Int;

	public var minRange: Int;
	public var maxRange: Int;

	public var rank: Int;		// 5 = E, 4 = D, 3 = C, 2 = B, 1 = A, 0 = S

	private var equippedBadge: FlxSprite;

	public function new(x: Int, y: Int) {
		super(x, y);

		equippedBadge = new FlxSprite(x + ViewPort.tileSize - 6, y + ViewPort.tileSize - 7);
		equippedBadge.loadGraphic("assets/images/ui/hud-equipped.png", 6, 7);
		equippedBadge.visible = false;
		add(equippedBadge);
	}

	public function setEquipped(equipped: Bool) {
		equippedBadge.visible = equipped;
	}

	public static function getDamageBonus(weaponA: Weapon, weaponB: Weapon): Int {
		var damageBonus: Int = 0;

		if (weaponA.type == "sword" && weaponB.type == "lance") {
			damageBonus = -1;
		} else if (weaponA.type == "sword" && weaponB.type == "axe") {
			damageBonus = 1;
		} else if (weaponA.type == "lance" && weaponB.type == "sword") {
			damageBonus = 1;
		} else if (weaponA.type == "lance" && weaponB.type == "axe") {
			damageBonus = -1;
		} else if (weaponA.type == "axe" && weaponB.type == "sword") {
			damageBonus = -1;
		} else if (weaponA.type == "axe" && weaponB.type == "lance") {
			damageBonus = 1;
		}

		return damageBonus;
	}

	public static function getAccuracyBonus(weaponA: Weapon, weaponB: Weapon): Int {
		var accuracyBonus: Int = 0;

		if (weaponA.type == "sword" && weaponB.type == "lance") {
			accuracyBonus = -15;
		} else if (weaponA.type == "sword" && weaponB.type == "axe") {
			accuracyBonus = 15;
		} else if (weaponA.type == "lance" && weaponB.type == "sword") {
			accuracyBonus = 15;
		} else if (weaponA.type == "lance" && weaponB.type == "axe") {
			accuracyBonus = -15;
		} else if (weaponA.type == "axe" && weaponB.type == "sword") {
			accuracyBonus = -15;
		} else if (weaponA.type == "axe" && weaponB.type == "lance") {
			accuracyBonus = 15;
		}

		return accuracyBonus;
	}

	public static function isWeapon(item: Item): Bool {
		return Type.getClassName(Type.getClass(item)) == "entities.Weapon";
	}
}
