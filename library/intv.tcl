### intv.tcl
#
# Integer interval manipulations

package provide aoc::intv 0.1

namespace eval intv {
    namespace export {[a-z]*}

    # Take care to use ::lrange, as we define a wrapper

    proc empty {} {return {}}

    proc make {a b} {
        if {$b < $a} {
            return {}
        } else {
            return [list $a $b]
        }
    }
    proc singleton {a} {
        return [list $a $a]
    }

    proc match_empty {iv avar bvar} {
        upvar 1 $avar a $bvar b
        set a [lindex $iv 0]
        if {$a eq {}} { return 1 }
        set b [lindex $iv 1]
        return [expr {$b < $a}]
    }

    proc left {iv} {
        if {[match_empty $iv a b]} {
            return -1000
        }
        return $a
    }
    proc right {iv} {
        if {[match_empty $iv a b]} {
            return -1001
        }
        return $b
    }
    proc normalize {iv} {
        if {[match_empty $iv a b]} {
            return {}
        }
        return $iv
    }

    proc isempty {iv} {
        set a [lindex $iv 0]
        return [expr {$a eq {} || [lindex $iv 1] < $a}]
    }

    proc width {iv} {
        if {[match_empty $iv a b]} { return 0 }
        return [expr {$b - $a}]
    }

    proc translate {iv dx} {
        if {[match_empty $iv a b]} { return {} }
        return [list [expr {$a + $x}] [expr {$b + $x}]]
    }
    proc extend_left {iv dx} {
        if {[match_empty $iv a b]} { return {} }
        return [make [expr {$a - $x}] $b]
    }
    proc extend_right {iv dx} {
        if {[match_empty $iv a b]} { return {} }
        return [make $a [expr {$b + $x}]]
    }

    proc contains {x iv} {
        lassign $iv a b
        return [expr {$a ne {} && $a <= $x && $x < $b}]
    }

    # For finite intervals [a,b] and [c,d], left-adjacent means b+1 == c
    proc left_adjacent {iv1 iv2} {
        if {[match_empty $iv1 a b]} {return 0}
        if {[match_empty $iv2 c d]} {return 0}
        return [expr {$b + 1 == $c}]
    }
    # For finite intervals [a,b] and [c,d], right-adjacent means d+1 == a
    proc right_adjacent {iv1 iv2} {
        if {[match_empty $iv1 a b]} {return 0}
        if {[match_empty $iv2 c d]} {return 0}
        return [expr {$d + 1 == $a}]
    }

    # Either left- or right-adjacent
    proc adjacent {iv1 iv2} {
        if {[match_empty $iv1 a b]} {return 0}
        if {[match_empty $iv2 c d]} {return 0}
        return [expr {$b + 1 == $c || $d + 1 == $a}]
    }

    # The minimum distance between points in iv1 and iv2
    # By convention, we take this to be 0 if one set is empty.
    # The separation of adjacent intervals is 1.
    # The separation of nondisjoint intervals is 0
    # If [a,b] and [c,d] are disjoint, then either b < c or d < a
    proc separation {iv1 iv2} {
        if {[match_empty $iv1 a b]} {return 0}
        if {[match_empty $iv2 c d]} {return 0}
        if {$b < $c} {
            return [expr {$c - $b}]
        } elseif {$d < $a} {
            return [expr {$d - $a}]
        } else {
            return 0
        }
    }


    # forall x, x in iv1 -> x in iv2 -> false
    proc disjoint {iv1 iv2} {
        if {[match_empty $iv1 a b]} {return 1}
        if {[match_empty $iv2 c d]} {return 1}
        return [expr {$b < $c || $d < $a}]
    }

    proc intersect {iv1 iv2} {
        if {[match_empty $iv1 a b]} {return {}}
        if {[match_empty $iv2 c d]} {return {}}
        # max(a,c) ... min(b,d)
        return [make [expr {$a < $c ? $c : $a}] [expr {$b < $d ? $b : $d}]]
    }

    # minimal interval that contains the two intervals
    proc cover {iv1 iv2} {
        if {[match_empty $iv1 a b]} {return $iv2}
        if {[match_empty $iv2 c d]} {return $iv1}
        # min(a,c) ... max(b,d)
        return [make [expr {$a < $c ? $a : $c}] [expr {$b < $d ? $d : $b}]]
    }

    # The interval contained in the cover whose points are in neither
    # iv1 or iv2.  This is nonempty only if iv1 and iv2 are disjoint
    # and nonadjacent.
    proc overcover {iv1 iv2} {
        if {[match_empty $iv1 a b]} {return {}}
        if {[match_empty $iv2 c d]} {return {}}
        if {$b + 1 < $c} {
            return [list [expr {$b + 1}] [expr {$c - 1}]]
        } elseif {$d + 1 < $a} {
            return [list [expr {$d + 1}] [expr {$a - 1}]]
        } else {
            return {}
        }
    }


    # a--b  c++d
    # a--c**b++d
    # a--c**d--b
    # c++d  a--b
    # c++a**d--b
    # c++a**b++d

