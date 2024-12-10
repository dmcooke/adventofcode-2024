#!/usr/bin/tclsh9.0

# Keep in mind: y increases downwards!
# This affects rotations:
# * rotating 90° clockwise takes (dx,dy) to (-dy, dx)
#   - this is turning right, if we're looking from above.
# * rotating 90° counterclockwise takes (dx,dy) to (dy,-dx)
#   - this is turning left

source ../library/intv.tcl
source ../library/tools.tcl
source ../library/geom.tcl

proc read_input {filename} {
    set input {}
    foreachLine line $filename {
        lappend input $line
    }
    return $input
}

# points and vectors are compatible

::geom::Point create point
::geom::Vector create vec

::oo::objdefine point method update_move {pvar dir {n 1}} {
    upvar 1 $pvar p
    lassign $p x y
    switch $dir {
        ^ { lset p 1 [expr {$y - $n}] }
        v { lset p 1 [expr {$y + $n}] }
        < { lset p 0 [expr {$x - $n}] }
        > { lset p 0 [expr {$x + $n}] }
        default { ::dir::Bad_dir $dir }
    }
    return
}

::oo::objdefine point method enumerate {p dir nsteps} {
    if {$nsteps < 0} {
        set dir [::dir opp $dir]
        set nsteps [expr {-$nsteps}]
    }
    if {$nsteps == 0} {
        return [list $p]
    }
    lassign $p x y
    switch $dir {
        ^ {
            set yvalues [lseq $y to [expr {$y - $nsteps}] -1]
            return [lmap i $yvalues {list $x $i}]
        }
        v {
            set yvalues [lseq $y to [expr {$y + $nsteps}] 1]
            return [lmap i $yvalues {list $x $i}]
        }
        < {
            set xvalues [lseq $x to [expr {$x - $nsteps}] -1]
            return [lmap i $xvalues {list $i $y}]
        }
        > {
            set xvalues [lseq $x to [expr {$x + $nsteps}] 1]
            return [lmap i $xvalues {list $i $y}]
        }
        default { ::dir::Bad_dir $dir }
    }
}

::oo::objdefine vec {
    method rot0 {v} {return $v}

    # → to ↑
    method turn_left {v} {
        lassign $v dx dy
        return [list $dy [expr {-$dx}]]
    }

    # (3,4) -> (-3,-4). Same as neg
    method rot180 {v} {
        lassign $v dx dy
        return [list [expr {-$dx}] [expr {-$dy}]]
    }

    # → to ↓
    method turn_right {v} {
        lassign $v dx dy
        return [list [expr {-$dy}] $dx]
    }
}

namespace eval dir {
    namespace export {[a-z]*}
    namespace ensemble create -prefixes 0

    proc Bad_dir {d} {error "bad dir \"$d\""}

    proc dx {d} {
        return [dict get {^ 0 v 0 < -1 > 1} $d]
    }

    proc dy {d} {
        return [dict get {^ -1 v 1 < 0 > 0} $d]
    }

    proc rot0 {d} { return $d }
    proc turn_left {d} {
        return [dict get {^ < v > < v > ^} $d]
    }
    proc opp {d} {
        return [dict get {^ v v ^ < > > <} $d]
    }
    proc turn_right {d} {
        return [dict get {^ > v < < ^ > v} $d]
    }

    proc tobits {d} {
        # ^ 0b0001   vertical:   0b0011
        # v 0b0010   horizontal: 0b1100
        # < 0b0100
        # > 0b1000
        return [dict get {^ 1 v 2 < 4 > 8} $d]
    }

    proc tovec {d {scale 1}} {
        if {$scale == 1} {
            return [dict get {^ {0 -1} v {0 1} < {-1 0} > {1 0}} $d]
        } else {
            switch $d {
                ^ { return [list 0 [expr {-$scale}]] }
                v { return [list 0 $scale] }
                < { return [list [expr -$scale] 0] }
                > { return [list $scale 0] }
                default { Bad_dir $d }
            }
        }
    }

}

namespace eval boxchars {
    namespace export {[a-z]*}
    namespace ensemble create -prefixes 0

