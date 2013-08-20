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
import Lambda;
import alphatab.model.Duration;
import alphatab.model.Note;
import alphatab.model.SongManager;
import alphatab.model.VoiceDirection;

/**
 * A beatgroup contains a set of notes which are grouped by bars.
 */
class BeatGroup 
{
    private static var SCORE_MIDDLE_KEYS:Array<Int> = [ 55, 40, 40, 50 ];
        
    private var _voices:Array<VoiceDrawing>;
    
    private var _lastVoice:VoiceDrawing;

    private var _graceShift:Int = 0;
    
    // the first min note within this group
    public var firstMinNote(default,default):NoteDrawing;
    // the first max note within this group
    public var firstMaxNote(default,default):NoteDrawing;
    // the last min note within this group
    public var lastMinNote(default,default):NoteDrawing;
    // the last max note within this group
    public var lastMaxNote(default,default):NoteDrawing;
    // the overall min note within this group
    public var minNote(default,default):NoteDrawing;
    // the overall max note within this group
    public var maxNote(default,default):NoteDrawing;    
    
    public var isPercussion(default,default):Bool;

    
    public function new() 
    { 
        _voices = new Array<VoiceDrawing>();
    }
 
    public function getDirection()
    { 
        var max:Float = Math.abs(getNoteValueForPosition(minNote) - (SCORE_MIDDLE_KEYS[_voices[0].measureDrawing().clef] + 100));
        var min:Float = Math.abs(getNoteValueForPosition(maxNote) - (SCORE_MIDDLE_KEYS[_voices[0].measureDrawing().clef] - 100));
        return max > min ? VoiceDirection.Up : VoiceDirection.Down;
    }
    
    private function getNoteValueForPosition(note:Note) 
    {
       if(note.voice.beat.measure.track.isPercussionTrack) 
       {
           return PercussionMapper.getValue(note);
       }
       else
       {
           return note.realValue();
       }
    }
    
    public function check(voice:VoiceDrawing) : Bool
    {
        if(voice.beat.measure.track.isPercussionTrack)
        {
           isPercussion = true;
        }
        
        // allow adding if there are no voices yet
        var add:Bool = false;
        if (_voices.length == 0)
        {
            add = true;
        }
        else if (canJoin(voice))
        {
            add = true;
        }
        
        if (add)
        {
            forceAdd(voice);
            setupVoicesProperties();
        }
        
        return add;
    }

    // add voice to beat group without any checks
    // Needed to calculate lines above group of any voices (eg. 4-th)
    public function forceAdd(voice:VoiceDrawing)
    {
        if(voice.minNote!=null && voice.maxNote!=null){
            _lastVoice = voice;
            _voices.push(voice);
            checkNote(voice.minNote);
            checkNote(voice.maxNote);
        }
    }
    
    private function checkNote(note:NoteDrawing)
    {
        var value:Int = note.realValue();

        // detect the smallest note which is at the beginning of this group
        if (firstMinNote == null || note.voice.beat.start < firstMinNote.voice.beat.start)
        {
            firstMinNote = note;
        }
        else if (note.voice.beat.start == firstMinNote.voice.beat.start)
        {
            if (note.realValue() < firstMinNote.realValue())
            {
                firstMinNote = note;
            }
        }

        // detect the biggest note which is at the beginning of this group
        if (firstMaxNote == null || note.voice.beat.start < firstMaxNote.voice.beat.start)
        {
            firstMaxNote = note;
        }
        else if (note.voice.beat.start == firstMaxNote.voice.beat.start)
        {
            if (note.realValue() > firstMaxNote.realValue())
            {
                firstMaxNote = note;
            }
        }

        // detect the smallest note which is at the end of this group
        if (lastMinNote == null || note.voice.beat.start > lastMinNote.voice.beat.start)
        {
            lastMinNote = note;
        }
        else if (note.voice.beat.start == lastMinNote.voice.beat.start)
        {
            if (note.realValue() < lastMinNote.realValue())
            {
                lastMinNote = note;
            }
        }
        // detect the biggest note which is at the end of this group
        if (lastMaxNote == null || note.voice.beat.start > lastMaxNote.voice.beat.start)
        {
            lastMaxNote = note;
        }
        else if (note.voice.beat.start == lastMaxNote.voice.beat.start)
        {
            if (note.realValue() > lastMaxNote.realValue())
            {
                lastMaxNote = note;
            }
        }

        if (maxNote == null || value > maxNote.realValue())
        {
            maxNote = note;
        }
        if (minNote == null || value < minNote.realValue())
        {
            minNote = note;
        }
    }

