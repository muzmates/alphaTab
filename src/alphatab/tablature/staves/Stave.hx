/*
 * This file is part of alphaTab.
 *
 *  alphaTab is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  alphaTab is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with alphaTab.  If not, see <http://www.gnu.org/licenses/>.
 */
package alphatab.tablature.staves;

import alphatab.model.BeatArpeggio;
import alphatab.tablature.model.BeatDrawing;
import alphatab.tablature.model.BarreDrawning;
import alphatab.model.Measure;
import alphatab.model.Direction;
import alphatab.model.Barre;
import alphatab.model.BeatArpeggioDirection;
import alphatab.tablature.drawing.DrawingContext;
import alphatab.tablature.drawing.DrawingLayer;
import alphatab.tablature.drawing.DrawingLayers;
import alphatab.tablature.drawing.DrawingResources;
import alphatab.tablature.drawing.MusicFont;
import alphatab.tablature.model.VoiceDrawing;
import alphatab.tablature.model.MeasureDrawing;
import alphatab.tablature.ViewLayout;

/**
 * Represents  the base class for a stave implementation 
 * which renders a line of measures. 
 */
class Stave 
{
    private static inline var TS_NUMBER_WIDTH:Int = 10;
    private static inline var TS_NUMBER_HEIGHT:Int = 15;

    // the stave index within a stave line
    public var index(default,default):Int;
    public var line(default,default):StaveLine;
    public var spacing(default,default):StaveSpacing;
    public var layout(default,default):ViewLayout;

    // Whether use the same painting for all voices
    public var multiVoiceSamePainting = false;

    // Whether to paint alternate endings
    public var bothStavesActive = false;

    public function new(line:StaveLine, layout:ViewLayout)
    {
        this.index = 0;
        this.line = line;
        this.layout = layout;

        this.multiVoiceSamePainting = line.tablature.getStaveSetting(getStaveId(), "multiVoiceSamePainting", false);
        this.bothStavesActive = line.tablature.getStaveSetting(getStaveId(), "bothStavesActive", false);
    }
    
    public function getStaveId() : String
    {
        // set in implementation 
        return ""; 
    }
    
    // gets the spacing index used for grouping staves with a bar
    public function getBarTopSpacing() : Int
    {
        return 0;
    }
    
    // gets the spacing index used for grouping staves with a bar
    public function getBarBottomSpacing() : Int
    {
        return 0;
    }    
    
    // gets the spacing index used for grouping staves with a line
    public function getLineTopSpacing() : Int
    {
        return 0;
    }
    
    // gets the spacing index used for grouping staves with a line
    public function getLineBottomSpacing() : Int
    {
        return 0;
    }    
    
    public function prepare(measure:MeasureDrawing)
    {
        // for layouting requirements
    }
    
    public function paintStave(layout:ViewLayout, context:DrawingContext, x:Int, y:Int)
    {
    }
    
      
    public function paintMeasure(layout:ViewLayout, context:DrawingContext, measure:MeasureDrawing, x:Int, y:Int)
    {
        // for layouting requirements
    }

    public function paintBarre(layout:ViewLayout, context:DrawingContext, barre:BarreDrawning, x:Int, y:Int)
    {

        var startX:Float = x + barre.getStartX(layout);
        var endX:Float = x + barre.getEndX(layout);
        var realY:Float = y + getBarreY(layout, barre);
        var h = 8;
        var draw:DrawingLayer = context.get(DrawingLayers.MainComponentsDraw);
        var text:String = barre.getText();

        context.graphics.font = DrawingResources.defaultFont;
        var w:Float = context.graphics.measureText(text);

        draw.addLine(endX, realY, endX, realY + h);
        draw.addDashedLine(startX + w, realY, endX, realY);
        context.get(DrawingLayers.MainComponentsDraw)
        .addString(text, DrawingResources.defaultFont, startX, realY);
    }

    private function getBarreY(layout:ViewLayout, barre:BarreDrawning): Int
    {
        return Math.floor(5*layout.scale);
    }
    
