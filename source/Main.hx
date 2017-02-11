package;

import flixel.FlxGame;
import openfl.Lib;
import openfl.display.Sprite;

import states.BattleState;

class Main extends Sprite
{
	public function new()
	{
		super();
		//addChild(new FlxGame(0, 0, MenuState));
		addChild(new FlxGame(240, 160, BattleState, 3, 30, 30, true, false));
	}
}
