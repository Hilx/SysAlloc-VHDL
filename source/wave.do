onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/Buddy_Allocator/dmark/clk
add wave -noupdate /tb/Buddy_Allocator/dmark/reset
add wave -noupdate /tb/Buddy_Allocator/dmark/start
add wave -noupdate /tb/Buddy_Allocator/dmark/flag_alloc
add wave -noupdate /tb/Buddy_Allocator/dmark/probe_in
add wave -noupdate /tb/Buddy_Allocator/dmark/reqsize
add wave -noupdate /tb/Buddy_Allocator/dmark/done_bit
add wave -noupdate /tb/Buddy_Allocator/dmark/ram_we
add wave -noupdate /tb/Buddy_Allocator/dmark/ram_addr
add wave -noupdate /tb/Buddy_Allocator/dmark/ram_data_in
add wave -noupdate /tb/Buddy_Allocator/dmark/ram_data_out
add wave -noupdate /tb/Buddy_Allocator/dmark/state
add wave -noupdate /tb/Buddy_Allocator/dmark/nstate
add wave -noupdate /tb/Buddy_Allocator/dmark/top_node_size
add wave -noupdate /tb/Buddy_Allocator/dmark/log2top_node_size
add wave -noupdate /tb/Buddy_Allocator/dmark/group_addr
add wave -noupdate /tb/Buddy_Allocator/dmark/mtree
add wave -noupdate /tb/Buddy_Allocator/dmark/cur
add wave -noupdate /tb/Buddy_Allocator/dmark/gen
add wave -noupdate /tb/Buddy_Allocator/dmark/size_left
add wave -noupdate /tb/Buddy_Allocator/dmark/flag_first
add wave -noupdate /tb/Buddy_Allocator/dmark/original_top_node
add wave -noupdate /tb/Buddy_Allocator/dmark/alvec_sel
add wave -noupdate /tb/Buddy_Allocator/dmark/shift
add wave -noupdate /tb/Buddy_Allocator/dmark/utree
add wave -noupdate /tb/Buddy_Allocator/dmark/flag_markup
add wave -noupdate /tb/Buddy_Allocator/dmark/holder
add wave -noupdate /tb/Buddy_Allocator/dmark/index
add wave -noupdate /tb/Buddy_Allocator/dmark/effective_node
add wave -noupdate /tb/Buddy_Allocator/dmark/offset_debug
add wave -noupdate /tb/Buddy_Allocator/dmark/step_debug
add wave -noupdate /tb/Buddy_Allocator/dmark/size_left_debug
add wave -noupdate /tb/Buddy_Allocator/dmark/FLAG_HERE
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
WaveRestoreZoom {0 ps} {2334 ps}
