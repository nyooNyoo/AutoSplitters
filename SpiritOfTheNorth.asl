state("Infused-Win64-Shipping"){}

startup
{
    // Asks user to change to game time if LiveSplit is currently set to Real Time.
    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {        
        var timingMessage = MessageBox.Show (
            "This game uses Time without Loads (Game Time) as the main timing method.\n"+
            "LiveSplit is currently set to show Real Time (RTA).\n"+
            "Would you like to set the timing method to Game Time?",
            "LiveSplit | Spirit of The North",
            MessageBoxButtons.YesNo,MessageBoxIcon.Question
        );
        if (timingMessage == DialogResult.Yes)
        {
            timer.CurrentTimingMethod = TimingMethod.GameTime;
        }
    }

    vars.SetTextComponent = (Action<string, string>)((id, text) =>
    {
        var textSettings = timer.Layout.Components.Where(x => x.GetType().Name == "TextComponent").Select(x => x.GetType().GetProperty("Settings").GetValue(x, null));
        var textSetting = textSettings.FirstOrDefault(x => (x.GetType().GetProperty("Text1").GetValue(x, null) as string) == id);
        if (textSetting == null)
        {
            var textComponentAssembly = Assembly.LoadFrom("Components\\LiveSplit.Text.dll");
            var textComponent = Activator.CreateInstance(textComponentAssembly.GetType("LiveSplit.UI.Components.TextComponent"), timer);
            timer.Layout.LayoutComponents.Add(new LiveSplit.UI.Components.LayoutComponent("LiveSplit.Text.dll", textComponent as LiveSplit.UI.Components.IComponent));
            textSetting = textComponent.GetType().GetProperty("Settings", BindingFlags.Instance | BindingFlags.Public).GetValue(textComponent, null);
            textSetting.GetType().GetProperty("Text1").SetValue(textSetting, id);
        }
        if (textSetting != null)
            textSetting.GetType().GetProperty("Text2").SetValue(textSetting, text);
    });

    vars.Chapters = new Dictionary<string, string>()
    {
        {"429437 872547", "Chapter1"},
        {"429542 883115", "Chapter2"},
        {"429640 883119", "Chapter3"},
        {"429738 883137", "Chapter4"},
        {"429738 883153", "Chapter5"},
        {"429934 883185", "Chapter6"},
        {"429836 883177", "Chapter7"},
        {"430032 883197", "Chapter8"} 
    };

    settings.Add("Splits", true, "Splits");
    settings.Add("chapterSplit", true, "Split on chapter transition", "Splits");
    settings.Add("shamanSplit", false, "Split on getting a shaman", "Splits");

    settings.Add("autoReset", false, "Automatically reset after making a new save");
    settings.Add("exhaustShow", false, "Shows your stamina in a new text element");
    settings.Add("IL", false, "Start timer on moving in any chapter (IL Mode)");
    
    settings.Add("debugValues", false, "[Debug] Show tracked values");
}

init
{
    vars.GetStaticPointerFromSig = (Func<string, int, IntPtr>) ( (signature, instructionOffset) => {
        var scanner = new SignatureScanner(game, modules.First().BaseAddress, (int)modules.First().ModuleMemorySize);
        var pattern = new SigScanTarget(signature);
        var location = scanner.Scan(pattern);
        if (location == IntPtr.Zero) return IntPtr.Zero;
        int offset = game.ReadValue<int>((IntPtr)location + instructionOffset);
        return (IntPtr)location + offset + instructionOffset + 0x4;
    });

    vars.UWorld = vars.GetStaticPointerFromSig("TODO");

    vars.watchers = new MemoryWatcherList
    {
        new MemoryWatcher<int>(new DeepPointer(vars.UWorld, 0x170, 0x180)) { Name = "chapterID"},
        new MemoryWatcher<int>(new DeepPointer(vars.UWorld, 0x170, 0x188)) { Name = "checkpointID"},
        new MemoryWatcher<int>(new DeepPointer(vars.UWorld, 0x170, 0x2F8)) { Name = "shamanID"},
        new MemoryWatcher<bool>(new DeepPointer(vars.UWorld, 0x170, 0x1E0, 0x974)) { Name = "isMoving"},
        new MemoryWatcher<bool>(new DeepPointer(vars.UWorld, 0x170, 0x170, 0x1A8, 0x28, 0x130)) { Name = "loading"},
        new MemoryWatcher<float>(new DeepPointer(vars.UWorld, 0x)) { Name = "exhaustLevel"}
    };
}

update
{
    vars.watchers.UpdateAll(game);
    current.chapterID = vars.watchers["chapterID"].current;
    current.checkpointID = vars.watchers["checkpointID"].current;
    current.shamanID = vars.watchers["shamanID"].current;
    current.isMoving = vars.watchers["isMoving"].current;
    current.loading = vars.watchers["loading"].current;

    vars.exhaustLevel = (vars.watchers["exhaustLevel"].current * 100) + "%";

    vars.chapterKey = current.chapterID + " " + current.checkpointID;
    vars.chapter = vars.Chapters[vars.chapterKey];

    if(settings["debugValues"])
    {
        vars.SetTextComponent("CheckpointID", current.checkpointID.ToString());
        vars.SetTextComponent("ChapterID", current.chapterID.ToString());
        vars.SetTextComponent("Chapter", current.chapter);

        vars.SetTextComponent("Moving?", current.isMoving.ToString());
        vars.SetTextComponent("Loading?", current.loading.ToString());
        
    }

    if(settings["exhaustShow"])
    {
        vars.SetTextComponent("Stamina", current.exhaustLevel);
    }
}

start
{
    if((current.chapter == "Chapter1" || settings["IL"]) && isMoving)
    {
        return true;
    }
}

onStart
{
    vars.chaptersVisited = new List<String>(){};
}

split
{
    if(current.chapter != old.chapter && !vars.chaptersVisited.Contains(current.chapter)
    {
        return true;
    }
}

loading
{
    return current.loading;
}

reset
{
    if(current.chapter != old.chapter && current.chapter == "Chapter1")
}
