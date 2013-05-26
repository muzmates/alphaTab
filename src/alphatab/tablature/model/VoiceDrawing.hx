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
import alphatab.model.Duration;
import alphatab.model.Note;
import alphatab.model.SongFactory;
import alphatab.model.Tuplet;
import alphatab.model.Voice;
import alphatab.tablature.drawing.DrawingResources;
import alphatab.tablature.staves.ScoreStave;
import alphatab.tablature.ViewLayout;

class VoiceDrawing extends Voice
{
    // cache for storing which effects are available in this beat
    public var effectsCache(default,default):EffectsCache;
    
    // is there any note displaced?
    public var anyDisplaced(default,default):Bool;

    
    public var width(default,default):Int;
    
    public var beatGroup(default,default):BeatGroup;
    public var tripletGroup(default,default):TripletGroup;
    
    public var leftJoin(default,default):VoiceDrawing;
    public var rightJoin(default,default):VoiceDrawing;
    public var joinedType(default,default):JoinedType;
    public var isJoinedGreaterThanQuarter(default,default):Bool;
    
    public var minStringNote(default,default):NoteDrawing;
    public var maxStringNote(default,default):NoteDrawing;
    
#if cpp
    public function beatDrawing() : BeatDrawing
#else
    public inline function beatDrawing() : BeatDrawing
#end
    {
        return cast beat;
    }

#if cpp
    public function measureDrawing() : MeasureDrawing
#else
    public inline function measureDrawing() : MeasureDrawing
#end
    {
        return beatDrawing().measureDrawing();
    }

    public function new(factory:SongFactory, index:Int)
    {
        super(factory, index);
        effectsCache = new EffectsCache();
    }

    public function getPreviousVoice() : VoiceDrawing
    {
         var previousBeat = beatDrawing().getPreviousBeat();
        // ignore previous beat if it is not in the same line
        if (previousBeat == null)
            return null;
            
        return previousBeat != null ? cast previousBeat.voices[index] : null;
    }

    public function getPreviousVoiceWithNotes(): VoiceDrawing
    {
        var previousBeat = beatDrawing().getPreviousBeat();
        var voice:VoiceDrawing = null;

        while((voice == null || voice.isEmpty ) && previousBeat != null)
        {
            voice = cast previousBeat.voices[index];
            previousBeat = previousBeat.getPreviousBeat();
        }

        return voice;
    }

    
    public function getNextVoice() : VoiceDrawing
    {
         var previousBeat = beatDrawing().getNextBeat();
        // ignore previous beat if it is not in the same line
        if (previousBeat == null)
            return null;
            
        return previousBeat != null ? cast previousBeat.voices[index] : null;
    }

    public function getNextVoiceWithNotes(): VoiceDrawing
    {
        var nextBeat = beatDrawing().getNextBeat();
        var voice:VoiceDrawing = null;

        while((voice == null || voice.isEmpty) && nextBeat != null)
        {
            voice = cast nextBeat.voices[index];
            nextBeat = nextBeat.getNextBeat();
        }

        return voice;
    }
    
    public var minNote(default,default):NoteDrawing;
    public var maxNote(default,default):NoteDrawing;   
    
    public function checkNote(note:NoteDrawing)
    {        
        var bd:BeatDrawing = beatDrawing();
        bd.checkNote(note);

        if (minNote == null || minNote.realValue() > note.realValue())
        {
            minNote = note;
        }
        if (maxNote == null || maxNote.realValue() < note.realValue())
        {
            maxNote = note;
        }
        
        if (minStringNote == null || minStringNote.string > note.string)
        {
            minStringNote = note;
        }
        if (maxStringNote == null || maxStringNote.string < note.string)
        {
            maxStringNote = note;
        }
    }
    
    private function compareNotes(a:Note, b:Note) : Int
    {
        if (a.realValue() > b.realValue())
            return 1;
        if (a.realValue() < b.realValue())
            return -1;
        return 0;
    }
    