    private function setupVoicesProperties()
    {
        var lastIndex:Int = _voices.length - 1;
        var previousVoice:VoiceDrawing = null;

        if(lastIndex > 0){
            previousVoice = _voices[lastIndex-1];
        };

        _lastVoice.joinedType = JoinedType.NoneRight;
        _lastVoice.leftJoin = _lastVoice;
        _lastVoice.rightJoin = _lastVoice;
        _lastVoice.isJoinedGreaterThanQuarter = false;

        if (previousVoice != null){

            if (previousVoice.duration.value >= _lastVoice.duration.value)
            {
                _lastVoice.leftJoin = previousVoice;
                _lastVoice.rightJoin = _lastVoice;
                _lastVoice.joinedType = JoinedType.Left;

            } else {
                _lastVoice.joinedType = JoinedType.NoneLeft;
            }

            if (previousVoice.duration.value > Duration.QUARTER)
            {
                _lastVoice.isJoinedGreaterThanQuarter = true;
            }

            if (_lastVoice.duration.value >= previousVoice.duration.value)
            {
                previousVoice.rightJoin = _lastVoice;
                previousVoice.joinedType = JoinedType.Right;

            }

            if (_lastVoice.duration.value > Duration.QUARTER)
            {
                previousVoice.isJoinedGreaterThanQuarter = true;
            }
        }

        if (previousVoice == null || previousVoice.isRestVoice()
        || previousVoice.duration.value < _lastVoice.duration.value)
        {
            _lastVoice.leftJoin = _lastVoice;
        }
    }
    
    private function canJoin(voice:VoiceDrawing)
    {
        // is this a voice we can join with?
        if (_lastVoice == null || voice == null || _lastVoice.isRestVoice() || voice.isRestVoice())
        {
            return false;
        } 
        
        var m1 = _lastVoice.measureDrawing();
        var m2 = voice.measureDrawing();
        // only join on same measure
        if (m1 != m2) return false;
        
        // get times of those voices and check if the times 
        // are in the same division
        var start1 = _lastVoice.beat.start;
        var start2 = voice.beat.start;
        
        // we can only join 8th, 16th, 32th and 64th voices
        if (_lastVoice.duration.value < Duration.EIGHTH || voice.duration.value < Duration.EIGHTH)
        {
            // other voices only get a beam if they are on the same voice
            return start1 == start2;
        }
        
        // we have two 8th, 16th, 32th and 64th voices
        // a division can contains a single quarter
        var divisionLength = SongManager.getDivisionLength(m1.header);

        // add grace shift if there are grace notes in current measure and voice
        var prevBeat:BeatDrawing = (cast voice.beat).getPreviousBeat();
        while (prevBeat != null && prevBeat.measureDrawing() == m1){
            if (prevBeat.voices[voice.index].isGrace){
                var nextBeat:BeatDrawing = prevBeat.getNextBeat();
                _graceShift = nextBeat.getRealStart() - prevBeat.getRealStart();
                break;
            }
            prevBeat = prevBeat.getPreviousBeat();
        };

        // check if voices are on the same division
        return (voice.beat.getRealStart() - m1.start()) % divisionLength != _graceShift;

    }
    
}