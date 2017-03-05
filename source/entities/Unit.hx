package entities;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.util.FlxColor;
import flixel.util.FlxPath;
import flixel.util.FlxSpriteUtil;
import flixel.tweens.FlxTween;
import flixel.math.FlxPoint;
import haxe.Timer;

import utils.MapUtils;
import utils.MapUtils.Path;
import utils.Utils;

import entities.Item;
import entities.Weapon;
import utils.data.TilePoint;

import ui.ProgressBar;

import states.BattleState;

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

	public var battle: BattleState;
	public var hpBar: ProgressBar;
	public var missedAttack: FlxSprite;

	public function new(posX: Int, posY: Int, colour: FlxColor) {
		offsetX = -2;
		offsetY = -4;

		super(posX * ViewPort.tileSize + offsetX, posY * ViewPort.tileSize + offsetY);
		if (colour == FlxColor.BLUE)
			sprite.loadGraphic("assets/images/sword-warrior-blue.png", true, 20, 20);
		else
			sprite.loadGraphic("assets/images/sword-warrior-red.png", true, 20, 20);

		sprite.setFacingFlip(FlxObject.LEFT, false, false);
		sprite.setFacingFlip(FlxObject.RIGHT, true, false);

		sprite.animation.add("idle", [12, 13], 2, true);
		sprite.animation.add("walk-down", [0, 1, 2, 3], 6, true);
		sprite.animation.add("walk-lr", [4, 5, 6, 7], 6, true);
		sprite.animation.add("walk-up", [8, 9, 10, 11], 6, true);
		sprite.animation.add("selected", [14, 15, 16, 15], 6, true);

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

		battle = BattleState.getInstance();

		hpBar = new ProgressBar(posX * ViewPort.tileSize, (posY + 1) * ViewPort.tileSize - 1, ViewPort.tileSize, 1, 0, 100, false);
		hpBar.hideIndicator();
		hpBar.setColour(FlxColor.GREEN, "foreground");
		for (member in hpBar.members)
			add(member);

		missedAttack = new FlxSprite(posX * ViewPort.tileSize + offsetX, (posY + 1) * ViewPort.tileSize - 9);
		missedAttack.loadGraphic("assets/images/ui/hud-miss.png", 20, 8);
		missedAttack.visible = false;
		add(missedAttack);
	}

	public function useItem(item: Item) {
		var itemClass: String = Type.getClassName(Type.getClass(item));
		if (itemClass == "entities.Item") {
			trace(item.name + " is an item");
		} else if (itemClass == "entities.Weapon") {
		   equipWeapon(cast(item, Weapon));
	   }
	}

	public function equipWeapon(weapon: Weapon) {
		if (equippedWeapon != null)
			equippedWeapon.setEquipped(false);

		equippedWeapon = weapon;
		atkRangeMin = weapon.minRange;
		atkRangeMax = weapon.maxRange;

		var index: Int = items.indexOf(weapon);
		if (index >= 0) {
			items.splice(index, 1);
			items.insert(0, weapon);
			weapon.setEquipped(true);
		}
	}

	public function select(): Bool {
		if (status == UnitStatus.STATUS_AVAILABLE || status == UnitStatus.STATUS_MOVED) {
			sprite.animation.play("selected");
			status = UnitStatus.STATUS_SELECTED;
			return true;
		}
		return false;
	}

	public function deselect() {
		if (status == UnitStatus.STATUS_SELECTED) {
			sprite.animation.play("idle");
			status = UnitStatus.STATUS_AVAILABLE;
		}
	}

	public function enable() {
		sprite.animation.play("idle");
		status = UnitStatus.STATUS_AVAILABLE;
		sprite.color = 0xffffff;
	}

	public function disable() {
		sprite.animation.finish();
		sprite.animation.frameIndex = 12;
		status = UnitStatus.STATUS_DONE;
		sprite.color = 0x555555;
	}

	public function moveUnit(posX: Int, posY: Int, path: Path, callback: FlxPath -> Void = null) {
		pos.x = posX;
		pos.y = posY;

		if (path != null) {
			status = UnitStatus.STATUS_MOVING;

			if (activePath != null)
				activePath.destroy();

			activePath = path;

			if (sprite.path != null) {
				for (step in sprite.path.nodes)
					step.destroy();
			}

			var pathArray = new Array<FlxPoint>();
			for (step in path.path)
				pathArray.push(new FlxPoint(step.x * ViewPort.tileSize + ViewPort.tileSize / 2,
					step.y * ViewPort.tileSize + (ViewPort.tileSize + offsetY) / 2));

			sprite.path = new FlxPath(pathArray);

			if (callback != null)
				sprite.path.onComplete = callback;
			else
				moveElems(pos.x, posY);

			sprite.animation.play("walk-lr");
			sprite.path.start(200);

			for (step in pathArray)
				step.destroy();

		} else {
			sprite.x = pos.x * ViewPort.tileSize + offsetX;
			sprite.y = pos.y * ViewPort.tileSize + offsetY;
			moveElems(pos.x, posY);

			if (callback != null)
				callback(null);
		}
	}

	public function moveElems(posX: Int, posY: Int) {
		hpBar.move(pos.x * ViewPort.tileSize, (posY + 1) * ViewPort.tileSize - 1);
		missedAttack.x = posX * ViewPort.tileSize + offsetX;
		missedAttack.y = (posY + 1) * ViewPort.tileSize - 9;
	}

	override public function update(elapsed: Float) {
		if (status == UnitStatus.STATUS_MOVING) {
			var nodeIndex = sprite.path.nodeIndex;
			var changedFacing = false;

			if (nodeIndex > 0 && nodeIndex < activePath.path.length) {
				if (sprite.facing != activePath.facing[nodeIndex - 1]) {
					sprite.facing = activePath.facing[nodeIndex - 1];
					changedFacing = true;
				}
			} else if (nodeIndex == 0) {
				sprite.facing = activePath.facing[nodeIndex];
				changedFacing = true;
			}

			if (changedFacing && (sprite.facing == FlxObject.LEFT || sprite.facing == FlxObject.RIGHT)) {
				sprite.animation.play("walk-lr");
			} else if (changedFacing && sprite.facing == FlxObject.UP) {
				sprite.animation.play("walk-up");
			} else if (changedFacing && sprite.facing == FlxObject.DOWN) {
				sprite.animation.play("walk-down");
			}
		}

		super.update(elapsed);
	}

	public function getPhysicalPower(enemy: Unit): Int {
		// Physical Attack = Strength + (Weapon Might + Weapon Triangle Bonus) X Weapon effectiveness + Support Bonus
		var physicalPower: Int = cs.str;
		var weaponBonus: Int = 0;

		if (equippedWeapon != null) {
			weaponBonus += equippedWeapon.might;
		}

		if (enemy.equippedWeapon != null) {
			weaponBonus += Weapon.getDamageBonus(equippedWeapon, enemy.equippedWeapon);
		}

		return physicalPower + weaponBonus * 1;
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
		return Utils.min(100, Utils.max(0, getHitRate() - enemy.getEvasionRate() +
			Weapon.getAccuracyBonus(equippedWeapon, enemy.equippedWeapon)));
	}

	public function calcPhysicalDamage(enemy: Unit): Int {
		return Utils.max(getPhysicalPower(enemy) - enemy.getDefensePower(), 0);
	}

	public function calcMagicalDamage(enemy: Unit): Int {
		return Utils.max(getMagicalPower() - enemy.getResistancePower(), 0);
	}

	public function attack(enemy: Unit, callback: Void -> Void) {
		performAttack(enemy, 2, function() {
			if (enemy.isAlive() && enemy.canCounterattack(this)) {
				// Defender counter attacks
				enemy.performAttack(this, 1 ,function() {
					if (enemy.repeatsAttack(this) && isAlive()) {
						// Defender attacks again
						enemy.performAttack(this, 1, function() {
							if (isAlive() && repeatsAttack(enemy)) {
								// Attacker's second attack
								performAttack(enemy, 2, function() {
									callback();
								});
							} else {
								callback();
							}
						});
					} else if (isAlive() && repeatsAttack(enemy) && enemy.isAlive()) {
						// Attacker's second attack
						performAttack(enemy, 2, function() {
							callback();
						});
					} else {
						callback();
					}
				});
			} else if (isAlive() && repeatsAttack(enemy) && enemy.isAlive()) {
				// Attacker's second attack
				performAttack(enemy, 2, function() {
					callback();
				});
			} else {
				callback();
			}
		});
	}

	private function performAttack(enemy: Unit, which: Int, callback: Void -> Void) {
		var xDir: Int = Utils.sign0(enemy.pos.x - pos.x);
		var yDir: Int = Utils.sign0(enemy.pos.y - pos.y);

		FlxTween.tween(sprite, { x: sprite.x + xDir * 4, y: sprite.y + yDir * 4 }, 0.1, { onComplete: function(tween: FlxTween) {
			FlxTween.tween(sprite, { x: sprite.x + xDir * -4, y: sprite.y + yDir * -4 }, 0.1);
		} });

		if (getAccuracy(enemy) >= Std.random(100)) {
			enemy.setHP(Utils.max(0, enemy.cs.hp - calcPhysicalDamage(enemy)));

			FlxSpriteUtil.flicker(enemy.sprite, 0.2, 0.05, true, function(flicker: FlxFlicker) {
				if (which == 1)
					battle.battleHud.hpBar1.setValue(enemy.cs.hp, callback);
				else
					battle.battleHud.hpBar2.setValue(enemy.cs.hp, callback);
			});
		} else {
			// Attack misses
			enemy.missedAttack.visible = true;
			FlxTween.tween(enemy.missedAttack, { y: enemy.missedAttack.y - 8 }, 0.1, { onComplete: function(_) {
				Timer.delay(function() {
					enemy.missedAttack.visible = false;
					enemy.missedAttack.y += 8;
					callback();
				}, 600);
			}});
		}
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

	public function die(callback: Void -> Void) {
		function setAlpha(sprite: FlxSprite, value: Float) { sprite.alpha = value; };
		FlxTween.num(1, 0, 0.2, { onComplete: function(_) { callback(); } }, setAlpha.bind(sprite));
	}

	public function setHP(hp: Int) {
		cs.hp = hp;
		hpBar.setValue(cs.hp);

		var hpPercentage: Float = hpBar.getPercentage();
		if (hpPercentage >= 66)
			hpBar.setColour(FlxColor.GREEN, "foreground");
		else if (hpPercentage < 66 && hpPercentage >= 33)
			hpBar.setColour(FlxColor.YELLOW, "foreground");
		else if (hpPercentage < 33)
			hpBar.setColour(FlxColor.RED, "foreground");
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
	STATUS_ATTACK_READY;
	STATUS_ATTACKING;
	STATUS_ON_INVENTORY;
	STATUS_DONE;
}

enum UnitMovementType {
	ONFOOT;
	RIDE;
	FLY;
}
