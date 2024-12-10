#!/usr/bin/tclsh9.0

puts "Part 1:"

proc issafe {report} {
    set first 1
    set diffsign 0
    foreach x $report {
        if {$first} {
            set first 0
        } else {
            set diff [expr {$x - $lastx}]
            set adiff [expr {abs($diff)}]
            if {$adiff < 1 || $adiff > 3} {
                return 0
            }
            if {$diffsign == 0} {
                set diffsign [expr {$diff < 0 ? -1 : 1}]
            } elseif {$diffsign * $diff < 0} {
                return 0
            }
        }
        set lastx $x
    }
    return 1
}

set reports {}
foreachLine r input.txt { lappend reports $r }

proc count_safe_reports {reports predicate} {
    set nreports 0
    set nsafe 0
    foreach report $reports {
        incr nreports
        if {[{*}$predicate $report]} {
            incr nsafe
        }
    }
    puts "Number of reports is $nreports"
    puts "Number of safe reports is $nsafe"
}

count_safe_reports $reports issafe

puts ""
puts "Part 2:"

proc issafe_with_dampener {report} {
    if {[issafe $report]} {
        return 1
    }
    set len [llength $report]
    for {set i 0} {$i < $len} {incr i} {
        set report2 [lreplace $report $i $i]
        if {[issafe $report2]} {
            return 1
        }
    }
    return 0
}

count_safe_reports $reports issafe_with_dampener