    // paint division lines, measure numbers and repeat bars/endings
    public function paintDivisions(layout:ViewLayout, context:DrawingContext, measure:MeasureDrawing, x:Int, y:Int, dotSize:Int, offset:Int, staveHeight:Int)
    {
        var x2:Int; // variable for additional calculations
        var number:String = Std.string(measure.header.number); 
        var fill:DrawingLayer = context.get(DrawingLayers.MainComponents);
        var draw:DrawingLayer = context.get(DrawingLayers.MainComponentsDraw);
        
        var lineWidthBig:Int = cast Math.max(1, Math.round(3.0 * layout.scale));
        
        var startY = y;
        
        var bottomY:Int;

        // Directions
        if(measure.header.direction.hasTarget(Target.Segno)) {
            if(!Std.is(this, TablatureStave) || !this.bothStavesActive)
                fill.addMusicSymbol(MusicFont.Segno, x, y, layout.scale);
        }

        if (index == 0) // the first stave will get the infos and won't draw any upper offset
        { 
            context.get(DrawingLayers.Red).addString(number, DrawingResources.defaultFont, x + Math.round(layout.scale*2), y + offset - DrawingResources.defaultFontHeight);
        }
        y += offset;
        bottomY = y + staveHeight;      
        
        dotSize = cast Math.max(1, (dotSize * layout.scale));

        // RepeatEndings
        if (measure.header.isRepeatOpen)
        {
            // add a rect and a line
            fill.addRect(x, y, lineWidthBig, bottomY - y);
            draw.startFigure();            
            x2 = Math.floor(x + lineWidthBig + (3 * layout.scale));
            draw.addLine(x2, y, x2, bottomY);
        
            // two dots 
            x2 += Math.floor(2 * layout.scale);     
            
            var centerY = y + ((bottomY - y) / 2);            
            var yMove:Float = 6 * layout.scale;         
            
            fill.addCircle(x2, centerY - yMove - dotSize, dotSize);
            fill.addCircle(x2, centerY + yMove, dotSize);
        }
        else
        {
            // a simple line
            draw.startFigure();
            draw.addLine(x, y, x, bottomY);
        }

        if(!Std.is(this, TablatureStave) || !this.bothStavesActive){
            if(measure.header.direction.hasJump(Jump.DaCoda)) {
                measureHeaderTailText("Da Coda", measure, context, layout, x, y);
            }

            if(measure.header.direction.hasJump(Jump.DaSegnoAlCoda)) {
                measureHeaderTailText("D.S. al Coda", measure, context,
                layout, x, y);
            }
        }

        // Repeat Closings
        x += measure.width + measure.spacing;

        if (measure.header.repeatClose > 0 || measure.header.number == measure.track.measureCount())
        {
            // add a rect and a line
            x2 = Math.floor(x - (lineWidthBig + (3 * layout.scale)));

            draw.startFigure();            
            draw.addLine(x2, y, x2, bottomY);            
            fill.addRect(x - lineWidthBig, y, lineWidthBig, bottomY - y);

            if (measure.header.repeatClose > 0)
            {
                // two dots  
                x2 -= (Math.floor(2 * layout.scale) + dotSize);     
                
                var centerY = y + ((bottomY - y) / 2);            
                var yMove:Float = 6 * layout.scale;         
                
                fill.addCircle(x2, centerY - yMove - dotSize, dotSize);
                fill.addCircle(x2, centerY + yMove, dotSize);

                if (index == 0 && measure.header.repeatClose > 2)
                {
                    var repetitions:String = ("x" + (measure.header.repeatClose));
                    var numberSize = context.graphics.measureText(repetitions);
                    fill.addString(repetitions, DrawingResources.defaultFont, x2 - dotSize, 
                    y - DrawingResources.defaultFontHeight);
                }
            }
        }
        else
        {
            draw.startFigure();
            draw.addLine(x, y, x, bottomY);
        }

    }

    // Get appropriate voice drawing base on multiVoiceSamePainting var
    public function getVoiceDrawing<T>(voice: Int,
                                       voice1Data: T,
                                       voice2Data: T): T {
        if(multiVoiceSamePainting || voice == 0)
            return voice1Data;
        else
            return voice2Data;
    }

