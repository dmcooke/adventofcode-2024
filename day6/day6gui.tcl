#!/usr/bin/tclsh9.0

source day6.tcl

set debug_log 0

::oo::class create Task {
    # Does the computation exist (suspended or not)
    variable active
    # Should we not compute the next step?
    variable paused
    # How long (in ms) between steps
    variable delaytime
    # Number of steps allowed to run (may be inf)
    variable steps_available
    variable steps_per_slice

    variable idle_callback_id delay_callback_id

    constructor {} {
        if {[llength [self next]]} { next }
        set active 0
        set paused 0
        set delaytime 0
        set steps_available inf
        set steps_per_slice 1
        set idle_callback_id ""
        set delay_callback_id ""
    }

    # Set up the task
    method Create_task {} {
    }

    # Do what's needed to teardown a task
    method Stop_task {} {
    }

    # Return 0 if calculation is done
    method Execute_step {} {
    }

    method observed_state {} {
        if {!$active} {
            return stopped
        }
        if {$paused} {
            return paused
        } else {
            return running
        }
    }

    method start {} {
        set paused 0
        if {!$active} {
            my Create_task
            set active 1
        }
        my Ensure_scheduled
    }

    method stop {} {
        set paused 1
        if {$active} {
            my Cancel
            my Stop_task
            set active 0
        }
    }

    method pause {} {
        set paused 1
        my Cancel
    }

    method unpause {} {
        set paused 0
        my Ensure_scheduled
    }

    method set_delaytime {thedelaytime} {
        set delaytime $thedelaytime
    }
    method set_steps_to_run {n} {
        if {$n eq {}} {
            set steps_available inf
        } else {
            set steps_available $n
        }
        if {$steps_available > 0} {
            my Ensure_scheduled
        }
    }
    method set_steps_per_slice {n} {
        if {$n <= 0} { error "Nonpositive number of steps" }
        set steps_per_slice $n
    }

    method Do_one_slice {} {
        set delay_callback_id ""
        if {$paused || !$active} { return }
        set nsteps [my Take_slice_steps]
        if {$nsteps == 0} {
            set paused 1
        } else {
            while {$nsteps > 0} {
                incr nsteps -1
                if {![my Execute_step]} {
                    my Return_slice_steps $nsteps
                    set active 0
                    my Stop_task
                    return
                }
            }
            my Schedule
        }
        return
    }

    # We work on the honour system here
    method Take_slice_steps {} {
        if {$steps_available >= inf} {
            return $steps_per_slice
        } elseif {$steps_available > 0} {
            set n [expr {min($steps_available, $steps_per_slice)}]
            set steps_available [expr {$steps_available - $n}]
            return $n
        } else {
            return 0
        }
    }
    method Return_slice_steps {nsteps} {
        if {$nsteps > 0} {
            set steps_available [expr {$steps_available + $nsteps}]
        }
    }

    method Consume_one_work_unit {} {
        if {$steps_available >= inf} {
            return 1
        } elseif {$steps_available > 0} {
            incr steps_available -1
            return 1
        } else {
            return 0
        }
    }

    method Ensure_scheduled {} {
        if {$idle_callback_id eq "" && $delay_callback_id eq ""} {
            my Schedule
        }
    }

    method Cancel {} {
        if {$idle_callback_id ne ""} {
            after cancel $idle_callback_id
            set idle_callback_id ""
        }
        if {$delay_callback_id ne ""} {
            after cancel $delay_callback_id
            set delay_callback_id ""
        }
    }

    method Schedule {} {
        if {!$active} { return }
        set my [namespace which my]
        set idle_callback_id [::after idle [list $my After_idle]]
    }
    method After_idle {} {
        set idle_callback_id ""
        set my [namespace which my]
        set delay_callback_id [::after $delaytime $my Do_one_slice]
    }

}

::oo::class create ComputationTask {
    superclass -append ::Task

    variable observers
    variable create_task_command
    variable corocommand
    variable coroutine_done

    constructor {thecreate_task_command} {
        set observers {}
        set create_task_command $thecreate_task_command
        set corocommand [namespace current]::do_one_step
        set coroutine_done 0
        next
    }

    method Create_coroutine {} {
        set corocommand [namespace current]::do_one_step
        coroutine $corocommand {*}[mymethod Coroutine_impl]
    }
    method Coroutine_impl {} {
        set coroutine_done 0
        try {
            return [{*}$create_task_command]
        } finally {
            set coroutine_done 1
        }
    }

    method Create_task {} {
        variable active
        my Create_coroutine
        trace add command do_one_step {delete} \
            [mymethod Trace_coroutine_command]
        set active 1
        my Notify_observers reset
    }

    method Stop_task {} {
        if {[namespace which $corocommand] ne ""} {
            rename $corocommand {}
        }
    }
    method Execute_step {} {
        set datum [$corocommand]
        if {$coroutine_done} {
            my Notify_observers done
            return 0
        } else {
            my Notify_observers update $datum
            return 1
        }
    }

    method Trace_coroutine_command {oldname newname op} {
        if {$op ne "delete"} { return }
        variable active
        set active 0
    }


    method add_observer {cmd args} {
        lappend observers [list $cmd {*}$args]
    }

    # Messages sent to observers:
    # update <datum>   where <datum> is the value yielded by the computation
    # done             computation finished normally
    # reset

    method Notify_observers {msg args} {
        foreach obs $observers {
            uplevel #0 [list {*}$obs $msg {*}$args]
        }
    }

}

