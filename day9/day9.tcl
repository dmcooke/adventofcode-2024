#!/usr/bin/tclsh9.0

#source ../library/tools.tcl

proc measure {script} {
    set bt [clock microseconds]
    set result [uplevel 1 $script]
    set dt [expr {[clock microseconds] - $bt}]
    puts "elapsed = $dt μs"
    return $result
}

proc read_input {input_file} {
    return [string trim [readFile $input_file text]]
}

if {$argc > 0} {
    set input_file [lindex $argv 0]
} else {
    set input_file example.txt
}

set diskmap [read_input $input_file]

proc 1+ {x} { return [expr {$x + 1}] }
proc 1- {x} { return [expr {$x - 1}] }


namespace eval ::part1 {
    namespace export {[a-z]*}
    namespace ensemble create -prefixes 0
}

proc ::part1::expand_disk_map {diskmap} {
    set layout {}
    set fileid -1
    foreach {fsize free} [split $diskmap ""] {
        incr fileid
        lappend layout {*}[lrepeat $fsize $fileid]
        if {$free ne ""} {
            lappend layout {*}[lrepeat $free .]
        }
    }
    return [list $fileid $layout]
}

proc ::part1::next_free_block {layout freepointer} {
    set p [lsearch -exact -ascii -start $freepointer $layout "."]
    return $p
}

proc ::part1::defrag {layout} {
    set freepointer 0
    set end [expr {[llength $layout] - 1}]
    while {1} {
        while {[set fileid [lindex $layout $end]] eq "."} {
            incr end -1
        }
        set freepointer [next_free_block $layout $freepointer]
        if {$freepointer == -1 || $end < $freepointer} {
            break
        }
        lset layout $end "."
        lset layout $freepointer $fileid
        incr end -1
        incr freepointer
    }
    return $layout
}

proc layout_checksum {layout} {
    set csum 0
    set i -1
    foreach fileid $layout {
        incr i
        if {$fileid ne "."} {
            set csum [expr {$csum + $i * $fileid}]
        }
    }
    return $csum
}

proc compress_tail {layout} {
    set i [expr {[llength $layout] - 1}]
    set n 0
    while {0 <= $i && [lindex $layout $i] eq "."} {
        incr i -1
        incr n 1
    }
    return [list [lrange $layout 0 $i] "<$n free space>"]
}


puts "Part 1"

proc ::part1::run {diskmap} {
    set do_show [expr {[string length $diskmap] < 1000}]
    if {$do_show} {puts [list [split $diskmap ""]]}
    lassign [expand_disk_map $diskmap] maxfileid layout
    if {$do_show} {puts $layout}
    set defragged_layout [defrag $layout]
    if {$do_show} {puts [compress_tail $defragged_layout]}
    return [layout_checksum $defragged_layout]
}

puts "checksum = [measure {part1 run $diskmap}]"


proc tty_width {} {
    if {[info exists env(COLUMNS)]
         && [string is integer -string $env(COLUMNS)]} {
        return $env(COLUMNS)
    } else {
        return 80
    }
}

