
package provide aoc::boxchars 0.1

namespace eval boxchars {
    namespace export {[a-z]*}
    namespace ensemble create -prefixes 0

    array set charlightheavy {
        " " ""
        ╵ u ╷ d ╴ l ╶ r
        ╹ U ╻ D ╸ L ╺ R
        ─ lr   ╼ lR   ╾ Lr   ━ LR
        │ ud   ╽ uD   ╿ Ud   ┃ UD
        ┌ rd   ┍ Rd   ┎ rD   ┏ RD
        ┐ ld   ┑ Ld   ┒ lD   ┓ LD
        └ ru   ┕ Ru   ┖ rU   ┗ RU
        ┘ lu   ┙ Lu   ┚ lU   ┛ LU
        ├ rud  ┝ Rud  ┞ rUd  ┟ ruD  ┠ rUD  ┡ RUd  ┢ RuD  ┣ RUD
        ┤ lud  ┥ Lud  ┦ lUd  ┧ luD  ┨ lUD  ┩ LUd  ┪ LuD  ┫ LUD
        ┬ lrd  ┭ Lrd  ┮ lRd  ┯ LRd  ┰ lrD  ┱ LrD  ┲ lRD  ┳ LRD
        ┴ lru  ┵ Lru  ┶ lRu  ┷ LRu  ┸ lrU  ┹ LrU  ┺ lRU  ┻ LRU
        ┼ lrud ┽ Lrud ┾ lRud ┿ LRud ╀ lrUd ╁ lruD ╂ lrUD ╃ LrUd
        ╄ lRUd ╅ LruD ╆ lRuD ╇ LRUd ╈ LRuD ╉ LrUD ╊ lRUD ╋ LRUD
    }

    # Not currently used
    array set charlightdouble {
        " " ""
        ═ !l!r ║ !u!d
        ╒ !rd ╓ r!d ╔ !r!d
        ╕ !ld ╖ l!d ╗ !l!d
        ╘ !ru ╙ r!u ╚ !r!u
        ╛ !lu ╜ l!u ╝ !l!u
        ╞ !rud ╟ r!u!d ╠ !r!u!d
        ╡ !lud ╢ l!u!d ╣ !l!u!d
        ╤ !l!rd ╥ lr!d ╦ !l!r!d
        ╧ !l!ru ╨ lr!u ╩ !l!r!u
        ╪ !l!rud ╫ lr!u!d ╬ !l!r!u!d
    }

    # The keys for lightheavybox are 8-bit integers, where
    # * the bottom 4 bits {b3 b2 b1 b0} are the directions
    #   {right left down up} (or, in terms of the direction symbols,
    #    ^ ↔ b0=1, v ↔ b1=1, < ↔ b2=1, > ↔ b3=1)
    # * the top 4 bits {b7 b6 b5 b4} are the weights of the
    #   corresponding lower 4, {b3 b2 b1 b0}.
    #   e.g. b6=1 if b2=1 (<) should be heavy, and b6=0 if it should
    #   be light.
    # * In the normalized encoding, a set bit in the weights
    #   correspond to a set bit in the directions.  In other words,
    #   bits that are 0 in the directions have the corresponding
    #   weight bit equal to 0.
    #
    # A value x can be normalized by ($x & (($x << 4) | 0b1111)),
    # which keeps the direction bits, and clears any weight bits
    # that aren't set in the direction bits.
    # $x & (($x << 4) | 0b1111) & 0b11111111

    array set lightheavybox {}
    array set lightbox {}
    array set heavybox {}

    # ^ (u) 0b0001 = 0x01 = 1   0x11 = 17   (U)
    # v (d) 0b0010 = 0x02 = 2   0x22 = 34   (D)
    # < (l) 0b0100 = 0x04 = 4   0x44 = 68   (L)
    # > (r) 0b1000 = 0x08 = 8   0x88 = 136  (R)

    variable up    1
    variable down  2
    variable left  4
    variable right 8

