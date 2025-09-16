package options;

class PerformanceSettingsSubState extends BaseOptionsMenu
{
	var limitCount:Option;
	var cacheCount:Option;
	var gcRateOption:Option;
	
	public function new()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Performance Settings", null);
		#end
		
		title = 'Performance Settings';
		rpcTitle = 'Performance Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Better Recycling',
			"If checked, the game will use NoteGroup's recycle system.\nIt boosts game performance massively.",
			'betterRecycle',
			BOOL);
		addOption(option);

		var option:Option = new Option('Max Notes Shown:',
			"How many notes do you wanna display? To unlimited, set the value to 0.",
			'limitNotes',
			INT);
		option.scrollSpeed = 30;
		option.minValue = 0;
		option.maxValue = 99999;
		option.changeValue = 1;
		option.decimals = 0;
		option.onChange = onChangeLimitCount;
		limitCount = option;
		addOption(option);

		var option:Option = new Option('Cache Notes:',
			"Enables recycling of a specified number of items before playing.\nIt cuts time of newing instances. To disable, set the value to 0.\nYou need the same amount of RAM as the value chosen.",
			'cacheNotes',
			INT);
		option.scrollSpeed = 30;
		option.minValue = 0;
		option.maxValue = 99999;
		option.changeValue = 1;
		option.decimals = 0;
		option.onChange = onChangeCacheCount;
		cacheCount = option;
		addOption(option);

        var option:Option = new Option('Process Notes before Spawning',
			"If checked, it process notes before they spawn.\nIt boosts game performance vastly.\nIt is recommended to enable this option.",
			'processFirst',
			BOOL);
		addOption(option);

        var option:Option = new Option('Skip Process for Spawned Note',
			"If checked, enables Skip Note Function.\nIt boosts game performance vastly, but it only works in specific situations.\nIf you don't understand, enable this.",
			'skipSpawnNote',
			BOOL);
		addOption(option);

        var option:Option = new Option('Optimize Process for Spawned Note',
			"If checked, it judges whether or not to do hit process\nimmediately when a note spawned. It boosts game performance vastly,\nbut it only works in specific situations. If you don't understand, enable this.",
			'optimizeSpawnNote',
			BOOL);
		addOption(option);

        var option:Option = new Option('noteHitPreEvent',
			"If unchecked, the game will not send any noteHitPreEvent on Lua/HScript.",
			'noteHitPreEvent',
			BOOL);
		addOption(option);

        var option:Option = new Option('noteHitEvent',
			"If unchecked, the game will not send any noteHitEvent on Lua/HScript.\nNot recommended to disable this option.",
			'noteHitEvent',
			BOOL);
		addOption(option);

		var option:Option = new Option('spawnNoteEvent',
			"If unchecked, the game will not send spawn event\non Lua/HScript for spawned notes. Improves performance.",
			'spawnNoteEvent',
			BOOL);
		addOption(option);

		var option:Option = new Option('noteHitEvents for Skipped Notes',
			"If unchecked, the game will not send any hit event\non Lua/HScript for skipped notes. Improves performance.",
			'skipNoteEvent',
			BOOL);
		addOption(option);

        var option:Option = new Option('Disable Garbage Collector',
			"If checked, You can play the main game without GC lag.\nIt only works on loading/playing charts.",
			'disableGC',
			BOOL);
		addOption(option);

		var option:Option = new Option('Garbage Collection Rate',
			"Have GC run automatically based on this option.\nSpecified by Frame and It turn on GC forcely.\n0 means disabled. Beware of memory leaks!",
			'gcRate',
			INT);
		addOption(option);
		
		option.minValue = 0;
		option.maxValue = 10000;
		option.scrollSpeed = 60;
		option.decimals = 0;
		option.onChange = onChangeGCRate;
		gcRateOption = option;

		var option:Option = new Option('Run Major Garbage Collection',
			"Increase the GC range and reduce memory usage.\nIt's for upper option.",
			'gcMain',
			BOOL);
		addOption(option);

        super();
    }

	function onChangeLimitCount(){
		limitCount.scrollSpeed = interpolate(30, 50000, (holdTime - 0.5) / 10, 3);
	}

	function onChangeCacheCount(){
		cacheCount.scrollSpeed = interpolate(30, 50000, (holdTime - 0.5) / 10, 3);
	}

	function onChangeGCRate(){
		gcRateOption.scrollSpeed = interpolate(30, 50000, (holdTime - 0.5) / 10, 3);
	}

	function interpolate(min:Float, max:Float, t:Float, ?power:Float = 1):Float {
		return Math.pow(t, power) * (max - min) + min;
	}
}
