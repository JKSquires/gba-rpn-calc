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
cmpeq r3,1
subge r3,r3,1

tst r2,%0000010000 ; right
cmpeq r3,13
addge r3,r3,1

tst r2,%0000000001 ; a
bne endA
; handle numbers
cmp r3,5 ; check if number
subge r6,r3,5
mulge r4,r4,10
addge r4,r4,r6
bge endA

; handle math functions
cmp r3,4 ; add
addeq r4,r4,r5
moveq r4,r5
ldreq r5,[r13],4
beq endA

cmp r3,3 ; subtract
subeq r4,r4,r5
moveq r4,r5
ldreq r5,[r13],4
beq endA

cmp r3,1 ; multiply
muleq r4,r4,r5
moveq r4,r5
ldreq r5,[r13],4
beq endA

cmp r3,0 ; divide
bne endDiv
mov r6,0
divLoop:
subs r5,r5,r4
addge r6,r6,1
bge divLoop
mov r4,r6
ldr r5,[r13],4
b endA
endDiv:

; handle clear
cmp r3,2 ; c
moveq r4,0
endA:

tst r2,%0000000010 ; b

tst r2,%0000000100 ; select
streq r5,[r13,-4]!
moveq r5,r4
moveq r4,0

b mainLoop
