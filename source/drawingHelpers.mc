using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;

function drawTopBar(dc, pos, color) {
	var width = dc.getWidth();
    var height = dc.getHeight();  
    var min_dim = min(width,height);
        
	if (screenShape == Sys.SCREEN_SHAPE_RECTANGLE) {				
		dc.setColor(color, Gfx.COLOR_TRANSPARENT);  
		dc.fillRectangle(0, 0, width * pos, 3); 
	
	} else {	
		dc.setColor(color, Gfx.COLOR_TRANSPARENT);  
		dc.drawArc(width/2, height/2, (min_dim-1)/2, Gfx.ARC_COUNTER_CLOCKWISE, 182 - 180 * pos, 178); 
	}
}

function drawBottomBar(dc, pos, color) {
	var width = dc.getWidth();
    var height = dc.getHeight();  
    var min_dim = min(width,height);
    
    pos = min(pos,1.0);
    
	if (screenShape == Sys.SCREEN_SHAPE_RECTANGLE) {				
		dc.setColor(color, Gfx.COLOR_TRANSPARENT);  
		dc.fillRectangle(0, height-3, width * pos, 3); 
	} else {
		dc.setColor(color, Gfx.COLOR_TRANSPARENT);  
		dc.drawPoint(0, height/2);
		dc.drawPoint(width-1, height/2);
		dc.drawArc(width/2-1, height/2-1, (min_dim-1)/2, Gfx.ARC_CLOCKWISE, - 178 * pos,  183 );    			
	}
}

function drawBatteryBar(dc, battery) {
	var color = Gfx.COLOR_LT_GRAY;

	if (battery < 15) {
		color = 0xFF0000;
	} else if (battery <= 30) {
		color = 0xFF3300;
	} 
	
	drawTopBar(dc, battery, color);
}

function drawStepsBar(dc, steps) {
	var color = Gfx.COLOR_LT_GRAY;

	steps = min(steps, 1.0);
	if (steps >= 1.0) {
		//color = Gfx.COLOR_GREEN;
	}

	drawBottomBar(dc, steps, color);
}
