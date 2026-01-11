transcript on
if {[file exists gate_work]} {
	vdel -lib gate_work -all
}
vlib gate_work
vmap work gate_work

vlog -vlog01compat -work work +incdir+. {t1b_ultrasonic.vo}

vlog -vlog01compat -work work +incdir+C:/Users/Rohan/Desktop/t1b_ultrasonic\ (1)/t1b_ultrasonic/.test {C:/Users/Rohan/Desktop/t1b_ultrasonic (1)/t1b_ultrasonic/.test/tb.v}

vsim -t 1ps -L altera_ver -L cycloneive_ver -L gate_work -L work -voptargs="+acc"  tb

add wave *
view structure
view signals
run 48065350 ns
