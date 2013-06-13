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
 * Possible targets
 **/
enum Target {
    Segno;
    Coda;
    Fine;
}

/**
 * Possible jump values
**/
enum Jump {
    DaCoda;
    DaSegnoAlCoda;
    DaSegnoAlFine;
}

/**
 * Direction definitions for measure
 */
class Direction
{
    private var targets: Hash<Bool>;
    private var jumps: Hash<Bool>;

    public function new() {
        targets = new Hash<Bool>();
        jumps = new Hash<Bool>();
    }

    /** Add new target */
    public function addTarget(t: Target): Void {
        targets.set(Std.string(t), true);
    }

    /** Add new jump direction */
    public function addJump(j: Jump): Void {
        jumps.set(Std.string(j), true);
    }

    /** Check if provided target exists */
    public function hasTarget(t: Target): Bool {
        return targets.exists(Std.string(t));
    }

    /** Check if jump exists */
    public function hasJump(j: Jump): Bool {
        return jumps.exists(Std.string(j));
    }
}