    array set charlightheavy {
        " " ""
        ╵ u ╷ d ╴ l ╶ r
        ╹ U ╻ D ╸ L ╺ R
        ─ lr   ╼ lR   ╾ Lr   ━ LR
        │ ud   ╽ uD   ╿ Ud   ┃ UD
        ┌ rd   ┍ Rd   ┎ rD   ┏ RD
        ┐ ld   ┑ Ld   ┒ lD   ┓ LD
        └ ru   ┕ Ru   ┖ rU   ┗ RU
        ┘ lu   ┙ Lu   ┚ lU   ┛ LU
        ├ rud  ┝ Rud  ┞ rUd  ┟ ruD  ┠ rUD  ┡ RUd  ┢ RuD  ┣ RUD
        ┤ lud  ┥ Lud  ┦ lUd  ┧ luD  ┨ lUD  ┩ LUd  ┪ LuD  ┫ LUD
        ┬ lrd  ┭ Lrd  ┮ lRd  ┯ LRd  ┰ lrD  ┱ LrD  ┲ lRD  ┳ LRD
        ┴ lru  ┵ Lru  ┶ lRu  ┷ LRu  ┸ lrU  ┹ LrU  ┺ lRU  ┻ LRU
        ┼ lrud ┽ Lrud ┾ lRud ┿ LRud ╀ lrUd ╁ lruD ╂ lrUD ╃ LrUd
        ╄ lRUd ╅ LruD ╆ lRuD ╇ LRUd ╈ LRuD ╉ LrUD ╊ lRUD ╋ LRUD
    }

    # Not currently used
    array set charlightdouble {
        " " ""
        ═ !l!r ║ !u!d
        ╒ !rd ╓ r!d ╔ !r!d
        ╕ !ld ╖ l!d ╗ !l!d
        ╘ !ru ╙ r!u ╚ !r!u
        ╛ !lu ╜ l!u ╝ !l!u
        ╞ !rud ╟ r!u!d ╠ !r!u!d
        ╡ !lud ╢ l!u!d ╣ !l!u!d
        ╤ !l!rd ╥ lr!d ╦ !l!r!d
        ╧ !l!ru ╨ lr!u ╩ !l!r!u
        ╪ !l!rud ╫ lr!u!d ╬ !l!r!u!d
    }

    # The keys for lightheavybox are 8-bit integers, where
    # * the bottom 4 bits {b3 b2 b1 b0} are the directions
    #   {right left down up} (or, in terms of the direction symbols,
    #    ^ ↔ b0=1, v ↔ b1=1, < ↔ b2=1, > ↔ b3=1)
    # * the top 4 bits {b7 b6 b5 b4} are the weights of the
    #   corresponding lower 4, {b3 b2 b1 b0}.
    #   e.g. b6=1 if b2=1 (<) should be heavy, and b6=0 if it should
    #   be light.
    # * In the normalized encoding, a set bit in the weights
    #   correspond to a set bit in the directions.  In other words,
    #   bits that are 0 in the directions have the corresponding
    #   weight bit equal to 0.
    #
    # A value x can be normalized by ($x & (($x << 4) | 0b1111)),
    # which keeps the direction bits, and clears any weight bits
    # that aren't set in the direction bits.
    # $x & (($x << 4) | 0b1111) & 0b11111111

    array set lightheavybox {}
    array set lightbox {}
    array set heavybox {}

    # ^ 0b0001 = 0x01 = 1   0x11 = 17
    # v 0b0010 = 0x02 = 2   0x22 = 34
    # < 0b0100 = 0x04 = 4   0x44 = 68
    # > 0b1000 = 0x08 = 8   0x88 = 136

    proc desc_to_enc {desc} {
        set enc 0
        set masks [dict create u 1 U 17  d 2 D 34  l 4 L 68  r 8 R 136]
        foreach d [split $desc ""] {
            set enc [expr {$enc | [dict get $masks $d]}]
        }
        return $enc
    }
    proc enc_to_desc {enc} {
        set desc {}
        set x [expr {$enc & 0x44}]
        if {$x == 0x04} { append desc l } elseif {$x == 0x44} { append desc L }
        set x [expr {$enc & 0x88}]
        if {$x == 0x08} { append desc r } elseif {$x == 0x88} { append desc R }
        set x [expr {$enc & 0x11}]
        if {$x == 0x01} { append desc u } elseif {$x == 0x11} { append desc U }
        set x [expr {$enc & 0x22}]
        if {$x == 0x02} { append desc d } elseif {$x == 0x22} { append desc D }
        return $desc
    }

    apply [list {} {
        variable charlightheavy
        variable lightheavybox
        variable lightbox
        variable heavybox
        set conv {}

        foreach {char desc} [array get charlightheavy] {
            set k [desc_to_enc $desc]
            set lightheavybox($k) $char
            if {($k >> 4) == 0} {
                set lightbox($k) $char
            }
            if {($k >> 4) == ($k & 0b1111)} {
                set heavybox([expr {$k & 0b1111}]) $char
            }
        }
        for {set i 0} {$i < 256} {incr i} {
            if {![info exists lightheavybox($i)]} {
                set k [expr {$i & (($i << 4) | 0b1111)}]
                set lightheavybox($i) $lightheavybox($k)
            }
        }
    } [namespace current]]

