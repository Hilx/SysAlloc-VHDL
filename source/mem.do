onerror resume
mem load -filltype value -filldata 0 -fillradix symbolic -skip 0 /tb/Buddy_Allocator/RAM0/myram
mem load -filltype value -filldata 00000000000000000100000001000101 -fillradix symbolic /tb/Buddy_Allocator/RAM0/myram(0)
mem load -filltype value -filldata 00000000000000011100000001000101 -fillradix symbolic /tb/Buddy_Allocator/RAM0/myram(1)
mem load -filltype value -filldata 00001100110011001101010101010101 -fillradix symbolic /tb/Buddy_Allocator/RAM0/myram(10)
mem load -filltype value -filldata 01010101010101010101010101010101 -fillradix symbolic /tb/Buddy_Allocator/RAM0/myram(10000)