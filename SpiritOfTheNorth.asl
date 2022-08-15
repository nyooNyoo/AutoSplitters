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
            "LiveSplit | Stray",
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
        {" ", "Chapter1"},
        {" ", "Chapter2"},
        {" ", "Chapter3"},
        {" ", "Chapter4"},
        {" ", "Chapter5"},
        {" ", "Chapter6"},
        {" ", "Chapter7"},
        {" ", "Chapter8"} 
    };

    settings.Add("Splits", true, "Splits");
    settings.Add("chapterSplit", true, "Split on chapter transition", "Splits");
    settings.Add("shamanSplit", false, "Split on getting a shaman", "Splits");

    settings.Add("autoReset", false, "Automatically reset after making a new save");
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

    vars.watchers = new MemoryWatcherList
    {
        new MemoryWatcher<int>(new DeepPointer(vars.GameEngine, 0xD28, 0x38, 0x0, 0x30, 0x2B8, 0x3F0)) { Name = "chapterID"},
        new MemoryWatcher<IntPtr>(new DeepPointer(vars.GameEngine, 0xD28, 0xF0, 0xE0, 0x68)) { Name = "checkpointID" },
        new MemoryWatcher<long>(new DeepPointer(vars.GameEngine, 0xD28, 0x348, 0x90, 0x110)) { Name = "shamansID" },
        new MemoryWatcher<long>(new DeepPointer(vars.GameEngine, 0x)) { Name = "exhaustLevel"},
        new MemoryWatcher<long>(new DeepPointer(vars.UWorld, 0x18)) { Name = "worldFName"}
}

update
{
    current.chapterID = 
    current.chapter = chapters["{current.chapterId} {current.checkpointID}"]

    if(settings["debugValues"])
    {
        vars.SetTextComponent("Chapter", current.map);
    }
}

start
{

}

split
{
    if(current.chapter != old.chapter && 
}

loading
{
    return current.loading;
}

reset
{
    if(old.
}
