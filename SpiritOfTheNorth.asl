state("Infused-Win64-Shipping"){}

startup
{
    // Prompt to switch to Game Time
    if (timer.CurrentTimingMethod == TimingMethod.RealTime)
    {
        var timingMessage = MessageBox.Show (
            "This game requires Time without Loads (Game Time).\n" +
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

    //Func from Micrologist
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

    vars.chapterNames = new Dictionary<int, string>()
    {
        //1.02 Chapters
        {429437, "Chapter 1"},
        {429542, "Chapter 2"},
        {429640, "Chapter 3"},
        {429738, "Chapter 4"},
        {429934, "Chapter 6"},
        {429836, "Chapter 7"},
        {430032, "Chapter 8"},
        //1.05 Chapters
        {471950, "Chapter 1"},
        {472055, "Chapter 2"},
        {472153, "Chapter 3"},
        {472251, "Chapter 4"},
        {472447, "Chapter 6"},
        {472349, "Chapter 7"},
        {472545, "Chapter 8"}
    };

    #region Settings
    settings.Add("Splits", true, "Splits");
    settings.Add("chapterSplit", true, "Split on chapter transition", "Splits");
    settings.Add("checkpointSplit", false, "Split on every checkpoint", "Splits");
    settings.Add("28", false, "28 Shamans", "Splits");
    settings.Add("shamanSplit", true, "Split on getting a shaman", "28");
    settings.Add("autoReset", false, "Reset on loading start", "Splits");

    settings.Add("ILmode", false, "IL Mode");
    settings.Add("ILstart", true, "Start timer on moving in any chapter", "ILmode");
    settings.Add("ILreset", false, "Reset on starting a chapter over", "ILmode");

    settings.Add("1.02", true, "Pre 1.05");
    settings.Add("exhaustShow", false, "Show your stamina in a text element", "1.02");
    settings.Add("debugText", false, "[Debug] Show tracked values");
    #endregion
}

init
{
    int moduleSize = modules.First().ModuleMemorySize;
    print("[INFUSED]" + moduleSize.ToString());
    switch (moduleSize)
    {
        case 57696256:
            version = "1.02";
            vars.GWorld = 0x3371D88;
            vars.watchers = new MemoryWatcherList
            {
                new MemoryWatcher<int>(new DeepPointer(vars.GWorld, 0x170, 0x180)) { Name = "chapterID"},
                new MemoryWatcher<int>(new DeepPointer(vars.GWorld, 0x170, 0x188)) { Name = "checkpoint"},
                new MemoryWatcher<int>(new DeepPointer(vars.GWorld, 0x170, 0x2F8)) { Name = "shaman"},
                new MemoryWatcher<float>(new DeepPointer(vars.GWorld, 0x170, 0x1E0, 0x1228)) { Name = "exhaustLevel"},
                new MemoryWatcher<bool>(new DeepPointer(vars.GWorld, 0x170, 0x1E0, 0x974)) { Name = "moving"},
                new MemoryWatcher<bool>(new DeepPointer(vars.GWorld, 0x170, 0x170, 0x1A8, 0x28, 0x130)) { Name = "loading"}
            };

            break;
        case 72040448:
            version = "1.05";
            vars.GWorld = 0x40AE870;
            vars.watchers = new MemoryWatcherList
            {
                new MemoryWatcher<int>(new DeepPointer(vars.GWorld, 0x180, 0x240)) { Name = "chapterID"},
                new MemoryWatcher<int>(new DeepPointer(vars.GWorld, 0x180, 0x248)) { Name = "checkpoint"},
                new MemoryWatcher<int>(new DeepPointer(vars.GWorld, 0x180, 0x3B0)) { Name = "shaman"},
                new MemoryWatcher<bool>(new DeepPointer(vars.GWorld, 0x180, 0x2A0, 0x804)) { Name = "moving"},
                new MemoryWatcher<bool>(new DeepPointer(vars.GWorld, 0x180, 0x230, 0x1D8, 0x28, 0x130)) { Name = "loading"}
            };

            break;
        default:
            version = "Unknown" + moduleSize.ToString();
            break;
    }
}

update
{
    #region Variable Updates
    vars.watchers.UpdateAll(game);

    current.chapterID = vars.watchers["chapterID"].Current;
    current.chapter = vars.chapterNames[current.chapterID];
    current.checkpoint = vars.watchers["checkpoint"].Current;
    current.shaman = vars.watchers["shaman"].Current;
    current.moving = vars.watchers["moving"].Current;
    current.loading = vars.watchers["loading"].Current;

    if(version != "1.05")
    {
        current.exhaustLevel = Math.Round((1 - vars.watchers["exhaustLevel"].Current) * 100).ToString() + "%";
    }
    #endregion

    if(settings["debugText"])
    {
        vars.SetTextComponent("Chapter", current.chapter);
        vars.SetTextComponent("Checkpoint", current.checkpoint.ToString());
        vars.SetTextComponent("Shaman", current.shaman.ToString());
        vars.SetTextComponent("Moving?", current.moving.ToString());
        vars.SetTextComponent("Loading?", current.loading.ToString());
    }

    if(settings["exhaustShow"] && version != "1.05")
    {
        vars.SetTextComponent("Stamina", current.exhaustLevel);
    }
}

start
{
    if(settings["ILstart"])
    {
        return current.moving;
    }

    else if(current.chapter == "Chapter 1")
    {
        return current.moving;
    }
}

onStart
{
    vars.firstCheckpoint = current.checkpoint;
    vars.checkpointCounter = 0;
}

split
{
    if(settings["shamanSplit"])
    {
        if(current.shaman != old.shaman)
        {
            return true;
        }
    }
    
    if(settings["checkpointSplit"])
    {
        return (current.checkpoint != old.checkpoint);
    }

    else if(settings["chapterSplit"] || settings["ILmode"])
    {
        if(current.chapter == "Chapter 4" && current.checkpoint != old.checkpoint) //Because Chapter 5 is a checkpoint in Chapter 4 we just count the checkpoints
        {
            vars.checkpointCounter++;
            return ((!settings["28"] && vars.checkpointCounter == 2 ) || (settings["28"] && vars.checkpointCounter == 4));
        }
        return (current.chapter != old.chapter);
    }
}

isLoading
{
    return current.loading;
}

reset
{
    if(settings["autoReset"] || settings["ILreset"])
    {
        return ((current.checkpoint != old.checkpoint || current.loading != old.loading) && current.checkpoint == vars.firstCheckpoint);
    }
}
