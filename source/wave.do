onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/clk
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/reset
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/start
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/probe_in
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/size
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/direction_in
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/probe_out
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/done_bit
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/ram_addr
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/ram_data_out
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/flag_failed
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/state
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/nstate
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/search_status
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/group_addr
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/mtree
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/utree
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/mtree_VOUT
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/flag_found
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/cur
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/gen
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/gen_direction
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/direction
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/FLAG_HERE
add wave -noupdate -radix unsigned /tb/Buddy_Allocator/LOCATOR0/FLAG_ELSE
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1957509 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {6670336 ps}
