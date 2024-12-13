
package require aoc::tools

# Define B : ℕ -> Seq(ℕ)
#  * ℕ = {0, 1, 2, ...}
#  * Seq(ℕ) is the set of sequences of ℕ
#
#  B(0) = [1]
#  B(s) where s = a*10^n + b, and 10^{n-1} <= a < 10^n and 0 <= b < 10^n
#   = [a, b]
#   - an integer with an even number of digits in base-10 is split into
#     the 'upper half' and the 'lower half'.  Leading zeros are discarded
#     from the lower half.
#  Otherwise,
#   B(s) = [2024*s]
#
# We define B(S) where S is a sequence as
#  B([a, b, ..., c]) = B(a) / B(b) / ... / B(c)
#   (where we use / to mean sequence concatenation)
# Obv, B(S) is (distributive?) over concatenation.
#
# We also define B(S, n) as the iterated versions:
#  B(S, 0) = S, B(S, 1) = B(S), B(S, 2) = B(B(S)), etc.
# Also, B(s,n) = B([s], n).
#
# B(0, 1) = [1]
# B(0, 2) = B([1], 1) = B(1,1) = B(1) = 2024
# B(0, 3) = B(1, 2) = B(2024, 1) = [20, 24]
# B(0, 4) = B(20, 1) / B(24, 1)
# B(20, 1) = [2, 0]  B(24,1) = [2, 4]
# -> B(0, 4) = [2, 0, 2, 4]
# we then have B(0, 5) = B(2,1) / B(0,1) / B(2,1) / B(4,1)

# We're concerned with the length of the sequence; let
#   L(s) = |B(s)|,  L(S) = |B(S)|, L(S,n) = |B(S,n)|, L(s,n)=|B(s,n)|
#
# Note that L([a,b,...,c]) = L(a) + L(b) + L(c)
#
# L(0,4) = L(20,1) + L(24,1)
#        = |[2,0]| + |[2,4]| = 4
# L(0,5) = L(20,2) + L(24,2)
#        = L(2,1) + L(0,1) + L(2,1) + L(4,1)  <- no 'double-size' ints
#
# Let D = subset of ℕ which have an even number of decimal digits
# L(n, 1) = 1 when n is not in D
#         = 2 when n is in D

# B(0, 2) = [2024]
# B(1, 2) = [20, 24]
# B(2, 2) = [40, 48]
# B(3, 2) = [60, 72]
# B(4, 2) = [80, 96]
# B(5, 2) = [20482880]
# B(6, 2) = [24579456]
# B(7, 2) = [28676032]
# B(8, 2) = [32772608]
# B(9, 2) = [36869184]
#
# B(10, 2) = B(1,1) / B(0,1)
# B(10+k, 2) = B(1,1) / B(k, 1)

# L(28, 75) = |B(28, 75)|
#   = |B(2, 74)| + |B(8, 74)|
#   = L(2, 74) + L(8, 74)
#   = L(4048, 73) + L(16192, 73)
#   = L(40,72) + L(48,72) + L(32772608, 72)
#   = L(4,71) + L(0, 71) + L(4, 71) + L(8, 71)
#      + L(3277, 71) + L(2608, 71)
#   = 2*L(8096,70) + L(1,70) + L(16192,70) + L(32,70) + L(77,70)
#       + L(26,70) + L(8, 70)
#   = 2*L(80,69) + 2*L(96,69) + L(2024,69) + L(32772608,69) + 2*L(7,69)
#       + L(2,69) + L(6,69) + L(16192,69)

