state("Infused-Win64-Shipping") {}

startup
{
    // Prompt to switch to Game Time
    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {
        var timingMessage = MessageBox.Show (
            "This game uses Time without Loads (Game Time) as the main timing method.\n" +
            "LiveSplit is currently set to show Real Time (RTA).\n" +
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

    //TODO: 
    //Get actuall chapter and checkpoint values, these are just placeholders
    vars.startingCheckpoints = new Dictionary<string, string>()
    {
        { "00", "00_00"},
        { "01", "01_00"},
        { "02", "02_00"},
        { "03", "03_00"},
        { "04", "04_00"},
        { "05", "05_00"},
        { "06", "06_00"},
        { "07", "07_00"},
    };

    settings.Add("Splits", true, "Splits");
    settings.Add("chapterSplit", true, "Split on chapter transition", "Splits");
    settings.Add("checkpointSplit", false, "Split on every checkpoint", "Splits");
    settings.Add("shamanSplit", false, "Split on getting a shaman", "Splits");
    settings.Add("autoReset", false, "Reset on loading the start of chapter 1", "Splits");

    settings.Add("ILMode", false, "IL Mode");
    settings.Add("ILstart", true, "Start timer on moving in any chapter", "ILMode");
    settings.Add("ILreset", false, "Reset on starting a chapter over", "ILMode");

    //TODO: 
    //conditional exhaustShow only for version != 1.3
    if(version != "1.3"){
    settings.Add("exhaustShow", false, "Shows your stamina in a new text element");}
    settings.Add("debugText", false, "[Debug] Show tracked values");
}

init
{
    int moduleSize = modules.First().ModuleMemorySize;
    switch (moduleSize)
    {
        case 57696256:
            version = "1.2";
            break;
        case 0: //TODO: Get Module Size for 1.3
            version = "1.3";
            break;
        default:
            version = "Unknown" + moduleSize.ToString();
            break;
    }

    var scanner = new SignatureScanner(game, game.BaseAddress, game.ModuleMemorySize);

    //TODO: FName Func
    //vars.GetName = (Action<long, )

    //FnamePool & GSyncLoadCount signatures from Ero
    var FNamePool = new SigScanTarget(3, "89 5C 24 ?? 89 44 24 ?? 74 ?? 48 8D 15");
    var GWorld = new SigScanTarget(3, "48 8B 1D ?? ?? ?? ?? 48 85 DB 74 ?? 41 B0 01");
    var GSyncLoadCount = new new SigScanTarget(21, "33 C0 0F 57 C0 F2 0F 11 05");

    vars.watchers = new MemoryWatcherList
    {
        new MemoryWatcher<long>(new DeepPointer(GWorld, 0x170, 0x180)) { Name = "chapter"},
        new MemoryWatcher<long>(new DeepPointer(GWorld, 0x170, 0x188)) { Name = "checkpoint"},
        new MemoryWatcher<int>(new DeepPointer(GWorld, 0x170, 0x2F8)) { Name = "shaman"},
        new MemoryWatcher<float>(new DeepPointer(GWorld, 0x170, 0x1E0, 0x1228)) { Name = "exhaustLevel"},
        new MemoryWatcher<bool>(new DeepPointer(GWorld, 0x170, 0x1E0, 0x974)) { Name = "moving"},
        new MemoryWatcher<bool>(new DeepPointer(GSyncLoadCount)) { Name = "loading"}
    };
}

update
{
    vars.watchers.UpdateAll(game);

    current.chapter = vars.watchers["chapter"].Current;
    current.checkpoint = vars.watchers["checkpoint"].Current;
    current.shaman = vars.watchers["shaman"].Current;
    current.moving = vars.watchers["moving"].Current;
    current.loading = vars.watchers["loading"].Current;

    current.exhaustLevel = ((1 - vars.watchers["exhaustLevel"].Current) * 100).ToString() + "%";

    if(settings["debugText"])
    {
        vars.SetTextComponent("Chapter", current.chapter.ToString());
        vars.SetTextComponent("Checkpoint", current.checkpoint.ToString());
        vars.SetTextComponent("Shaman", current.shaman.ToString());
        vars.SetTextComponent("Moving?", current.moving.ToString());
        vars.SetTextComponent("Loading?", current.loading.ToString());
    }

    if(settings["exhaustShow"])
    {
        vars.SetTextComponent("Stamina", current.exhaustLevel);
    }
}

start
{
    if(current.checkpoint == "00_00" || settings["ILstart"])
    {
        return current.moving;
    }
}

split
{
    if(settings["chapterSplit"])
    {
        return (current.chapter != old.chapter || (current.checkpoint != old.checkpoint && current.checkpoint == "05_00"));
    }

    if(settings["checkpointSplit"])
    {
        return (current.checkpoint != old.checkpoint)
    }

    if(settings["shamanSplit"])
    {
        return (current.shaman != old.shaman);
    }
}

isLoading
{
    return current.loading;
}

reset
{
    if(settings["autoReset"])
    {
        return (current.checkpoint != old.checkpoint && current.checkpoint == "00_00");
    }

    if(settings["ILreset"])
    {
        return (current.checkpoint != old.checkpoint && vars.startingCheckpoints[current.chapter] == current.checkpoint);

    }
}
