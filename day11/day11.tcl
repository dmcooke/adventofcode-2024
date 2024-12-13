#!/usr/bin/tclsh9.0

package require aoc::tools

namespace import ::tcl::mathop::*

proc read_input {input_file} {
    return [readFile $input_file]
}

array set blink_cache {0 1}

proc clear_blink_cache {} {
    global blink_cache
    array unset blink_cache *
}

proc calc_stone_blink {stone} {
    if {$stone == 0} {
        return [list 1]
    } elseif {[set n [string length $stone]] % 2 == 0} {
        set n2 [expr {$n / 2}]
        set left [string range $stone 0 [expr {$n2 - 1}]]
        set right [string range $stone $n2 end]
        set right [expr {int([string cat 0d $right])}]
        return [list $left $right]
    } else {
        return [list [expr {$stone * 2024}]]
    }
}

proc memo_stone_blink {stone} {
    global blink_cache
    if {[info exists blink_cache($stone)]} {
        return $blink_cache($stone)
    } else {
        return [set blink_cache($stone) [calc_stone_blink $stone]]
    }
}


proc blink {stones} {
    set result {}
    foreach stone $stones {
        lappend result {*}[stone_blink $stone]
    }
    return $result
}

proc count_frequency {stones} {
    set bystone {}
    foreach stone $stones {
        dict incr bystone $stone
    }
    return $bystone
}


proc slow_repeated_blinks {stones nblinks} {
    for {set i 1} {$i <= $nblinks} {incr i} {
        set stones [blink $stones]
    }
    return $stones
}


# Observations
# * the sequence starts to get _very_ long.  However, the number of distinct
#   values is relatively very small (< 1000 at 25 blinks), and grows
#   slowly.
# * What one stone does does not affect what another stone does.  So
#   we could compute each stone in turn.  In fact, we can just store
#   the stone's multiplicity.


proc part1 {stones {nblinks 25}} {
    set stones [slow_repeated_blinks $stones $nblinks]
    return [llength $stones]
}

array set blink_cache {0 1}

proc multiset_blink {stones} {
    variable blink_cache
    set result {}
    dict for {stone mult} $stones {
        lassign [stone_blink $stone] stone1 stone2
        dict incr result $stone1 $mult
        if {$stone2 ne {}} {
            dict incr result $stone2 $mult
        }
    }
    return $result
}

proc stones_to_multiset {stones} {
    set ms_stones {}
    foreach stone $stones {
        dict incr ms_stones $stone
    }
    return $ms_stones
}

proc total_multiset_stones {ms_stones} {
    set total 0
    dict for {_ nstones} $ms_stones {
        incr total $nstones
    }
    return $total
}

proc fast_repeated_blinks {stones nblinks} {
    set ms_stones [stones_to_multiset $stones]
    for {set i 1} {$i <= $nblinks} {incr i} {
        set ms_stones [multiset_blink $ms_stones]
    }
    return $ms_stones
}

proc part2 {stones {nblinks 75}} {
    set ms_stones [fast_repeated_blinks $stones $nblinks]
    puts "Number of distinct stones: [dict size $ms_stones]"
    return [total_multiset_stones $ms_stones]
}

set input_file [lindex $argv 0]
if {$input_file eq ""} {
    set input_file example.txt
}

puts "Part 1"

record start

set input_stones [read_input $input_file]
record mark load

puts "Number of stones after 6 blinks is [part1 $input_stones 6]"
puts "Number of stones after 25 blinks is [measure {part1 $input_stones 25}]"
record mark part1

clear_blink_cache

puts "Part 2"
set n 75
puts "Number of stones after $n blinks is [part2 $input_stones $n]"
puts "Size of blink cache: [array size blink_cache]"
record mark part2

record report