# L(8, n) = L(16192, n-1) = L(32772608, n-2)
#   = L(3277, n-3) + L(2608, n-3)
#   = L(32, n-4) + L(77, n-4) + L(26, n-4) + L(8, n-4)
#   = L(3,n-5) + 2*L(2,n-5) + 2*L(7,n-5) + L(6,n-5) + L(8, n-4)
#
# L(0, n) = L(1,n-1)
# L(1, n) = 2*L(2,n-3) + L(0,n-3) + L(4,n-3)
# L(2, n) = 2*L(4,n-3) + L(0,n-3) + L(8,n-3)
# L(3, n) = L(6,n-3) + L(0,n-3) + L(7,n-3) + L(2,n-3)
# L(4, n) = L(8,n-3) + L(0,n-3) + L(9,n-3) + L(6,n-3)
#
# L(0, n) = L(1, n-1) = 2*L(2,n-4) + L(0,n-4) + L(4,n-4)
#
# L(5, n) = L(10120, n-1) = L(20482880, n-2)
#   = L(2048, n-3) + L(2880, n-3)
#   = 2*L(2,n-5) + 2*L(0, n-5) + L(4, n-5) + 3*L(8, n-5)
# L(6, n) = L(12144, n-1) = L(24579456, n-2)
#   = L(2,n-5) + 2*L(4,n-5) + 2*L(5,n-5) + L(7, n-5) + L(9,n-5) + L(6,n-5)
# L(7, n) = L(14168, n-1) = L(28676032, n-2)
#   = 2*L(2,n-5) + L(8,n-5) + 2*L(6,n-5) + L(7,n-5) + L(0, n-5) + L(3,n-5)
# L(9, n) = L(18216, n-1) = L(36869184, n-2)
#   = L(3,n-5) + 2*L(6,n-5) + 2*L(8,n-5) + L(9,n-5) + L(1,n-5) + L(4,n-5)

# Coefficients of L(i,n-3) in L(k,n) expansion
# k\i   0    1    2    3    4   5    6   7   8   9
#   1   1         2         1
#   2   1                   2                1
#   3   1         1                  1   1
#   4   1                            1       1   1
#
# Coefficients of L(i,n-5) in L(k,n) expansion
# k\i   0    1    2    3    4   5    6   7   8   9
#   5   2         2         1                3
#   6             1         2   2    1   1       1
#   7   1         2    1        1    2   1   1
#   8             2    1             1   2            + L(8,n-4)
#   9        1         1    1        2       2   1
#


# L(0,n) = L([0, 2∙2, 4], n-4)
#        = L(0,n-4) + 2*L(2,n-4) + L(4,n-4)
#        = L([0, 2∙2, 4], n-8) + 2*L([0, 2∙4, 8], n-7) + L([0,6,8,9],n-7)
#        = L([0, 2∙2, 4], n-8) + 2*L(0,n-7) + 2*L([2∙4, 6,2∙8,9], n-7)
#        = L([0, 2∙1, 2∙2, 4], n-8) + 2*L([2∙4, 6, 2∙8, 9], n-7)
#        = L([0,2∙2,4],n-12)
#           + 2*L([0,2∙2,4],n-11) + 2*L([0,2∙4,8],n-11)
#           + L([0,6,8,9],n-11) + 4*L([0,6,8,9],n-10)
#           + 2*L([2,2∙4,2∙5,6,7,9],n-12) + 4*L([2∙2,3,6,2∙7],n-12)
#           + 4*L(8, n-11) + 2*L([1,3,4,2∙6,2∙8,9],n-12)
#        = L([4∙0,4∙6,4∙8,4∙9],n-10)
#          + L([3∙0,4∙2,4∙4,6,6∙8,9],n-11)
#          + L([2∙1,10∙2,6∙3,6∙4,4∙5,10∙6,10∙7,4∙8,3∙9],n-12)
#  L([0:1 2:2 4:1],n-4) = L(1,n-5) + L([2:2 4:1],n-4)
#
#

# All the expansions can be written as
#  L(d, n) = \sum(k=k0..k1, \sum(i=0..9, c_{ik}*L(i, n-k)))
#
# We represent this in Tcl as a dict with the depth (k) as the key,
# and the values are { c_0k c_1k c_2k ... c_9k }.
#
# So,  L(0,n) is {0 {1 0 0 0 0  0 0 0 0 0}}
#      L([0,2∙2,4], n-4) is {4 {1 0 2 0 1 0 0 0 0 0}}

namespace eval stones {
    namespace export {[a-z]*}

    proc term {k i coeff} {
        set t [terms::Zero_term]
        lset t $i $coeff
        return [dict create $k $t]
    }
    proc digits {} {
        return [list 0 1 2 3 4 5 6 7 8 9]
    }

