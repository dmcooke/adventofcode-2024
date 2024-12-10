#!/usr/bin/tclsh9.0

set input [readFile input.txt]

### Part 1

# Input is 140x140

# Find number of times 'XMAS' appears.
# It can be written in any of the 8 standard directions directions
# on a square lattice: →, ↘, ↓, ↙, ←, ↖, ↑, or ↗.
# (E, SE, S, SW, W, NW, N, NE)

# Approach 1:
# - for each X, check each of the 8 directions to form XMAS
#
# Approach 2:
# - for each direction, search for XMAS
#
# Or a hybrid (search horizontally as in approach 2, but other directions
# as in approach 1).
#
# We can search in just 4 directions (say →, ↓, ↘, and ↙) if we search
# for XMAS and SMAX

# There are no repeated letters in XMAS, so we don't need to worry
# about counting overlapping words.

proc find_indices {word string {overlap 0}} {
    set indices {}
    if {$overlap} {
        set offset 1
    } else {
        set offset [string length $word]
    }
    set i 0
    while {1} {
        set j [string first $word $string $i]
        if {$j == -1} {
            break
        }
        lappend indices $j
        set i [expr {$j + $offset}]
    }
    return $indices
}

proc count_east {lines word} {
    set nwords 0
    foreach line $lines {
        incr nwords [llength [find_indices $word $line]]
    }
    return $nwords
}

# Label directed line segments by start position (a, b), number of
# steps n, and direction (dx, dy)
#
# Cells covered are L(a,b) = {(a + i*dx, b + i*dy) | i = 0..n-1}
#
# If grid is G = {(x,y) | x = 0 .. N-1, y = 0 .. M-1}, what line
# segments fit on the grid?
# {(a, b) | L(a,b) is subset of G}
#
# so, for i=0..n-1, need 0 <= a + i*dx <= N-1, and
# 0 <= b + i * dy <= M-1.
# We can satisfy this by looking at the constraints on i=0 and i=n-1:
# 0 <= a <= N-1, 0 <= b <= M-1
# 0 <= a + (n-1)*dx <= N-1, 0 <= b + (n-1)*dy <= M-1
#
# If dx == 0:  0 <= a <= N-1
# If dx > 0: 0 <= a+(n-1)*dx <= N-1
#   -> -(n-1)*dx <= a <= N - 1 - (n-1)*dx
#   ->         0 <= a <= N - 1 - (n-1)*dx    (constraint intersection)
# If dx < 0: 0 <= a+(n-1)*(-|dx|) <= N-1
#   -> (n-1)*|dx| <= a <= N - 1 + (n-1)*|dx|
#   -> (n-1)*|dx| <= a <= N - 1
#
# We can simplify by treating (n-1)*dx as a step size Dx.
# We want 0 <= a <= N-1, and 0 <= a + Dx <= N-1.
# For Dx = 0, 0 <= a <= N-1
# For Dx>0, 0 <= a <= N-1-Dx
# For Dx<0, |Dx| <= a <= N-1

# For a step size dx and a closed interval [x0, x1] return the
# largest interval [u0, u1] such that for all x in [u0, u1],
# x in [x0, x1] and x+dx in [x0, x1].
# -> x in [u0, u1] and x in [x0, x1] and x in [x0-dx, x1-dx]
# -> x in [u0, u1] and x in [max(x0, x0-dx), min(x1,x1-dx)]
proc step_range {x0 x1 dx} {
    if {$dx == 0} {
        return [list $x0 $x1]
    } elseif {$dx > 0} {
        set u1 [expr {$x1 - $dx}]
        return [list $x0 $u1]
    } else {
        set u0 [expr {$x0 - $dx}]
        return [list $u0 $x1]
    }
}

proc grid_width {lines} {
    set width 0
    foreach line $lines {
        set len [string length $line]
        if {$len > $width} {
            set width $len
        }
    }
    return $width
}


