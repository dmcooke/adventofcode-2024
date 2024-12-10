
package require aoc::intv
package provide aoc::geom 0.1

# points and vectors are compatible

namespace eval ::geom {
    namespace export {[a-z]*}
}

::oo::class create ::geom::BasePoint {
    method make {x y} {return [list $x $y]}
    method zero {} {return {0 0}}

    method Proj0 {p} {return [lindex $p 0]}
    method Proj1 {p} {return [lindex $p 1]}

    method Replace0 {p x} {return [list $x [lindex $p 1]]}
    method Replace1 {p y} {return [list [lindex $p 0] $y]}

    method equal {p1 p2} {
        return [expr {[lindex $p1 0] == [lindex $p2 0]
                      && [lindex $p1 1] == [lindex $p2 1]}]
    }
    method iszero {p} {
        return [expr {[lindex $p 0] == 0 && [lindex $p 1] == 0}]
    }

    method Neg {p} {
        return [list [expr {-[lindex $p 0]}] [expr {-[lindex $p 1]}]]
    }

    method Scale {p scale} {
        return [list [expr {$scale*[lindex $p 0]}] \
                    [expr {$scale*[lindex $p 1]}]]
    }

    method Invscale {p scale} {
        return [list [expr {[lindex $p 0] / $scale}] \
                    [expr {[lindex $p 1] / $scale}]]
    }
    method Invscalef {p scale} {
        set scale [expr {double($scale)}]
        return [list [expr {[lindex $p 0] / $scale}] \
                    [expr {[lindex $p 1] / $scale}]]
    }

    method Scalefrac {p numer denom} {
        return [list [expr {(numer * [lindex $p 0]) / $denom}] \
                    [expr {(numer * [lindex $p 1]) / $denom}]]
    }

    method Add {p1 p2} {
        lassign $p1 x1 y1
        lassign $p2 x2 y2
        return [list [expr {$x1 + $x2}] [expr {$y1 + $y2}]]
    }

    method Sub {p1 p2} {
        lassign $p1 x1 y1
        lassign $p2 x2 y2
        return [list [expr {$x1 - $x2}] [expr {$y1 - $y2}]]
    }

    # Square of the Euclidean norm
    method L2norm2 {v} {
        lassign $v dx dy
        return [expr {$dx*$dx + $dy*$dy}]
    }

    # L₁ norm (Manhattan metric)
    method L1norm {v} {
        lassign $v dx dy
        return [expr {abs($dx) + abs($dy)}]
    }

    method Dot {v1 v2} {
        lassign $v1 dx1 dy1
        lassign $v2 dx2 dy2
        return [expr {$dx1 * $dx2 + $dy1 * $dy2}]
    }

    method Project {p dp n} {
        if {$n == 0} {
            return [list $p]
        }
        lassign $p x y
        lassign $dp dx dy
        if {$n < 0} {
            set n [expr {-$n}]
            set dx [expr {-$dx}]
            set dy [expr {-$dy}]
        }
        set result [list $p]
        for {set i 1} {$i < $n} {incr i} {
            lappend result [list [expr {$x + $i*$dx}] [expr {$y + $i*$dy}]]
        }
        return $result
    }
}

::oo::class create ::geom::Point {
    superclass -append ::geom::BasePoint

    forward x  my Proj0
    forward y  my Proj1

    forward with_x  my Replace0
    forward with_y  my Replace1

    # translate p v
    forward translate    my Add
    # untranslate p v = translate p [vec neg v]
    forward untranslate  my Sub

    # diff p1 p2 -> vector
    forward diff  my Sub
}

::oo::class create ::geom::Vector {
    superclass -append ::geom::BasePoint

    forward dx  my Proj0
    forward dy  my Proj1

    forward with_dx  my Replace0
    forward with_dy  my Replace1

    # Square of the Euclidean norm
    forward l2norm2  my L2norm2

    # L₁ norm (Manhattan metric)
    forward l1norm  my L1norm

    forward neg    my Neg
    forward scale  my Scale
    forward add    my Add
    forward sub    my Sub

    forward dot    my Dot
}

::geom::Point create ::geom::point
::geom::Vector create ::geom::vec

# Given an arithmetic sequence a+i*d, find an interval [s,t]
# such that for i in [s,t], 0 <= a+i*d < h (or return {} if none)
proc ::geom::arith_seq_into_interval0 {a d h} {
    if {$d == 0} {
        if {0 <= $a < $h} {
            return [list 0 0]
        } else {
            return {}
        }
    } elseif {$d < 0} {
        # 0 <= a + i * d < h -> 0 <= a + (-i) * (-d) < h
        set negate 1
        set d [expr {-$d}]
    } else {
        set negate 0
    }
    # 0 <= a + i * d < h  where d > 0
    # -a/d <= i < (h-a)/d
    #  s-1 < -a/d  <= s   -> s = ceil(-a/d)
    #  t < (h-a)/d <= t+1 -> t = ceil((h-a)/d)-1
    # Integer division in Tcl is floored: for d>0, a/d = floor(a/double(d))
    # For m>0, ceil(n/m) = floor((n+m-1)/m) = floor((n-1)/m)+1
    # ceil(-x) = -floor(x)
    # so s=ceil(-a/d) = -floor(a/d)
    set s [expr {-($a / $d)}]
    # t = ceil((h-a)/d)-1 = floor((h-a-1)/d)
    set t [expr {($h - $a - 1)/$d}]
    if {$t < $s} {
        return {}
    } elseif {$negate} {
        return [list [expr {-$t}] [expr {-$s}]]
    } else {
        return [list $s $t]
    }
}