    public function performLayout(layout:ViewLayout)
    {

        // get default voice width provided by the layout
        width = layout.getVoiceWidth(this);
        effectsCache.reset();
        
        // sort notes ascending
        notes.sort(compareNotes);
        
        anyDisplaced = false;
        var previousNote:NoteDrawing = null;
        for (note in notes)
        {
            var noteDrawing:NoteDrawing = cast note;
            noteDrawing.displaced = ScoreStave.isDisplaced(previousNote, noteDrawing);      
            if (noteDrawing.displaced) 
            {
                anyDisplaced = true;
            }
            noteDrawing.performLayout(layout); 
            previousNote = noteDrawing;
        }
        
        // make space for an additional notehead 
        if (anyDisplaced)
        {
            width += Math.floor(DrawingResources.getScoreNoteSize(layout, false).x);
        }

        if(beatDrawing().effectsCache.arpeggio)
            width += Math.floor(DrawingResources.getScoreNoteSize(layout,
                                true).x);

        var previousVoice = getPreviousVoiceWithNotes();
        var nextVoice = getNextVoiceWithNotes();

        // check for joins with previous / next beat 
        var noteJoined:Bool = false;
        var withPrevious:Bool = false;
        
        joinedType = JoinedType.NoneRight;
        leftJoin = this;
        rightJoin = this;
        isJoinedGreaterThanQuarter = false;
        
        if (BeatGroup.canJoin(this, previousVoice))
        {
            withPrevious = true;
            
            if (previousVoice.duration.value >= duration.value)
            {
                leftJoin = previousVoice;
                rightJoin = this;
                joinedType = JoinedType.Left;                
                noteJoined = true;
            }
            
            if (previousVoice.duration.value > Duration.QUARTER)
            {
                isJoinedGreaterThanQuarter = true;
            }

        }
        
        if (BeatGroup.canJoin(this, nextVoice))
        {
            if (nextVoice.duration.value >= duration.value)
            {
                rightJoin = nextVoice;
                if (previousVoice == null || previousVoice.isRestVoice() || previousVoice.duration.value < duration.value)
                {
                    leftJoin = this;
                }
                
                noteJoined = true;
                joinedType = JoinedType.Right;                    
            }
            if (nextVoice.duration.value > Duration.QUARTER)
            {
                isJoinedGreaterThanQuarter = true;
            }
        }
        
        if (!noteJoined && withPrevious)
        {
            joinedType = JoinedType.NoneLeft;
        }

        // create beat group
        if (!isRestVoice())
        {            
            if (beatGroup == null)
            {
                // if there is no previous voice 
                // we need to create a new group, we also create a new group if 
                // we can't join with the previous group
                if (previousVoice != null && previousVoice.beatGroup != null 
                    && previousVoice.beatGroup.check(this))
                {
                    beatGroup = previousVoice.beatGroup;
                }
                else
                {
                    beatGroup = new BeatGroup();
                    beatGroup.check(this);
                }
            }
            
            if(!Lambda.has(measureDrawing().groups, beatGroup))
            {
                measureDrawing().groups.push(beatGroup);                
            }
        }
        
        
       
        // try to add on tripletgroup of previous beat or create a new group
        if (duration.tuplet != null && !duration.tuplet.equals(Tuplet.NORMAL))
        {
            beatDrawing().effectsCache.triplet = true;
            measureDrawing().effectsCache.triplet = true;
            
            // ignore previous beat if it is not in the same line
            if (previousVoice != null && previousVoice.measureDrawing().staveLine != measureDrawing().staveLine)
                previousVoice == null;

            if (previousVoice == null || previousVoice.tripletGroup == null || !previousVoice.tripletGroup.check(this))
            {            
                tripletGroup = new TripletGroup(index);
                tripletGroup.check(this);
            }
            else
            {
                tripletGroup = previousVoice.tripletGroup;
            }
        }
    }
    
}