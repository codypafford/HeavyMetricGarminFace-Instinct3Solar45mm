import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Time.Gregorian;
import Toybox.Lang;
import Toybox.Activity;
using Toybox.Time;

class MyProjectApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    // This is the "Ignition" that tells the watch to load your face
    function getInitialView() {
        return [ new MyWatchFace() ];
    }
}

class MyWatchFace extends WatchUi.WatchFace {
    var timer;

    // HR
    const HEART_RATE_PLACEHOLDER = "--";

    // Weather
    var lastWeatherFetchTime = 0;
    var cachedConditions = null;
    const WEATHER_UPDATE_INTERVAL = 15 * 60; // 15 minutes in seconds

    // Battery
    var lastSystemStatsFetchTime = 0;
    var cachedSystemStats= null;
    const SYSTEM_STATS_UPDATE_INTERVAL = 5 * 60; // 5 minutes in seconds

    // Cached Activity
    var cachedSteps = 0;
    var cachedStepGoal = 7500; // Default if not found
    var cachedDistanceMiles = 0.0;
    var cachedCalories = 0;
    var cachedTimeToRecovery = 0;

    // Called when the watch enters sleep mode (e.g., wrist down)
    function onEnterSleep() {
        timer.stop();
        WatchUi.requestUpdate(); // Force a redraw to hide seconds
    }

    // Called when the watch exits sleep mode (e.g., wrist up)
    function onExitSleep() {
        updateActivityData();
        timer.start(method(:updateActivityData), 60000, true);
        WatchUi.requestUpdate(); // Force a redraw to show seconds
    }

    function onShow() {
        updateActivityData();
        // Start the timer when the watch face is active
        timer.start(method(:updateActivityData), 60000, true);
        WatchUi.requestUpdate(); // Initial call
    }

    function onHide() {
        // Stop the timer when the watch face is no longer visible
        timer.stop();
    }

    function initialize() {
        WatchFace.initialize();
        timer = new Timer.Timer();
    }

    function onPartialUpdate(dc) {
        partialUpdateHeartRate(dc);
        partialUpdateSeconds(dc);
    }

    function onUpdate(dc) {
        // Clear Screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        drawActivityData(dc); // On a timer to update fresh data
        drawHeartRate(dc, null); // Uses partial updates/clips
        drawDate(dc); // Not cached
        drawTime(dc); // Seconds are partialUpdated and Hours/Mins are not
        drawBattery(dc); // Cached
        drawWeather(dc); // Cached
    }

    function updateActivityData() {
        var info = ActivityMonitor.getInfo();

        if (info != null) {
            if (info.steps != null) { cachedSteps = info.steps; }
            if (info.stepGoal != null) { cachedStepGoal = info.stepGoal; }
            if (info.distance != null) { cachedDistanceMiles = info.distance / 160934.4; }
            if (info.calories != null) { cachedCalories = info.calories; }
            if (info.timeToRecovery != null) { cachedTimeToRecovery = info.timeToRecovery; }
        }
    }

