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
package alphatab.platform.js;
#if js
import alphatab.platform.js.JsonCanvas.JsonCommand;
import alphatab.platform.Canvas;


class JsonCommand {
    public static inline var APPLY_TO_CANVAS = 1;
    public static inline var APPLY_TO_CONTEXT = 2;

    public static inline function getCommandsMap(){
     return {"height": 0,
         "width": 1,
         "strokeStyle": 2,
        "fillStyle": 3,
        "lineWidth": 4,
        "clearRect": 5,
        "fillRect": 6,
        "strokeRect": 7,
        "beginPath": 8,
        "closePath": 9,
        "moveTo": 10,
        "lineTo": 11,
        "quadraticCurveTo": 12,
        "bezierCurveTo": 13,
        "arc": 14,
        "rect": 15,
        "fill": 16,
        "stroke": 17,
        "font": 18,
        "textBaseline": 19,
        "textAlign": 20,
        "fillText": 21,
        "strokeText": 22,
        "measureText": 23
    };
    }

    private static inline function createFunction(command:Int, applyTo: Int, args: Array<Dynamic>){
        var c:Dynamic = {"c":command, "cl":1, "a2":applyTo};
        if (args.length > 0){
            c.a = args;
        }
        return c;
    }

    private static inline function createProperty(name:Int, applyTo:Int, value: Dynamic){
        return {"c":name, "cl":0, "a2":applyTo, "v":value};
    }

    public static inline function createContextFunction(command: Int, args:Array<Dynamic>){
        return createFunction(command, APPLY_TO_CONTEXT, args);

    }

    public static inline function createCanvasFunction(command:Int, args:Array<Dynamic>) {
        return createFunction(command, APPLY_TO_CANVAS, args);
    }

    public static inline function createCanvasProperty(name:Int, value:Dynamic){
        return createProperty(name, APPLY_TO_CANVAS, value);
    }

    public static inline function createContextProperty(name:Int, value:Dynamic){
        return createProperty(name, APPLY_TO_CONTEXT, value);
    }

    public static function normalizeFloat(value:Float){
        var precision = 2;
        value = value * Math.pow(10, precision);
        value  = Math.round( value ) / Math.pow(10, precision);
        return value;
    }

}


/**
 * Render canvas commands to JSON structure
 */


class CanvasContext {
    public var defaultTextWidth: Int;

    public var width: Int;

    public var height: Int;

    public var strokeStyle: String;

    public var fillStyle: String;

    public var lineWidth: Float;

    public var font: String;

    public var textBaseline: String;

    public var textAlign: String;

    public var map: Dynamic;

    public function new(){
        defaultTextWidth = -100000000;
        height = 0;
        map = JsonCommand.getCommandsMap();
    }

    public function toDynamic(){
        return {"defaultTextWidth": defaultTextWidth,
        "width": width,

        "height": height,

        "strokeStyle": strokeStyle,

        "fillStyle": fillStyle,

        "lineWidth": lineWidth,

        "font": font,

        "textBaseline": textBaseline,

        "textAlign": textAlign,

        "map": map

        };
    }

}

class CanvasAcc {
    public var commands: Array<Dynamic>;

    public var context: CanvasContext;

    public var counter: Int;

    function new(commands, context){
        this.commands = commands;
        this.context = context;
        counter = 0;
    }

    public function add(cmd: Dynamic){
        this.commands.push(cmd);
        counter ++;
        // trace("["+(cast counter)+"] "+cmd.command);
    }

    public function toDynamic(){
        return {"commands": commands, "context": context.toDynamic()};
    }

}

class JsonCanvas implements Canvas
{
    private var _acc: CanvasAcc;
    private var _map: Dynamic;

    public function new(acc:CanvasAcc)
    {
        this._acc = acc;
        this.width = this._acc.context.width;
        this._map = this._acc.context.map;
        trace(this._map);
    }

    // convert command name to its int representation
    public function m(command:String){
        var cmd: Int;
        untyped {cmd = _acc.context.map[command];};
        if (cmd == null){
            throw("No mapping for command: "+command);
        }
        return cmd;
    }

