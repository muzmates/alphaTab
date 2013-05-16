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


package alphatab.tablature.model;
import alphatab.model.Beat;
import alphatab.model.Barre;

class BarreDrawning extends Barre{
    public static var DELTA_X:Int = 6;
    public static var HALF:String = "1/2";
    public static var ROMAN =
    ["0", "I", "II", "III",
    "IV", "V", "VI", "VII",
    "VIII", "IX", "X", "XI",
    "XII", "XIII", "XIV", "XV",
    "XVI", "XVII", "XVIII","XIX",
    "XX", "XXI"];

    public var beats(default, default): Array<Beat>;

    public function new() {
        super();
        beats = new Array<Beat>();
    }

    public function addBeat(beat:Beat) : Void
    {
        if (beat.properties.barre != null){
            fret = (fret == null) ? beat.properties.barre.fret: fret;
            string = (string == null) ? beat.properties.barre.string: string;
            beats.push(beat);
        }
    }

    public function getStartX(layout: ViewLayout): Int
    {
        if (beats.length > 0){
            var first_beat:BeatDrawing = cast beats[0];
            return getX(layout, first_beat);
        }
        return null;
    }

    public function getEndX(layout: ViewLayout): Int
    {
        if (beats.length > 0){
            var last_beat:BeatDrawing = cast beats[beats.length-1];
            return getX(layout, last_beat) + DELTA_X;
        }
        return null;
    }

    public function getText(): String
    {
        var prefix = string!=null && string > 0 ? HALF : "";
        return prefix+" B "+ROMAN[fret];
    }

    private function getX(layout:ViewLayout, beat:BeatDrawing): Int
    {
        var measure: MeasureDrawing = cast beat.measure;
        return measure.getDefaultSpacings(layout) + measure.x + beat.x;
    }


}