    # An expansion is represented as a dict from the depth
    # (the k in n-k) to a list of the 10 coefficients.
    # The canonical form is sorted in order of the depth.
    namespace eval terms {
        namespace path [list [namespace parent]]

        namespace export {[a-z]*}
        namespace ensemble create -prefixes 0

        proc Zero_term {} {
            return [list 0 0 0 0 0  0 0 0 0 0]
        }

        proc Term {c0 c1 c2 c3 c4 c5 c6 c7 c8 c9} {
            return [list $c0 $c1 $c2 $c3 $c4 $c5 $c6 $c7 $c8 $c9]
        }
        proc Term_by_coeffs {args} {
            if {[llength $args] % 2 != 0} {
                error "odd number of arguments"
            }
            set term [Zero_term]
            foreach {i c} $args {
                lset term $i [expr {$c + [lindex $term $i]}]
            }
            return $term
        }

        proc Add_terms {term1 term2} {
            return [lmap c1 $term1 c2 $term2 {expr {$c1 + $c2}}]
        }
        proc Mul_term {term m} {
            return [lmap c $term {expr {$c * $m}}]
        }
        proc Term_is_zero {term} {
            foreach c $term {
                if {$c != 0} {
                    return 0
                }
            }
            return 1
        }
        proc Check_digit {i} {
            if {$i ni {0 1 2 3 4 5 6 7 8 9}} {
                error "$i is not a digit"
            }
        }

        proc make {args} {
            if {[llength $args] % 2 != 0} {
                error "odd number of arguments"
            }
            set bydepth {}
            foreach {k term} $args {
                if {[lindex $term 0] eq "T"} {
                    # compressed  {T {coeff i} i ...}
                    set t [Zero_term]
                    foreach ci [lrange $term 1 end] {
                        if {[llength $ci] > 1} {
                            lassign $ci c i
                        } else {
                            set i $ci
                            set c 1
                        }
                        Check_digit $i
                        lset t $i [expr {$c + [lindex $t $i]}]
                    }
                    set term $t
                }
                if {[dict exists $bydepth $k]} {
                    set t [Add_terms $term [dict get $bydepth $k]]
                } else {
                    set t $term
                }
                if {![Term_is_zero $t]} {
                    dict set bydepth $k $t
                }
            }
            return [normalize $bydepth]
        }

        proc remove_zeros {terms} {
            set zeroterms {}
            dict for {k term} $terms {
                if {[Term_is_zero $term]} {
                    lappend zeroterms $k
                }
            }
            return [dict remove $terms {*}$zeroterms]
        }

        proc normalize {terms} {
            return [lsort -integer -index 0 -stride 2 $terms]
        }
        proc canonicalize {terms} {
            return [normalize [remove_zeros $terms]]
        }

        proc Format_coeff {i c} {
            if {$c == 0} {
                return ""
            } elseif {$c == 1} {
                return $i
            } else {
                return "${c}∙${i}"
            }
        }

        proc repr {terms} {
            set result {}
            foreach {k term} [canonicalize $terms] {
                set termrepr {}
                set i -1
                foreach c $term {
                    incr i
                    if {$c != 0} {
                        if {$termrepr ne ""} {append termrepr ","}
                        append termrepr [Format_coeff $i $c]
                    }
                }
                if {$termrepr eq ""} {
                    # Add it something to show we've got a zero term
                    lappend result "0*L(\[\], n-$k)"
                } else {
                    lappend result "L(\[$termrepr\], n-$k)"
                }
            }
            set result [join $result " + "]
            if {$result eq ""} {
                return 0
            } else {
                return $result
            }
        }

        proc get_depth {terms k} {
            return [dict getdef $terms $k [Zero_term]]
        }
        proc get_coeff {terms k i} {
            set t [get_depth $terms $k]
            return [lindex $t $i]
        }

        # Multiply all coefficients by m
        # Optionally also adds to the depth
        proc mul {terms m {kshift 0}} {
            if {$m == 1} {
                return [adddepth $terms $kshift]
            } elseif {$m == 0} {
                return {}
            } else {
                return [dict map {k t} $terms {
                    incr k $kshift
                    Mul_term $t $m
                }]
            }
        }

