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
package alphatab.tablature;
import alphatab.model.Beat;
import alphatab.model.Measure;
import alphatab.model.Padding;
import alphatab.model.Point;
import alphatab.model.Rectangle;
import alphatab.model.Track;
import alphatab.tablature.drawing.DrawingContext;
import alphatab.tablature.model.BeatDrawing;
import alphatab.tablature.model.MeasureDrawing;
import alphatab.tablature.staves.StaveLine;

/**
 * This layout renders all measures in one single line
 */
class HorizontalViewLayout extends ViewLayout
{
    public static var LAYOUT_ID = "horizontal"; 
    
    public static var PAGE_PADDING:Padding = PageViewLayout.PAGE_PADDING;

    private var _line:StaveLine;

    public function new() 
    {
        super();
        contentPadding = PAGE_PADDING;
    }
    
    public override function init(scale:Float) : Void
    { 
        super.init(scale);
        layoutSize = new Point(width, height);
    }
    
    public override function getLines() : Array<StaveLine>
    {
        return [_line];
    }
    
    // Returns the index of the measure drawn under the coordinates given
    public override function getBeatAt(xPos:Int, yPos:Int) : Beat
    {
        xPos -= PAGE_PADDING.left;
        return getBeatAtLine(_line, xPos, yPos);
    }
    
    // 
    // Layouting
    //
    
    public override function prepareLayout(clientArea:Rectangle, x:Int, y:Int) : Void
    {
        width = 0;
        height = 0;

        var posY:Int = y;

        var startIndex:Int = tablature.getLayoutSetting("startMeasure", -1);
        startIndex--;
        startIndex = Std.int(Math.min(tablature.track.measureCount() - 1, Math.max(0, startIndex)));

        var endIndex:Int = tablature.getLayoutSetting("measureCount", tablature.track.measures.length);
        endIndex = startIndex + endIndex - 1;
        endIndex = Std.int(Math.min(tablature.track.measureCount() - 1, Math.max(0, endIndex)));

        var track:Track = tablature.track;
        var nextMeasureIndex:Int = startIndex;
        
        x += contentPadding.left;
        posY = Math.floor(posY + firstMeasureSpacing);
         
        while (endIndex >= nextMeasureIndex)
        {
            // calculate a stave line
            _line = getStaveLine(track, nextMeasureIndex, endIndex, posY, x);

            // add it to offset
            posY += _line.getHeight();
            
            // next measure index
            nextMeasureIndex = _line.lastIndex() + 1;
        }
        
        height = posY + contentPadding.bottom;
        
        width = _line.width + PAGE_PADDING.getHorizontal();
        layoutSize = new Point(width, height);
    }
        
    public function getStaveLine(track:Track, startIndex:Int, endIndex: Int,
                                 y:Int, x:Int) : StaveLine
    {
        var line:StaveLine = createStaveLine(track);
        line.y = y;
        line.x = x;
                
        // default spacings
        line.spacing.set(StaveLine.TopPadding, Math.floor(10 * scale));
        line.spacing.set(StaveLine.BottomSpacing, Math.floor(10 * scale));
        
        var measureCount = endIndex + 1;
        x = 0;
        for (i in startIndex ... measureCount) 
        {
            var measure:MeasureDrawing = cast track.measures[i];
            measure.staveLine = line;
            measure.performLayout(this);            
            
            measure.x = x;            
            x += measure.width;            
            
            for (stave in line.staves)
            {
                stave.prepare(measure);
            }
                    
            line.addMeasure(i);
        }
        line.width = x;        
        return line;
    }
    
 
    //
    // Painting
    //
    
    public override function paintSong(ctx:DrawingContext, clientArea:Rectangle, x:Int, y:Int) : Void
    {
        var track:Track = tablature.track;
        y = Math.floor(y + contentPadding.top + firstMeasureSpacing);
        _line.paint(this, track, ctx);
    }
    
}