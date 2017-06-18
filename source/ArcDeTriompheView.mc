using Toybox.ActivityMonitor as Act;
using Toybox.Graphics as Gfx;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.WatchUi as Ui;
using Toybox.SensorHistory as Sensor;
using Toybox.Application as App;


class ArcDeTriompheView extends Ui.WatchFace
{
	
    var isAwake;
    var showSunrise = true;
    var showSunriseTimes = false;
    var showDate = false;
    var showTime = false;
    var showBatteryBar = true;
    var showStepsBar = true;
    var showMemoryBar = true;    
    var showHRHistory = true;

    var screenShape;  
    var utcOffset;
    var width;
    var height;  
    var sunrise = null;
    var sunset = null; 
    var offset; 
    var clockTime;
    var day = -1;
    var location;
    var lonW;
	var latN;
	var hasNewLocation = false;
    
    
    function initialize() {
        WatchFace.initialize();
		var app = App.getApp();
		
		latN = app.getProperty("latN");
		lonW = app.getProperty("lonW");
		if (location != null) {
			hasNewLocation = true;
		}
    }

    function onLayout(dc) {
        screenShape = Sys.getDeviceSettings().screenShape;
    }

    function onUpdate(dc) {
        clockTime = Sys.getClockTime();

        var hourHand;
        var minuteHand;
        var secondHand;
        
        
		var width = dc.getWidth();
        var height = dc.getHeight();
        var min_dim = min(width,height);
        var max_dim = max(width,height);


        // Clear the screen
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());
        

        if (showBatteryBar) {
			var battery = Sys.getSystemStats().battery / 100;
			drawBatteryBar(dc, battery);
		}
		
		if (showStepsBar) {
			var steps = min(Act.getInfo().steps * 1.0 / Act.getInfo().stepGoal, 1.0);
			drawStepsBar(dc, steps);
		}

		if (showMemoryBar) {
			var mem = Sys.getSystemStats().usedMemory * 1.0 / Sys.getSystemStats().totalMemory;
			var mem_color = Gfx.COLOR_LT_GRAY;

			if (mem > 0.85) {
				mem_color = 0xff0000;
			} 

			if (screenShape == Sys.SCREEN_SHAPE_RECTANGLE) {				       		
				dc.setColor(mem_color, Gfx.COLOR_TRANSPARENT);   
				dc.fillRectangle(width * mem, 4, width, 3);  
			} else {       		
				dc.setColor(mem_color, Gfx.COLOR_TRANSPARENT);    				
				dc.drawArc(width/2-1, height/2-1, (min_dim-1)/2 - 6, Gfx.ARC_CLOCKWISE, 179*mem, 1);      
			}		
		}	

