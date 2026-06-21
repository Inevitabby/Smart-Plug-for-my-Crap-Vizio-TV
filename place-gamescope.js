var handler = workspace.windowAdded.connect(function(window) {
    if (window.resourceClass === "gamescope") {
        var screens = workspace.screens;
        for (var i = 0; i < screens.length; i++) {
            if (screens[i].name === "HDMI-A-4") {
                workspace.sendClientToScreen(window, screens[i]);
                workspace.windowAdded.disconnect(handler);
                break;
            }
        }
    }
});
