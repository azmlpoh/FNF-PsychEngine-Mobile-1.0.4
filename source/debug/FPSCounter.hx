package debug;

import flixel.FlxG;
import openfl.Lib;
import haxe.Timer;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import lime.system.System as LimeSystem;

class FPSCounter extends TextField
{
	public var currentFPS(default, null):Int;
	public var memoryMegas(get, never):Float;
	public var peakMemory:Float = 0;

	private var times:Array<Float>;
	private var lastFramerateUpdateTime:Float;
	private var updateTime:Int;
	private var framesCount:Int;
	private var prevTime:Int;
	private var latencyTimer:Float = 0;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();
		positionFPS(x, y);
		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;

		var filter = new openfl.filters.GlowFilter(0x000000, 1, 2, 2, 10, 1);
		filters = [filter];

		var format:TextFormat = new TextFormat(Paths.font("vcr.ttf"), 14, color);
		format.align = TextFormatAlign.LEFT;
		defaultTextFormat = format;

		width = 290;
		multiline = true;
		text = "FPS: 0\nLatency: 0ms\nRAM: 0MB (0MB peak)";

		times = [];
		lastFramerateUpdateTime = Timer.stamp();
		prevTime = Lib.getTimer();
		updateTime = prevTime + 500;
		latencyTimer = Timer.stamp();
}
	//感谢DeepSeek大跌的亲手相助

	public dynamic function updateText():Void
	{
		if (memoryMegas > peakMemory) peakMemory = memoryMegas;

		var currentTime:Float = Timer.stamp();
		var latency:Int = Math.round((currentTime - latencyTimer) * 1000);
		latencyTimer = currentTime;

		var currentRAM:String = flixel.util.FlxStringUtil.formatBytes(memoryMegas);
		var peakRAM:String = flixel.util.FlxStringUtil.formatBytes(peakMemory);
		
		currentRAM = StringTools.replace(currentRAM, "MB", "");
		currentRAM = StringTools.replace(currentRAM, "KB", "");
		currentRAM = StringTools.replace(currentRAM, "GB", "");
		peakRAM = StringTools.replace(peakRAM, "MB", "");
		peakRAM = StringTools.replace(peakRAM, "KB", "");
		peakRAM = StringTools.replace(peakRAM, "GB", "");

		text = 'FPS: $currentFPS\nLatency: ${latency}ms\nRAM: ${currentRAM}MB (${peakRAM}MB peak)';

		textColor = 0xFFFFFFFF;
		if (currentFPS < FlxG.stage.window.frameRate * 0.5) textColor = 0xFFFF0000;
	}

	private override function __enterFrame(deltaTime:Float):Void
	{
		if (ClientPrefs.data.fpsRework)
		{
			if (FlxG.stage.window.frameRate != ClientPrefs.data.framerate && FlxG.stage.window.frameRate != FlxG.game.focusLostFramerate)
				FlxG.stage.window.frameRate = ClientPrefs.data.framerate;

			var currentTime = openfl.Lib.getTimer();
			framesCount++;

			if (currentTime >= updateTime)
			{
				var elapsed = currentTime - prevTime;
				currentFPS = Math.ceil((framesCount * 1000) / elapsed);
				framesCount = 0;
				prevTime = currentTime;
				updateTime = currentTime + 500;
			}

			if ((FlxG.updateFramerate >= currentFPS + 5 || FlxG.updateFramerate <= currentFPS - 5) && haxe.Timer.stamp() - lastFramerateUpdateTime >= 1.5 && currentFPS >= 30)
			{
				FlxG.updateFramerate = FlxG.drawFramerate = currentFPS;
				lastFramerateUpdateTime = haxe.Timer.stamp();
			}
		}
		else
		{
			final now:Float = haxe.Timer.stamp() * 1000;
			times.push(now);
			while (times[0] < now - 1000) times.shift();
			
			if (deltaTime < 50) return;
			currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;
		}

		updateText();
	}

	inline function get_memoryMegas():Float return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);

	public inline function positionFPS(X:Float, Y:Float, ?scale:Float = 1)
	{
		scaleX = scaleY = #if android (scale > 1 ? scale : 1) #else (scale < 1 ? scale : 1) #end;
		x = FlxG.game.x + X;
		y = FlxG.game.y + Y;
	}
}