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

    settings.Add("Splits", true, "Splits");
    settings.Add("chapterSplit", true, "Split on chapter transition", "Splits");
    settings.Add("shamanSplit", false, "Split on getting a shaman", "Splits");

    settings.Add("autoReset", false, "Automatically reset after making a new save");
    settings.Add("exhaustShow", false, "Shows your stamina in a new text element (Pre 1.3)");
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

    vars.GetNameFromFName = (Func<long, string>) ( longKey => {
        int key = (int)(longKey & uint.MaxValue);
        int partial = (int)(longKey >> 32);
        int chunkOffset = key >> 16;
        int nameOffset = (ushort)key;
        IntPtr namePoolChunk = memory.ReadValue<IntPtr>((IntPtr)vars.FNamePool + (chunkOffset+2) * 0x8);
        Int16 nameEntry = game.ReadValue<Int16>((IntPtr)namePoolChunk + 2 * nameOffset);
        int nameLength = nameEntry >> 6;
        string output = game.ReadString((IntPtr)namePoolChunk + 2 * nameOffset + 2, nameLength);
        return (partial == 0) ? output : output + "_" + partial.ToString();
    });

    vars.GWorld = vars.GetStaticPointerFromSig("48 8B 5C 24 ?? 48 89 1D ???????? 48 85 DB", 0x8);
    vars.FNamePool = vars.GetStaticPointerFromSig("89 5C 24 ?? 89 44 24 ?? 74 ?? 48 8D 15", 0x13);
    vars.GSyncLoadCount = vars.GetStaticPointerFromSig("33 C0 0F 57 C0 F2 0F 11 05", 0x21);
    
    vars.watchers = new MemoryWatcherList
    {
        new MemoryWatcher<int>(new DeepPointer(vars.GWorld, 0x170, 0x180)) { Name = "chapter"},
        new MemoryWatcher<int>(new DeepPointer(vars.GWorld, 0x170, 0x188)) { Name = "checkpoint"},
        new MemoryWatcher<int>(new DeepPointer(vars.GWorld, 0x170, 0x2F8)) { Name = "shaman"},
        new MemoryWatcher<bool>(new DeepPointer(vars.GWorld, 0x170, 0x1E0, 0x974)) { Name = "isMoving"},
        new MemoryWatcher<bool>(new DeepPointer(vars.GSyncLoadCount)) { Name = "loading"},
        new MemoryWatcher<float>(new DeepPointer(vars.GWorld, 0x170, 0x1E0, 0x1228)) { Name = "exhaustLevel"}
    };
}

update
{
    vars.watchers.UpdateAll(game);
    current.chapter = vars.GetNameFromFName(watchers["chapter"].Current);
    current.checkpoint = vars.watchers["checkpoint"].Current;
    current.shamanID = vars.watchers["shaman"].Current;
    current.isMoving = vars.watchers["isMoving"].Current;
    current.loading = vars.watchers["loading"].Current;

    current.exhaustLevel = (vars.watchers["exhaustLevel"].Current *100).ToString() + "%";

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
