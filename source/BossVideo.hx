package;

import flixel.FlxG;
import hxvlc.flixel.FlxVideo;

class BossVideo extends FlxVideo
{
	public var canSkip:Bool = false;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override private function postUpdate():Void
	{
		if (canSkip && (controls.ACCEPT #if android || FlxG.android.justReleased.BACK #end))
		{
			FlxG.sound.music.stop();
			dispose();
		}

		super.postUpdate();
	}
}
