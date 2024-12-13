#!/usr/bin/tclsh9.0

package require aoc::tools
package require aoc::geom

namespace import ::geom::point
namespace import ::tcl::mathop::*

::oo::class create MapGrid {
    superclass -append ::geom::StringGrid

}

proc read_input {input_file} {
    # clean up the list by remaking it
    return [list {*}[readFile $input_file]]
}

proc check_rectangular {lines} {
    set lastlen {}
    foreach line $lines {
        set len [string length $line]
        if {$lastlen ne {} && $lastlen != $len} {
            error "Data is not rectangular"
        }
    }
}

proc findall {needle haystack {start 0}} {
    set locs {}
    set n [string length $needle]
    while {1} {
        set i [string first $needle $haystack $start]
        if {$i == -1} {
            break
        }
        lappend locs $i
        set start [expr {$i + $n}]
    }
    return $locs
}

proc locate_trailheads {map} {
    set trailheads {}
    set y -1
    foreach line $map {
        incr y
        foreach x [findall 0 $line] {
            lappend trailheads [list $x $y]
        }
    }
    return $trailheads
}

proc getmap {map x y} {
    set line [lindex $map $y]
    return [string index $line $x]
}

# Von Neumann neighbourhood
#     ^
#   < X >
#     v
# Returns a list of 4 values
# Order is {^ v < >}
proc neighbourhood {map x y} {
    if {$x < 0 || $y < 0 || [llength $map] <= $y} {
        return {}
    }
    set line0 [lindex $map $y]
    if {[string length $line0] <= $x} { return {} }
    set dahood {}
    if {0 < $y} {
        set lineup [lindex $map [expr {$y - 1}]]
        lappend dahood [string index $lineup $x]
    } else {
        lappend dahood {}
    }
    if {$y < [llength $map]-1} {
        set linedn [lindex $map [expr {$y + 1}]]
        lappend dahood [string index $linedn $x]
    } else {
        lappend dahood {}
    }
    # Using defined out-of-bounds behaviour here
    lappend dahood [string index $line0 [expr {$x - 1}]]
    lappend dahood [string index $line0 [expr {$x + 1}]]
    return $dahood
}

proc dx {dirno} {
    return [lindex {0 0 -1 1} $dirno]
}
proc dy {dirno} {
    return [lindex {-1 1 0 0} $dirno]
}
proc oppdir {dirno} {
    return [lindex {1 0 3 2} $dirno]
}

proc trailhead_score {map trailhead} {
    lassign $trailhead x y
    set c [getmap $map $x $y]
    if {$c != 0} { error "trailhead $x,$y isn't at 0" }
    set worklist [list [list $x $y 1]]
    set maxheight_posns {}
    while {[llength $worklist] > 0} {
        lassign [lpop worklist] x y next
        if {$next == 10} {
            dict set maxheight_posns $x,$y {}
        } else {
            foreach c [neighbourhood $map $x $y] dx {0 0 -1 1} dy {-1 1 0 0} {
                if {$c == $next} {
                    lappend worklist [list [expr {$x+$dx}] [expr {$y+$dy}] \
                                          [expr {$next + 1}]]
                }
            }
        }
    }
    return [dict size $maxheight_posns]
}

proc total_score {map} {
    set trailheads [locate_trailheads $map]
    set total 0
    foreach th $trailheads {
        set n [trailhead_score $map $th]
        #puts "th=[list $th] n=$n"
        incr total $n
    }
    return $total
}

proc count_trailhead_trails {map trailhead} {
    lassign $trailhead x y
    set c [getmap $map $x $y]
    if {$c != 0} { error "trailhead $x,$y isn't at 0" }
    set worklist [list [list $x $y 1]]
    set ntrails 0
    while {[llength $worklist] > 0} {
        lassign [lpop worklist] x y next
        if {$next == 9} {
            foreach c [neighbourhood $map $x $y] {
                if {$c == 9} {
                    incr ntrails
                }
            }
        } else {
            foreach c [neighbourhood $map $x $y] dx {0 0 -1 1} dy {-1 1 0 0} {
                if {$c == $next} {
                    lappend worklist [list [expr {$x+$dx}] [expr {$y+$dy}] \
                                          [expr {$next + 1}]]
                }
            }
        }
    }
    return $ntrails
}

# Part 2 again.
# * map is a list of lists of symbols
# * we add a 1-cell border around the map so that x+/-1, y+/-1 is
#   still in the list of lists.  Further excursion is prevented by
#   making the border be -1.

proc padded_data_from_lines {lines} {
    set width [list_max $lines ::string length]
    set height [llength $lines]
    set gwidth [expr {$width + 2}]
    set fill -1
    set data [list [lrepeat $gwidth $fill]]
    foreach line $lines {
        lappend data [list $fill {*}[split $line ""] $fill]
    }
    lappend data [lrepeat $gwidth $fill]
    set stridey $gwidth
    return [list $data [+ 1 $gwidth] $stridey]
}

proc count_trailhead_trails2 {data x y {next 1} {acc 0}} {
    set next1 [expr {$next + 1}]
    foreach {dx dy} {0 -1 0 1 -1 0 1 0} {
        set x1 [+ $x $dx]
        set y1 [+ $y $dy]
        set c [lindex $data $y1 $x1]
        if {$c == $next} {
            if {$next == 9} {
                incr acc
            } else {
                set acc [count_trailhead_trails2 $data $x1 $y1 $next1 $acc]
            }
        }
    }
    return $acc
}

proc count_trails2 {map} {
    set trailheads [locate_trailheads $map]
    set dirmaps [padded_data_from_lines $map]
    set data [lindex $dirmaps 0]
    set stridey [lindex $dirmaps 2]
    set total 0
    foreach th $trailheads {
        lassign $th x y
        incr x
        incr y
        set n [count_trailhead_trails2 $data $x $y]
        #puts "th=[list $th] n=$n"
        incr total $n
    }
    return $total
}

set input_file [lindex $argv 0]
if {$input_file eq ""} {
    set input_file example.txt
}

record start
puts "Part 1"
set trailmap [read_input $input_file]
check_rectangular $trailmap

record mark readmap

puts "Total trailhead score: [measure {total_score $trailmap}]"
record mark part1

puts "Part 2"
puts "Total trailhead rating: [measure {count_trails2 $trailmap}]"
puts "(expected: 1960)"
record mark part2

record report