        # Add a constant to the depth
        # Basically, change an expansion for L(_, n) to L(_, n-kshift).
        proc adddepth {terms kshift} {
            if {$kshift == 0} {
                return $terms
            }
            return [dict map {k t} $terms {
                incr k $kshift
                set t
            }]
        }

        proc add_term {terms k term} {
            if {[dict exists $terms $k]} {
                set t [dict get $terms $k]
                set t [Add_terms $t $term]
            } elseif {[Term_is_zero $term]} {
                return $terms
            } else {
                set t $term
            }
            dict set terms $k $t
            return $terms
        }
        proc add_terms {terms args} {
            if {[llength $args] % 2 != 0} {
                error "odd number of extra arguments"
            }
            foreach {k t} $args {
                set terms [add_term $terms $k $t]
            }
            return $terms
        }

        # Add two expansions
        proc add {terms1 terms2} {
            set result {}
            dict for {k term1} $terms1 {
                if {[dict exists $terms2 $k]} {
                    set term2 [dict get $terms2 $k]
                    set t [Add_terms $term1 $term2]
                } else {
                    set t $term1
                }
                dict set result $k $t
            }
            return [dict merge $terms2 $result]
        }

        proc update_sum {termsvar args} {
            upvar 1 $termsvar terms
            foreach ts $args {
                set terms [add $terms $ts]
            }
            return
        }

        # expand_depth_coeff k i replterms terms
        # -> Replace c_ik*L(i,k) with c_ik*(replacement terms)
        # So, we can expand (say) L(0, 5) with L([1],4)
        proc expand_depth_coeff {k i repl terms} {
            if {![dict exists $terms $k]} {
                return $terms
            }
            set termk [dict get $terms $k]
            set c_ik [lindex $termk $i]
            if {$c_ik == 0} {
                return $terms
            }
            # Remove c_ik*L(i,k) from terms
            lset termk $i 0
            if {[Term_is_zero $termk]} {
                dict unset terms $k
            } else {
                dict set terms $k $termk
            }
            return [add $terms [mul $repl $c_ik $k]]
        }

        # expand_ceoff i replterms terms
        # Replace c_ik*L(i,k) for all k with c_ik*(replacement)
        proc expand_coeff {i repl terms} {
            set result {}
            dict for {k term} $terms {
                set c_ik [lindex $term $i]
                lset term $i 0
                if {![Term_is_zero $term]} {
                    set result [add_term $result $k $term]
                }
                if {$c_ik != 0} {
                    set p [mul $repl $c_ik $k]
                    set result [add $result $p]
                }
            }
            return $result
        }

        proc replace_nonzero_term {termsvar k termvar script} {
            upvar 1 $termsvar terms $termvar term
            if {[dict exists $terms $k]} {
                set term [dict get $terms $k]
                dict unset terms $k
                if {![Term_is_zero $term]} {
                    set term [uplevel 1 $script]
                    if {![Term_is_zero $term]} {
                        dict set terms $k $term
                    }
                }
            }
        }

    }

    # L(0,n) -> L(1,n-1)
    proc expand_0 {terms {k {}}} {
        set repl [term 1 1 1]
        if {$k eq {}} {
            set result [terms expand_coeff 0 $repl $terms]
        } else {
            set result [terms expand_depth_coeff $k 0 $repl $terms]
        }
        return [terms normalize $result]
    }

    # repl is assumed to be a replacement for L(i,n) (make 0 {T i})
    proc subst {i repl terms {k {}}} {
        if {$k eq {}} {
            set result [terms expand_coeff $i $repl $terms]
        } else {
            set result [terms expand_depth_coeff $k $i $repl $terms]
        }
        return [terms normalize $result]
    }

    array set substs {}
    # L(0, n) = L(1,n-1)
    set substs(0) [term 1 1 1]
    # L(1, n) = 2*L(2,n-3) + L(0,n-3) + L(4,n-3)
    set substs(1) [terms make 3 {T 0 {2 2} 4}]
    # L(2, n) = 2*L(4,n-3) + L(0,n-3) + L(8,n-3)
    set substs(2) [terms make 3 {T 0 {2 4} 8}]
    # L(3, n) = L(6,n-3) + L(0,n-3) + L(7,n-3) + L(2,n-3)
    set substs(3) [terms make 3 {T 0 2 6 7}]
    # L(4, n) = L(8,n-3) + L(0,n-3) + L(9,n-3) + L(6,n-3)
    set substs(4) [terms make 3 {T 0 6 8 9}]

