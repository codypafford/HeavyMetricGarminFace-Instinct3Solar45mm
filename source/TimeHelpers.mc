import Toybox.Lang;

module TimeHelpers {
    function getFormattedTime(clockTime) {
        // Calculate 12-hour format
        var hour12 = clockTime.hour;
        if (hour12 > 12) {
            hour12 -= 12;
        } else if (hour12 == 0) {
            hour12 = 12;
        }
                
        // Format string (e.g., "3:05")
        var timeString = Lang.format("$1$:$2$", [
            hour12,
            clockTime.min.format("%02d")
        ]);
        
        return timeString;
    }
}