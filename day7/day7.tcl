#!/usr/bin/tclsh9.0

source ../library/tools.tcl

proc read_input {input_file} {
    set inputs {}
    # line format is <int>: <int> <int> ...
    foreachLine line $input_file {
        set result [string trimright [lindex $line 0] :]
        lappend inputs $result [lrange $line 1 end]
    }
    return $inputs
}

proc operator_results_part1 {a b} {
    return [list [expr {$a + $b}] [expr {$a * $b}]]
}
proc operator_results_part2 {a b} {
    return [list [expr {$a + $b}] [expr {$a * $b}] "$a$b"]
}

proc find_operators_aux {opers result acc operand args} {
    set n [llength $args]
    set applied [$opers $acc $operand]
    if {$n == 0} {
        foreach x $applied {
            if {$x == $result} {
                throw {FOUND} "found"
            }
        }
    } else {
        foreach x $applied {
            find_operators_aux $opers $result $x {*}$args
        }
    }
}

proc test_operators_exist {opers result operands} {
    try {
        find_operators_aux $opers $result 0 {*}$operands
    } trap {FOUND} {} {
        return 1
    }
    return 0
}

proc sum_of_calibrations {opers inputs} {
    set n 0
    set sum 0
    foreach {result operands} $inputs {
        if {[test_operators_exist $opers $result $operands]} {
            incr n
            incr sum $result
        }
    }
    return [list n $n sum $sum]
}

proc part1 {inputs} {
    return [sum_of_calibrations ::operator_results_part1 $inputs]
}

proc part2 {inputs} {
    return [sum_of_calibrations ::operator_results_part2 $inputs]
}

set inputs [read_input input.txt]

puts "Part 1"
puts "sum of results of satisfiable inputs: [measure {part1 $inputs}]"
puts "Part 2"
puts "sum of results of satisfiable inputs: [measure {part2 $inputs}]"