    private function paintTimeSignatureNumber(layout:ViewLayout, context:DrawingContext, number:Int, x:Int, y:Int, scale:Float)
    {
        if(number < 10)
        {
            var symbol = this.getTimeSignatureSymbol(number);
            if (symbol != null) 
                context.get(DrawingLayers.MainComponents).addMusicSymbol(symbol, x, y, scale);
        }
        else
        {
            var firstDigit = Math.floor(number / 10);
            var secondDigit = number - (firstDigit * 10); 
            
            var symbol = this.getTimeSignatureSymbol(firstDigit);
            if (symbol != null) 
                context.get(DrawingLayers.MainComponents).addMusicSymbol(symbol, x, y, scale);
            symbol = this.getTimeSignatureSymbol(secondDigit);
            if (symbol != null) 
                context.get(DrawingLayers.MainComponents).addMusicSymbol(symbol, x + TS_NUMBER_WIDTH * scale, y, scale);
        }
    }
    
    private function getTimeSignatureSymbol(number:Int)
    {
        switch(number) 
        {
            case 0:  
                return MusicFont.Num0;
            case 1:  
                return MusicFont.Num1;
            case 2: 
                return MusicFont.Num2;
            case 3: 
                return MusicFont.Num3;
            case 4: 
                return MusicFont.Num4;
            case 5: 
                return MusicFont.Num5;
            case 6: 
                return MusicFont.Num6;
            case 7: 
                return MusicFont.Num7;
            case 8: 
                return MusicFont.Num8;
            case 9: 
                return MusicFont.Num9;
        }
        return null;
    }

    // Paint Coda sign
    private function paintCoda(layout, context, measure, realX, y) {
        if(!measure.header.direction.hasTarget(Target.Coda))
            return;

        var fill: DrawingLayer = context.get(DrawingLayers.MainComponents);

        fill.addMusicSymbol(MusicFont.Coda, realX, y, layout.scale);
    }

    // Paint text at measure header tail
    private function measureHeaderTailText(text: String,
                                           measure: MeasureDrawing,
                                           context: DrawingContext,
                                           layout: ViewLayout, x, y) {
        var font = DrawingResources.defaultFont;
        var fontHeight = DrawingResources.defaultFontHeight;

        layout.tablature.canvas.font = font;

        var len = layout.tablature.canvas.measureText(text);
        var xx = x + measure.width + measure.spacing - len;

        var comp = context.get(DrawingLayers.MainComponents);

        comp.addString(text, font, xx + Math.round(layout.scale*2),
                       y - fontHeight);
    }

    // Paint alternate ending sign
    private function paintAlternateEndings(layout: ViewLayout,
                                           context: DrawingContext,
                                           measure: MeasureDrawing, x, y) {

        if(measure.header.alternateEndings == 0)
            return;

        var val = measure.header.alternateEndings;
        var prev: MeasureDrawing = measure.getPreviousMeasure();
        // Alternate endings sign continues from previous measure
        var is_cont = prev != null && prev.header.alternateEndings == val;

        var draw:DrawingLayer = context.get(DrawingLayers.MainComponentsDraw);

        draw.addLine(x, y, x + measure.width + measure.spacing, y);

        if(!is_cont) {
            draw.addLine(x, y, x, y + 8);

            var num = Std.string(measure.header.alternateEndings);

            context.get(DrawingLayers.MainComponentsDraw)
            .addString(num, DrawingResources.defaultFont,
            x + 5, y + DrawingResources.defaultFontHeight);
        }
    }

    // Pain arpeggio effect
    private function paintArpeggio(layout:ViewLayout,
                                   context:DrawingContext,
                                   beat:BeatDrawing,
                                   x:Int, y:Int): Int
    {
        if (beat.effect.arpeggio.direction == BeatArpeggioDirection.None)
            return 0;

        var offset = BeatArpeggio.size(layout);

        for(i in beat.voices) {
            var v: VoiceDrawing = cast i;

            if(v.anyDisplaced) {
                offset += Math.floor(DrawingResources.getScoreNoteSize(layout,
                                     false).x);
                break;
            }
        }

        x -= offset;
        y += spacing.get(getLineTopSpacing());

        var symbolScale = 0.75;
        var w:Int = Std.int((beat.measure.track.stringCount() - 1) *
                    layout.stringSpacing);

        var layer:DrawingLayer = context.get(DrawingLayers.MainComponents);
        var step:Float = 18 * layout.scale * symbolScale;
        var loops:Int = Math.floor(Math.max(1, (w / step)));

        for (i in 0 ... loops)
        {
            layer.addMusicSymbol(MusicFont.ArpeggioDown, x, y,
                                 layout.scale * symbolScale);
            y += Math.floor(step);
        }

        return offset;
    }
}