    proc ofdir {d} {
        return [dict get {^ 1 v 2 < 4 > 8} $d]
    }
    proc lightofdir {d} {
        return [dict get {^ 1 v 2 < 4 > 8} $d]
    }
    proc heavyofdir {d} {
        return [dict get {^ 17 v 34 < 68 > 136} $d]
    }

    proc get {enc} {
        variable lightheavybox
        return $lightheavybox($enc)
    }

    proc getascii {enc} {
        if {$enc & 0x3} {
            return [expr {($enc & 0xc) ? "+" : "|"}]
        } else {
            return [expr {($enc & 0xc) ? "-" : " "}]
        }
    }
}

namespace eval guard {
    namespace export {[a-z]*}

    proc create {p dir} { return [list $p $dir] }

    proc x {g} {return [lindex $g 0 0]}
    proc y {g} {return [lindex $g 0 1]}
    proc dir {g} {return [lindex $g 1]}

    proc xy {g} {return [lindex $g 0]}

    proc with_xy {g xy} {
        return [list $xy [lindex $g 1]]
    }

    proc dx {g} { return [::dir dx [dir $g]] }
    proc dy {g} { return [::dir dy [dir $g]] }

    proc walk {g n} {
        lassign $g p d
        return [list [::vec add $p [::dir tovec $d $n]] $d]
    }

    proc turn_left {g} {
        lassign $g p d
        return [list $p [::dir turn_left $d]]
    }
    proc turn_right {g} {
        lassign $g p d
        return [list $p [::dir turn_right $d]]
    }

    namespace ensemble create -prefixes 0
}