    # tagged_head_range head1 head2 -> {tag head head1' head2'}
    # Peel the next interval from the union of head1 and head2
    # Eg, for a--c**d--b, we'd get tag=1, head={a c-1}
    # and head1'={c b}, head2'={c,d}
    proc tagged_head_interval {iv1 iv2} {
        if {[match_empty $iv1 a b]} {
            if {[isempty $iv2]} {
                return [list 0 {} {} {}]
            } else {
                return [list 2 $iv2 {} {}]
            }
        }
        if {[match_empty $iv2 c d]} {
            return [list 1 $iv1 {} {}]
        }
        if {$a < $c} {
            if {$b < $c} {
                # a <= b < c <= d   a--b  c++d  -> 1:[a,b] + 2:[c,d]
                return [list 1 $iv1 {} $iv2]
            } else {
                # a < c <= {b,d}  a--c**{b,d} -> 1:[a,c-1] + U(1:[c,b],2:[c,d])
                set iv1left [list $a [expr {$c-1}]]
                set iv1right [list $c $b]
                return [list 1 $iv1left $iv1right $iv2]
            }
        } elseif {$c < $a} {
            if {$d < $a} {
                # c <= d < a <= b   c++d  a--b -> 2:[c,d] + 1:[a,b]
                return [list 2 $iv2 $iv1 {}]
            } else {
                # c < a <= {b,d}  c++a**{b,d} -> 2:[c,a-1] + U(1:[a,b],2:[a,d])
                set iv2left [list $c [expr {$a-1}]]
                set iv2right [list $a $d]
                return [list 2 $iv2left $iv1 $iv2right]
            }
        } else {
            # a == c
            if {$b < $d} {
                # a == c <= b < d   {ac}**b++d -> 3:[a,b] + 2:[b+1,d]
                return [list 3 $iv1 {} [list [expr {$b+1}] $d]]
            } elseif {$d < $b} {
                # a == c <= d < b   {ac}**d--b -> 3:[c,d] + 1:[d+1,b]
                return [list 3 $iv2 [list [expr {$d+1}] $b] {}]
            } else {
                # a == c <= b == d  {ac}**{bd} -> 3:[a,b]
                return [list 3 $iv1 {} {}]
            }
        }
    }
    # U(1:[c,b], 2:[c,d]) ->
    #   b < d: 3:[c,b] + 2:[b+1,d]
    #   d < b: 3:[c,d] + 1:[d+1,b]
    #   b = d: 3:[c,b]

    proc tagged_union {iv1 iv2} {
        set union {}
        while {1} {
            lassign [tagged_head_interval $iv1 $iv2] tag0 head iv1 iv2
            if {$tag0 == 0} {
                break
            }
            lappend union $tag0 $head
        }
        return $union
    }

    # It can be advantageous to split an interval I0 into a displacement d
    # and a 'relative interval' I, so that I0 = translate I d.
    # * E.g., if the numbers in I0 are large, but the width is small,
    #   we could use a large displacement d to the mid of I0, and then
    #   a small interval I that straddles 0.
    # * The extent of a string can be described as a interval, with the
    #   left side at 0.  A substring is then an interval, but could
    #   be considered as a string in its own right, displaced by an
    #   amount d along the original string.

    # Given:
    # * an interval iv1
    # * an interval [translate iv2 d]
    # Return the intersection I, and the translation I' of I by -d
    # (so that I = [translate I' d])
    #
    # Motivation: consider two strings A and B, which we line up with
    # each other by displacing B by an amount d (so position 0 of B
    # lines up with position d of A).  Then consider a substring on
    # each, s and t, which are most naturally expressed as intervals
    # relative to their respective strings. Then, the interval for t,
    # relative to A, is translate t d.  The overlap between the two
    # substrings is the intersection, which can be represented as
    # relative to either A or B.
    proc overlap {iv1 iv2 {d 0}} {
        # Translate iv2' to iv1's reference frame
        set iv2' [translate $iv2 $d]
        set int [intersect $iv1 ${iv2'}]
        # Return int, which is in iv1's reference frame,
        # and a version translated to iv2's reference frame.
        return [list $int [translate $int [expr {-$d}]]]
    }

    proc all {} {return [list -inf inf]}

    proc lessthan {x} {
        return [list -inf [expr $x - 1]]
    }
    proc greaterthan {x} {
        return [list [expr {$x + 1}] inf]
    }
    proc lesseqthan {x} {
        return [list -inf $x]
    }
    proc greatereqthan {x} {
        return [list $x inf]
    }

    proc left_complement {iv} {
        lassign $iv a b
        if {$a eq {} || $b < $a} {return [all]}
        return [lessthan $a]
    }
    proc right_complement {iv} {
        lassign $iv a b
        if {$a eq {} || $b < $a} {return [all]}
        return [greaterthan $b]
    }

    # Lifting of intervals to lists and strings

    proc forlist {list} {
        return [make 0 [llength $list]]
    }

    proc lrange {list iv} {
        set ivl [forlist $list]
        set int [intersect $ivl $iv]
        if {[match_empty $int a b]} {
            return {}
        }
        return [::lrange $list $a $b]
    }

    proc forstring {s} {
        return [make 0 [string length $s]]
    }

    proc srange {str iv} {
        set ivl [forstring $list]
        set int [intersect $ivl $iv]
        if {[match_empty $int a b]} {
            return {}
        }
        return [::string range $list $a $b]
    }

    namespace ensemble create -prefixes 0
}