proc count_delta {lines word dx dy} {
    set nwords 0
    set nlines [llength $lines]
    set width [grid_width $lines]
    set wordlen [string length $word]
    set Dx [expr {($wordlen - 1) * $dx}]
    lassign [step_range 0 [expr {$width - 1}] $Dx] xfirst xlast
    set Dy [expr {($wordlen - 1) * $dy}]
    lassign [step_range 0 [expr {$nlines - 1}] $Dy] yfirst ylast

    set c0 [string index $word 0]

    for {set y0 $yfirst} {$y0 <= $ylast} {incr y0} {
        set line [lindex $lines $y0]
        foreach x0 [find_indices $c0 $line] {
            if {$x0 < $xfirst || $xlast < $x0} {
                continue
            }
            set found 1
            for {set i 1} {$i < $wordlen} {incr i} {
                set y [expr {$y0 + $i * $dy}]
                if {$y == $y0} {
                    set yline $line
                } else {
                    set yline [lindex $lines $y]
                }
                set x [expr {$x0 + $i * $dx}]
                set gridchar [string index $yline $x]
                set wordchar [string index $word $i]
                if {$wordchar != $gridchar} {
                    set found 0
                    break
                }
            }
            incr nwords $found
        }
    }
    return $nwords
}

# South (down) is +1, since line count increases downwards
proc count_south {lines word} {
    return [count_delta $lines $word 0 1]
}
proc count_southeast {lines word} {
    return [count_delta $lines $word 1 1]
}
proc count_southwest {lines word} {
    return [count_delta $lines $word 1 -1]
}

proc wordsearch_count {lines word} {
    set rword [string reverse $word]
    set nwords 0
    incr nwords [count_east $lines $word]
    incr nwords [count_east $lines $rword]
    incr nwords [count_south $lines $word]
    incr nwords [count_south $lines $rword]
    incr nwords [count_southeast $lines $word]
    incr nwords [count_southeast $lines $rword]
    incr nwords [count_southwest $lines $word]
    incr nwords [count_southwest $lines $rword]
    return $nwords
}

puts "Part 1"
puts "Total number of XMAS is [wordsearch_count $input XMAS]"

### Part 2
#
# We want to find how many times MAS occurs as an X.  For example,
#   M.S
#   .A.
#   M.S
#
# We can read "MAS" in either direction, so
#
#   S.S
#   .A.
#   M.M

#   M.M
#   .A.
#   S.S

#   S.M
#   .A.
#   S.M

# are the other variants.
#
# This seems easier: search for A with coordinates (x,y) in (1..N-2, 1..M-2).
# Then check
#      (x-1,y-1) = S, (x+1,y+1) = M
#   or (x-1,y-1) = M, (x+1,y+1) = S
# and
#      (x-1,y+1) = S, (x+1,y-1) = M
#   or (x-1,y+1) = M, (x+1,y-1) = S

proc grid_get {grid x y} {
    set line [lindex $grid $y]
    return [string index $line $x]
}

proc count_crosses {lines} {
    set nwords 0
    set nlines [llength $lines]
    set width [grid_width $lines]
    set xfirst 1; set xlast [expr {$width - 2}]
    set yfirst 1; set ylast [expr {$nlines - 2}]

    for {set y $yfirst} {$y <= $ylast} {incr y} {
        set line [lindex $lines $y]
        foreach x [find_indices A $line] {
            if {$x < $xfirst || $xlast < $x} {
                continue
            }
            set cnw [grid_get $lines [expr {$x-1}] [expr {$y-1}]]
            set cne [grid_get $lines [expr {$x+1}] [expr {$y-1}]]
            set csw [grid_get $lines [expr {$x-1}] [expr {$y+1}]]
            set cse [grid_get $lines [expr {$x+1}] [expr {$y+1}]]
            if {(($cnw eq "S" && $cse eq "M")
                 || ($cnw eq "M" && $cse eq "S"))
                && (($cne eq "S" && $csw eq "M")
                    || ($cne eq "M" && $csw eq "S"))} {
                incr nwords
            }
        }
    }
    return $nwords
}

puts "Part 2"
puts "Number of X-MAS crosses is [count_crosses $input]"
