b start

@include header.asm
@include sprites.asm

div:
	; r9  dividend
	; r10 divisor
	; r11 quotient
	; r12 remainder
	stmfd r13!,{r0-r1,r3}

	mov r0,r9
	mov r1,r10
	swi 0x60000 ; division system call
	mov r11,r0
	mov r12,r1

	ldmfd r13!,{r0-r1,r3}
	bx r14


updateRegDisp:
	; r1 OAM
	; r4 X
	; r5 Y

	; y register uses sprites 1-11
	; x register uses sprites 12-23

	stmfd r13!,{r0,r2,r6-r12,r14}

	mov r0,r4
	mov r2,0 ; track x (0) and y (1)

	setRegDigits:
		; handle negatives
		tst r0,%10000000000000000000000000000000
		mov r8,0 ; no sprite if +
		movne r8,12 ; - sprite if -
		movne r6,0
		subne r0,r6,r0 ; if X was -, make + for digit logic

		cmp r2,0
		orreq r7,r1,0xC ; -X char
		orrne r7,r1,0x64 ; -Y char
		strh r8,[r7]

		mov r6,10 ; 2147483647 uses 10 digits
		orr r7,r1,8 ; skip - sprite
		cmp r2,1
		addeq r7,r7,(11 * 8) ; shift for if Y
		mov r8,r0
		digitLoop:
			; r6 counter
			; r7 OAM location for OBJ
			; r8 progress
			add r7,r7,8
			sub r6,r6,1

			mov r11,r6 ; copy to modify later
			mov r9,10
			mov r10,1
			powLoop: ; r10 = 10^r6
				cmp r11,0
				mulne r10,r10,r9
				subne r11,r11,1
				bne powLoop

			mov r9,r8
			bl div

			mov r8,r12

			cmp r11,0
			moveq r11,10 ; handle 0 sprite being at 10, whereas 1-9 sprites are at 1-9
			strh r11,[r7,4]

			cmp r6,0
			bne digitLoop

		cmp r2,0
		moveq r2,1
		moveq r0,r5 ; loop for Y
		beq setRegDigits


	ldmfd r13!,{r0,r2,r6-r12,r14}
	bx r14


start:
mov r0,0x4000000
mov r1,%0001000100000000 ; turn on OBJ and BG0 screens
strh r1,[r0]

mov r1,%0000000100000000 ; set BG0 screen base block to 1
strh r1,[r0,0x8]

transferPalette:
	addr r1,palette
	str r1,[r0,0xD4]

	; background
	mov r2,0x5000000
	str r2,[r0,0xD8]

	mov r3,(%10000100000 << 21) ; do DMA transfer (32-bit)
	orr r3,r3,2 ; do 2 transfers
	str r3,[r0,0xDC]

	; OBJ
	orr r2,r2,0x200 ; 0x5000200
	str r2,[r0,0xD8]

	str r3,[r0,0xDC]

transferSprites:
	addr r1,spritesStart
	str r1,[r0,0xD4]

	; background
	mov r1,0x6000000
	orr r2,r1,0x20 ; skip tile0
	str r2,[r0,0xD8]

	mov r3,(%10000100000 << 21) ; do DMA transfer (32-bit)
	orr r3,r3,(8 * 18) ; do (8 sprite lines * 18 sprites) transfers
	str r3,[r0,0xDC]

	; OBJ
	orr r2,r1,0x10000 ; 0x6010000
	orr r2,r2,0x20 ; skip char0
	str r2,[r0,0xD8]

	str r3,[r0,0xDC]

createBackground:
	orr r1,r1,0x800 ; BG0 base block at 0x6000800

	mov r2,16 ; 'Y'
	strh r2,[r1]

	mov r2,14 ; 'x'
	strh r2,[r1,0x40]

	mov r2,17 ; ':'
	strh r2,[r1,0x2]
	strh r2,[r1,0x42]

	; keypad
	orr r1,r1,0xC6
	mov r2,9 ; 9 -> 1
	numKeyLoop:
		strh r2,[r1],-2 ; go back one halfword
		sub r2,r2,1
		tst r1,7 ; test if X pos = 0
		bne numKeyLoop

		add r1,r1,0x46 ; next line and over 3 (halfwords)
		cmp r2,0
		bne numKeyLoop

	mov r2,10 ; 10 -> 15 (0, +, -, C, *, /)
	otherKeyLoop:
		strh r2,[r1],-2 ; go back one halfword
		add r2,r2,1
		tst r1,7 ; test if X pos = 0
		bne otherKeyLoop

		add r1,r1,0x46 ; next line and over 3 (halfwords)
		cmp r2,16
		bne otherKeyLoop