    # L(5, n) = L(10120, n-1) = L(20482880, n-2)
    #   = L(2048, n-3) + L(2880, n-3)
    #   = 2*L(2,n-5) + 2*L(0, n-5) + L(4, n-5) + 3*L(8, n-5)
    set substs(5) [terms make 5 {T {2 0} {2 2} 4 {3 8}}]
    # L(6, n) = L(12144, n-1) = L(24579456, n-2)
    #   = L(2,n-5) + 2*L(4,n-5) + 2*L(5,n-5) + L(7, n-5) + L(9,n-5) + L(6,n-5)
    set substs(6) [terms make 5 {T 2 {2 4} {2 5} 6 7 9}]
    # L(7, n) = L(14168, n-1) = L(28676032, n-2)
    #   = 2*L(2,n-5) + L(8,n-5) + 2*L(6,n-5) + L(7,n-5) + L(0, n-5) + L(3,n-5)
    set substs(7) [terms make 5 {T 0 {2 2} 3 {2 6} 7 8}]
    # L(9, n) = L(18216, n-1) = L(36869184, n-2)
    #   = L(3,n-5) + 2*L(6,n-5) + 2*L(8,n-5) + L(9,n-5) + L(1,n-5) + L(4,n-5)
    set substs(9) [terms make 5 {T 1 {2 6} 3 4 8 9}]
    # Odd one out
    # L(8, n) = L(3,n-5) + 2*L(2,n-5) + 2*L(7,n-5) + L(6,n-5) + L(8, n-4)
    set substs(8) [terms make 4 {T 8} 5 {T {2 2} 3 6 {2 7}}]

    proc subst_chain {terms args} {
        variable substs
        foreach arg $args {
            if {[llength $arg] > 1} {
                lassign $arg k i
                if {$i eq "*"} {
                    set t [terms get_depth $terms $k]
                    dict unset terms $k
                    foreach c $t i [digits] {
                        if {$c != 0} {
                            set terms [terms add $terms \
                                           [terms mul $substs($i) $c $k]]
                        }
                    }
                    continue
                }
            } else {
                set i $arg
                set k {}
            }
            set terms [subst $i $substs($i) $terms $k]
        }
        return [terms normalize $terms]
    }

    proc Subst_scheme_term {scheme term} {
        set result {}
        dict for {i irepl} $scheme {
            set c [lindex $term $i]
            if {$c != 0} {
                terms update_sum result [terms mul $irepl $c]
            }
        }
        return $result
    }

    proc subst_scheme {scheme terms {ks {}}} {
        if {[string is dict $scheme]} {
            set replacements $scheme
        } else {
            upvar 1 $scheme schemearr
            set replacements [array get schemearr]
        }
        set result {}
        if {[llength $ks] == 0} {
            set ks [dict keys $terms]
        }
        set ks [lsort -integer -unique $ks]
        foreach k $ks {
            if {[dict exists $terms $k]} {
                set term [dict get $terms $k]
                dict unset terms $k
                set tresult [Subst_scheme_term $replacements $term]
                terms update_sum result [terms adddepth $tresult $k]
            }
        }
        # Add the terms in terms that weren't modified
        return [terms normalize [terms add $result $terms]]
    }

    set scheme1 [array get substs]
    dict set scheme1 0 [subst 1 $substs(1) $substs(0)]

    proc subst_lower {scheme terms} {
        set keys [lsort -integer [dict keys $terms]]
        set max [lindex $keys end]
        set sub5 {}
        foreach k $keys {
            if {$k + 5 <= $max} {
                lappend sub5 $k
            } else {
                break
            }
        }
        if {[llength $sub5] > 0} {
            set terms [subst_scheme $scheme $terms $sub5]
        }
        return $terms
    }

    proc subst_adaptive {scheme terms} {
        set terms [subst_scheme $scheme $terms]
        return [subst_lower $scheme $terms]
    }
}

