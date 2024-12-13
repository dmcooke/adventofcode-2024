#!/usr/bin/tclsh9.0

package require aoc::tools
package require aoc::boxchars

package require struct::disjointset 1.2

namespace import ::tcl::mathop::*

proc read_input {input_file} {
    set data [readFile $input_file]
    # Check it's rectangular
    lassign [list_extrema $data ::string length] minwidth maxwidth
    if {$minwidth != $maxwidth} {
        error "Map isn't rectangular"
    }
    return $data
}
#
#  A A A
#  A A B
#
# * Area of a region is just how many cells of that type make up
#   a _connected_ region.
# * Perimeter: the perimeter associated with a cell is the number of
#   (von Neuman) neighbours which don't belong to the region.  Since
#   connectedness is done the same way, this means the number of
#   neighbours which are a different type of plant (letter).
# * fence price is \sum(R in regions, area(R) * perimeter(R))
# * we can have more than one region with the same type of plant,
#   so we can't just accumulate by plant.

::oo::class create GardenMap {
    variable width height xmax ymax
    variable plants boundaries regions
    variable region_counter outer_region regionids

    # We offset all coordinates by 1, so the origin (upper-left) is
    # (1,1), and the map runs to (width, height).  Additionally, we
    # add padding rows and columns so that +/- 1 on the coordinate is
    # valid.

    constructor {mapdata} {
        set outer_region 0
        set region_counter 1
        ::struct::disjointset regionPartition
        regionPartition add-element $outer_region
        my Create_map $mapdata
        my markup_boundaries
    }

    method New_region {} {
        set reg $region_counter
        incr region_counter
        regionPartition add-element $reg
        return $reg
    }

    method Extended_row {left middle right} {
        return [list $left {*}[lrepeat $width $middle] $right]
    }

    method Create_map {mapdata} {
        set width [list_max $mapdata ::string length]
        set height [llength $mapdata]
        set xmax [+ 1 $width]
        set ymax [+ 1 $height]
        array set plants {}
        array set boundaries {}
        array set regions {}
        set initboundaries [my Extended_row [boxchars encode >] -1 \
                                [boxchars encode <]]
        # Outer boundary will be its own region
        set initregions [my Extended_row $outer_region -1 $outer_region]
        set y 0
        foreach line $mapdata {
            incr y
            set plants($y) " $line "
            set boundaries($y) $initboundaries
            set regions($y) $initregions
        }
        set plants(0) [string repeat " " [+ $width 2]]
        set plants($ymax) $plants(0)
        set boundaries(0) [my Extended_row 0 [boxchars encode v] 0]
        set boundaries($ymax) [my Extended_row 0 [boxchars encode ^] 0]
        set regions(0) [my Extended_row $outer_region $outer_region \
                            $outer_region]
        set regions($ymax) $regions(0)
    }

    method get_plant {x y} {
        return [string index $plants($y) $x]
    }
    method get_boundary {x y} {
        return [lindex $boundaries($y) $x]
    }
    method get_regionid {x y} {
        return [lindex $regions($y) $x]
    }
    method set_boundary {x y b} {
        lset boundaries($y) $x $b
    }

    method Set_extent_region {x0 x1 y region} {
        if {$x0 > $x1} { return }
        if {$region == -1} {
            set region [my New_region]
        }
        for {set x $x0} {$x <= $x1} {incr x} {
            lset regions($y) $x $region
        }
    }

    method width {} {return $width}
    method height {} {return $height}

    method boundaries {} {
        set result {}
        for {set y 0} {$y <= $ymax} {incr y} {
            lappend result $boundaries($y)
        }
        return $result
    }

    method regions {} {
        set result {}
        for {set y 0} {$y <= $ymax} {incr y} {
            lappend result $regions($y)
        }
        return $result
    }

    method regionids {{all 0}} {
        if {$all} {
            return [list $outer_region {*}$regionids]
        } else {
            return $regionids
        }
    }

    method markup_boundaries {} {
        namespace upvar ::boxchars up upmask down downmask \
            left leftmask right rightmask
        for {set y 1} {$y <= $height} {incr y} {
            set extent_start 1
            set extent_region -1
            set left " "

            for {set x 1} {$x <= $width} {incr x} {
                set boundary 0
                set letter [my get_plant $x $y]

                if {$left ne $letter} {
                    set boundary [expr {$boundary | $leftmask}]
                    my Set_extent_region $extent_start [- $x 1] $y \
                        $extent_region
                    set extent_region -1
                    set extent_start $x
                }

                set up [my get_plant $x [- $y 1]]
                set upreg [my get_regionid $x [- $y 1]]
                if {$up ne $letter} {
                    set boundary [expr {$boundary | $upmask}]
                } elseif {$upreg != $extent_region} {
                    if {$extent_region != -1} {
                        # We already assigned this extent a region
                        # based on the row above.  This likely means
                        # we have something like
                        #     AAAA     AAAAA
                        #      AAAAAAAAAAA
                        # (This is the whole reason we're using a
                        # a disjoint set data structure)
                        regionPartition merge $upreg $extent_region
                    } else {
                        set extent_region $upreg
                    }
                }

                # For down and right we just do the boundary

                set dn [my get_plant $x [+ $y 1]]
                if {$dn ne $letter} {
                    set boundary [expr {$boundary | $downmask}]
                } else {
                }
                set rt [my get_plant [+ $x 1] $y]
                if {$rt ne $letter} {
                    set boundary [expr {$boundary | $rightmask}]
                }
                lset boundaries($y) $x $boundary

                set left $letter
            }
            my Set_extent_region $extent_start $width $y $extent_region
        }
        my Assign_exemplars
    }

    # Replaces the region ids with a renumbering based on the exemplars.
    method Assign_exemplars {} {
        set exemplars [lsort -integer [regionPartition exemplars]]
        #puts "exemplars: $exemplars"
        #puts "partitions: [regionPartition num-partitions]"
        set oute [regionPartition find-exemplar $outer_region]
        set exmap {}
        set regionids {}
        set i 0
        foreach e $exemplars {
            if {$e == $oute} {
                dict set exmap $oute 0
            } else {
                incr i
                dict set exmap $e $i
                lappend regionids $i
            }
        }
        for {set y 1} {$y <= $height} {incr y} {
            set regions($y) [lmap r $regions($y) {
                set e [regionPartition find-exemplar $r]
                ::id [dict get $exmap $e]
            }]
        }
    }

    method make_perimeter_count_map {} {
        # map of boundary bitfield to perimeter count.  This is basically
        # just popcount
        set perimap {}
        #                           rldu
        lappend perimap 0;      # 0b0000
        lappend perimap 1;      # 0b0001
        lappend perimap 1;      # 0b0010
        lappend perimap 2;      # 0b0011
        lappend perimap 1;      # 0b0100
        lappend perimap 2;      # 0b0101
        lappend perimap 2;      # 0b0110
        lappend perimap 3;      # 0b0111
        lappend perimap 1;      # 0b1000
        lappend perimap 2;      # 0b1001
        lappend perimap 2;      # 0b1010
        lappend perimap 3;      # 0b1011
        lappend perimap 2;      # 0b1100
        lappend perimap 3;      # 0b1101
        lappend perimap 3;      # 0b1110
        lappend perimap 4;      # 0b1111
        return $perimap
    }

    method areas {} {
        set areas {}
        for {set y 1} {$y <= $height} {incr y} {
            set regionrow $regions($y)
            for {set x 1} {$x <= $width} {incr x} {
                set region [lindex $regionrow $x]
                dict incr areas $region
            }
        }
        dict unset areas $outer_region
        return $areas
    }
    method perimeters {} {
        set perimeters {}
        set perimap [my make_perimeter_count_map]
        for {set y 1} {$y <= $height} {incr y} {
            set boundrow $boundaries($y)
            set regionrow $regions($y)
            for {set x 1} {$x <= $width} {incr x} {
                set boundary [lindex $boundrow $x]
                set region [lindex $regionrow $x]
                dict incr perimeters $region [lindex $perimap $boundary]
            }
        }
        dict unset perimeters $outer_region
        return $perimeters
    }

    method fence_price {} {
        set areas [my areas]
        set perimeters [my perimeters]
        set price 0
        dict for {reg area} $areas {
            set perim [dict get $perimeters $reg]
            incr price [expr {$area * $perim}]
        }
        return $price
    }

    method print_fences {} {
        # Fences are between cells, which makes this a bit trickier.
        # The cells are related to corner (x,y) as in this diagram:
        #           (x,y)  |  (x+1,y)
        #          ------(x,y)-------
        #          (x,y+1) |  (x+1,y+1)
        # x goes from 0 to width+1, and y from 0 to height+1
        namespace upvar ::boxchars up upmask down downmask \
            left leftmask right rightmask
        set ywidth [string length $ymax]
        for {set y 0} {$y < $ymax} {incr y} {
            if {$y % 10 == 0 || $y == $height} {
                set line [format {%-*d } $ywidth $y]
            } else {
                set line [format {%*s } $ywidth ""]
            }
            for {set x 0} {$x < $xmax} {incr x} {
                lassign [my gridpoint_regions $x $y] ul ur dl dr
                set b [my gridpoint_fence $ul $ur $dl $dr]
                if {$b == 0} {
                    set c [string index " ░▒▓█" [expr {(37 * $ul) % 5}]]
                } else {
                    set c [boxchars get $b]
                }
                append line $c
            }
            puts $line
        }
    }

    method gridpoint_regions {x y} {
        set x1 [+ 1 $x]
        set y1 [+ 1 $y]
        set ul [my get_regionid $x $y]
        set ur [my get_regionid $x1 $y]
        set dl [my get_regionid $x $y1]
        set dr [my get_regionid $x1 $y1]
        return [list $ul $ur $dl $dr]
    }

    method gridpoint_fence {ul ur dl dr} {
        set b 0
        if {$ul != $ur} {
            set b [expr {$b | 0x1}]
        }
        if {$dl != $dr} {
            set b [expr {$b | 0x2}]
        }
        if {$ul != $dl} {
            set b [expr {$b | 0x4}]
        }
        if {$ur != $dr} {
            set b [expr {$b | 0x8}]
        }
        return $b
    }

    # Now, instead of perimeter, we want number of straight runs
    # of fence.
    #
    # We need to take care that the fences between A and B here
    # count separately as four fences, not as two long fences:
    #
    #     AAA|BBB
    #     AAA|BBB
    #     ---+---
    #     BBB|AAA
    #     BBB|AAA
    #
    # The above probably isn't a problem; as it stands, those are four
    # different regions.  However,  if we connect the A regions,
    #
    #   +-------+-----+
    #   |A A A A|B B B|
    #   |       |     |
    #   |A A A A|B B B|
    #   |A+-----+-----+
    #   |A|B B B|A A A|
    #   | |     |     |
    #   |A|B B B|A A A|
    #   | +-----+     |
    #   |A A A A A A A|
    #   +-------------+
    #
    # then the fences should still count separately.
    #
    # Another:
    #
    #  +---------+-+
    #  |A A A A A|D|
    #  +-----+---+-+
    #  |B B B|C C C|
    #  +-----+-----+
    #
    # Here, each region has 4 sides.
    #
    # We'll use the labelling of grid lines that we use in print_fences.
    #
    # What we do know: every side starts at a grid point, runs vertically
    # or horizontally, then stops at a grid point.  So each side has
    # a point where its fence starts and goes down, or goes right.  This
    # is 1:1, so we just need to count those.
    #
    # Label the grid point regions as such:
    # A|B
    # -+-
    # C|D
    #
    # Then:
    # * " " has no fences
    # * ╴,╶, ╵, ╷ aren't possible.
    # * ─ and │ don't count for any region
    # * ┌ would have A=B=C.  It starts two sides for both regions
    # * ┐ and └ have similiar assignments, but only start one side
    #   for each region
    # * ┘ starts no sides for either region.
    # * ├ would have A=C. It starts two sides for D, and one for B,
    #   but none for A=C.
    # * ┬ is similiar; two for D, 1 for C, and none for A=B
    # *  ┤ starts one for C, but none for the others
    # * ┴ starts one for B, but none for the others
    # * ┼ starts two for D, one for B, one for C, and zero for A
    #
    # * No sides are started for A, unless it's equal to one of B or C.
    # * D gets two if it isn't equal to either B or C,

    #                                                 boundary bits rldu
    #       rldu    A B C D                           A    B    C    D
    #                                                  .   .   .       .
    # " "   0000    0 0 0 0   no fences              0x0x x00x 0xx0 x0x0
    #  ╵    0001    0 0 0 0   not possible
    #  ╷    0010    0 0 0 0   not possible
    #  │    0011    0 0 0 0   A=C, B=D; vertical     1x0x x10x 1xx0 x1x0
    # ─╴    0100    0 0 0 0   not possible
    # ─┘    0101    0 0 0 0   B=C=D                  1x1x x10x 0xx1 x0x0
    # ─┐    0110    0 0 1 1   A=B=D                  0x1x x00x 1xx1 x1x0
    # ─┤    0111    0 0 1 0   B=D                    1x1x x10x 1xx1 x1x0
    #  ╶─   1000    0 0 0 0   not possible
    #  └─   1001    0 1 0 1   A=C=D                  1x0x x11x 0xx0 x0x1
    #  ┌─   1010    0 1 1 2   A=B=C                  0x0x x01x 1xx0 x1x1
    #  ├─   1011    0 1 0 2   A=C                    1x0x x11x 1xx0 x1x1
    # ───   1100    0 0 0 0   A=B, C=D; horizontal   0x1x x01x 0xx1 x0x1
    # ─┴─   1101    0 1 0 0   C=D                    1x1x x11x 0xx1 x0x1
    # ─┬─   1110    0 0 1 2   A=B                    0x1x x01x 1xx1 x1x1
    # ─┼─   1111    0 1 1 2                          1x1x x11x 1xx1 x1x1
    #              \-------/ assignments compatible with comments above
    # ^I added ─ to the horizontals to make it clearer
    #
    # Boundary bits: A(d)=C(u), C(r)=D(l), D(u)=B(d), B(l)=A(r)
    #                  B(d)C(u)D(l)A(r)
    #        A B C D   D(u)A(d)C(r)B(l)  C(r)B(l)B(d)C(u)
    #  0000  0 0 0 0    0   0   0   0     0   0   0   0      0
    #  0011  0 0 0 0    0   0   1   1     1   1   0   0     12
    #  0101  0 0 0 0    0   1   0   1     0   1   0   1      5
    #  0110  0 0 1 1    0   1   1   0     1   0   0   1      9
    #  0111  0 0 1 0    0   1   1   1     1   1   0   1     13
    #  1001  0 1 0 1    1   0   0   1     0   1   1   0      6
    #  1010  0 1 1 2    1   0   1   0     1   0   1   0     10
    #  1011  0 1 0 2    1   0   1   1     1   1   1   0     14
    #  1100  0 0 0 0    1   1   0   0     0   0   1   1      3
    #  1101  0 1 0 0    1   1   0   1     0   1   1   1      7
    #  1110  0 0 1 2    1   1   1   0     1   0   1   1     11
    #  1111  0 1 1 2    1   1   1   1     1   1   1   1     15
    #                  B(d)C(u)C(r)B(l)
    # C(r)B(l)B(d)(Cu) = (c & 0b1001) | (b & 0b0110)


    method sides {} {
        set add_b [lrepeat 16 0]
        foreach i {6 7 10 14 15} {lset add_b $i 1}
        set add_c [lrepeat 16 0]
        foreach i {9 10 11 13 15} {lset add_c $i 1}
        set add_d [lrepeat 16 0]
        foreach {i n} {6 1  9 1  10 2  11 2  14 2  15 2} {lset add_d $i $n}

        set sides {}
        for {set y 0} {$y < $ymax} {incr y} {
            for {set x 0} {$x < $xmax} {incr x} {
                set x1 [+ 1 $x]
                set y1 [+ 1 $y]
                set bound_b [my get_boundary $x1 $y]
                set bound_c [my get_boundary $x $y1]
                set i [expr {($bound_b & 0b0110) | ($bound_c & 0b1001)}]
                set regb [my get_regionid $x1 $y]
                set regc [my get_regionid $x $y1]
                set regd [my get_regionid $x1 $y1]
                dict incr sides $regb [lindex $add_b $i]
                dict incr sides $regc [lindex $add_c $i]
                dict incr sides $regd [lindex $add_d $i]
            }
        }
        dict unset sides $outer_region
        return $sides
    }

    method straight_fence_price {} {
        set areas [my areas]
        set sides [my sides]
        set price 0
        dict for {reg area} $areas {
            set nsides [dict get $sides $reg]
            incr price [expr {$area * $nsides}]
        }
        return $price
    }
}

