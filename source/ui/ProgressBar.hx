package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.text.FlxText;
import flixel.group.FlxGroup;

import flash.display.Bitmap;
import flash.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.geom.Point;

import utils.Utils;

class ProgressBar extends FlxTypedGroup<FlxSprite> {
	private var bar: FlxSprite;
	private var indicator: FlxText;

	private var bg: BitmapData;
	private var fg: BitmapData;
	private var canvas: BitmapData;

	private var bgRect: Rectangle;
	private var fgRect: Rectangle;

	private var x: Int;
	private var y: Int;

	public var currentValue: Int;
	public var minValue: Int;
	public var maxValue: Int;
	private var lengthInPixels: Int;

	private var numberOfSteps: Int;
	private var currentStep: Int;
	private var stepSize: Int;

	private var foregroundColour: FlxColor;
	private var backgroundColour: FlxColor;
	private var borderColour: FlxColor;

	private var timeSinceLastUpdate: Float;
	private var timePerStep: Float;

	private var callback: Void -> Void;

	public function new(x: Int, y: Int, length: Int, min: Int, max: Int, stepsPerSecond: Float = 30) {
		super();

		this.x = x;
		this.y = y;

		currentValue = max;
		minValue = min;
		maxValue = max;

		foregroundColour = FlxColor.RED;
		backgroundColour = FlxColor.BLACK;
		borderColour = FlxColor.WHITE;

		numberOfSteps = length - 2;
		currentStep = numberOfSteps - 1;

		bar = new FlxSprite(x, y).makeGraphic(length, 4);
		add(bar);

		canvas = new BitmapData(length, 4, false, borderColour);
		bg = new BitmapData(length - 2, 2, false, backgroundColour);
		fg = new BitmapData(length - 2, 2, false, foregroundColour);

		bgRect = new Rectangle(0, 0, length - 2, 2);
		fgRect = new Rectangle(0, 0, length - 2, 2);

		indicator = new FlxText(x + length, y - 3, 20, Std.string(currentValue));
		indicator.setFormat("assets/fonts/pixelmini.ttf", FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(indicator);

		repaint();

		timeSinceLastUpdate = 0;
		timePerStep = 1 / stepsPerSecond;

		callback = null;
	}

	public function updateParams() {
		currentStep = Math.ceil(currentValue * numberOfSteps / (maxValue - minValue));
		stepSize = Math.ceil(numberOfSteps / (maxValue - minValue));
		indicator.text = Std.string(currentValue);

		repaint();
	}

	public function repaint() {
		fgRect.width = currentStep;
		var offset: Point = new Point(1, 1);

		canvas.copyPixels(bg, bgRect, offset);
		canvas.copyPixels(fg, fgRect, offset);
		bar.pixels = canvas;
	}

	public function setValue(value: Int, onValueSet: Void -> Void = null) {
		if (value >= minValue && value <= maxValue) {
			currentValue = value;
			callback = onValueSet;
		}
	}

	override public function update(elapsed: Float) {
		if (timeSinceLastUpdate >= timePerStep) {
			var targetStep: Int = Math.ceil(currentValue * numberOfSteps / (maxValue - minValue));
			var tempValue: Int = Math.floor(currentStep * (maxValue - minValue) / numberOfSteps);

			var i: Int = 0;
			while (currentStep != targetStep && i < stepSize) {
				if (currentStep > targetStep) {
					currentStep--;
				} else if (currentStep < targetStep) {
					currentStep++;
				}

				indicator.text = Std.string(tempValue);
				repaint();
				i++;
			}

			if (currentStep == targetStep && callback != null) {
				indicator.text = Std.string(currentValue);
				callback();
				callback = null;
			}

			timeSinceLastUpdate = 0;
		} else {
			timeSinceLastUpdate += elapsed;
		}

		super.update(elapsed);
	}
}
