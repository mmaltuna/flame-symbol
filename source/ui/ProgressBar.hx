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

class ProgressBar extends FlxTypedGroup<FlxSprite> {
	private var bar: FlxSprite;
	private var indicator: FlxText;

	private var bg: BitmapData;
	private var fg: BitmapData;
	private var canvas: BitmapData;

	private var bgRect: Rectangle;
	private var fgRect: Rectangle;
	private var offset: Point;

	public var currentValue: Int;
	public var minValue: Int;
	public var maxValue: Int;

	private var numberOfSteps: Int;
	private var currentStep: Int;
	private var stepSize: Int;

	private var foregroundColour: FlxColor;
	private var backgroundColour: FlxColor;
	private var borderColour: FlxColor;

	private var timeSinceLastUpdate: Float;
	private var timePerStep: Float;

	private var callback: Void -> Void;

	public function new(x: Int, y: Int, width: Int, height: Int, min: Int, max: Int, border: Bool = true, stepsPerSecond: Float = 30) {
		super();

		currentValue = max;
		minValue = min;
		maxValue = max;

		foregroundColour = FlxColor.RED;
		backgroundColour = FlxColor.BLACK;
		borderColour = FlxColor.WHITE;

		numberOfSteps = border ? width - 2 : width;
		currentStep = numberOfSteps;

		bar = new FlxSprite(x, y).makeGraphic(width, height);
		add(bar);

		bgRect = new Rectangle(0, 0, numberOfSteps, border ? height - 2 : height);
		fgRect = new Rectangle(0, 0, bgRect.width, bgRect.height);
		offset = border ? new Point(1, 1) : new Point(0, 0);

		canvas = new BitmapData(width, height, false, borderColour);
		bg = new BitmapData(Std.int(bgRect.width), Std.int(bgRect.height), false, backgroundColour);
		fg = new BitmapData(Std.int(bgRect.width), Std.int(bgRect.height), false, foregroundColour);

		indicator = new FlxText(x + width, y - 9, 12, Std.string(currentValue));	// TODO: param this
		indicator.setFormat("assets/fonts/font-pixel-7.ttf", 16, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		indicator.alignment = FlxTextAlign.RIGHT;
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
		canvas.copyPixels(bg, bgRect, offset);
		canvas.copyPixels(fg, fgRect, offset);
		bar.pixels = canvas;
	}

	public function setValue(value: Int, onValueSet: Void -> Void = null) {
		if (value >= minValue && value <= maxValue) {
			currentValue = value;
			callback = onValueSet;
		}

		if (onValueSet == null)
			updateParams();
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

	public function show() {
		showBar();
		showIndicator();
	}

	public function hide() {
		hideBar();
		hideIndicator();
	}

	public function showBar() {
		bar.visible = true;
	}

	public function hideBar() {
		bar.visible = false;
	}

	public function showIndicator() {
		indicator.visible = true;
	}

	public function hideIndicator() {
		indicator.visible = false;
	}

	public function move(newX: Int, newY: Int) {
		var offsetX: Float = newX - bar.x;
		var offsetY: Float = newY - bar.y;

		for (member in members) {
			member.x += offsetX;
			member.y += offsetY;
		}

		bar.x = newX;
		bar.y = newY;
	}

	public function setColour(colour: FlxColor, elemName: String) {
		var elem: BitmapData = null;
		var rect: Rectangle = null;

		if (elemName == "foreground") {
			elem = fg;
			rect = fgRect;
			foregroundColour = colour;
		} else if (elemName == "background") {
			elem = bg;
			rect = bgRect;
			backgroundColour = colour;
		}

		if (elem != null && rect != null) {
			elem.fillRect(rect, colour);
		}

		repaint();
	}

	public function getPercentage(): Float {
		return currentStep * 100 / numberOfSteps;
	}
}
