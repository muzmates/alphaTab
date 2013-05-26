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
 * A beat contains multiple voices. 
 */

class Beat
{
    public static inline var MAX_VOICES:Int = 2;
    
    public var voices(default,default):Array<Voice>;
    public var text(default,default):BeatText;
    public var measure(default,default):Measure;
    public var start(default,default):Int;
    public var effect(default,default):BeatEffect;
    public var index(default,default):Int;
    public var properties(default, default): BeatProperties;
    public var isGrace(getIsGrace, null): Bool;
    private var _isGrace(default, default): Bool;
        
    public function isRestBeat() : Bool
    {
        for(i in 0 ... voices.length)
        {
            var voice:Voice = this.voices[i];
            if(!voice.isEmpty && !voice.isRestVoice())
                return false;
        }
        return true;
    }

    private function getIsGrace(): Bool
    {
        if (_isGrace == null){
            _isGrace = false;
            for (v in voices){
                _isGrace = v.isGrace || _isGrace;
            }
        }
        return _isGrace;
    }
    
    public function getRealStart() : Int
    {
        var offset = start - measure.start();
        return measure.header.realStart + offset;
    }
    
    public function setText(text:BeatText) : Void
    {
        text.beat = this;
        this.text = text;
    }
    public function setChord(chord:Chord) : Void
    {
        chord.beat = this;
        this.effect.chord = chord;
    }
    
    public function ensureVoices(count:Int, factory:SongFactory) : Void
    {
        while(voices.length < count) // as long we hav not enough voicex
        {
            // create new ones
            var voice = factory.newVoice(voices.length);
            voice.beat = this;
            this.voices.push(voice);
        }
    }
    
    public function getNotes() : Array<Note>
    {
        var notes:Array<Note> = new Array<Note>();
        for (voice in voices) 
        {
            for (note in voice.notes)
            {
                notes.push(note);
            }
        }
        return notes;
    }
    
    public function new(factory:SongFactory)
    {
        start = Duration.QUARTER_TIME;
        effect = factory.newBeatEffect();
        voices = new Array<Voice>();
        properties = new BeatProperties();
        isGrace = false;
        for(i in 0 ... Beat.MAX_VOICES)
        {
            var voice = factory.newVoice(i);
            voice.beat = this;
            this.voices.push(voice);
        }
    }
}