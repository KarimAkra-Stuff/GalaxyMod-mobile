package;

#if HAS_DISCORD_RPC
import discord_rpc.DiscordRpc;
#end 
using StringTools;

class DiscordClient
{
	public function new()
	{
		#if HAS_DISCORD_RPC
		trace("Discord Client starting...");
		DiscordRpc.start({
			clientID: "847320098464727041",
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected
		});
		trace("Discord Client started.");

		while (true)
		{
			DiscordRpc.process();
			sleep(2);
			//trace("Discord Client Update");
		}

		DiscordRpc.shutdown();
		#end
	}

	public static function shutdown()
	{
		#if HAS_DISCORD_RPC
		DiscordRpc.shutdown();
		#end
	}
	
	static function onReady()
	{
		#if HAS_DISCORD_RPC
		DiscordRpc.presence({
			details: "In the Menus",
			state: null,
			largeImageKey: 'icon',
			largeImageText: "Friday Night Funkin' - In the Galaxy"
		});
		#end
	}

	static function onError(_code:Int, _message:String)
	{
		#if HAS_DISCORD_RPC
		trace('Error! $_code : $_message');
		#end
	}

	static function onDisconnected(_code:Int, _message:String)
	{
		#if HAS_DISCORD_RPC
		trace('Disconnected! $_code : $_message');
		#end
	}

	public static function initialize()
	{
		#if HAS_DISCORD_RPC
		var DiscordDaemon = sys.thread.Thread.create(() ->
		{
			new DiscordClient();
		});
		trace("Discord Client initialized");
		#end
	}

	public static function changePresence(details:String, state:Null<String>, ?smallImageKey : String, ?hasStartTimestamp : Bool, ?endTimestamp: Float)
	{
		#if HAS_DISCORD_RPC
		var startTimestamp:Float = if(hasStartTimestamp) Date.now().getTime() else 0;

		if (endTimestamp > 0)
		{
			endTimestamp = startTimestamp + endTimestamp;
		}

		DiscordRpc.presence({
			details: details,
			state: state,
			largeImageKey: 'icon',
			largeImageText: "Friday Night Funkin' - In the Galaxy",
			smallImageKey : smallImageKey,
			// Obtained times are in milliseconds so they are divided so Discord can use it
			startTimestamp : Std.int(startTimestamp / 1000),
            endTimestamp : Std.int(endTimestamp / 1000)
		});

		//trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
		#end
	}
}
