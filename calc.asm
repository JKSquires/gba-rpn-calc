b start

@include header.asm
@include sprites.asm

start:
mov r0,0x4000000
mov r1,%0001000100000000
strh r1,[r0]

mov r1,%0000000100000000
strh r1,[r0,0x8]

transferPalette:
	addr r1,palette
	str r1,[r0,0xD4]

	; background
	mov r2,0x5000000
	str r2,[r0,0xD8]

	mov r3,(%10000100000 << 21)
	orr r3,r3,2
	str r3,[r0,0xDC]

	; OBJ
	orr r2,r2,0x200
	str r2,[r0,0xD8]

	str r3,[r0,0xDC]

transferSprites:
	addr r1,spritesStart
	str r1,[r0,0xD4]

	; background
	mov r1,0x6000000
	orr r2,r1,0x20
	str r2,[r0,0xD8]

	mov r3,(%10000100000 << 21)
	orr r3,r3,(8 * 18)
	str r3,[r0,0xDC]

	; OBJ
	orr r2,r1,0x10000
	orr r2,r2,0x20
	str r2,[r0,0xD8]

	str r3,[r0,0xDC]

createBackground:
	orr r1,r1,0x800

	mov r2,16 ; 'Y'
	strh r2,[r1]

	mov r2,13 ; 'x'
	strh r2,[r1,0x40]

	mov r2,17 ; ':'
	strh r2,[r1,0x2]
	strh r2,[r1,0x42]

	; keypad
	orr r1,r1,0xC1
	mov r2,9
	numKeyLoop:
		str r2,[r1],-1
		sub r2,r2,1
		and r3,r1,3
		cmp r3,0
		bne numKeyLoop

		add r1,r1,0x43
		cmp r2,0
		bne numKeyLoop

	mov r2,10
	otherKeyLoop:
		str r2,[r1],-1
		add r2,r2,1
		and r3,r1,3
		cmp r3,0
		bne otherKeyLoop

		add r1,r1,0x43
		cmp r2,16
		bne otherKeyLoop

mov r1,0x7000000

mov r3,10
mvn r8,0

mainLoop:
; r0 I/O reg
; r1 OAM
; r2 Key Input / Other
; r3 Selection
; r4 X
; r5 Y
; r8 Previous Key Input

waitForVBlankEnd:
ldrh r2,[r0,0x4]
tst r2,1
bne waitForVBlankEnd
waitForVBlankStart:
ldrh r2,[r0,0x4]
tst r2,1
beq waitForVBlankStart

orr r6,r0,0x130
ldrh r2,[r6]

tst r2,%0010000000 ; down
bne endDown
tst r8,%0010000000
beq endDown
cmp r3,3
subge r3,r3,3
endDown:

tst r2,%0001000000 ; up
bne endUp
tst r8,%0001000000
beq endUp
cmp r3,11
addle r3,r3,3
endUp:

tst r2,%0000100000 ; left
bne endLeft
tst r8,%0000100000
beq endLeft
cmp r3,1
subge r3,r3,1
endLeft:

tst r2,%0000010000 ; right
bne endRight
tst r8,%0000010000
beq endRight
cmp r3,13
addle r3,r3,1
endRight:

tst r2,%0000000001 ; a
bne endA
tst r8,%0000000001
beq endA
	; handle numbers
	cmp r3,5 ; check if number
	subge r6,r3,5
	movge r7,10
	mulge r4,r4,r7
	addge r4,r4,r6
	bge endA

	; handle math functions
	cmp r3,4 ; add
	addeq r4,r5,r4
	ldreq r5,[r13],4
	beq endA

	cmp r3,3 ; subtract
	subeq r4,r5,r4
	ldreq r5,[r13],4
	beq endA

	cmp r3,1 ; multiply
	muleq r4,r5,r4
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
bne endB
tst r8,%0000000010
beq endB
	mov r6,0
	divTenLoop:
		subs r4,r4,10
		addge r6,r6,1
		bge divTenLoop
	mov r4,r6
	b endB
endB:

tst r2,%0000000100 ; select
bne endSelect
tst r8,%0000000100
beq endSelect
str r5,[r13,-4]!
mov r5,r4
mov r4,0
endSelect:

mov r8,r2 ; copy key selection into old key selection

b mainLoop
