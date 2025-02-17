package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.addons.api.FlxGameJolt;
import haxe.Timer;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import lime.system.System as LimeSystem;
import openfl.Lib;
import lime.utils.Log as LimeLogger;
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import sys.FileSystem;
import sys.io.File;
#if cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#elseif java
import java.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end

using StringTools;
class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = #if mobile 60 #else 120 #end; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	public static var fps:FPSCounter;
	public static var base:Main;
	public static var skipNextDump:Bool = false;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		base = new Main();
		Lib.current.addChild(base);
	}

	public function new()
	{
		super();

		#if android
		Sys.setCwd(haxe.io.Path.addTrailingSlash(android.content.Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(LimeSystem.documentsDirectory);
		#end
		
		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		uncaughtErrorHandler();

		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			#if !mobile
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
			#end
		}

		#if !debug
		initialState = TitleState;
		#end

		FlxG.save.bind('funkin', 'ninjamuffin99');

		if (FlxG.save.data.FPS != null)
		{
			framerate = FlxG.save.data.FPS;
		}

		#if mobile
		if(FlxG.save.data.mouse == null)
		{
			FlxG.save.data.mouse = 2;
			FlxG.save.flush();
		}
		#end

		addChild(new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, skipSplash, startFullscreen));

		fps = new FPSCounter(10, 3, 0xFFFFFF);
		fps.visible = !FlxG.save.data.showFPS;
		addChild(fps);

		#if !mobile
		FlxG.autoPause = false;
		#end

		#if android
		FlxG.android.preventDefaultKeys = [flixel.input.android.FlxAndroidKey.BACK];
		#end
	}

	public static function clearCache()
	{
		clearMajor();
		if(skipNextDump) return;
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null)
			{
				Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}
		Assets.cache.clear("songs");
	}

	public static function clearMajor() {
		#if cpp
		Gc.run(true);
		Gc.compact();
		#elseif hl
		Gc.major();
		#elseif (java || neko)
		Gc.run(true);
		#end
		openfl.system.System.gc();
	}

	/**
	 * Uncaught error handler, original made by: Sqirra-RNG and YoshiCrafter29
	 */
	public static function uncaughtErrorHandler():Void
	{
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onError);
		Lib.application.onExit.add(function(exitCode:Int)
		{
			if (Lib.current.loaderInfo.uncaughtErrorEvents.hasEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR))
				Lib.current.loaderInfo.uncaughtErrorEvents.removeEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onError);
		});
	}

	private static function onError(e:UncaughtErrorEvent):Void
	{
		var stack:Array<String> = [];
		stack.push(e.error);

		for (stackItem in CallStack.exceptionStack(true))
		{
			switch (stackItem)
			{
				case CFunction:
					stack.push('C Function');
				case Module(m):
					stack.push('Module ($m)');
				case FilePos(s, file, line, column):
					stack.push('$file (line $line)');
				case Method(classname, method):
					stack.push('$classname (method $method)');
				case LocalFunction(name):
					stack.push('Local Function ($name)');
			}
		}

		e.preventDefault();
		e.stopPropagation();
		e.stopImmediatePropagation();

		final msg:String = stack.join('\n');

		#if sys
		try
		{
			if (!FileSystem.exists('logs'))
				FileSystem.createDirectory('logs');

			File.saveContent('logs/'
				+ Lib.application.meta.get('file')
				+ '-'
				+ Date.now().toString().replace(' ', '-').replace(':', "'")
				+ '.txt',
				msg + '\n');
		}
		catch (e:Dynamic)
		{
			#if (android && debug)
			Toast.makeText("Error!\nClouldn't save the crash dump because:\n" + e, Toast.LENGTH_LONG);
			#else
			LimeLogger.println("Error!\nClouldn't save the crash dump because:\n" + e);
			#end
		}
		#end

		LimeLogger.println(msg);
		Lib.application.window.alert(msg, 'Error!');
		LimeSystem.exit(1);
	}

	// public static function syncTrophy():Array<Int>
	// {
	// 	var tro:Array<Int> = [];
	// 	if (FlxG.save.data.trophies == null)
	// 		return [];
	// 	if (FlxG.save.data.trophiesC == null)
	// 		FlxG.save.data.trophiesC = [];
	// 	var kk:Array<Int> = FlxG.save.data.trophies.copy();
	// 	var ss:Array<Int> = FlxG.save.data.trophiesC.copy();
	// 	for (i in ss)
	// 		kk.remove(i);
	// 	trace(FlxG.save.data.trophiesC);
	// 	for (i in kk)
	// 	{
	// 		var e:Bool = true;
	// 		FlxGameJolt.fetchTrophy(i, function(a:Dynamic)
	// 		{
	// 			trace(a);
	// 			var m = true;
	// 			if (!a.get("achieved"))
	// 			{
	// 				FlxGameJolt.addTrophy(i, function(z:Dynamic)
	// 				{
	// 					if (z.get("success"))
	// 						FlxG.save.data.trophiesC.push(i);
	// 					m = false;
	// 				});
	// 				tro.push(i);
	// 			}
	// 			else
	// 			{
	// 				m = false;
	// 				FlxG.save.data.trophiesC.push(i);
	// 			}
	// 			var k:Int = 0;
	// 			while (m && k < 30)
	// 			{
	// 				k += 1;
	// 				#if PRELOAD_ALL
	// 				Sys.sleep(0.1);
	// 				#end
	// 			}
	// 			e = false;
	// 		});
	// 		var k:Int = 0;
	// 		while (e && k < 30)
	// 		{
	// 			k += 1;
	// 			#if PRELOAD_ALL
	// 			Sys.sleep(0.1);
	// 			#end
	// 		}
	// 	}
	// 	trace(FlxG.save.data.trophies);
	// 	return tro;
	// }

	// public static function syncData()
	// {
	// 	var save:Saving = new Saving();
	// 	base.addChild(save);
	// 	#if PRELOAD_ALL
	// 	sys.thread.Thread.create(() ->
	// 	{
	// 		var task:Bool = true;

	// 		var wp:String = "";
	// 		task = true;
	// 		for (i in StoryMenuState.weekPassed)
	// 		{
	// 			for (j in i)
	// 			{
	// 				wp += j ? "1" : "0";
	// 				wp += ",";
	// 			}
	// 			wp = wp.substr(0, wp.length - 1);
	// 			wp += ";";
	// 		}
	// 		wp = wp.substr(0, wp.length - 1);
	// 		FlxGameJolt.setData("weekPassed", wp, true, function(e:Dynamic)
	// 		{
	// 			task = false;
	// 		});

	// 		var sc:String = "";
	// 		var k:Int = 0;
	// 		while (task)
	// 			Sys.sleep(0.1);
	// 		task = true;
	// 		for (i in Highscore.songScores.keys())
	// 		{
	// 			sc += i + ":" + Highscore.songScores.get(i) + ",";
	// 		}
	// 		sc = sc.substr(0, sc.length - 1);
	// 		FlxGameJolt.setData("songScores", sc, true, function(e:Dynamic)
	// 		{
	// 			task = false;
	// 		});

	// 		var sa:String = "";
	// 		var k:Int = 0;
	// 		while (task && k < 30)
	// 		{
	// 			k += 1;
	// 			Sys.sleep(0.1);
	// 		}
	// 		task = true;
	// 		for (i in Highscore.songAccs.keys())
	// 		{
	// 			sa += i + ":" + Highscore.songAccs.get(i) + ",";
	// 		}
	// 		sa = sa.substr(0, sa.length - 1);
	// 		FlxGameJolt.setData("songAccs", sa, true, function(e:Dynamic)
	// 		{
	// 			task = false;
	// 		});

	// 		var sco:String = "";
	// 		var k:Int = 0;
	// 		while (task && k < 30)
	// 		{
	// 			k += 1;
	// 			Sys.sleep(0.1);
	// 		}
	// 		task = true;
	// 		for (i in Highscore.songCombos.keys())
	// 		{
	// 			sco += i + ":" + Highscore.songCombos.get(i) + ",";
	// 		}
	// 		sco = sco.substr(0, sco.length - 1);
	// 		FlxGameJolt.setData("songCombos", sco, true, function(e:Dynamic)
	// 		{
	// 			task = false;
	// 		});

	// 		var k:Int = 0;
	// 		while (task && k < 30)
	// 		{
	// 			k += 1;
	// 			Sys.sleep(0.1);
	// 		}
	// 		base.removeChild(save);
	// 	});
	// 	#end
	// }
}

// class Saving extends TextField
// {
// 	/**
// 		The current frame rate, expressed using frames-per-second
// 	**/
// 	private var up:Bool = true;

// 	public function new(color:Int = 0xffff00)
// 	{
// 		super();

// 		this.x = 0;
// 		this.y = 10;

// 		selectable = false;
// 		mouseEnabled = false;
// 		defaultTextFormat = new TextFormat("VCR OSD Mono", 30, color);
// 		text = "Syncing...";
// 		this.alpha = 0;
// 		this.x = Lib.application.window.width - 200;
// 		width = 200;

// 		#if flash
// 		addEventListener(Event.ENTER_FRAME, function(e)
// 		{
// 			var time = Lib.getTimer();
// 			__enterFrame(time - currentTime);
// 		});
// 		#end
// 	}

// 	// Event Handlers
// 	@:noCompletion
// 	private #if !flash override #end function __enterFrame(deltaTime:Float):Void
// 	{
// 		if (up)
// 		{
// 			alpha += 0.02;
// 			if (alpha >= 1)
// 				up = false;
// 		}
// 		else
// 		{
// 			alpha -= 0.02;
// 			if (alpha <= 0)
// 				up = true;
// 		}
// 		x = Lib.application.window.width - 200;
// 	}
// }
