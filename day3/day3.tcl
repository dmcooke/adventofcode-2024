#!/usr/bin/tclsh9.0

if {[namespace which ::readFile] eq ""} {
    proc readFile {filename {mode text}} {
        set MODES {binary text}
        set ERR [list -level 1 -errorcode [list TCL LOOKUP MODE $mode]]
        set mode [tcl::prefix match -message "mode" -error $ERR $MODES $mode]

        set f [open $filename [dict get {text r binary rb} $mode]]
        try {
            return [read $f]
        } finally {
            close $f
        }
    }
}

set input [readFile input.txt]

set pattern {mul\(([1-9][0-9]{0,2}),([1-9][0-9]{0,2})\)}

proc part1 {input} {
    global pattern
    set total 0
    foreach {m n1 n2} [regexp -all -inline $pattern $input] {
        incr total [expr {$n1 * $n2}]
    }
    return $total
}

set pattern2 [string cat {(do\(\))|(don't\(\))|} "(?:" $pattern ")"]

proc part2 {input} {
    global pattern2
    set total 0
    set enabled 1
    foreach {m do dont n1 n2} [regexp -all -inline $pattern2 $input] {
        if {$do ne ""} {
            set enabled 1
        } elseif {$dont ne ""} {
            set enabled 0
        } elseif {$enabled} {
            incr total [expr {$n1 * $n2}]
        }
    }
    return $total
}

# About twice as fast as part2
# I think it's b/c all the string index's are inlined to a single bytecode;
# there's basically no calls to other commands.
proc part2_bychar {input} {
    set len [string length $input]
    set i 0
    set total 0
    set enabled 1
    while {$i < $len} {
        set c [string index $input $i]; incr i
        switch $c {
            d {
                set c [string index $input $i]; incr i
                if {$c ne "o"} {
                    if {$c in {d m}} { incr i -1 }
                    continue
                }
                set c [string index $input $i]; incr i
                switch $c {
                    n {
                        set s [string range $input $i [expr {$i + 3}]]
                        if {$s ne "'t()"} {
                            continue
                        }
                        incr i 4
                        set enabled 0
                    }
                    "(" {
                        set c [string index $input $i]; incr i
                        if {$c ne ")"} {
                            if {$c in {d m}} { incr i -1 }
                            continue
                        }
                        set enabled 1
                    }
                    default {
                        if {$c in {d m}} { incr i -1 }
                        continue
                    }
                }
            }
            m {
                if {!$enabled} {
                    continue
                }
                set s [string range $input $i [expr {$i + 2}]]
                if {$s ne "ul("} {
                    continue
                }
                incr i 3
                set c [string index $input $i]; incr i
                if {$c ni {1 2 3 4 5 6 7 8 9}} {
                    if {$c in {d m}} { incr i -1 }
                    continue
                }
                set x $c
                set c [string index $input $i]; incr i
                if {$c in {0 1 2 3 4 5 6 7 8 9}} {
                    set x [expr {$x * 10 + $c}]
                    set c [string index $input $i]; incr i
                    if {$c in {0 1 2 3 4 5 6 7 8 9}} {
                        set x [expr {$x * 10 + $c}]
                        set c [string index $input $i]; incr i
                    }
                }
                if {$c ne ","} {
                    if {$c in {d m}} { incr i -1 }
                    continue
                }
                set c [string index $input $i]; incr i
                if {$c ni {1 2 3 4 5 6 7 8 9}} {
                    if {$c in {d m}} { incr i -1 }
                    continue
                }
                set y $c
                set c [string index $input $i]; incr i
                if {$c in {0 1 2 3 4 5 6 7 8 9}} {
                    set y [expr {$y * 10 + $c}]
                    set c [string index $input $i]; incr i
                    if {$c in {0 1 2 3 4 5 6 7 8 9}} {
                        set y [expr {$y * 10 + $c}]
                        set c [string index $input $i]; incr i
                    }
                }
                if {$c ne ")"} {
                    if {$c in {d m}} { incr i -1 }
                    continue
                }
                incr total [expr {$x * $y}]
            }
        }
    }
    return $total
}


proc part2_bychar2 {input} {
    set len [string length $input]
    set i 0
    set total 0
    set enabled 1
    while {$i < $len} {
        set c [string index $input $i]; incr i
        switch $c {
            d {
                set s [string range $input $i [expr {$i + 4}]]
                if {$s eq "on't()"} {
                    incr i 5
                    set enabled 0
                } else {
                    set s [string range $input $i [expr {$i + 2}]]
                    if {$s eq "o()"} {
                        incr i 3
                        set enabled 1
                    }
                }
            }
            m {
                if {!$enabled} {
                    continue
                }
                set s [string range $input $i [expr {$i + 2}]]
                if {$s ne "ul("} {
                    continue
                }
                incr i 3
                if {![match_mul_ints $input i x y]} {
                    continue
                }
                incr total [expr {$x * $y}]
            }
        }
    }
    return $total
}

apply [list {} {
    set block1 {
        set c [string index $input $i]
        switch $c {
            1 - 2 - 3 - 4 - 5 - 6 - 7 - 8 - 9 {
                incr i
                set %X% $c
            }
            0 {
                incr i
                set %X% 0
                set c [string index $input $i]
                if {$c eq %TC%} {
                    incr i
                    set intdone 1
                } else {
                    return 0
                }
            }
            default {
                return 0
            }
        }
    }
    set block2 {
        set c [string index $input $i]
        switch $c {
            0 - 1 - 2 - 3 - 4 - 5 - 6 - 7 - 8 - 9 {
                incr i
                set %X% [expr {10*$%X% + $c}]
            }
            %TC% {
                incr i
                set intdone 1
            }
            default {
                return 0
            }
        }
    }
    set tc_block {
        set c [string index $input $i]
        if {$c eq %TC%} {
            incr i
        } else {
            return 0
        }
    }
    set map1 [dict create %B1% $block1 \
                  %B2% $block2 \
                  %BTC% $tc_block]
    set template [string map $map1 {
        set intdone 0
        %B1%
        if {!$intdone} {
            %B2%
            if {!$intdone} {
                %B2%
                if {!$intdone} {
                    %BTC%
                }
            }
        }
    }]
    set mapx [dict create %X% x %TC% {","}]
    set xblock [string map $mapx $template]
    set mapy [dict create %X% y %TC% {")"}]
    set yblock [string map $mapy $template]
    set map2 [dict create %XBLOCK% $xblock %YBLOCK% $yblock]
    set body [string map $map2 {
        upvar 1 $posvar pos $xvar x $yvar y
        set i $pos
        %XBLOCK%
        %YBLOCK%
        set pos $i
        return 1
    }]
    proc match_mul_ints_2 {input posvar xvar yvar} $body
} [namespace current]]

proc match_short_uint {input posvar terminalchar xvar} {
    upvar 1 $posvar pos $xvar x
    set i $pos
    set x 0
    set c [string index $input $i]
    switch $c {
        1 - 2 - 3 - 4 - 5 - 6 - 7 - 8 - 9 {
            incr i
            set x $c
        }
        0 {
            incr i
            set x 0
            set c [string index $input $i]
            if {$c eq $terminalchar} {
                incr i
                set pos $i
                return 1
            } else {
                return 0
            }
        }
        default {
            return 0
        }
    }
    set c [string index $input $i]
    switch $c {
        0 - 1 - 2 - 3 - 4 - 5 - 6 - 7 - 8 - 9 {
            incr i
            set x [expr {10*$x + $c}]
        }
        default {
            if {$c eq $terminalchar} {
                incr i
                set pos $i
                return 1
            } else {
                return 0
            }
        }
    }
    set c [string index $input $i]
    switch $c {
        0 - 1 - 2 - 3 - 4 - 5 - 6 - 7 - 8 - 9 {
            incr i
            set x [expr {10*$x + $c}]
        }
        default {
            if {$c eq $terminalchar} {
                incr i
                set pos $i
                return 1
            } else {
                return 0
            }
        }
    }
    set c [string index $input $i]
    if {$c eq $terminalchar} {
        incr i
        set pos $i
        return 1
    } else {
        return 0
    }
}

proc match_mul_ints {input posvar xvar yvar} {
    upvar 1 $posvar pos $xvar x $yvar y
    return [expr {[match_short_uint $input pos "," x]
                  && [match_short_uint $input pos ")" y]}]
}

proc get_two_ints {input posvar} {
    upvar 1 $posvar pos
    if {[regexp -start $pos -indices \
             {^([1-9][0-9]{0,2}),([1-9][0-9]{0,2})\)} \
             $input m a b]} {
        set pos [expr {[lindex $m 1] + 1}]
        set a [string range $input {*}$a]
        set b [string range $input {*}$b]
        return [list $a $b]
    } else {
        return {}
    }
}

proc getint2 {input posvar terminalchar} {
    upvar 1 $posvar pos
    set c [string index $input $pos]
    if {$c eq "" || $c < "0" || "9" < $c} {
        return -1
    }
    set x $c
    incr pos
    set c [string index $input $pos]
    if {$c eq "" || $c < "0" || "9" < $c} {
        if {$c eq $terminalchar} {
            incr pos
            return $x
        } else {
            return -1
        }
    }
    set x [expr {10 * $x + $c}]
    incr pos
    set c [string index $input $pos]
    if {$c eq "" || $c < "0" || "9" < $c} {
        if {$c eq $terminalchar} {
            incr pos
            return $x
        } else {
            return -1
        }
    }
    set x [expr {10 * $x + $c}]
    incr pos
    set c [string index $input $pos]
    if {$c eq $terminalchar} {
        incr pos
        return $x
    } else {
        return -1
    }
}


# mul()* "don't()" (anything) "do()" mul()* ($ | don't())
# loop:
#   find next of mul() or don't()
#   - if mul(), add product to total
#   - if don't(), skip to next do()
#     - if no do(), done

proc part2_find {input} {
    set length [string length $input]
    set i 0
    set total 0
    set next_mul [string first "mul(" $input]
    if {$next_mul == -1} {
        return 0
    }
    set next_do [string first "do()" $input]
    if {$next_do == -1} {
        set next_do $length
    }
    set next_dont [string first "don't()" $input]
    if {$next_dont == -1} {
        set next_dont $length
    }
    set lasti -1
    while {$i < $length} {
        if {$i <= $lasti} {
            error "Not progressing! i=$i  lasti=$lasti"
        }
        set lasti $i
        if {$next_mul < $next_dont} {
            set i [expr {$next_mul + 4}]
            set next_mul [string first "mul(" $input [expr {$i+4}]]
            if {$i + 4 >= $length} {
                break
            }
            # it's faster with this than with match_mul_ints
            # (which is faster in other places)
            set x [getint2 $input i ","]
            if {$x == -1} {
                continue
            }
            set y [getint2 $input i ")"]
            if {$y == -1} {
                continue
            }
            incr total [expr {$x * $y}]
            if {$next_mul == -1} {
                break
            }
        } else {
            set i [expr {$next_dont + [string length "don't()"]}]
            if {$next_do < $i} {
                set next_do [string first "do()" $input $i]
                if {$next_do == -1} {
                    break
                }
            }
            set i [expr {$next_do + [string length "do()"]}]
            set next_dont [string first "don't()" $input $i]
            if {$next_dont == -1} {
                set next_dont $length
            }
            if {$next_mul < $i} {
                set next_mul [string first "mul(" $input $i]
                if {$next_mul == -1} {
                    break
                }
            }
        }
    }
    return $total
}

proc next_needle_position {needleposnvar string pos needle} {
    upvar 1 $needleposnvar needle_posns
    if {[dict exists $needle_posns $needle]} {
        set i [dict get $needle_posns $needle]
        set update [expr {$i != -1 && $i < $pos}]
    } else {
        set update 1
    }
    if {$update} {
        set i [string first $needle $string $pos]
        dict set needle_posns $needle $i
    }
    return $i
}

proc next_needle {needleposnvar string posvar cases} {
    set caseslen [llength $cases]
    if {$caseslen % 2 != 0} {
        error "cases argument should be dict-like"
    }
    set ncases [expr {$caseslen / 2}]
    upvar 1 $needleposnvar needle_posns $posvar pos
    if {![info exists needle_posns]} {
        set needle_posns {}
    }
    set minpos -1
    set minscript {}
    set index -1
    foreach {needle script} $cases {
        incr index
        if {$index == $ncases - 1 && $needle eq "default"} {
            if {$minpos == -1} {
                set minscript $script
            }
        } else {
            set i [next_needle_position needle_posns $string $pos $needle]
            if {$i == -1} {
                continue
            }
            incr i [string length $needle]
            if {$minpos == -1 || $i < $minpos} {
                set minpos $i
                set minscript $script
            }
        }
    }
    if {$minpos != -1} {
        set pos $minpos
    }
    tailcall uplevel 0 $minscript
    #tailcall try $minscript
}


proc part2_needlematch {input} {
    set length [string length $input]
    set total 0
    set pos 0
    set needle_posns {}
    while {$pos < $length} {
        next_needle needle_posns $input pos {
            "mul(" {
                if {[match_mul_ints_2 $input pos x y]} {
                    incr total [expr {$x * $y}]
                }
            }
            "don't()" {
                next_needle needle_posns $input pos {
                    "do()" {
                    }
                    default {
                        break
                    }
                }
            }
            default {
                break
            }
        }
    }
    return $total
}


proc move_to_needle {string posvar needle nposvar} {
    upvar 1 $posvar pos $nposvar minpos
    if {$minpos == -2} {
        set minpos [string first $needle $string $pos]
        if {$minpos == -1} {
            return 0
        }
        incr minpos [string length $needle]
    }
    set pos $minpos
    set minpos -2
    return 1
}

proc next_needle_2 {string posvar needle1 n1posvar needle2 n2posvar} {
    upvar 1 $posvar pos $n1posvar n1pos $n2posvar n2pos
    if {$n1pos == -2 || ($n1pos >= 0 && $n1pos < $pos)} {
        set n1pos [string first $needle1 $string $pos]
        if {$n1pos != -1} {
            incr n1pos [string length $needle1]
        }
    }
    if {$n2pos == -2 || ($n2pos >= 0 && $n2pos < $pos)} {
        set n2pos [string first $needle2 $string $pos]
        if {$n2pos != -1} {
            incr n2pos [string length $needle2]
        }
    }
    if {$n1pos == -1} {
        if {$n2pos == -1} {
            return nomatch
        } else {
            set pos $n2pos
            set n2pos -2
            return second
        }
    } elseif {$n2pos == -1 || $n1pos < $n2pos} {
        set pos $n1pos
        set n1pos -2
        return first
    } else {
        set pos $n2pos
        set n2pos -2
        return second
    }
}

proc part2_needlematch2 {input} {
    set length [string length $input]
    set pos 0
    set total 0
    set next_mul -2
    set next_do -2
    set next_dont -2
    while {$pos < $length} {
        switch [next_needle_2 $input pos "mul(" next_mul "don't()" next_dont] {
            first {
                if {[match_mul_ints_2 $input pos x y]} {
                    incr total [expr {$x * $y}]
                }
                # set x [getint2 $input pos ","]
                # if {$x == -1} {
                #     continue
                # }
                # set y [getint2 $input pos ")"]
                # if {$y == -1} {
                #     continue
                # }
                # incr total [expr {$x * $y}]
            }
            second {
                if {![move_to_needle $input pos "do()" next_do]} {
                    break
                }
            }
            nomatch {
                break
            }
        }
    }
    return $total
}

proc check_upvar_exists {level varname} {
    upvar [expr {$level + 1}] $varname x
    if {![info exists x]} {
        throw [list UPVAR MISSING $varname] \
            "No such variable \"$varname\" at level $level"
    }
}

proc create_needle_var {needle varname} {
    upvar 1 $varname ndstate
    array set ndstate {pos -2}
    set ndstate(needle) $needle
}

proc init_needle_vars {args} {
    foreach {needle nvar} $args {
        upvar 1 $nvar ndstate
        array set ndstate {pos -2}
        set ndstate(needle) $needle
    }
}

proc choose_needle {string posvar cases {else ""} {nomatch {}}} {
    if {$nomatch ne ""} {
        if {$else ne "else"} {
            error "Missing 'else'"
        }
    } elseif {$else ni {"" else}} {
        error "Wrong # args, should be: choose_needle <string> <posVar> {<needleVar> script ...} ?\"else\" <nomatchScript>?"
    }
    upvar 1 $posvar pos
    set minpos -1
    set minscript $nomatch
    set minvar {}
    set i -1
    foreach {nvar script} $cases {
        incr i
        upvar 1 $nvar ndstate
        set npos $ndstate(pos)
        if {$npos != -1} {
            if {$npos < $pos} {
                set needle $ndstate(needle)
                set npos [string first $needle $string $pos]
                if {$npos == -1} {
                    set ndstate(pos) -1
                    continue
                } else {
                    incr npos [string length $needle]
                }
            }
            if {$npos < $minpos || $minpos == -1} {
                set minpos $npos
                set minvar $nvar
                set minscript $script
            }
            set ndstate(pos) $npos
        }
    }
    if {$minpos != -1} {
        set pos $minpos
        upvar 1 $minvar ndstate
        set ndstate(pos) -2
    }
    # Ok, I don't know why _this_ bytecompiles minscript and runs it
    tailcall uplevel 0 $minscript
    # ... while this does not
    # tailcall try $minscript
}

proc find_needle {string posvar nvar} {
    upvar 1 $posvar pos $nvar ndstate
    set npos $ndstate(pos)
    if {$npos == -1} {
        return 0
    }
    if {$npos < $pos} {
        # this includes npos == -2
        set needle $ndstate(needle)
        set npos [string first $needle $string $pos]
        if {$npos == -1} {
            set ndstate(pos) -1
            return 0
        }
        incr npos [string length $needle]
    }
    set pos $npos
    set ndstate(pos) -2
    return 1
}

proc part2_needlematch3 {input} {
    set length [string length $input]
    set total 0
    set pos 0
    create_needle_var "mul(" next_mul
    create_needle_var "don't()" next_dont
    create_needle_var "do()" next_do
    while {$pos < $length} {
        choose_needle $input pos {
            next_mul {
                if {[match_mul_ints_2 $input pos x y]} {
                    incr total [expr {$x * $y}]
                }
            }
            next_dont {
                if {![find_needle $input pos next_do]} {
                    set pos $length
                }
            }
        } else {
            set pos $length
        }
    }
    return $total
}

if {0} {
    # Hypothetical macro structure (--cmd arg ... --) would be
    # replaced with the result of calling cmd arg .... The delimiters
    # are lua-like: any sequence of ( followed by 2 or more dashes can
    # be used, pairing with the next matching number of dashes + ).
    while {$pos < $length} {
        (---Choose_needle $input pos {
            "mul(" {
                ...
            }
            "don't()" {
                (--Choose_needle $input pos {
                    "do()" { }
                } else {
                    break
                }--)
            }
        } else {
            ...
        }---)
    }
}

# It appears that we need to warm up the Tcl interpreter.
# Not the individual procs themselves: the difference between their
# first run and last run is fractions of a millisecond.  However, the
# first proc to run will take about 7 ms longer than any subsequent run,
# regardless of which proc we measure first.


proc measure {msg cmd args} {
    lappend cmd {*}$args
    set times {}
    foreach _ {1 2 3} {
        set bt [clock microseconds]
        set total [{*}$cmd]
        set et [clock microseconds]
        lappend times [expr {$et - $bt}]
    }
    #set times [lsort -real $times]
    puts "$msg $total  (in [list $times] μs)"
}

measure "Part 1: Total sum is" part1 $input
measure "Part 2: Total sum is" part2 $input
measure "Part 2 (by char): Total sum is" part2_bychar $input
measure "Part 2 (by char 2): Total sum is" part2_bychar2 $input

# Current winner
measure "Part 2 (find): Total sum is" part2_find $input

measure "Part 2 (needle matcher): Total sum is" part2_needlematch $input
# Not too far off part2_find
measure "Part 2 (needle matcher 2): Total sum is" part2_needlematch2 $input
measure "Part 2 (needle matcher 3): Total sum is" part2_needlematch3 $input

# Part 1: Total sum is 173529487  (in {10465 3787 3658} μs)
# Part 2: Total sum is 99532691  (in {7794 7541 7396} μs)
# Part 2 (by char): Total sum is 99532691  (in {3009 2626 2616} μs)
# Part 2 (find): Total sum is 99532691  (in {1507 1327 1327} μs)
# Part 2 (needle matcher): Total sum is 99532691  (in {3526 3402 3394} μs)
# Part 2 (needle matcher 2): Total sum is 99532691  (in {1712 1606 1592} μs)

# Conclusion:
# - by char works faster than I initially figured.  I believe it comes down
#   to `string index` being compiled to a single bytecode, and no or
#   very few command calls are done.
# - Regexp is slower than it should be.
# - Using string first is the fastest.  This is so even though
#   `string first $n $s $i` (with the start position) doesn't compile
#   to a bytecode (`string first $n $s` does, however).  But what it does
#   is push to C as much work as possible.  Bookkeeping is a pain though.
# - part2_needle_matcher2 is pretty close to part2_find.  The difference
#   between part2_needle_matcher and part2_needle_matcher2 is that there's
#   more overhead in the abstraction in the first version.  The second
#   specializes routines for matching one or two needles.