proc cmditer {n cmd x} {
    set i [lsearch -exact $cmd %%]
    if {$i != -1} {
        set prefix [lrange $cmd 0 [expr {$i-1}]]
        set suffix [lrange $cmd [expr {$i+1}] end]
    } else {
        set prefix $cmd
        set suffix {}
    }
    for {set i 0} {$i < $n} {incr i} {
        set x [uplevel 1 [list {*}$prefix $x {*}$suffix]]
    }
    return $x
}

# L[n-k, n-k1 ...] means we have terms in terms of n-k, n-k1, etc.
#
# L(0,n) -> L[n-4] -> L[     n-7, n-8]
# L(1,n) -> L[n-3] -> L[n-6, n-7     ]
# L(2,n) -> L[n-3] -> L[n-6, n-7, n-8]
# L(3,n) -> L[n-3] -> L[n-6, n-7, n-8]
# L(4,n) -> L[n-3] -> L[     n-7, n-8]
# L(5,n) -> L[n-5] -> L[n-8, n-9, n-10]
# L(6,n) -> L[n-5] -> L[n-8,      n-10]
# L(7,n) -> L[n-5] -> L[n-8, n-9, n-10]
# L(8,n) -> L([8],n-4) + L[n-5] -> L[n-8, n-9, n-10]
# L(9,n) -> L[n-5] -> L[n-8, n-9, n-10]

# L(0,n) -> L[10, 11, 12] -> L[14,15,16,17] -> L[18,19,20,21,22]
# L(1,n) -> L[9, 10, 11]  -> L[13,14,15,16,17] -> L[18,19,20,21,22]
# L(2,n) -> L[10,11,12,13] -> L[14,15,16,17,18] -> L[19,20,21,22,23]
# L(3,n) -> L[9,10,11,12,13] -> L[14,15,16,17,18] -> L[19,20,21,22,23]
# L(4,n) ->

# L(0,n) -> L[      68,69,70,71,72]
# L(1,n) -> L[   67,68,69,70,71]
# L(2,n) -> L[         69,70,71,72,73]
# L(3,n) -> L[         69,70,71,72,73]
# L(4,n) -> L[         69,70,71,72,73]
# for k=5,6,7,8,9
# L(k,n) -> L[66,67,68,69,70]
#        -> L[              71,72,73,74,75]

# 14
# L(1,n) -> L[         62,63,64,65,66]
# L(2,n) -> L[               64,65,66,67,68]
# L(2,n) -> L[59,60,61,62,63]
# L(9,n) -> L[      61,62,63,64,65]

# If we know (most of) L(i,k) for i=0..9, k=2..10, then
# we can determine L(i,73)


# Working the other way
# L(0, n) = L(1,n-1)
#  -> L(0, n+1) = L(1, n)
# L(1, n) = 2*L(2,n-3) + L(0,n-3) + L(4,n-3)
#  -> L(1,n+3) = 2*L(2,n) + L(0,n) + L(4,n)
#
# L(28, n+1) = L(2, n) + L(8, n)
# L(a*10 + b, n+1) = L(a, n) + L(b, n)   for a=1..9, b=0..9
# L(a*1000 + b*100 + c*10 + d, n)        a=1..9, b,c,d=0..9
#   = L(a*10+b, n-1) + L(c*10+d, n-1)
#   = L(a,n-2) + L(b,n-2) + [c!=0]L(c, n-2) + L(d, n-2)

# 0 -> 1 -> 2024 -> {20,24} -> {2|2,0,4} -> {4048|2,1,8096|4}



return

# An integer k >= 1 has D(k)=m digits in its decimal expansion if
#    10^(m-1) <= k < 10^m.
#   or  D(k)-1 <= log_10 k < D(k)
#  --> D(k) = 1 + floor(log_10(k))
# To have an odd number of digits, then, m=2n+1 and
#    10^2n <= k < 10^(2n+1) = 10*10^2n
# For an even number of digits m=2n',
#    10^(2n'-1) <= k < 10^2n'

# If we multiply by 2024,
#   2024*10^2n <= 2024*k < 20240 * 10^2n
# Note that 2024*10^2n = 2.024*10^{2(n+2)-1}.

