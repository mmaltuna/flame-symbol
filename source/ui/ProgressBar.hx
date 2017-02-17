package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;

import utils.Utils;

class ProgressBar extends FlxTypedGroup<FlxSprite> {
	private var spriteMap: FlxSprite;

	private var x: Int;
	private var y: Int;

	public var currentValue: Int;
	public var minValue: Int;
	public var maxValue: Int;
	private var lengthInPixels: Int;

	private var numberOfSteps: Int;
	private var currentStep: Int;
	private var stepSize: Int;

	private var colour: FlxColor;

	private var callback: Void -> Void;

	public function new(x: Int, y: Int, length: Int, min: Int, max: Int) {
		super();

		this.x = x;
		this.y = y;

		currentValue = max;
		minValue = min;
		maxValue = max;

		colour = FlxColor.RED;

		numberOfSteps = 2 + Std.int((length - 4) / 2);
		currentStep = numberOfSteps;

		for (i in 0 ... numberOfSteps) {
			var step: FlxSprite = new FlxSprite(x + i * 2, y);
			step.loadGraphic("assets/images/progress-bar.png", true, 2, 4);
			step.replaceColor(FlxColor.MAGENTA, colour);
			step.animation.frameIndex = getFrameIndex(i);

			add(step);
		}

		updateParams();

		callback = null;
	}

	public function move(x: Int, y: Int) {
		var offsetX = x - this.x;
		var offsetY = y - this.y;

		for (member in members) {
			member.x += offsetX;
			member.y += offsetY;
		}
	}

	public function setValue(value: Int, onValueSet: Void -> Void = null) {
		if (value >= minValue && value <= maxValue) {
			currentValue = value;
			callback = onValueSet;
		}
	}

	public function updateParams() {
		stepSize = Utils.max(1, Std.int((maxValue - maxValue) / numberOfSteps));
		currentStep = Std.int((currentValue - minValue) / stepSize);

		trace("stepSize = " + stepSize);
		trace("currentStep = " + currentStep);

		for (i in 0 ... members.length) {
			members[i].animation.frameIndex = getFrameIndex(i);
			if (i > currentStep)
				members[i].animation.frameIndex += 3;
		}
	}

	override public function update(elapsed: Float) {
		var targetStep: Int = Std.int((currentValue - minValue) / stepSize);

		if (currentStep > targetStep) {

			trace("targetStep = " + targetStep);
			trace("currentStep = " + currentStep);

			currentStep--;
			members[currentStep].animation.frameIndex += 3;
		} else if (currentStep < targetStep) {
			members[currentStep].animation.frameIndex = getFrameIndex(currentStep);
			currentStep++;
		} else if (currentStep == targetStep && callback != null) {
			callback();
			callback = null;
		}

		super.update(elapsed);
	}

	private function getFrameIndex(index: Int) {
		var frameIndex = 0;

		if (index == 0)
			frameIndex = 0;
		else if (index > 0 && index < numberOfSteps - 1)
			frameIndex = 1;
		else if (index == numberOfSteps - 1)
			frameIndex = 2;

		return frameIndex;
	}
}
