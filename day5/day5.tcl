#!/usr/bin/tclsh9.0

proc read_input {inputfile ordervar rordervar} {
    upvar 1 $ordervar order $rordervar rorder
    array set order {}
    array set rorder {}
    set ch [open $inputfile r]
    while {[chan gets $ch line] > 0} {
        if {![regexp {^([[:digit:]]+)[|]([[:digit:]]+)} $line m p1 p2]} {
            error "Not an ordering line: [list $line]"
        }
        lappend order($p1) $p2
        lappend rorder($p2) $p1
    }
    set update_pages {}
    while {[chan gets $ch line] > 0} {
        lappend update_pages [split $line ","]
    }
    chan close $ch
    return $update_pages
}

set update_pages [read_input input.txt ordering rordering]

proc mid_update_page {pages} {
    set n [llength $pages]
    if {$n % 2 == 0} {
        error "Unexpected even-length page update [list $pages]"
    }
    set m [expr {($n - 1)/2}]
    return [lindex $pages $m]
}

# Verify all the update page lists are of odd length
foreach pages $update_pages {
    mid_update_page $pages
}

proc total_mid_pageno {correctly_ordered} {
    set total 0
    foreach pages $correctly_ordered {
        incr total [mid_update_page $pages]
    }
    return $total
}

proc is_correctly_ordered {pages} {
    global ordering rordering
    set npages [llength $pages]
    for {set i 0} {$i < $npages-1} {incr i} {
        set p [lindex $pages $i]
        if {![info exists rordering($p)]} {
            continue
        }
        set p_bad_order $rordering($p)
        for {set j [expr {$i+1}]} {$j < $npages} {incr j} {
            set q [lindex $pages $j]
            if {$q in $p_bad_order} {
                return 0
            }
        }
    }
    return 1
}

set correctly_ordered {}
set incorrectly_ordered {}
foreach pages $update_pages {
    if {[is_correctly_ordered $pages]} {
        lappend correctly_ordered $pages
    } else {
        lappend incorrectly_ordered $pages
    }
}


puts "Part 1"
puts "Total of the middle page number of the correctly-ordered updates"
puts "is [total_mid_pageno $correctly_ordered]"


proc compare_pages {p1 p2} {
    global ordering
    if {[info exists ordering($p1)] && $p2 in $ordering($p1)} {
        # p1 comes before p2
        return -1
    }
    if {[info exists ordering($p2)] && $p1 in $ordering($p2)} {
        # p1 comes after p2
        return 1
    }
    # Otherwise, no order defined.  Fallback to numerical.
    if {$p1 < $p2} {
        return -1
    } elseif {$p2 < $p1} {
        return 1
    } else {
        return 0
    }
}

# this ... should not have worked.  Turns out the subgraph of the
# ordering relation for each list is transitive or something.
# (There is no global order -- there are cycles.)

proc reorder_pages {pages} {
    set order [lsort -command compare_pages $pages]
    return $order
}

set reordered_incorrect [lmap pages $incorrectly_ordered {
    set order [reorder_pages $pages]
    if {![is_correctly_ordered $order]} {
        error "Incorrectly reordered: $pages"
    }
    set order
}]

puts ""
puts "Part 2"
puts "After reordering the incorrectly ordered pages, the sum of the middle"
puts "page numbers for these is [total_mid_pageno $reordered_incorrect]"