    proc encode {args} {
        set enc 0
        set masks [dict create \
                       u 1 U 17 ^ 1  \
                       d 2 D 34 v 2 \
                       l 4 L 68 < 4 \
                       r 8 R 136 > 8]
        foreach desc $args {
            foreach d [split $desc ""] {
                set enc [expr {$enc | [dict get $masks $d]}]
            }
        }
        return $enc
    }
    proc decode {enc} {
        set desc {}
        set x [expr {$enc & 0x44}]
        if {$x == 0x04} { append desc l } elseif {$x == 0x44} { append desc L }
        set x [expr {$enc & 0x88}]
        if {$x == 0x08} { append desc r } elseif {$x == 0x88} { append desc R }
        set x [expr {$enc & 0x11}]
        if {$x == 0x01} { append desc u } elseif {$x == 0x11} { append desc U }
        set x [expr {$enc & 0x22}]
        if {$x == 0x02} { append desc d } elseif {$x == 0x22} { append desc D }
        return $desc
    }

    apply [list {} {
        variable charlightheavy
        variable lightheavybox
        variable lightbox
        variable heavybox
        set conv {}

        foreach {char desc} [array get charlightheavy] {
            set k [encode $desc]
            set lightheavybox($k) $char
            if {($k >> 4) == 0} {
                set lightbox($k) $char
            }
            if {($k >> 4) == ($k & 0b1111)} {
                set heavybox([expr {$k & 0b1111}]) $char
            }
        }
        for {set i 0} {$i < 256} {incr i} {
            if {![info exists lightheavybox($i)]} {
                set k [expr {$i & (($i << 4) | 0b1111)}]
                set lightheavybox($i) $lightheavybox($k)
            }
        }
    } [namespace current]]

    proc ofdir {d} {
        return [dict get {^ 1 v 2 < 4 > 8} $d]
    }
    proc lightofdir {d} {
        return [dict get {^ 1 v 2 < 4 > 8} $d]
    }
    proc heavyofdir {d} {
        return [dict get {^ 17 v 34 < 68 > 136} $d]
    }

    proc hasup {enc} {return [expr {($enc & 0x1) != 0}]}
    proc hasdown {enc} {return [expr {($enc & 0x2) != 0}]}
    proc hasleft {enc} {return [expr {($enc & 0x4) != 0}]}
    proc hasright {enc} {return [expr {($enc & 0x8) != 0}]}
    proc hasvertical {enc} {return [expr {($enc & 0x3) != 0}]}
    proc hashorizontal {enc} {return [expr {($enc & 0xc) != 0}]}

    proc Coerce_enc {argslist} {
        switch [llength $argslist] {
            0 {
                error "No arguments given"
            }
            1 {
                set enc [lindex $argslist 0]
                if {![string is integer -strict $enc]} {
                    set enc [encode $enc]
                }
                return $enc
            }
            default {
                return [encode {*}$argslist]
            }
        }
    }

    proc get {args} {
        variable lightheavybox
        return $lightheavybox([Coerce_enc $args])
    }

    # ASCII approximations using | - and +
    proc getascii {args} {
        set enc [Coerce_enc $args]
        if {$enc & 0x3} {
            return [expr {($enc & 0xc) ? "+" : "|"}]
        } else {
            return [expr {($enc & 0xc) ? "-" : " "}]
        }
    }

    apply [list {} {
        set test_cases {}
        lappend test_cases \
            "┌┬─┐" \
            [string cat [get v >] [get < > v] [get < >] [get v <]]
        lappend test_cases \
            "┌┬─┐" \
            [string cat [get rd] [get lrd] [get lr] [get ld]]
        lappend test_cases \
            "││ │" \
            [string cat [get v ^] [get v^] " " [get ^v]]
        lappend test_cases \
            "├┼─┤" \
            [string cat [get ^v >] [get < ^ v >] [get ><] [get < ^v]]
        lappend test_cases \
            "└┴─┘" \
            [string cat [get > ^] [get <> ^] [get > <] [get < ^]]

        set errors 0
        foreach {expected actual} $test_cases {
            if {$expected ne $actual} {
                puts "boxchars: [list $expected] != [list $actual]"
                incr errors
            }
        }
        if {$errors > 0} {
            error "Errors in boxchars self-test"
        }
    } [namespace current]]
}
