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

import alphatab.tablature.model.BarreDrawning;
import alphatab.model.Beat;
import alphatab.model.Track;
import alphatab.tablature.drawing.DrawingContext;
import alphatab.tablature.drawing.DrawingLayer;
import alphatab.tablature.drawing.DrawingLayers;
import alphatab.tablature.model.MeasureDrawing;
import alphatab.tablature.Tablature;
import alphatab.tablature.ViewLayout;
import alphatab.model.Barre;

class StaveLine 
{
    public static inline var TopPadding = 0;
    public static inline var BottomSpacing = 1;

    // a list of the measures in the line
    public var measures(default,default):Array<Int>;
    // a list of the staves to render 
    public var staves(default,default):Array<Stave>;
    
    // spacing definitions for a full staveline
    public var spacing(default,default):StaveSpacing;
    
    // the tablature in which the line is placed in 
    public var tablature(default,default):Tablature; 
    
    public var track(default, default):Track;
    
    public var paintFeatures:Array<Int>;
    
    // the last measure within this line
    public function lastIndex() : Int 
    {
        return measures[measures.length - 1];
    }    
    
    public function getFeaturePaintPriority(feature:StaveFeatures) : Int
    {
        return paintFeatures[Type.enumIndex(feature)];
    }
    
    public function shouldPaintFeature(feature:StaveFeatures, priority:Int = 1) : Bool
    {
        return getFeaturePaintPriority(feature) <= priority;
    }
    
    public function setFeaturePaintPriority(feature:StaveFeatures, priority:Int = 1)
    {
        if (getFeaturePaintPriority(feature) < priority)
        {
            paintFeatures[Type.enumIndex(feature)] = priority;
        }
    }
    
    // calculates the height
    public function getHeight() : Int
    {
        var height:Int = 0;
        // default spacings of line
        height += spacing.getSize();
        // all stave heights
        for (stave in staves)
        {
            height += stave.spacing.getSize();
        }        
        return height;
    }
    
    // the top Y
    public var y(default,default):Int;    
    public var x(default,default):Int;    
    public var index(default,default):Int;    
    
    // is the line full, which means we need to stretch the measures
    public var fullLine(default,default):Bool;
    // the current width including all measures.
    public var width(default,default):Int;
    
    public function new()
    {
        measures = new Array<Int>();
        staves = new Array<Stave>();
        
        spacing = new StaveSpacing(BottomSpacing + 1);  
        paintFeatures = new Array<Int>();
        for (i in 0 ... Type.getEnumConstructs(StaveFeatures).length)
        {
            paintFeatures.push(0);
        }
        
        y = 0;
        x = 0;        
        fullLine = false;
        width = 0;
    }
    
    public function addMeasure(index:Int)
    {
        measures.push(index);
    }
    
    public function addStave(stave:Stave)
    {
        stave.index = staves.length;
        staves.push(stave);
    }
    
    public function paint(layout:ViewLayout, track:Track, context:DrawingContext)
    {
        if (staves.length == 0) return;
        
        var posY = y + spacing.get(TopPadding);
        var lastStave:Bool = false;
        
        for (si in 0 ... staves.length)
        {
            var stave:Stave = staves[si];
            
            //Last stave?
            if(si+1 == staves.length) {
                lastStave=true;
            }
            
            // stave background
            stave.paintStave(layout, context, x, posY);

            // paint measures in this stave
            var currentMeasure:MeasureDrawing;
            for (i in 0 ... measures.length) 
            {
                var index:Int = measures[i];
                currentMeasure = cast track.measures[index]; 
                var previousMeasureX:Int = 0;
                
                stave.paintMeasure(layout, context, currentMeasure, x, posY);
            }

            paintBarre(layout, context, stave, posY);
            
            posY += stave.spacing.getSize();
        }
        
        // group needed?
        if (staves.length > 1)
        {
            var firstStave = staves[0];
            var lastStave = staves[staves.length - 1];
            
            var firstStaveY = y + spacing.get(TopPadding);
            var lastStaveY = posY - lastStave.spacing.getSize();
            
            var fill = context.get(DrawingLayers.MainComponents);
            var draw = context.get(DrawingLayers.MainComponentsDraw);
            
            // Draw Bar for grouping
            var groupTopY = firstStaveY + firstStave.spacing.get(firstStave.getBarTopSpacing());
            var groupBottomY = lastStaveY + lastStave.spacing.get(lastStave.getBarBottomSpacing());
            
            var barSize:Int = Math.floor(3 * layout.scale);
            var barOffset:Int = barSize;
            
            
            fill.addRect(x - barOffset - barSize, groupTopY, barSize, groupBottomY - groupTopY);
            
            var spikeStartX = x - barOffset - barSize;
            var spikeEndX = x + barSize * 2;
            
            // top spike
            fill.startFigure();
            fill.moveTo(spikeStartX, groupTopY);
            fill.bezierTo(spikeStartX, groupTopY, x, groupTopY, spikeEndX, groupTopY - barSize);
            fill.bezierTo(x, groupTopY + barSize, spikeStartX, groupTopY + barSize, spikeStartX, groupTopY + barSize);
            fill.closeFigure();
            
            // bottom spike
            fill.startFigure();
            fill.moveTo(spikeStartX, groupBottomY);
            fill.bezierTo(spikeStartX, groupBottomY, x, groupBottomY, spikeEndX, groupBottomY + barSize);
            fill.bezierTo(x, groupBottomY - barSize, spikeStartX, groupBottomY - barSize, spikeStartX, groupBottomY - barSize);
            fill.closeFigure();
            
            
            // Draw Line for grouping
            var lineTopY = firstStaveY + firstStave.spacing.get(firstStave.getLineTopSpacing());
            var lineBottomY = lastStaveY + lastStave.spacing.get(lastStave.getLineBottomSpacing());
            
            draw.addLine(x, lineTopY, x, lineBottomY);
        }
    
        /*TODO: Lyrics Stave
         * if (track.song.lyrics != null && track.song.lyrics.trackChoice == track.number)
        {
            var ly:LyricsImpl = cast track.song.lyrics;
            ly.paintCurrentNoteBeats(context, this, currentMeasure, beatCount, currentMeasure.posX, currentMeasure.posY);
        }*/
        //beatCount += currentMeasure.beatCount();

    }

    private function paintBarre(layout:ViewLayout, context:DrawingContext,
                                stave: Stave, posY:Int)
    {
        var barre:BarreDrawning = null;
        var barres = new Array<BarreDrawning>();
        var currentMeasure:MeasureDrawing;

        function addBarre(barre: BarreDrawning){
            if(barre!=null && barre.beats.length > 0){
            barres.push(barre);
            }
        }

        for (i in 0 ... measures.length)
        {
            var index:Int = measures[i];
            currentMeasure = cast track.measures[index];

            if(currentMeasure.hasBarre()){
                for (beat in currentMeasure.beats){
                    barre = (barre!=null) ? barre : new BarreDrawning();
                    if (beat.properties.barre != null){
                        if (barre.fret != null && beat.properties.barre.fret != barre.fret){
                            addBarre(barre);
                            barre = new BarreDrawning();
                        }
                        barre.addBeat(beat);
                    } else {
                        addBarre(barre);
                        barre = null;
                    }
                }
            } else{
                addBarre(barre);
                barre = null;
            }
            // for full width barre in last measure
            if (i == measures.length-1)
                addBarre(barre);
        }

        for (b in barres){
            stave.paintBarre(layout, context, b, x, posY);
        }
    }


}