proc fence_price {map {discount 0}} {
    set m [GardenMap new $map]
    if {$discount} {
        set price [$m straight_fence_price]
    } else {
        set price [$m fence_price]
    }
    $m destroy
    return $price
}



namespace eval main {
    variable test_cases {}
}

proc ::main::add_test_case {name part1 part2 map} {
    variable test_cases
    dict set test_cases $name [list $map $part1 $part2]
}

::main::add_test_case example1 140 80 {
    AAAA
    BBCD
    BBCC
    EEEC
}
::main::add_test_case example2 772 436 {
    OOOOO
    OXOXO
    OOOOO
    OXOXO
    OOOOO
}
::main::add_test_case example3 1930 1206 {
    RRRRIICCFF
    RRRRIICCCF
    VVRRRCCFFF
    VVRCCCJFFF
    VVVVCJJCFE
    VVIVCCJJEE
    VVIIICJJEE
    MIIIIIJJEE
    MIIISIJEEE
    MMMISSJEEE
}

::main::add_test_case example4 - 236 {
    EEEEE
    EXXXX
    EEEEE
    EXXXX
    EEEEE
}
::main::add_test_case example5 - 368 {
    AAAAAA
    AAABBA
    AAABBA
    ABBAAA
    ABBAAA
    AAAAAA
}