::oo::class create ::geom::Rectangle00 {
    method make {w h} {return [list $w $h]}

    method width {r} {return [lindex $r 0]}
    method height {r} {return [lindex $r 1]}

    method xmin {r} {return 0}
    method xmax {r} {return [expr {[lindex $r 0] - 1}]}

    method ymin {r} {return 0}
    method ymax {r} {return [expr {[lindex $r 1] - 1}]}

    method contains {rect p} {
        lassign $p x y
        lassign $rect w h
        return [expr {0 <= $x && $x < $w && 0 <= $y && $y < $h}]
    }

    # Given a line segment described by a point p0 and a displacement dp,
    # return the range I of i s.t. {i in I | p + i*dp in rect}
    # I will be an iterval: either {} if no values exist, or the closed
    # interval [a b] as a list {a b}.
    method delta_intersection_range {rect p0 dp} {
        if {[::geom::vec iszero $dp]} {
            if {[my contains $rect $p]} {
                return {0 0}
            } else {
                return {}
            }
        }
        lassign $rect w h
        lassign $p0 x0 y0
        lassign $dp dx dy
        set xI [::geom::arith_seq_into_interval0 $x0 $dx $w]
        if {$xI eq {}} {
            return {}
        }
        set yI [::geom::arith_seq_into_interval0 $y0 $dy $h]
        if {$yI eq {}} {
            return {}
        }
        # i in [xs,xt] -> x0 + i*dx in [0, w-1]
        # i in [ys,yt] -> y0 + i*dy in [0, h-1]
        # We need both of these to be true
        return [intv intersect $xI $yI]
    }

}

::geom::Rectangle00 create ::geom::rect00

::oo::class create ::geom::StringGrid {
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
            if {[info exists options(-fill)]} {
                set c $options(-fill)
                if {[string length $c] != 1} {
                    error "-fill arg should be a string of length 1"
                }
            } else {
                set c " "
            }
            set row [string repeat $c $width]
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

    method isvalid_x {x} {
        return [expr {0 <= $x && $x < $width}]
    }
    method isvalid_y {x} {
        return [expr {0 <= $y && $y < $height}]
    }

    method isvalid_xy {x y} {
        return [expr {0 <= $x && $x < $width && 0 <= $y && $y < $height}]
    }
    method isvalid_p {p} {
        lassign $p x y
        return [expr {0 <= $x && $x < $width && 0 <= $y && $y < $height}]
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

    method Unchecked_get {x y} {
        return [string index [lindex $rows $y] $x]
    }

    method get {p} {
        my Check_point $p x y
        set row [lindex $rows $y]
        return [string index $row $x]
    }

    method get_xy {x y} {
        my Check_xy $x $y
        set row [lindex $rows $y]
        return [string index $row $x]
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

    method Search_d0d0 {x y sym} {
        if {![my isvalid_xy $x $y]} {
            return {}
        }
        set c [my Unchecked_get $x $y]
        if {$c eq $sym} {
            return [list $x $y]
        } else {
            return {}
        }
    }

    method General_search {x y dx dy sym} {
        if {$dx == 0 && $dy == 0} {
            tailcall my Search_d0d0 $x $y $sym
        }
        while {0 <= $x && 0 <= $y && $x < $width && $y < $height} {
            set c [string index [lindex $rows $y] $x]
            if {$c eq $sym} {
                return [list $x $y]
            }
            set x [expr {$x + $dx}]
            set y [expr {$y + $dy}]
        }
        return {}
    }

    # search_in_direction p0 dp sym
    # check positions p=p0 + n*dp for n=0... until either we find
    # n s.t. [get p] eq $sym, or p is not in the grid.
    method search_in_direction {p dp sym} {
        my Check_point $p x y
        my Check_point $dp dx dy
        # we have efficient searches for < and >
        if {$dy == 0} {
            if {$dx == 0} {
                tailcall my Search_d0d0 $x $y $sym
            } elseif {$dx == 1} {
                set row [lindex $rows $y]
                set i [string first $sym $row $x]
                if {$i == -1} {
                    return {}
                }
                return [list $i $y]
            } elseif {$dx == -1} {
                set row [lindex $rows $y]
                set i [string last $sym $row $x]
                if {$i == -1} {
                    return {}
                }
                return [list $i $y]
            }
        }
        tailcall my General_search $x $y $dx $dy $sym
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