::oo::class create Part2Disk {

    # Observations
    #
    # * files only move once
    # * files are examined in decreasing order of their file id.
    # * initially, files are in order of their id.
    # * files are kept contiguous
    # * files are only moved to the left
    # * files are at least 1 block, and at most 9 blocks long
    #
    # * after we move a file we don't have to consolidate the free space
    #   it leaves behind: nothing will be moved into there.
    #   -> free space search stops at file position.
    # * free space starts with entries from 1 to 9 blocks. Since we
    #   won't use new space opened by moving a file then the entries
    #   we track will remain from 1 to 9 blocks long.

    # Data structures:
    #
    # * files tracked in an array indexed by file id containing position
    #   and size
    # * free space tracked in an array indexed by length, containing
    #   a list in descreasing order of the position (so removing from the
    #   list removes from the end)

    variable files freemap maxfileid maxfree maxposition

    constructor {diskmap} {
        array set files {}
        array set freemap {1 {} 2 {} 3 {} 4 {} 5 {} 6 {} 7 {} 8 {} 9 {}}
        # maxfileid maxfree maxposition are set in here
        my Expand_disk_map $diskmap
    }

    method Expand_disk_map {diskmap} {
        set posn 0
        set fileid -1
        foreach {fsize free} [split $diskmap ""] {
            incr fileid
            if {$fsize == 0} {
                puts "File $fileid has length 0"
            }
            set files($fileid) [list $posn $fsize]
            incr posn $fsize
            if {$free ne "" && $free > 0} {
                lappend freemap($free) $posn
                incr posn $free
            }
        }
        set maxposition $posn
        foreach free [lsort -integer [array names freemap]] {
            set freeposns [lreverse $freemap($free)]
            set freemap($free) $freeposns
            if {[llength $freeposns] > 0} {
                set maxfree $free
            }
        }
        set maxfileid $fileid
    }

    method Choose_fileid_char_braille {fileid} {
        # first non-blank braille character is U+2801
        # last is U+28ff
        set cp [expr {0x2801 + ($fileid % 254)}]
        return [format %c $cp]
    }
    method Choose_fileid_char_digits {fileid} {
        set cp [expr {48 + ($fileid % 10)}]
        return [format %c $cp]
    }
    forward Choose_fileid_char  my Choose_fileid_char_digits

    method dump_expanded_layout {} {
        set nproblems 0
        array set alayout {}
        for {set i 0} {$i <= $maxposition} {incr i} {
            set alayout($i) " "
        }
        foreach fileid [array names files] {
            lassign $files($fileid) fpos fsize
            set fend [expr {$fpos + $fsize}]
            set c [my Choose_fileid_char $fileid]
            for {} {$fpos < $fend} {incr fpos} {
                if {$alayout($fpos) ne " "} {
                    # Uh oh!
                    set alayout($fpos) "X"
                    incr nproblems
                } else {
                    set alayout($fpos) $c
                }
            }
        }
        foreach free [array names freemap] {
            foreach p $freemap($free) {
                set pend [expr {$p + $free}]
                for {} {$p < $pend} {incr p} {
                    if {$alayout($p) ne " "} {
                        # Oh no!
                        set alayout($p) "#"
                        incr nproblems
                    } else {
                        set alayout($p) "_"
                    }
                }
            }
        }
        set taillen 0
        for {set i $maxposition} {0 <= $i} {incr i -1} {
            if {$alayout($i) ne " "} {
                break
            } else {
                incr taillen
            }
        }
        set columns [tty_width]
        if {$taillen > 2*$columns} {
            set maxlayoutpos $i
        } else {
            set maxlayoutpos $maxposition
            set taillen 0
        }
        set have_line 0
        for {set i 0} {$i <= $maxlayoutpos} {incr i} {
            set c $alayout($i)
            if {$c eq " "} { set c "-" }
            puts -nonewline $c
            set have_line 1
            if {$i % $columns == $columns-1} {
                puts ""
                set have_line 9
            }
        }
        if {$taillen > 0} {
            puts "($taillen empty blocks)"
        } 
        if {$have_line} {
            puts ""
        }
        if {$nproblems > 0} {
            puts "$nproblems inconsistencies"
        }
    }

    method dump_state {} {
        puts "Part2Disk: maxfileid=$maxfileid maxfree=$maxfree maxpostion=$maxposition"
        #parray files
        #parray freemap
        my dump_expanded_layout
    }

    method trim_freemap {maxfilepos} {
        for {set i $maxfree} {0 < $i} {incr i -1} {
            if {[llength $freemap($i)] > 0} {
                if {[lindex $freemap($i) end] > $maxfilepos} {
                    set freemap($i) {}
                    if {$i == $maxfree} {
                        incr maxfree -1
                    }
                }
            } elseif {$i == $maxfree} {
                incr maxfree -1
            }
        }
    }

    method insert_free_space {posn size} {
        if {$size <= 0} {
            return
        }
        if {$size > $maxfree} {
            my dump_state
            error "Inconsistent free space;\
                   posn=$posn size=$size maxfree=$maxfree"
        }
        set i [lsearch -bisect -decreasing -integer $freemap($size) $posn]
        # i is the last index where [lindex freeposns i] >= posn
        # We want to insert after that, so before $i+1
        ledit freemap($size) [1+ $i] $i $posn
    }

    method allocate_free_space {fsize filepos} {
        if {$maxfree < $fsize} {
            return -1
        }
        set firstfree -1
        set firstfreepos $filepos
        set i [1- $fsize]
        while {$i < $maxfree} {
            incr i
            # $i <= $maxfree
            if {[llength $freemap($i)] > 0} {
                set pos [lindex $freemap($i) end]
                if {$pos < $firstfreepos} {
                    set firstfreepos $pos
                    set firstfree $i
                }
            }
        }
        if {$firstfree > 0} {
            set leftover [expr {$firstfree - $fsize}]
            ledit freemap($firstfree) end end
            my insert_free_space [expr {$firstfreepos + $fsize}] $leftover
            return $firstfreepos
        } else {
            return -1
        }
    }

    method defrag_file {fileid} {
        lassign $files($fileid) filepos fsize
        set pos [my allocate_free_space $fsize $filepos]
        if {$pos >= 0} {
            set files($fileid) [list $pos $fsize]
            return 1
        } else {
            return 0
        }
    }

    method defrag {} {
        set nmoved 0
        set n 0
        for {set fileid $maxfileid} {$fileid >= 0} {incr fileid -1} {
            set fpos [lindex $files($fileid) 0]
            incr nmoved [my defrag_file $fileid]
            incr n
            if {$nmoved % 10 == 0 || $fileid == 0} {
                my trim_freemap $fpos
            }
            if {$n % 20 == 0} {
                puts -nonewline "$fileid ($nmoved moved; $n processed)\r"
            }
        }
        if {$n >= 20} { puts "" }
    }

    method file_checksum {fileid} {
        lassign $files($fileid) fpos fsize
        # blocks $fpos to $fpos+$fsize-1 are allocated to fileid
        # checksum for this file is csum =\sum(i=fpos..fpos+size-1, i*fileid)
        # -> csum = fileid * sum(i=fpos..fpos+size-1, i)
        #         = fileid * (size*fpos + sum(i=0..size-1, i))
        #         = fileid * (size*fpos + (size*(size-1))/2)
        # (note: don't factor size out, as either it or size-1 cancels the /2)
        set nsum [expr {($fsize * ($fsize-1))/2}]
        return [expr {$fileid * ($fsize * $fpos + $nsum)}]
    }
    method checksum {} {
        set csum 0
        for {set i 0} {$i <= $maxfileid} {incr i} {
            incr csum [my file_checksum $i]
        }
        return $csum
    }

    method run {} {
        my defrag
        #my dump_state
        return [my checksum]
    }

}

puts "Part 2"

proc run2 {diskmap} {
    set d [Part2Disk new $diskmap]
    set n [$d run]
    $d destroy
    return $n
}

puts "checksum = [measure {run2 $diskmap}]"
