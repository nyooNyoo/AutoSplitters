state("Infused-Win64-Shipping", "[Steam] 1.02")
{
    int chapterID : 0x3371D88, 0x170, 0x180;
    int checkpointID : 0x3371D88, 0x170, 0x188;
    int shamanID : 0x3371D88, 0x170, 0x2F8;
    bool isMoving : 0x3371D88, 0x170, 0x1E0, 0x974;
    bool isLoading : 0x3371D88, 0x170, 0x170, 0x1A8, 0x28, 0x130;
    float exhaustLevel : 0x3371D88, 0x170, 0x1E0, 0x1228;
}
state("Infused-Win64-Shipping", "[Steam] 1.05")
{
    int chapterID : 0x40AE870, 0x180, 0x240;
    int checkpointID : 0x40AE870, 0x180, 0x248;
    int shamanID : 0x40AE870, 0x180, 0x3B0;
    bool isMoving : 0x40AE870, 0x180, 0x2A0, 0x804;
    bool isLoading : 0x40AE870, 0x180, 0x230, 0x1D8, 0x28, 0x130;
}
state("Infused-Win64-Shipping", "[Epic] 3.92.0")
{
    int chapterID : 0x479C180, 0x180, 0x280;
    int checkpointID : 0x479C180, 0x180, 0x288;
    int shamanID : 0x479C180, 0x180, 0x3F8;
    bool isMoving : 0x479C180, 0x180, 0x2E0, 0x804;
    bool isLoading : 0x479C180, 0x180, 0x270, 0x1D8, 0x28, 0x130;
}

startup
{
    vars.checkpointCounter = 0;
    vars.chapterCounter = 1;

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

    #region Settings
    settings.Add("Splits", true, "Splits");
    settings.Add("chapterSplit", true, "Split on chapter transition", "Splits");
    settings.Add("checkpointSplit", false, "Split on every checkpoint", "Splits");
    settings.Add("autoReset", false, "Reset automatically", "Splits");

    settings.Add("28", false, "28 Shamans", "Splits");
    settings.Add("shamanSplit", true, "Split on getting a shaman", "28");

    settings.Add("Pre 1.05", false, "Pre 1.05");
    settings.Add("exhaustShow", true, "Show your stamina in a text element", "Pre 1.05");

    //settings.Add("debugText", false, "[Debug] Show tracked values");
    #endregion
}

init
{
    int moduleSize = modules.First().ModuleMemorySize;
    switch (moduleSize)
    {
        case 57696256:
            version = "[Steam] 1.02";
            break;
        case 72040448:
            version = "[Steam] 1.05";
            break;
        case 79597568:
            version = "[Epic] 3.92.0";
            break;
        default:
            version = "Unknown " + moduleSize.ToString();
            break;
    }
}

update
{
    
    if(settings["debugText"])
    {
        vars.SetTextComponent("Chapter Counter", vars.chapterCounter.ToString());
        vars.SetTextComponent("Checkpoint Counter", vars.checkpointCounter.ToString());
        vars.SetTextComponent("Shaman", current.shamanID.ToString());
        vars.SetTextComponent("Moving?", current.isMoving.ToString());
        vars.SetTextComponent("Loading?", current.isLoading.ToString());
    }
    

    if(settings["exhaustShow"] && version == "[Steam] 1.02")
    {
        vars.SetTextComponent("Stamina", Math.Round((1 - current.exhaustLevel) * 100).ToString() + "%");
    }
}

start
{
    return current.isMoving;
}

onStart
{
    vars.firstCheckpoint = current.checkpointID;
    vars.checkpointCounter = 0;
    vars.chapterCounter = 1;
}

split
{
    if(settings["shamanSplit"])
    {
        if(current.shamanID != old.shamanID)
        {
            return true;
        }
    }
    
    if(settings["checkpointSplit"])
    {
        return (current.checkpointID != old.checkpointID);
    }

    else if(settings["chapterSplit"])
    {
        if(current.chapterID != old.chapterID)
        {
            vars.chapterCounter++;
            vars.checkpointCounter = 0;
            return true;
        }

        if(current.checkpointID != old.checkpointID) //Because Chapter 5 is a checkpoint in Chapter 4 we just count the checkpoints
        {
            vars.checkpointCounter++;
            return (vars.chapterCounter == 4 && ((!settings["28"] && vars.checkpointCounter == 2 ) || (settings["28"] && vars.checkpointCounter == 4)));
        }
    }
}

isLoading
{
    return current.isLoading;
}

reset
{
    if(settings["autoReset"])
    {
        return ((current.checkpointID != old.checkpointID || current.isLoading != old.isLoading) && current.checkpointID == vars.firstCheckpoint);
    }
}
