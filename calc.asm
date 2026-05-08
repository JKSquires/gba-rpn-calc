b start

@include header.asm

start:
mov r0,0x4000000
mov r1,(%00010000 << 8)
orr r1,r1,%01000000
strh r1,[r0]

mov r1,0x6000000

mov r3,7

mainLoop:
; r0 I/O reg
; r1 VRAM
; r2 Key Input / Other
; r3 Selection
; r4 X
; r5 Y

waitForVBlankEnd:
ldrh r2,[r0,0x4]
tst r2,1
bne waitForVBlankEnd
waitForVBlankStart:
ldrh r2,[r0,0x4]
tst r2,1
beq waitForVBlankStart:

ldrh r2,[r0,0x130]

tst r2,%0010000000 ; down
cmpeq r3,3
subge r3,r3,3
tst r2,%0001000000 ; up
cmpeq r3,11
addle r3,r3,3
tst r2,%0000100000 ; left
cmpeq r3,13
addle r3,r3,1
tst r2,%0000010000 ; right
cmpeq r3,1
subge r3,r3,1

b mainLoop
