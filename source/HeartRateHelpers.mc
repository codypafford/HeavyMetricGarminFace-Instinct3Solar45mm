using Toybox.UserProfile;
using Toybox.Time;

module HeartRateHelpers {
    function getHeartRateMessage(currentHr, maxHr) {
        if (maxHr == 0 || maxHr == null) { return ""; }
        
        // Calculate percentage
        var percentage = (currentHr.toFloat() / maxHr.toFloat()) * 100;
        
        // Return message based on threshold
        if (percentage < 50) { return "REST"; }
        else if (percentage < 60) { return "LITE"; }
        else if (percentage < 70) { return "FAT "; }
        else if (percentage < 80) { return "AERO"; }
        else if (percentage < 90) { return "HARD"; }
        else { return "MAX!"; }
    }

    function calculateMaxHrByAge() {
        // 1. Get user profile to find birth year
        var profile = UserProfile.getProfile();
        
        // 2. Get the current year
        var now = Time.now();
        var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var currentYear = info.year;
        
        // 3. Calculate age
        var age = null;
        if (profile.birthYear != null) {
            age = currentYear - profile.birthYear;
        }

        // 4. Standard Formula: 220 - age
        var maxHr = 220 - age;
        
        return maxHr;
    }
}