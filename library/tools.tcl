
package provide aoc::tools 0.1

variable debug_log 1

proc debug_puts {arg} {
    variable debug_log
    if {$debug_log} {
        set msg [uplevel 1 [list ::subst $arg]]
        puts $msg
    }
}

proc list_max {lst cmd args} {
    set max {}
    foreach x $lst {
        set n [uplevel 1 [list $cmd {*}$args $x]]
        if {$max eq "" || $n > $max} {
            set max $n
        }
    }
    return $max
}
proc list_min {lst cmd} {
    set min {}
    foreach x $lst {
        set n [uplevel 1 [list $cmd {*}$args $x]]
        if {$min eq "" || $n < $min} {
            set min $n
        }
    }
    return $min
}


proc fq {level name} {
    if {[string match {::*} $name]} { return $name }
    incr level
    set ns [uplevel 1 {::namespace current}]
    if {$ns eq "::"} { set ns "" }
    return ${ns}::${name}
}

proc format_elapsed {us} {
    if {$us < 3000} {
        return "$us μs"
    } elseif {$us < 3000000} {
        return [format {%.3f ms} [expr {$us * 1e-3}]]
    } else {
        return [format {%.3f s} [expr {$us * 1e-6}]]
    }
}

proc measure {script} {
    set bt [clock microseconds]
    set r [uplevel 1 $script]
    set et [clock microseconds]
    set dt [expr {$et - $bt}]
    puts "elapsed time = [format_elapsed $dt]"
    return $r
}


namespace eval record {
    array set times {}

    proc start {} {
        variable times
        set times(start) [clock microseconds]
    }

    proc mark {name} {
        variable times
        set times($name) [clock microseconds]
    }

    proc Update_max_length {varname string} {
        upvar 1 $varname var
        set n [string length $string]
        if {![info exists var] || $n > $var} {
            set var $n
        }
    }

    proc Elapsed {label0 label1} {
        variable times
        return [expr {$times($label1) - $times($label0)}]
    }

    proc Format_elapsed {dt} {
        return [format {%.3f ms} [expr {$dt * 1e-3}]]
    }
    proc Left {width s {slen {}}} {
        if {$slen eq ""} {
            set slen [string length $s]
        }
        if {$slen >= $width} { return $s }
        return [string cat $s [string repeat " " [expr {$width-$slen}]]]
    }
    proc Right {width s {slen {}}} {
        if {$slen eq ""} {
            set slen [string length $s]
        }
        if {$slen >= $width} { return $s }
        return [string cat [string repeat " " [expr {$width-$slen}]] $s]
    }
    proc Center {width s {slen {}}} {
        if {$slen eq ""} {
            set slen [string length $s]
        }
        if {$slen >= $width} { return $s }
        set left [expr {($width - $slen)/2}]
        return [string cat [string repeat " " $left] $s \
                    [string repeat " " [expr {$width - $slen - $left}]]]
    }

    proc report {} {
        variable times
        set sortedtimes [lsort -stride 2 -index 1 -integer [array get times]]
        set sortedpoints [lmap {p t} $sortedtimes {set p}]
        set npoints [llength $sortedpoints]
        set start [lindex $sortedpoints 0]
        set last [lindex $sortedpoints end]

        Update_max_length maxlen_elapsed "elapsed"
        Update_max_length maxlen_cumul "cumulative"
        set rows {}
        set p0 $start
        for {set i 1} {$i < $npoints} {incr i} {
            set p1 [lindex $sortedpoints $i]
            set elapsed [Format_elapsed [Elapsed $p0 $p1]]
            set cumul [Format_elapsed [Elapsed $start $p1]]
            lappend rows $p0 $p1 $elapsed $cumul [expr {$i == $npoints-1}]
            Update_max_length maxlen_elapsed $elapsed
            Update_max_length maxlen_cumul $cumul
            Update_max_length pointlen0 $p0
            Update_max_length pointlen1 $p1
            set p0 $p1
        }
        set w [expr {$pointlen0 + $pointlen1 + 4}]
        puts [format {%-*s   %-*s   %-*s} $w "Stage" \
                  $maxlen_elapsed elapsed $maxlen_cumul cumulative]
        foreach {p0 p1 elapsed cumul islast} $rows {
            if {$islast} {
                set cs "\x1b\[4m${cumul}\x1b\[m"
            } else {
                set cs $cumul
            }
            puts [format {%*s -> %-*s : %*s  %s} \
                      $pointlen0 $p0 $pointlen1 $p1 \
                      $maxlen_elapsed $elapsed \
                      [Right $maxlen_cumul $cs [string length $cumul]]]
        }
    }

    namespace export {[a-z]*}
    namespace ensemble create -prefixes 0
}
