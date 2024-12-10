# Tcl package index file, version 1.1

if {[package vsatisfies [package provide Tcl] 9.0-]} {
    apply {{dir} {
        foreach {pkg ver file} {
            aoc::geom 0.1 geom.tcl
            aoc::intv 0.1 intv.tcl
            aoc::tools 0.1 tools.tcl
        } {
            package ifneeded $pkg $ver \
                [list source -encoding utf-8 [file join $dir $file]]
        }
    }} $dir
}
