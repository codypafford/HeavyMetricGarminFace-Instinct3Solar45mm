import Toybox.Graphics;

// Wrapping in a module keeps things organized
module WeatherHelpers {
    function drawSun(dc, x, y) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        // The core of the sun
        dc.drawCircle(x, y, 4); 
        
        // --- Cardinal Rays (Length 2) ---
        dc.drawLine(x - 8, y, x - 6, y); // Left
        dc.drawLine(x + 6, y, x + 8, y); // Right
        dc.drawLine(x, y - 8, x, y - 6); // Top
        dc.drawLine(x, y + 6, x, y + 8); // Bottom

        // --- Diagonal Rays (Length 3 - slightly longer) ---
        // Top-Left
        dc.drawLine(x - 7, y - 7, x - 4, y - 4); 
        // Top-Right
        dc.drawLine(x + 4, y - 4, x + 7, y - 7);
        // Bottom-Left
        dc.drawLine(x - 7, y + 7, x - 4, y + 4);
        // Bottom-Right
        dc.drawLine(x + 4, y + 4, x + 7, y + 7);
    }

    function drawMoon(dc, x, y) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, 4); 

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x - 3, y, 4); 
    }

    function drawClouds(dc, x, y) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        // 1. Left fluffy part
        dc.fillCircle(x - 5, y + 2, 4);
        
        // 2. Right fluffy part
        dc.fillCircle(x + 5, y + 2, 4);
        
        // 3. Center fluffy part (slightly higher)
        dc.fillCircle(x, y - 1, 5); 

        // 4. Lower center to fill the gap
        dc.fillCircle(x, y + 3, 3);
    }

    function drawRain(dc, x, y) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(x - 6, y + 2, x - 8, y + 6);
        dc.drawLine(x - 2, y + 1, x - 4, y + 5);
        dc.drawLine(x + 2, y, x, y + 4);
        dc.drawLine(x + 5, y + 2, x + 3, y + 6);
        dc.drawLine(x + 8, y + 1, x + 6, y + 5);
    }

    function drawStorm(dc, x, y) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        x = x + 1;
        y = y - 7;
        // Start X/Y for the bolt
        var bx = x;
        var by = y + 5;
        
        // Zigzag lines
        dc.drawLine(bx, by, bx - 3, by + 6);     // Down-Left
        dc.drawLine(bx - 3, by + 6, bx + 2, by + 6); // Horizontal
        dc.drawLine(bx + 2, by + 6, bx - 1, by + 12); // Down-Right
        dc.setPenWidth(1);
    }

    function drawSnow(dc, x, y) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        x = x - 6;
        dc.fillCircle(x, y, 1);

        x = x + 5;
        y = y + 2;
        dc.fillCircle(x, y, 1);

        x = x + 3;
        y = y - 4;
        dc.fillCircle(x, y, 1);

        x = x + 3;
        y = y + 3;
        dc.fillCircle(x, y, 1);
    }

    function tempFormatter(tempC, settings, metric) {
        if (settings.temperatureUnits == metric) {
            // Display as Celsius
            return tempC.format("%d") + "°C";
        } else {
            // Convert to Fahrenheit
            var tempF = (tempC * 9 / 5) + 32;
            return tempF.format("%d") + "°F";
        }
    }
}