# If 2024*k < 10000 * 10^2n = 10^{2(n+2)}, then 2024*k has an odd
# number of digits, since it's bounded by
#     10^{2(n+2)-1} < 2024*k < 10^{2(n+2)}
#

# D(k) = 1 + floor(lg(k))
# D(2024*k) = 1 + floor(lg(2024*k))
#           = 1 + floor(lg(2024) + lg(k))
#           = 4 + floor(lg(2.024) + lg(k))
#
# If k = x*10^D(k), where 0.1 <= x < 1, then lg(k) = D(k) + lg(x),
# and -1 <= lg(x) < 0.
# D(2024*k) = 4 + floor(lg(2.024) + D(k) + lg(x))
#           = D(k) + 4 + floor(lg(2.024*x))
# Note that 0.2024 <= 2.024*x < 2.024
#
# If 0.2024 <= 2.024*x < 1 (which implies 0.1 <= x < 0.49407..)
# then -1 < lg(2.024*x) < 0 and floor(lg(2.024*x)) = -1
# So D(2024*k) = D(k) + 3
# ==> If D(k) is odd, then D(2024*k) is even.

# If 1 <= 2.024*x < 2.024  (0.49407.. <= x < 1),
# then 0 <= lg(2.024*x) < 1 and floor(lg(2.024*x)) = 0
# So D(2024*k) = D(k) + 4
# ==> If D(k) is odd, then D(2024*k) is also odd.
#   Further: 2024*k = 2024*x*10^D(k)  = (0.2024*x)*10^(D(k)+4)
#   We have then 0.1 <= 0.2024*x < 0.2024 < 1.
#   So we can apply the calculation again:
#   D(2024*(2024*k)) = D(2024*k) + 4 + floor(lg(2.024*(0.2024*x)))
#   This time, the first condition holds (as 0.2024 < 0.4907),
#   and D(2024*(2024*k)) = D(2024*k) + 3 = D(k) + 7.
#   ==> multiplying by 2024 twice gives an integer with an even number
#   of digits.

# Conclusion: if k has an odd number of digits, we need to multiply
# by 2024 at most twice to arrive at an integer with an even number
# of digits.  That integer will have at most 7 more digits than k.
#
# D(k) = 2n+1, then either
# * D(2024*k) = D(k)+3 = 2n+4 = 2(n+2), in which case the integers in
#   B(B(k)) will have at most n+2 digits,
# * or D(2024*k) = D(k)=4, and D(2024*2024*k) = 2n+1 + 7 = 2(n+4),
#   in which case the integers in B(B(B(k))) will have at most n+4 digits.
#
# 1 digit -> *2024 -> 4 digits -> 2 digits
#        -         -> 5 digits -> *2024 -> 8 digits -> 4 digits
# 3 digits -> *2024 -> 6 digits -> 3 digits
#                   -> 7 digits -> *2024 -> 10 digits -> 5 digits
# 5 digits -> 8 digits -> 4 digits
#          -> 9 digits -> 12 digits -> 6 digits
# 7 digits -> 10 digits -> 5 digits
#          -> 11 digits -> 14 digits -> 7 digits
# 9 digits -> 12 digits -> 6 digits
#          -> 13 digits -> 16 digits -> 8 digits
# 11 digits -> 14 digits -> 7 digits
#           -> 15 digits -> 18 digits -> 9 digits
#
# IF we consider the process of multiplying by 2024 until we have
# an even number of digits, then splitting the even-number-of-digits
# integers in half as one, we can compute the length of the longest
# possible resulting integer in terms of the number of input digits:
#
#      input (n)         longest possible (m; largest odd factor of (n-1)/2+4)
#        1                     1
#        3                     5
#        5                     3
#        7                     7
#        9                     3
#       11                     9
#
# (n-1)/2+4 = (n+7)/2
# For n = 2i+1, (n-1)/2+4 = i+4
# For n = 4i+1, (n-1)/2+4 = 2i+4 = 2(i+2) so m <= i+2
#     n = 4i+3, (n-1)/2+4 = 2i+5          so m <= 2i+5
#

# IN OUR CASE, n = 7.
