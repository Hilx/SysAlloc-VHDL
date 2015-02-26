onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/clk
add wave -noupdate /tb/reset
add wave -noupdate /tb/start
add wave -noupdate /tb/command
add wave -noupdate /tb/done
add wave -noupdate /tb/size
add wave -noupdate /tb/address
add wave -noupdate /tb/saddr
add wave -noupdate /tb/CtrCounter
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/clk
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/reset
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/start
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/probe_in
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/size
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/direction_in
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/probe_out
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/done_bit
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/ram_addr
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/ram_data_out
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/flag_failed
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/state
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/nstate
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/search_status
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/top_node_size
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/log2top_node_size
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/group_addr
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/mtree
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/utree
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/flag_found
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/cur
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/gen
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/gen_direction
add wave -noupdate /tb/Buddy_Allocator/LOCATOR0/direction
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {0 ps} {1 ns}