::main::add_test_case test1 - - {
    AAAAA
    BBCDC
    BBCCC
    EEECE
}

proc ::main::run_test_cases {part test_cases} {
    switch $part {
        part1 {
            set discount 0
            set expidx 1
        }
        part2 {
            set discount 1
            set expidx 2
        }
        default { error "try combing the other way (bad part)" }
    }
    dict for {name case} $test_cases {
        set garden_map [lindex $case 0]
        set price [lindex $case $expidx]
        if {$price eq "-"} { continue }
        set actual_price [fence_price $garden_map $discount]
        if {$price != $actual_price} {
            puts "$part test \"$name\" failed: expected price $price,\
                  but calculated $actual_price"
        }
    }
}

proc puts_gridded_data {data} {
    array set colwidths {}
    foreach row $data {
        set i -1
        foreach val $row {
            incr i
            set w [string length $val]
            if {![info exists colwidths($i)] || $colwidths($i) < $w} {
                set colwidths($i) $w
            }
        }
    }
    set ynumwidth [string length [- [llength $data] 1]]
    set y -1
    foreach row $data {
        incr y
        set line [format {%-*d :} $ynumwidth $y]
        set i -1
        foreach val $row {
            incr i
            append line [format { %*s} $colwidths($i) $val]
        }
        puts $line
    }
}

proc main::main {} {
    variable test_cases
    record start
    run_test_cases part1 $test_cases
    record mark part1_tests
    run_test_cases part2 $test_cases
    record mark part2_tests

    set input_file [lindex $::argv 0]
    if {$input_file ne ""} {
        try {
            set garden_map [read_input $input_file]
        } trap {POSIX ENOENT} {} {
            set garden_map [lindex [dict get $test_cases $input_file] 0]
        }

        record mark load

        GardenMap create map $garden_map
        map print_fences

        if {[map width] < 25} {
            puts "boundaries"
            puts_gridded_data [map boundaries]
            puts "regions"
            puts_gridded_data [map regions]

            set measures {}
            foreach m {areas perimeters sides} {
                set meas [map $m]
                lappend measures [list $m {*}[lmap r [map regionids] {
                    dict get $meas $r
                }]]
            }
            puts_gridded_data $measures
        }
        record mark findregions

        puts "Part 1"
        puts "Fence price = [map fence_price]"
        record mark part1

        puts "Part 2"
        puts "New fence price = [map straight_fence_price]"
        record mark part2

        record report
    }
}

::main::main