    public var width(getWidth, setWidth):Int;
    public var height(getHeight, setHeight):Int;

    private function getWidth():Int
    {
        return _acc.context.width;
    }

    private function getHeight():Int
    {
        return _acc.context.height;
    }

    private function setWidth(width:Int):Int
    {
        _acc.add(JsonCommand.createCanvasProperty(m("width"), width));
        _acc.context.width = width;
        return width;
    }

    private function setHeight(height:Int):Int
    {
        _acc.add(JsonCommand.createCanvasProperty(m("height"), height));
        _acc.context.height = height;
        return height;
    }

    // colors and styles
    public var strokeStyle(getStrokeStyle, setStrokeStyle):String;

    private function getStrokeStyle() : String
    {
        return _acc.context.strokeStyle;
    }
    private function setStrokeStyle(value:String) : String
    {
        _acc.add(JsonCommand.createContextProperty(m("strokeStyle"), value));
        _acc.context.strokeStyle = value;
        return _acc.context.strokeStyle;
    }

    public var fillStyle(getFillStyle, setFillStyle):String;
    private function getFillStyle() : String
    {
        return _acc.context.fillStyle;
    }
    private function setFillStyle(value:String) : String
    {
        _acc.context.fillStyle = value;
        _acc.add(JsonCommand.createContextProperty(m("fillStyle"), value));
        return _acc.context.fillStyle;
    }

    // line caps/joins
    public var lineWidth(getLineWidth, setLineWidth):Float;
    private function getLineWidth() : Float
    {
        return _acc.context.lineWidth;
    }
    private function setLineWidth(value:Float) : Float
    {
        _acc.add(JsonCommand.createContextProperty(m("lineWidth"), JsonCommand.normalizeFloat(value)));
        _acc.context.lineWidth = value;
        return _acc.context.lineWidth;
    }

    // rects
    public function clear():Void
    {
        _acc.add(JsonCommand.createContextFunction(m("clearRect"), [0, 0, width, height]));
    }
    public function fillRect(x:Float, y:Float, w:Float, h:Float):Void
    {
        x = JsonCommand.normalizeFloat(x);
        y = JsonCommand.normalizeFloat(y);
        w = JsonCommand.normalizeFloat(w);
        h = JsonCommand.normalizeFloat(h);
        _acc.add(JsonCommand.createContextFunction(m("fillRect"), [x, y, w, h]));
    }
    public function strokeRect(x:Float, y:Float, w:Float, h:Float):Void
    {
        x = JsonCommand.normalizeFloat(x);
        y = JsonCommand.normalizeFloat(y);
        w = JsonCommand.normalizeFloat(w);
        h = JsonCommand.normalizeFloat(h);
        _acc.add(JsonCommand.createContextFunction(m("strokeRect"), [x, y, w, h]));
    }