        if(showSunrise){
       
	        var pos = Activity.getActivityInfo().currentLocation;
			if (pos != null) {				
				var newlonW = pos.toDegrees()[1].toFloat();
				var newlatN = pos.toDegrees()[0].toFloat();			
				if (lonW != newlonW) { 
					hasNewLocation = true;
					lonW = newlonW;
					latN = newlatN;
					var app = App.getApp();
					app.setProperty("latN", latN);
					app.setProperty("lonW", lonW);
					System.println("compute sun - has new location");
				}
			} 
			
			var info = Calendar.info(Time.now(), Time.FORMAT_MEDIUM);
			if(day != info.day || utcOffset != clockTime.timeZoneOffset || hasNewLocation) {
				clockTime = Sys.getClockTime();
				utcOffset = clockTime.timeZoneOffset;				
				System.println("compute sun");
				computeSun(dc);
				hasNewLocation = false;
			}
			if (sunrise != null) {
			
				if (showSunriseTimes) {
					// useful for debugging
					var s_str = "<" + (sunrise.toNumber() % 24) + ":" + ((sunrise - sunrise.toNumber() ) * 60).format("%.2d") + " ~ " + 
						(sunset.toNumber() % 24) + ";" + ((sunset - sunset.toNumber() ) * 60).format("%.2d") + ">";
					dc.drawText(width / 2, height - 42, Gfx.FONT_TINY, s_str, Gfx.TEXT_JUSTIFY_CENTER);			
				}

				var tnow = clockTime.hour + clockTime.min *1.0 / 60;	
				var tdaylight = sunset - sunrise;
				var tleft = sunset - tnow;
				if (tleft < 0) { tleft = 0; }
				if (tleft > tdaylight) { tleft = tdaylight; }

				dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);       		       										
				if (screenShape == Sys.SCREEN_SHAPE_RECTANGLE) {
					dc.fillRectangle((tdaylight - tleft)/tdaylight*width, height-7, width, 3);		
				}

				if (screenShape != Sys.SCREEN_SHAPE_RECTANGLE) {
					dc.drawArc(width/2, height/2, (min_dim-1)/2  - 6, Gfx.ARC_COUNTER_CLOCKWISE, 181, 359 - 180 * (tdaylight - tleft)/tdaylight);    
				}
				
				dc.setColor(0xff9d00, Gfx.COLOR_TRANSPARENT);
				dc.setPenWidth(1);
				hourHand = ((sunrise * 60) / (12 * 60.0)) * Math.PI * 2;
				drawHand(dc, hourHand, 13, 38, 3);

				dc.setColor(0xff9d00, Gfx.COLOR_TRANSPARENT);
				dc.setPenWidth(1);
				hourHand = ((sunset * 60) / (12 * 60.0)) * Math.PI * 2;
				drawHand(dc, hourHand, 26, 25, 3);
								
			}
        }
        
        if (showHRHistory) {
			if ( Toybox has :SensorHistory ) {
				var hr_min = 0;
				var hr_max = 0;
				var hr = 0;
				if (Sensor != null) {
					var hrhist = Sensor.getHeartRateHistory({ :order=>Sensor.ORDER_NEWEST_FIRST} );
					if (hrhist != null) {
						if (hrhist.getMin() != null) { 
							hr_min = hrhist.getMin(); 
						}
						
						if (hrhist.getMax() != null) { 
							hr_max = hrhist.getMax(); 
						}
						dc.setPenWidth(1);
						for (var i = 0; i <= width; i +=1) {
							var hr_sample = hrhist.next();
							if (hr_sample != null) {
								hr = hr_sample.data;
								if (hr != null) {
									dc.setColor(0xff66666, Gfx.COLOR_TRANSPARENT); 
									dc.drawLine(width - i, height - 10, width - i, (height - 10) - (hr - hr_min) *1.0 /(hr_max - hr_min) * 40);

								}
							}
						}
					}
				}
			}
        }

		if (showDate) {
			var now = Time.now();
			var info = Calendar.info(now, Time.FORMAT_LONG);     
			var dateStr = Lang.format("$1$ $2$", [info.month, info.day]);			
			dc.setColor(0xaaaaaa, Gfx.COLOR_TRANSPARENT);
			dc.drawText(width / 2, 7, Gfx.FONT_TINY, dateStr, Gfx.TEXT_JUSTIFY_CENTER);
		}
		
		if (showTime) {
			var timeStr = (clockTime.hour).format("%02d") + ":" + (clockTime.min).format("%02d");
			dc.drawText(width / 2, 20, Gfx.FONT_TINY, timeStr, Gfx.TEXT_JUSTIFY_CENTER);
			dc.drawLine(width / 2 - 48, height / 2 + 7, width / 2 + 23, height / 2 + 7); 
		}	        

		// draw the arcs for hours
        hourHand = ((((clockTime.hour % 12) * 60) + clockTime.min) / (12 * 60.0)) * Math.PI * 2;
        dc.setColor(0xc0c0c0, Gfx.COLOR_TRANSPARENT);
		dc.setPenWidth(6);
		
        if(clockTime.hour > 12) {
			dc.drawArc(width / 2, height / 2, 30, Gfx.ARC_CLOCKWISE, 90, ((12 - (clockTime.hour  % 12 + clockTime.min /  60.0) + 3) * 30) );
			dc.drawArc(width / 2, height / 2, 20, Gfx.ARC_CLOCKWISE, 90, 90 );
			dc.setPenWidth(1);
			drawHand(dc, hourHand, 26, 10, 3);
		} else {
			dc.drawArc(width / 2, height / 2, 20, Gfx.ARC_CLOCKWISE, 90, ((12 - (clockTime.hour  % 12 + clockTime.min / 60.0) + 3) * 30) );
			dc.setPenWidth(1);
			drawHand(dc, hourHand, 15, 10, 3);
		}
        
        //draw arcs for minutes
        dc.setColor(0xd0d0d0, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawArc(width / 2, height / 2, 40 , Gfx.ARC_CLOCKWISE, 90, ((60 - clockTime.min + 15 ) * 6) );
        dc.setPenWidth(1);        

        // Draw the minute hand
        minuteHand = (clockTime.min / 60.0) * Math.PI * 2;
        drawHand(dc, minuteHand, 35, 10, 2);
       
    }

	function onEnterSleep() {
        isAwake = false;
        Ui.requestUpdate();
    }

    function onExitSleep() {
        isAwake = true;
    }    

	// Draw the watch hand
    function drawHand(dc, angle, offset, length, width) {
        // Map out the coordinates of the watch hand
        var coords = [[-(width / 2), -offset], [-(width / 2), -offset-length], [width / 2, -offset-length], [width / 2, -offset]];
        var result = new [4];
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result[i] = [centerX + x, centerY + y];
        }

        // Draw the polygon
        dc.fillPolygon(result);
        dc.fillPolygon(result);
    }

    
	function computeSun(dc) {
        // compute current date as day number from beg of year
        utcOffset = clockTime.timeZoneOffset;
        var timeInfo = Calendar.info(Time.now().add(new Time.Duration(utcOffset)), Calendar.FORMAT_SHORT);

        day = timeInfo.day;
        var now = dayOfYear(timeInfo.day, timeInfo.month, timeInfo.year);
        
        sunset = computeSunriset(now, lonW, latN, false);
		sunrise = computeSunriset(now, lonW, latN, true);
        offset=new Time.Duration(utcOffset).value()/3600;
        sunrise += offset;
        sunset += offset;
   }    

}
