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
package alphatab.model;

/**
 * A measure contains multiple beats
 */
class Measure
{
    public static inline var DEFAULT_CLEF:Int = MeasureClef.Treble;
    
    public var track(default,default):Track;
    public var clef(default,default):Int;
    
    public var beats(default,default):Array<Beat>;
    public var header(default,default):MeasureHeader;

    private var _hasBarre(default, default): Bool;
    
    public inline function beatCount() : Int
    {
        return beats.length;
    }
    
    public inline function end() : Int
    {
        return (start() + length());
    }
    
    public inline function number() : Int
    {
        return header.number;
    }
    
    public inline function keySignature(): Int
    {
        return header.keySignature;
    }
    
    public inline function repeatClose() : Int
    {
        return header.repeatClose;
    }
    
    public inline function start() : Int
    {
        return header.start;    
    }
    
    public inline function length() : Int
    {
        return header.length();
    }
    
    public inline function tempo() : Tempo
    {
        return header.tempo;
    }
    
    public inline function timeSignature() : TimeSignature
    {
        return header.timeSignature;
    }

    public inline function isRepeatOpen() : Bool
    {
        return header.isRepeatOpen;
    }
    
    public inline function tripletFeel() : Int 
    {
        return header.tripletFeel;
    }
    
    public inline function hasMarker() : Bool
    {
        return header.hasMarker();
    }
    
    public inline function marker() : Marker
    {
        return header.marker;
    }
    
    public function new(header:MeasureHeader)
    {
        this.header = header;
        clef = DEFAULT_CLEF;
        beats = new Array<Beat>();
        _hasBarre = null;
    }
    
    public function addBeat(beat:Beat) : Void
    {
        beat.measure = this;
        beat.index = beats.length;
        beats.push(beat);

        beats.sort(compareBeats);

        for(i in 0...beats.length)
            beats[i].index = i;
    }

    private function compareBeats(a:Beat, b:Beat) : Int
    {
        if (a.start > b.start)
            return 1;
        if (a.start < b.start)
            return -1;

        return 0;
    }

    public function hasBarre(): Bool
    {
        if (_hasBarre != null)
            return _hasBarre;

        for (beat in beats){
            if (beat.properties.barre != null){
                _hasBarre = true;
                return _hasBarre;
            }
        }
        _hasBarre = false;
        return _hasBarre;
    }

}