    // path API
    public function beginPath():Void
    {
        _acc.add(JsonCommand.createContextFunction(m("beginPath"), []));
    }
    public function closePath():Void
    {
        _acc.add(JsonCommand.createContextFunction(m("closePath"), []));
    }
    public function moveTo(x:Float, y:Float):Void
    {
        x = JsonCommand.normalizeFloat(x);
        y = JsonCommand.normalizeFloat(y);
        _acc.add(JsonCommand.createContextFunction(m("moveTo"), [x, y]));
    }
    public function lineTo(x:Float, y:Float):Void
    {
        x = JsonCommand.normalizeFloat(x);
        y = JsonCommand.normalizeFloat(y);
        _acc.add(JsonCommand.createContextFunction(m("lineTo"), [x, y]));
    }
    public function quadraticCurveTo(cpx:Float, cpy:Float, x:Float, y:Float):Void
    {
        cpx = JsonCommand.normalizeFloat(cpx);
        cpy = JsonCommand.normalizeFloat(cpy);
        x = JsonCommand.normalizeFloat(x);
        y = JsonCommand.normalizeFloat(y);
        _acc.add(JsonCommand.createContextFunction(m("quadraticCurveTo"), [cpx, cpy, x, y]));
    }
    public function bezierCurveTo(cp1x:Float, cp1y:Float, cp2x:Float, cp2y:Float, x:Float, y:Float):Void
    {
        cp1x = JsonCommand.normalizeFloat(cp1x);
        cp1y = JsonCommand.normalizeFloat(cp1y);
        cp2x = JsonCommand.normalizeFloat(cp2x);
        cp2y = JsonCommand.normalizeFloat(cp2y);
        x = JsonCommand.normalizeFloat(x);
        y = JsonCommand.normalizeFloat(y);
        _acc.add(JsonCommand.createContextFunction(m("bezierCurveTo"), [cp1x, cp1y, cp2x, cp2y, x, y]));

    }
    public function circle(x:Float, y:Float, radius:Float):Void
    {
        x = JsonCommand.normalizeFloat(x);
        y = JsonCommand.normalizeFloat(y);
        radius = JsonCommand.normalizeFloat(radius);
        _acc.add(JsonCommand.createContextFunction(m("arc"), [x, y, radius, 0, Math.PI*2, true]));
    }
    public function rect(x:Float, y:Float, w:Float, h:Float):Void
    {
        x = JsonCommand.normalizeFloat(x);
        y = JsonCommand.normalizeFloat(y);
        w = JsonCommand.normalizeFloat(w);
        h = JsonCommand.normalizeFloat(h);
        _acc.add(JsonCommand.createContextFunction(m("rect"), [x, y, w, h]));
    }
    public function fill():Void
    {
        _acc.add(JsonCommand.createContextFunction(m("fill"), []));
    }
    public function stroke():Void
    {
        _acc.add(JsonCommand.createContextFunction(m("stroke"), []));
    }

    // text
    public var font(getFont, setFont):String;
    private function getFont() : String
    {
        return _acc.context.font;
    }
    private function setFont(value:String) : String
    {
        _acc.add(JsonCommand.createContextProperty(m("font"), value));
        _acc.context.font = value;
        return _acc.context.font;
    }

    public var textBaseline(getTextBaseline, setTextBaseline):String;
    private function getTextBaseline() : String
    {

        return _acc.context.textBaseline;
    }
    private function setTextBaseline(value:String) : String
    {
        _acc.add(JsonCommand.createContextProperty(m("textBaseline"), value));
        _acc.context.textBaseline = value;
        return _acc.context.textBaseline;
    }

    public var textAlign(getTextAlign, setTextAlign):String;
    private function getTextAlign() : String
    {
        return _acc.context.textAlign;
    }
    private function setTextAlign(value:String) : String
    {
        _acc.add(JsonCommand.createContextProperty(m("textAlign"), value));
        _acc.context.textAlign = value;
        return _acc.context.textAlign;
    }

    public function fillText(text:String, x:Float, y:Float, maxWidth:Float = 0):Void
    {
        x = JsonCommand.normalizeFloat(x);
        y = JsonCommand.normalizeFloat(y);
        var params:Array<Dynamic>;
        if (maxWidth == 0)
        {
              params = [text, x, y];
        }
        else
        {
            params = [text, x, y, maxWidth];
        }
        _acc.add(JsonCommand.createContextFunction(m("fillText"), params));
    }
    public function strokeText(text:String, x:Float, y:Float, maxWidth:Float = 0):Void
    {
        x = JsonCommand.normalizeFloat(x);
        y = JsonCommand.normalizeFloat(y);
        maxWidth = JsonCommand.normalizeFloat(maxWidth);
        var params:Array<Dynamic>;

        if (maxWidth == 0)
        {
            params = [text, x, y];
        }
        else
        {
            params = [text, x, y, maxWidth];
        }
        _acc.add(JsonCommand.createContextFunction(m("strokeText"), params));

    }
    public function measureText(text:String):Float
    {
        _acc.add(JsonCommand.createContextFunction(m("measureText"), [text]));
        return _acc.context.defaultTextWidth;
    }
}
#end