mov r1,0x7000000

createSelector:
	; OBJ Attr 0
	mov r3,32 ; Y
	strh r3,[r1]
	; OBJ Attr 1
	mov r3,16 ; X
	strh r3,[r1,2]
	; OBJ Attr 2
	mov r3,18 ; selector sprite
	strh r3,[r1,4]

mov r3,0
mov r4,16
mov r5,8
mov r6,r1
regDispSetup:
	add r6,r6,8
	add r3,r3,1

	strh r5,[r6]
	strh r4,[r6,2]

	add r4,r4,8

	cmp r3,11
	bne regDispSetup

	cmp r5,0
	movne r3,0
	movne r4,16
	movne r5,0
	bne regDispSetup ; do Y chars if not Y

; setup for main loop
mov r3,10
mov r4,0
mov r5,0
mvn r8,0

bl updateRegDisp


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
ldrh r2,[r6] ; read key-input

tst r2,%0010000000 ; down
bne endDown
tst r8,%0010000000 ; test if key just pressed
beq endDown
	; update selection
	cmp r3,3
	subge r3,r3,3
	; update selector
	ldrh r6,[r1]
	addge r6,r6,8
	strh r6,[r1]
endDown:

tst r2,%0001000000 ; up
bne endUp
tst r8,%0001000000 ; test if key just pressed
beq endUp
	; update selection
	cmp r3,11
	addle r3,r3,3
	; update selector
	ldrh r6,[r1]
	suble r6,r6,8
	strh r6,[r1]
endUp:

tst r2,%0000100000 ; left
bne endLeft
tst r8,%0000100000 ; test if key just pressed
beq endLeft
	; update selection
	cmp r3,1
	blt endLeft
	sub r3,r3,1
	; update selector
	add r9,r3,1
	mov r10,3
	bl div
	cmp r12,0
	ldrh r6,[r1]
	addeq r6,r6,8 ; drop down if edge
	strh r6,[r1]
	ldrh r6,[r1,2]
	addeq r6,r6,16 ; move right if edge
	subne r6,r6,8 ; else move left
	strh r6,[r1,2]
endLeft:

tst r2,%0000010000 ; right
bne endRight
tst r8,%0000010000 ; test if key just pressed
beq endRight
	; update selection
	cmp r3,13
	bgt endRight
	add r3,r3,1
	; update selector
	mov r9,r3
	mov r10,3
	bl div
	cmp r12,0
	ldrh r6,[r1]
	subeq r6,r6,8 ; pop up if edge
	strh r6,[r1]
	ldrh r6,[r1,2]
	subeq r6,r6,16 ; move left if edge
	addne r6,r6,8 ; else move right
	strh r6,[r1,2]
endRight:

tst r2,%0000000001 ; a
bne endA
tst r8,%0000000001 ; test if key just pressed
beq endA
	; handle numbers
	cmp r3,5 ; check if number
	blt endANum
	sub r6,r3,5 ; get num from position
	mov r7,10
	mul r4,r4,r7
	tst r4,%10000000000000000000000000000000 ; handle direction if negative
	addeq r4,r4,r6
	subne r4,r4,r6
	endANum:

	; handle math functions
	cmp r3,4 ; add
	addeq r4,r5,r4
	beq endMathFunc

	cmp r3,3 ; subtract
	subeq r4,r5,r4
	beq endMathFunc

	cmp r3,1 ; multiply
	muleq r4,r5,r4
	beq endMathFunc

	cmp r3,0 ; divide
	bne skipDiv
	mov r9,r5
	mov r10,r4
	bl div
	mov r4,r11
	endMathFunc:
	ldr r5,[r13],4 ; pop one off stack into r5
	skipDiv:

	; handle clear
	cmp r3,2 ; c
	moveq r4,0

	bl updateRegDisp
endA:

tst r2,%0000000010 ; b
bne endB
tst r8,%0000000010 ; test if key just pressed
beq endB
	ldr r6,[divTenMagicNum]
	smull r9,r10,r4,r6
	mov r4,r10

	tst r4,%10000000000000000000000000000000
	addne r4,r4,1 ; correct error when negative

	bl updateRegDisp
	b endB
divTenMagicNum:
@DCD 0x1999999A ; 2^32 / 10
endB:

tst r2,%0000000100 ; select
bne endSelect
tst r8,%0000000100 ; test if key just pressed
beq endSelect
	str r5,[r13,-4]! ; push just r5 onto stack
	mov r5,r4
	mov r4,0

	bl updateRegDisp
endSelect:

mov r8,r2 ; copy key selection into old key selection

b mainLoop