namespace eval ::gui {
    variable stop 0
    variable grid
    variable initial_guard

    variable guardpos ""
    variable walkedcount "Covered: 0"
    variable covered
    array set covered {}

    ::Problem create prob input.txt

    ::ComputationTask create model [list ::gui::prob walk_the_guard_coro]
    #model set_delaytime 100
    model set_steps_per_slice 1

    proc update_canvas {msg args} {
        switch $msg {
            update {
                set datum [lindex $args 0]
                lassign $datum gp gdir nsteps
                add_to_canvas $gp $gdir $nsteps
            }
            done { }
            reset {
                reset_canvas
            }
        }
    }
    model add_observer [namespace which update_canvas]

    proc set_walked_count {n} {
        variable walkedcount
        set walkedcount [format "Covered: %d" $n]
    }

    proc add_to_canvas {gp gdir nsteps} {
        variable covered
        step_spinner .bb.spinner
        set points [point enumerate $gp $gdir $nsteps]
        foreach p $points {
            lassign $p x y
            set tag P$x/$y
            set covered($tag) 1
            .c itemconfigure "$tag && ground" -fill ""
            .c itemconfigure "$tag && cover" -fill red -outline red
        }
        variable guardpos
        set guardpos [format "(%d, %d)" {*}$gp]
        set_walked_count [array size covered]
    }

    proc reset_canvas {} {
        variable covered
        unset covered
        array set covered {}
        .c itemconfigure cover -fill "" -outline ""
        .c itemconfigure ground -fill black
        variable guardpos ""
        set_walked_count 0
    }

    variable startstop "Start"

    proc update_startstop_button {msg args} {
        variable startstop
        switch $msg {
            update {
                if {$startstop ne "Stop"} {
                    set startstop "Stop"
                }
            }
            done {
                set startstop "Start"
            }
            reset {
                set startstop "Stop"
            }
        }
    }
    model add_observer [namespace which update_startstop_button]

    proc do_startstop {} {
        switch [model observed_state] {
            inhandler {}
            running {
                model pause
            }
            stopped {
                model start
            }
            paused {
                model unpause
            }
        }
    }
    proc do_reset {} {
        model stop
    }

    variable tick 0
    variable ticklabel ""

    proc update_tick {msg args} {
        variable tick
        variable ticklabel
        switch $msg {
            reset { set tick 0 }
            done { }
            update { incr tick }
        }
        set ticklabel [format "Tick %d" $tick]
    }
    model add_observer [namespace which update_tick]

    proc make_spinner {path} {
        canvas $path -height 20 -width 20
        $path create line 10 20 10 0 -tags arrow \
            -arrow last -fill black -width 1
    }
    proc step_spinner {path} {
        $path rotate arrow 10 10 10
    }
}


proc ::gui::gui {} {
    package require Tk

    # we'll put the middle of grid cell (x,y) at (3+5*x, 3+5*y)
    set gheight [::gui::prob grid height]
    set gwidth [::gui::prob grid width]
    set cellw 5
    set cellh 5
    set cellxofs 3
    set cellyofs 3

    ttk::frame .bb
    ttk::button .bb.reset -text "Reset" -command ::gui::do_reset
    ttk::button .bb.startstop -textvariable ::gui::startstop \
        -command ::gui::do_startstop
    ttk::label .bb.guardpos -textvariable ::gui::guardpos
    ttk::label .bb.count -textvariable ::gui::walkedcount
    ::gui::make_spinner .bb.spinner
    ttk::label .bb.tick -textvariable ::gui::ticklabel

    grid .bb.reset .bb.startstop .bb.guardpos .bb.count .bb.tick .bb.spinner
    grid columnconfigure .bb {.bb.reset .bb.startstop .bb.spinner} -weight 0
    grid columnconfigure .bb {.bb.guardpos .bb.count .bb.tick} -weight 1

    # pack .bb.reset     -side left
    # pack .bb.startstop -side left
    # pack .bb.spinner   -side right
    # pack .bb.tick      -side right
    # pack .bb.guardpos  -side right
    # pack .bb.count     -side right

    pack .bb -side top -fill x

    canvas .c -height [expr {$cellyofs + $cellh * ($gheight-1) + $cellyofs}] \
        -width [expr {$cellxofs + $cellw * ($gwidth-1) + $cellxofs}] \

    pack .c -side bottom -fill both -expand 1


    for {set i 0} {$i < $gwidth} {incr i} {
        set x [expr {$cellxofs + $cellw * $i}]
        set x0 [expr {$x - 2}]
        set x1 [expr {$x + 2}]
        for {set j 0} {$j < $gheight} {incr j} {
            set y [expr {$cellyofs + $cellh * $j}]
            set y0 [expr {$y - 2}]
            set y1 [expr {$y + 2}]
            switch [::gui::prob grid get_xy $i $j] {
                "." {
                    .c create rectangle $x $y [expr {$x+1}] [expr {$y+1}] \
                        -tags [list P$i/$j ground] -fill black -width 0
                    .c create rectangle $x0 $y0 $x1 $y1 \
                        -tags [list P$i/$j cover] -fill "" -width 1 -outline ""
                }
                "#" {
                    .c create oval $x0 $y0 $x1 $y1 \
                        -tags [list $i,$j thing] -fill blue \
                        -width 1 -outline black
                }
            }
        }
    }
    wm protocol . WM_DELETE_WINDOW {destroy . ; set ::gui::stop 1}

    vwait ::gui::stop
}

::gui::gui