::oo::class create SGrid {
    variable height width
    variable ymin ymax xmin xmax
    variable rows

    constructor {args} {
        array set options $args
        if {[info exists options(-lines)]} {
            set rows $options(-lines)
            set height [llength $rows]
            set width [list_max $rows ::string length]
        } elseif {[info exists options(-height)]
                  && [info exists options(-width)]} {
            set height $options(-height)
            set width $options(-width)
            set row [string repeat " " $width]
            set rows [lrepeat $height $row]
        }
        set ymin 0
        set ymax [expr {$height - 1}]
        set xmin 0
        set xmax [expr {$width - 1}]
    }

    method height {} {return $height}
    method width {} {return $width}
    method rows {} {return $rows}

    method isvalid_xy {x y} {
        return [expr {0 <= $x && x < $width && 0 <= $y && $y < $height}]
    }
    method isvalid_p {p} {
        lassign $p x y
        return [expr {0 <= $x && x < $width && 0 <= $y && $y < $height}]
    }

    method Check_x {x y} {
        if {$x < 0 || $width <= $x} {
            error "X coordinate $x is out of bounds"
        }
    }
    method Check_y {y} {
        if {$y < 0 || $height <= $y} {
            error "Y coordinate $x is out of bounds"
        }
    }
    method Check_xy {x y} {
        if {$x < 0 || $width <= $x || $y < 0 || $height <= $y} {
            error "Point ($x,$y) is out of bounds"
        }
    }

    method Check_point {p {xvar {}} {yvar {}}} {
        if {$xvar ne {}} {
            upvar 1 $xvar x
        }
        if {$yvar ne {}} {
            upvar 1 $yvar y
        }
        lassign $p x y
        my Check_xy $x $y
    }
    # The grid 'walls' are around the grid; we think of them as blocks
    # on the -1 lines and the width/height lines.
    #
    #    -1 0 1 2 3 4 5
    #  -1   # # # # #          <- wall
    #   0 # . . . . . #
    #   1 # . o>. . X # <- X is the > wall point of o
    #   2 # . . . . . #
    #   3 # . . . . . #
    #   4   # # # # #
    #

    method wall_point {p dir} {
        my Check_point $p x y
        switch $dir {
            ^ { return [list $x 0] }
            v { return [list $x $ymax] }
            < { return [list 0 $y] }
            > { return [list $xmax $y] }
            default { ::dir::Bad_dir $dir }
        }
    }

    # How many steps can we take before hitting the wall?
    # For the diagram above, o can take 3 steps in the > direction
    method dist_to_wall {p dir} {
        my Check_point $p x y
        switch $dir {
            ^ { return $x }
            v { return [expr {$ymax - $y}] }
            < { return $y }
            > { return [expr {$xmax - $x}] }
            default { ::dir::Bad_dir $dir }
        }
    }

    method row {y} {
        my Check_y $y
        return [lindex $rows $y]
    }

    method get {p} {
        my Check_point $p x y
        set row [lindex $rows $y]
        return [string index $row $x]
    }

    method get_xy {x y} {
        return [my get [list $x $y]]
    }

    method put {p val} {
        my Check_point $p x y
        if {[string length $val] != 1} {
            error "Value should be a string of length 1"
        }
        set row [lindex $rows $y]
        set row [string replace $row[set row ""] $x $x $val]
        lset rows $y $row
        return
    }

    method put_xy {x y val} {
        my put [list $x $y] $val
    }


    # Replace a portion of row y starting at x
    method replace_row_slice {p val} {
        my Check_point $p x y
        set n [string length $val]
        set string_iv [intv make 0 [expr {$n-1}]]
        set xmax [expr {$width - 1}]
        set coord_iv [intv make 0 $xmax]
        lassign [intv overlap $coord_iv $string_iv $x] c_iv s_iv
        if {[intv isempty $s_iv]} {
            # implies c_iv is empty too
            return
        }
        lassign $c_iv xstart xstop
        lassign $s_iv valstart valstop
        # Restriction of val to what fits in the row
        set s [string range $val $valstart $valstop]

        set row [lindex $rows $y]
        set row [string replace $row[set row ""] $xstart $xstop $s]
        lset rows $y $row
        return
    }

    # find p dir sym
    # find x y dir sym
    # Find the symbol `sym` in direction `dir` starting at (x,y)
    method find {p dir sym} {
        my Check_point $p x y
        # we have efficient searches for < and >
        switch $dir {
            > {
                set row [lindex $rows $y]
                set i [string first $sym $row $x]
                if {$i == -1} {
                    return {}
                }
                return [list $i $y]
            }
            < {
                set row [lindex $rows $y]
                set i [string last $sym $row $x]
                if {$i == -1} {
                    return {}
                }
                return [list $i $y]
            }
            ^ {
                for {set i $y} {0 <= $i} {incr i -1} {
                    set row [lindex $rows $i]
                    if {[string index $row $x] eq $sym} {
                        return [list $x $i]
                    }
                }
                return {}
            }
            v {
                for {set i $y} {$i < $height} {incr i} {
                    set row [lindex $rows $i]
                    if {[string index $row $x] eq $sym} {
                        return [list $x $i]
                    }
                }
                return {}
            }
            default { ::dir::Bad_dir $dir }
        }
    }

    method neighbourhood {p} {
        my Check_point $p x y
        set x0 [expr {0 < $x ? $x-1 : $x}]
        set x1 [expr {$x < $xmax ? $x+1 : $x}]
        set result {}
        if {0 < $y} {
            lappend result [string range [my row [expr {$y-1}]] $x0 $x1]
        }
        lappend result [string range [my row $y] $x0 $x1]
        if {$y < $ymax} {
            lappend result [string range [my row [expr {$y+1}]] $x0 $x1]
        }
        return $result
    }

    method repr {} {
        variable yheader
        if {![info exists yheader]} {
            set xw [string length $xmax]
            set yh [string length $ymax]
            set protoline [string repeat " " [expr {$width + $xw + 1}]]
            append protoline \n
            set yheader [lrepeat $yh $protoline]
            set ofs [expr {$xw + 1}]
            for {set y 0} {$y < $height} {incr y} {
                set p [expr {$ofs + $y}]
                set i -1
                foreach d [split [format %*d $yh $y] ""] {
                    incr i
                    set line [lindex $yheader $i]
                    set line [string replace $line $p $p $d]
                    lset yheader $i $line
                }
            }
            set yheader [join $yheader ""]
        }
        set result $yheader
        set x -1
        foreach row $rows {
            incr x
            append result [format "%*d %s\n" $xw $x $row]
        }
        return $result
    }
}


