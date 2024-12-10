#!/usr/bin/tclsh9.0

source ../library/tools.tcl
source ../library/intv.tcl
source ../library/geom.tcl

namespace import ::geom::*

::oo::objdefine ::geom::vec {
    forward invscale  my Invscale
    forward scalefrac my Scalefrac
}

proc read_input {input_file} {
    set lines {}
    foreachLine line $input_file {
        lappend lines $line
    }
    return $lines
}

proc find_antennas {lines} {
    set antennas {}
    set height [llength $lines]
    set width [list_max $lines ::string length]
    set y -1
    foreach line $lines {
        incr y
        set n [string length $line]
        for {set x 0} {$x < $n} {incr x} {
            set c [string index $line $x]
            if {[string match {[0-9a-zA-Z]} $c]} {
                dict lappend antennas $c [list $x $y]
            }
        }
    }
    return [list $width $height $antennas]
}

# "An antinode occurs at any point that is perfectly in line with two
# antennas of the same frequency - but only when one antenna is twice
# as far away as the other."
#
# According to the problem description, there are two antinodes.
# If the points are p0 = (x0, y0) and p1 = (x1, y1), the ones
# the problem descr. seems to want are
#   (2*x0 - x1, 2*y0 - y1)
#   (-x0 + 2*x1, -y0 + 2*y1)
#
# These are what I'll call 'external' antinodes.  On a line, they
# look like this.
#
#              antenna--+     +--antinode
#                       |     |
#   --------#-----a-----a-----#------
#           |<-d->|<-d->|<-d->|
#
# However, by the strict interpretation, there are actually *4*
# antinodes: the other two are 'interior' antinodes. Here I've
# labelled them with '*':
#
#   --------#-----a-*-*-a-----#------
#           |<-d->|<-d->|<-d->|
#
# They lie between the antennas, at 1/3 and 2/3 along the
# joining line.
#
# On an integer grid the external antinodes always exist (assuming
# infinite grid), however the internal antinodes will only exist
# when the x and y displacements between the antennas are both
# divisible by 3.

proc lerp_int {a b t} {
    return [expr {$a + $t * ($b - $a)}]
}
proc lerp_frac {a b tnumer {tdenom 1}} {
    return [expr {$a + ($tnumer * ($b - $a))/$tdenom}]
}
proc Point_lerp {x0 y0 x1 y1 tnumer {tdenom 1}} {
    set x [expr {$x0 + ($tnumer * ($x1 - $x0)) / $tdenom}]
    set y [expr {$y0 + ($tnumer * ($y1 - $y0)) / $tdenom}]
    return [list $x $y]
}


::oo::class create TheProblem {
    variable width height antennas
    variable unique_antinodes

    constructor {thewidth theheight theantennas} {
        set width $thewidth
        set height $theheight
        set antennas $theantennas
    }

    method antenna_pair_antinodes {p0 p1} {
        error "not implemented"
    }

    method antenna_antinodes {antenna_locs} {
        set antinodes {}
        set n [llength $antenna_locs]
        set n1 [expr {$n - 1}]
        for {set i 0} {$i < $n1} {incr i} {
            set p0 [lindex $antenna_locs $i]
            for {set j [expr {$i + 1}]} {$j < $n} {incr j} {
                set p1 [lindex $antenna_locs $j]
                lappend antinodes {*}[my antenna_pair_antinodes $p0 $p1]
            }
        }
        return $antinodes
    }

    method all_unique_antinodes {} {
        if {[info exists unique_antinodes]} {
            return $unique_antinodes
        }
        set unique_antinodes {}
        dict for {a ants} $antennas {
            set aps [my antenna_antinodes $ants]
            #puts "a=$a ants=[list $ants]  antinodes=[list $aps]"
            foreach ap $aps {
                lassign $ap x y
                if {$x < 0 || $y < 0 || $width <= $x || $height <= $y} {
                    continue
                }
                dict set unique_antinodes $ap {}
            }
        }
        return $unique_antinodes
    }

    method number_unique_antinodes {} {
        set aps [my all_unique_antinodes]
        return [dict size $aps]
    }

    method map_locations {} {
        ::geom::StringGrid create sgrid -width $width -height $height -fill "."
        dict for {a ants} $antennas {
            foreach p $ants {
                sgrid put $p $a
            }
        }
        set antinodes [my all_unique_antinodes]
        foreach p [dict keys $antinodes] {
            if {[sgrid get $p] ni {. #}} {
                sgrid put $p %
            } else {
                sgrid put $p "#"
            }
        }
        set map [sgrid repr]
        sgrid destroy
        return $map
    }

}

::oo::class create Part1 {
    superclass -append TheProblem

    method antenna_pair_antinodes {p0 p1} {
        set antinodes {}
        set dp [point diff $p0 $p1]
        # General equation: p = p0 + t * (p1 - p0) = (1-t)*p0 + t*p1
        # The antinodes are at t=-1, t=1/3, t=2/3, t=2.
        #   t           p(t)
        #  -1      2*p0 - p1       = p0 + (p0-p1)
        #  1/3     2/3*p0 + 1/3*p1 = p0 + 1/3*(p0-p1)
        #  2/3     1/3*p0 + 2/3*p1 = p0 + 2/3*(p0-p1)
        #   2      -p0 + 2*p1      = p0 - 2*(p0-p1)
        set antinodes {}
        lassign $p0 x0 y0
        lassign $p1 x1 y1
        set dx [expr {$x0 - $x1}]
        set dy [expr {$y0 - $y1}]
        if {$dx % 3 == 0 && $dy % 3 == 0} {
            puts "Found interior antinodes!"
            lappend antinodes [Point_lerp $x0 $y0 $x1 $y1 1 3]
            lappend antinodes [Point_lerp $x0 $y0 $x1 $y1 2 3]
        }
        lappend antinodes [Point_lerp $x0 $y0 $x1 $y1 2]
        lappend antinodes [Point_lerp $x0 $y0 $x1 $y1 -1]
        return $antinodes
    }
}


set antennamap [read_input input.txt]

lassign [find_antennas $antennamap] width height antennas

Part1 create part1 $width $height $antennas

puts "Part 1"
#show_locations $width $height $antennas
puts "Number of unique antinodes = [measure {part1 number_unique_antinodes}]"



# Now, we have antinodes at all positions p = p0 + n * (p1-p0)
# where n is an integer (including n=0 p=p0 and n=1 p=p1)

::oo::class create Part2 {
    superclass -append TheProblem

    variable width height

    method antenna_pair_antinodes {p0 p1} {
        # we assume p0, p1 are in the grid
        set dp [point diff $p0 $p1]
        set r [rect00 make $width $height]
        set ivn [rect00 delta_intersection_range $r $p0 $dp]
        if {$ivn eq {}} {
            return {}
        }
        lassign $ivn a b
        return [lmap i [lseq $a to $b] {
            point translate $p0 [vec scale $dp $i]
        }]
    }
}

#puts "Part 2"
Part2 create part2 $width $height $antennas

puts [part2 map_locations]

puts "Number of unique antinodes = [measure {part2 number_unique_antinodes}]"
