#!/usr/bin/tclsh9.0

puts "Part 1:"

set list1 {}
set list2 {}
foreachLine line input.txt {
    lassign $line val1 val2
    lappend list1 $val1
    lappend list2 $val2
}
set slist1 [lsort -integer $list1]
set slist2 [lsort -integer $list2]
set sum 0
foreach val1 $slist1 val2 $slist2 {
    set sum [expr {$sum + abs($val1 - $val2)}]
}
puts "Total distance between lists is $sum"
puts ""

puts "Part 2:"

proc count_occurences {list} {
    set result {}
    foreach x $list {
        dict incr result $x
    }
    return $result
}

set occ2 [count_occurences $list2]

# naive:
# set simscore 0
# foreach x $list1 {
#     if {[dict exists $occ2 $x]} {
#         set simscore [expr {$simscore + $x * [dict get $occ2 $x]}]
#     }
# }

# this means if we have n instances of $x in list 1, and m instances
# of $x in list2, then the amount of sim score due to x is $x * $n * $m.
#

set occ1 [count_occurences $list1]

set simscore 0
dict for {x n} $occ1 {
    incr simscore [expr {$x * $n * [dict getdef $occ2 $x 0]}]
}
puts "Similiarity score = $simscore"
