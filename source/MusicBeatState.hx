package;

import Conductor.BPMChangeEvent;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
#if mobileC
import mobile.MobileControls;
import mobile.TouchPad;
import flixel.FlxCamera;
import flixel.input.actions.FlxActionInput;
import flixel.util.FlxDestroyUtil;
#end

class MusicBeatState extends FlxUIState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var controls(get, never):Controls;

	public static var mouseX:Float = 0;
	public static var mouseY:Float = 0;
	public static var mouseS:Float = 0;
	public static var mouseA:Bool = true;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	#if mobileC
	public var mobileControls:MobileControls;
	public var virtualPad:TouchPad;

	public var camVPad:FlxCamera;
	public var camControls:FlxCamera;

	var trackedInputsMobileControls:Array<FlxActionInput> = [];
	var trackedInputsVirtualPad:Array<FlxActionInput> = [];

	public function addVirtualPad(DPad:FlxDPadMode, Action:FlxActionMode):Void
	{
		if (virtualPad != null)
			removeVirtualPad();

		virtualPad = new TouchPad(DPad, Action);
		add(virtualPad);

		controls.setVirtualPadUI(virtualPad, DPad, Action);
		trackedInputsVirtualPad = controls.trackedInputsUI;
		controls.trackedInputsUI = [];
	}

	public function removeVirtualPad():Void
	{
		if (trackedInputsVirtualPad.length > 0)
			controls.removeVirtualControlsInput(trackedInputsVirtualPad);

		if (virtualPad != null)
			remove(virtualPad);

		if (camVPad != null)
		{
		  FlxG.cameras.remove(camVPad, false);
		  camVPad = FlxDestroyUtil.destroy(camVPad);
		}
	}

	public function addVirtualPadCamera(DefaultDrawTarget:Bool = false):Void
	{
		if (virtualPad != null)
		{
			camVPad = new FlxCamera();
			camVPad.bgColor.alpha = 0;
			FlxG.cameras.add(camVPad, DefaultDrawTarget);
			virtualPad.cameras = [camVPad];
		}
	}

	public function addMobileControls(DefaultDrawTarget:Bool = false):Void
	{
		if (mobileControls != null)
			removeMobileControls();

		mobileControls = new MobileControls();

		switch (MobileControls.mode)
		{
			case 'Pad-Right' | 'Pad-Left' | 'Pad-Custom':
				controls.setVirtualPadNOTES(mobileControls.virtualPad, RIGHT_FULL, NONE);
			case 'Pad-Duo':
				controls.setVirtualPadNOTES(mobileControls.virtualPad, BOTH_FULL, NONE);
			case 'Hitbox':
				controls.setHitBox(mobileControls.hitbox);
			case 'Keyboard': // do nothing
		}

		trackedInputsMobileControls = controls.trackedInputsNOTES;
		controls.trackedInputsNOTES = [];

		camControls = new FlxCamera();
		camControls.bgColor.alpha = 0;
		FlxG.cameras.add(camControls, DefaultDrawTarget);

		mobileControls.cameras = [camControls];
		mobileControls.visible = false;
		add(mobileControls);
	}

	public function removeMobileControls():Void
	{
		if (trackedInputsMobileControls.length > 0)
			controls.removeVirtualControlsInput(trackedInputsMobileControls);

		if (mobileControls != null)
			remove(mobileControls);
	}
	#end

	override function destroy():Void
	{
		#if mobileC
		if (trackedInputsMobileControls.length > 0)
			controls.removeVirtualControlsInput(trackedInputsMobileControls);

		if (trackedInputsVirtualPad.length > 0)
			controls.removeVirtualControlsInput(trackedInputsVirtualPad);
		#end

		super.destroy();

		#if mobileC
		if (virtualPad != null)
			virtualPad = FlxDestroyUtil.destroy(virtualPad);

		if (mobileControls != null)
			mobileControls = FlxDestroyUtil.destroy(mobileControls);
		#end
	}

	override function create()
	{
		if (transIn != null)
			trace('reg ' + transIn.region);

		super.create();
	}

	override function update(elapsed:Float)
	{
		// everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();

		checkmouse(elapsed, this);

		super.update(elapsed);
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
	}

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		// do literally nothing dumbass
	}

	var loadedCompletely:Bool = false;

	public function load()
	{
		loadedCompletely = true;

		trace("loaded Completely");
	}

	override function remove(Object:FlxBasic, Splice:Bool = false):FlxBasic
	{
		LoadingState.allOfThem.remove(Object);
		return super.remove(Object, Splice);
	}

	override function add(Object:FlxBasic):FlxBasic
	{
		if (Std.isOfType(Object, FlxUI))
			return null;
		LoadingState.allOfThem.push(Object);

		return super.add(Object);
	}

	public static function checkmouse(elapsed:Float, state:FlxState)
	{
		mouseS += elapsed;
		if (Math.abs(mouseX - FlxG.mouse.screenX) > 20 || Math.abs(mouseY - FlxG.mouse.screenY) > 20 || FlxG.mouse.justPressed)
		{
			mouseS = 0;
			mouseX = FlxG.mouse.screenX;
			mouseY = FlxG.mouse.screenY;
		}
		if (mouseS > 2)
		{
			FlxG.mouse.visible = false;
			mouseA = false;
		}
		else
		{
			mouseA = true;
			switch (FlxG.save.data.mouse)
			{
				case 1:
					FlxG.mouse.visible = true;
					FlxG.mouse.useSystemCursor = true;
				case 2:
					FlxG.mouse.visible = false;
					mouseA = false;
				default:
					FlxG.mouse.visible = true;
					FlxG.mouse.useSystemCursor = false;
			}
		}
	}
}