::oo::class create Problem {
    variable initial_guard

    constructor {input_file} {
        set input [::read_input $input_file]
        ::SGrid create grid -lines $input
        set initial_guard [my find_guard]
        grid put [::guard xy $initial_guard] "."
    }

    forward grid  grid

    method initial_guard {} { return $initial_guard }

    method find_guard {} {
        for {set y 0} {$y < [grid height]} {incr y} {
            set row [grid row $y]
            foreach sym {^ v < >} {
                set x [string first $sym $row]
                if {$x != -1} {
                    return [::guard create [list $x $y] $sym]
                }
            }
        }
    }

    method find_obstacle {start dir} {
        return [grid find $start $dir \#]
    }

    method walk_leg {gp gdir} {
        set endp [my find_obstacle $gp $gdir]
        if {$endp eq {}} {
            set escape 1
            set endp [grid wall_point $gp $gdir]
        } else {
            # don't actually step on the obstacle
            set escape 0
            ::point update_move endp [::dir opp $gdir]
        }
        set nsteps [::vec l1norm [vec sub $endp $gp]]
        if {!$escape} {
            set gdir [::dir turn_right $gdir]
        }
        return [list $endp $gdir $nsteps $escape]
    }

    method walk_the_guard {callback} {
        set gp [::guard xy $initial_guard]
        set gdir [::guard dir $initial_guard]
        set escape 0
        while {1} {
            lassign [my walk_leg $gp $gdir] endp newgdir nsteps escape
            uplevel #0 [list {*}$callback $gp $gdir $nsteps]
            if {$escape} {
                break
            }
            set gdir $newgdir
            set gp $endp
        }
    }

    method walk_the_guard_coro {} {
        yield
        set gp [::guard xy $initial_guard]
        set gdir [::guard dir $initial_guard]
        set escape 0
        while {1} {
            lassign [my walk_leg $gp $gdir] endp newgdir nsteps escape
            yield [list $gp $gdir $nsteps]
            if {$escape} {
                break
            }
            set gdir $newgdir
            set gp $endp
        }
    }

    method walked_cells {{guard {}}} {
        if {$guard eq {}} {
            set guard $initial_guard
        }
        set walked {}
        set gp [::guard xy $initial_guard]
        set gdir [::guard dir $initial_guard]
        set escape 0
        while {!$escape} {
            lassign [my walk_leg $gp $gdir] endp newgdir nsteps escape
            set points [point enumerate $gp $gdir $nsteps]
            set gdirn [::dir tobits $gdir]
            set npoints [llength $points]
            set i 0
            foreach p $points {
                incr i
                #if {$i == $npoints} { break }
                lassign $p x y
                set wrow [dict getdef $walked $y {}]
                set prevdirs [dict getdef $wrow $x 0]

                if {($prevdirs & $gdirn) != 0} {
                    debug_puts {looped}
                    return [list $walked 1]
                }
                dict set wrow $x [expr {$prevdirs | $gdirn}]
                dict set walked $y $wrow
            }
            set gp $endp
            set gdir $newgdir
        }
        return [list $walked 0]
    }

    method part1 {} {
        lassign [my walked_cells] walked looped
        set n 0
        foreach row [dict values $walked] {
            incr n [dict size $row]
        }
        return $n
    }

    method walked_repr {walked {obsp {}}} {
        ::SGrid create wgrid -lines [grid rows]
        if {$obsp ne {}} {
            wgrid put $obsp O
        }
        try {
            dict for {y row} $walked {
                dict for {x dirbits} $row {
                    set c [boxchars getascii $dirbits]
                    wgrid put [list $x $y] $c
                }
            }
            return [wgrid repr]
        } finally {
            wgrid destroy
        }
    }

    # 1. A loop has occurred if you exit a square in the same direction
    #    twice.
    # 2. Only obstacles added to positions in the original path can
    #    influcence the path.

    method test_obstacle_for_loop {op} {
        set prev [grid get $op]
        if {$prev eq "#"} {
            return 0
        }
        grid put $op "#"
        try {
            lassign [my walked_cells] walked looped
        } finally {
            grid put $op $prev
        }
        debug_puts {[my walked_repr $walked $op]}
        return $looped
    }

    method part2 {} {
        set walked [lindex [my walked_cells] 0]
        set gx [::guard x $initial_guard]
        set gy [::guard y $initial_guard]
        set nloops 0
        foreach {y row} [lsort -integer -stride 2 $walked] {
            puts -nonewline "$y "
            flush stdout
            dict for {x dirs} $row {
                if {$x == $gx && $y == $gy} { continue }
                #puts "$x $y"
                set p [list $x $y]
                if {[my test_obstacle_for_loop $p]} {
                    incr nloops
                }
            }
        }
        puts ""
        return $nloops
    }

}


if {$::argv0 ne [info script]} {
    return
}

set debug_log 0

puts "Part 1"

Problem create prob input.txt

puts "number of grid cells covered: [measure {prob part1}]"

puts ""
puts "Part 2"

puts "number of obstacles that loop: [measure {prob part2}]"