    function drawActivityData(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var x = 3;
        var y = 110;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        ShapeHelpers.drawRunner(dc, x + 6, y + 15);
        dc.drawText(x + 15, y, Graphics.FONT_XTINY, cachedSteps, Graphics.TEXT_JUSTIFY_LEFT);
        var distStr = cachedDistanceMiles.format("%.2f") + " mi";
        dc.drawText(x + 8, y + 15, Graphics.FONT_XTINY, distStr, Graphics.TEXT_JUSTIFY_LEFT);
        drawStepGoalBar(dc, 90, y, cachedSteps, cachedStepGoal);

        var boxX = 36;
        var boxY = 30;
        var boxWidth = 35;
        
        // 2. Draw Number of Calories
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(boxX + (boxWidth/2), boxY + 4, Graphics.FONT_TINY, cachedCalories.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        
        // 3. Draw Subtext "CAL"
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(boxX + (boxWidth/2), boxY + 20, Graphics.FONT_XTINY, "CAL", Graphics.TEXT_JUSTIFY_CENTER);

        // Recovery
        drawRecovery(dc, cachedTimeToRecovery, 130, 120);
    }

    function drawRecovery(dc, recoveryHours, x, y) {
        dc.drawText(x, y, Graphics.FONT_GLANCE_NUMBER, recoveryHours + "HR.", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawStepGoalBar(dc, x, y, steps, stepGoal) {
        // --- VERTICAL STEP GOAL BAR ---
        var barX = x;       // Positioned on the right side
        var barY = y;       // Starting Y position
        var barWidth = 8;     // Width of the bar
        var barHeight = 40;   // Total height of the bar

        // Calculate percentage
        var percentage = steps.toFloat() / stepGoal.toFloat();
        if (percentage > 1.0) { percentage = 1.0; } // Cap at 100%

        // Draw Background Bar
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(barX, barY, barWidth, barHeight);

        // Draw Foreground Progress Bar
        // Fill from bottom up
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var progressHeight = (barHeight * percentage).toNumber();
        dc.fillRectangle(barX, (barY + barHeight) - progressHeight, barWidth, progressHeight);
    }

    function partialUpdateHeartRate(dc) {
        // Set clip around heart
        var x = 15;
        var y = 15;
        var width = 42;
        var height = 20;
        dc.setClip(x, y, width, height);
        // Clear only that region
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        // Draw Heart Rate
        // Fetch data here
        var info = Activity.getActivityInfo();
        var hr = (info != null && info.currentHeartRate != null) 
            ? info.currentHeartRate.toString() 
            : HEART_RATE_PLACEHOLDER;
        drawHeartRate(dc, hr);
        // Can't forget to clear clip
        dc.clearClip();
    }

    function drawHeartRate(dc, hr) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (hr == null) {
            var info = Activity.getActivityInfo();
            hr = HEART_RATE_PLACEHOLDER; // Default if not wearing the watch

            if (info != null && info.currentHeartRate != null) {
                hr = info.currentHeartRate.toString();
            }
        }

        var x = 33;
        var y = 13;
        dc.drawText(x, y, Graphics.FONT_TINY, hr, Graphics.TEXT_JUSTIFY_CENTER);

        x = x + 20;
        y = y + 10;
        // Draw the two top "humps"
        dc.fillCircle(x - 2, y, 2); // Left hump
        dc.fillCircle(x + 2, y, 2); // Right hump

        // 2. Draw the bottom triangle point (upside down triangle)
        // Use a "Polygon" (an array of [x, y] points)
        dc.fillPolygon([
            [x - 4, y + 1], // Left corner
            [x + 4, y + 1], // Right corner
            [x, y + 6]      // Bottom point
        ]);

        // Show text beside it
        var maxHr = HeartRateHelpers.calculateMaxHrByAge();
        if (maxHr != null && !hr.equals(HEART_RATE_PLACEHOLDER)) {
            var msg = HeartRateHelpers.getHeartRateMessage(hr, maxHr);
            dc.setPenWidth(1);
            dc.drawText(62, 13, Graphics.FONT_XTINY, msg, Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    function drawDate(dc) {
         // Get the current moment and convert to info
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_MEDIUM); // FORMAT_MEDIUM gives "Sat", FORMAT_LONG gives "Saturday"

        // 2. Format the string: "Saturday 28"
        // $1$ = Day of week (Saturday), $2$ = Day of month (28)
        var dayOfWeek = Lang.format("$1$", [info.day_of_week]);

        var dayOfMonth = Lang.format("$1$ $2$", [info.month, info.day]);

        // Draw it
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(142, 10, Graphics.FONT_LARGE, dayOfWeek, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(142, 33, Graphics.FONT_SMALL, dayOfMonth, Graphics.TEXT_JUSTIFY_CENTER);

        // Line to left of date
        dc.drawLine(0, 36, 104, 36);
    }

    function drawWeather(dc) {
        var currentTime = System.getTimer() / 1000;

        if (cachedConditions == null || (currentTime - lastWeatherFetchTime) > WEATHER_UPDATE_INTERVAL) {
            var newConditions = Weather.getCurrentConditions();
            if (newConditions != null) {
                cachedConditions = newConditions;
                lastWeatherFetchTime = currentTime;
            }
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        // 1. Is there any weather data at all? (Phone might be disconnected)
        if (cachedConditions != null) {
            
            var now = Time.now();
            var sunrise = Weather.getSunrise(cachedConditions.observationLocationPosition, now);
            var sunset = Weather.getSunset(cachedConditions.observationLocationPosition, now);

            // 2. Is it Day or Night?
            var isDay = now.greaterThan(sunrise) && now.lessThan(sunset);

            // What is the sky doing?
            if (cachedConditions.condition == Weather.CONDITION_CLEAR || cachedConditions.condition == Weather.CONDITION_FAIR) {
                if (isDay) {
                    // DRAW A SUN (Clear + Day)
                    WeatherHelpers.drawSun(dc, 84, 100);
                } else {
                    // DRAW A MOON (Clear + Night)
                    WeatherHelpers.drawMoon(dc, 84, 101);
                }
            } 
            else if (cachedConditions.condition == Weather.CONDITION_CLOUDY 
                || cachedConditions.condition == Weather.CONDITION_PARTLY_CLOUDY 
                || cachedConditions.condition == Weather.CONDITION_MOSTLY_CLOUDY) {
                // DRAW A CLOUD
                 WeatherHelpers.drawClouds(dc, 84, 100);
            }
            else if (cachedConditions.condition == Weather.CONDITION_RAIN) {
                WeatherHelpers.drawRain(dc, 84, 100);
            }
            else if (cachedConditions.condition == Weather.CONDITION_SNOW) {
                WeatherHelpers.drawSnow(dc, 84, 100);
            }
            else if (cachedConditions.condition == Weather.CONDITION_THUNDERSTORMS) {
                // Draw rain with lightning
                WeatherHelpers.drawRain(dc, 84, 100);
                WeatherHelpers.drawStorm(dc, 84, 100);
            }

            // Draw temperature
            var x = 122;
            var y = 77;

            var settings = System.getDeviceSettings();
            var curTemp = WeatherHelpers.tempFormatter(cachedConditions.temperature, settings, System.UNIT_METRIC);
            var highTemp = WeatherHelpers.tempFormatter(cachedConditions.highTemperature, settings, System.UNIT_METRIC);
            var lowTemp = WeatherHelpers.tempFormatter(cachedConditions.lowTemperature, settings, System.UNIT_METRIC);

            // Convert and Format
            var tempStr = (curTemp != null) ? curTemp.toNumber().toString() : "--";

            var highStr = (highTemp != null && lowTemp != null) ? highTemp.toNumber().toString() : "--";
            var lowStr = (highTemp != null && lowTemp != null) ? lowTemp.toNumber().toString() : "--";


            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            
            // Draw Current Temp
            dc.drawText(x, y, Graphics.FONT_GLANCE_NUMBER, tempStr + "°", Graphics.TEXT_JUSTIFY_CENTER);
            
            // Draw High/Low
            x = 153;
            y = 74;
            dc.drawText(x, y, Graphics.FONT_XTINY, highStr, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawLine(142, 94, 164, 94);
            y = y + 16;
            dc.drawText(x, y, Graphics.FONT_XTINY, lowStr, Graphics.TEXT_JUSTIFY_CENTER);
        }

    }

    function drawBattery(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        // Get Battery
        var currentTime = System.getTimer() / 1000;
        if (cachedSystemStats == null || (currentTime - lastSystemStatsFetchTime) > SYSTEM_STATS_UPDATE_INTERVAL) {
            var newStats = System.getSystemStats();
            if (newStats != null) {
                cachedSystemStats = newStats;
                lastSystemStatsFetchTime = currentTime;
            }
        }
        if (cachedSystemStats != null) {
            var battery = cachedSystemStats.battery.toNumber().toString() + "%";
            var batteryInDays = cachedSystemStats.batteryInDays.toNumber().toString() + " Days";
            // Line above battery
            dc.drawLine(9, 150, 159, 150);
            // Draw Battery %(Bottom)
            dc.drawText(
                47,
                150,
                Graphics.FONT_TINY,
                battery,
                Graphics.TEXT_JUSTIFY_CENTER
            );

            // Draw Battery in Days
            dc.drawText(
                144,
                150,
                Graphics.FONT_TINY,
                batteryInDays,
                Graphics.TEXT_JUSTIFY_RIGHT
            );
        }
    }

    function partialUpdateSeconds(dc) {
        var clockTime = System.getClockTime();

        // Define base square coordinates
        var rectX = 76;
        var rectY = 78;
        var rectWidth = 18;
        var rectHeight = 15;
        var padding = 2;

        // Set the clip with padding
        // Expand the box outward by the padding amount
        dc.setClip(
            rectX - padding,
            rectY - padding,
            rectWidth + (padding * 2),
            rectHeight + (padding * 2)
        );

        // Clear the area (now including the padding)
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Draw the square
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(rectX, rectY, rectWidth, rectHeight);

        // Draw the seconds
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        var secondsString = clockTime.sec.format("%02d");
        dc.drawText(
            rectX + (rectWidth / 2),
            rectY + (rectHeight / 2),
            Graphics.FONT_XTINY,
            secondsString,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Clear the clip
        dc.clearClip();
    }

    function drawTime(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        // Get Current Time
        var clockTime = System.getClockTime();
        var timeString = TimeHelpers.getFormattedTime(clockTime);

        // Draw Time (Left)
        dc.drawText(
            38,
            dc.getHeight() / 2,
            Graphics.FONT_NUMBER_MEDIUM,
            timeString,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        // Set the color of the square
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        // Draw a SOLID square
        // Arguments: x, y, width, height
        dc.fillRectangle(76, 78, 18, 15); 
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        // Draw the seconds
        var secondsString = clockTime.sec.format("%02d");
        dc.drawText(
            85,
            (dc.getHeight() / 2) - 4, // TODO: make the common centered calcs a variable to be reused
            Graphics.FONT_XTINY,
            secondsString,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        // Line below time
        dc.drawLine(0, 110, 172, 110);

        // Line to right of time
        dc.drawLine(101, 35, 101, 149);

        // Line above time
        dc.drawLine(0, 70, 101, 70);
    }
}
