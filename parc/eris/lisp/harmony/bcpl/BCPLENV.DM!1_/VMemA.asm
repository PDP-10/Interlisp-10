; VMemA.asm. Interlisp-D virtual memory package; MoveWords change on July 20, 1981 6:34 PM by Beau Sheil; Trill change February 24, 1981  10:40 AM by Beau Sheil; XBitBlt change January 28, 1981  5:03 PM by Alan Bell and Beau Sheil; Modified January 27, 1981  7:17 PM by Beau Sheil; procedures defined	.ent	BP, MovePage, ReadFlags, ReadRP, SetFlags	.ent	BGetBase32, XGetBase32	.ent	BGetBasePtr, XGetBasePtr, AGetBasePtr	.ent	BSetBR, XSetBR, RRead, RWrite	.ent	XGetBase, XGetBase1, XPutBase	.ent	BGetBase, BGetBase1, BPutBase	.ent	SGetBase, SPutBase	.ent	APutBase32, BPutBase32, XPutBase32	.ent	IncMiscStats, MiscStatsAdd1, BitBltSUBR	.ent	MoveWords, AtomNotNIL	.ent	MoveWordsBBT, MoveWordsBBTAddr; statics used	.extd	lvVPtr, VPtr0, VPtr1, Bpt, MiscSTATSbase; procedures used	.extn	PageFault; Lisp extended Nova instructions	.dusr	uReadFlags   = #67401	; ReadFlags(vp) -> (RP, flags)	.dusr	uSetFlags    = #67402	; SetFlags(vp, RP, flags)	.dusr	uXferPage    = #67403	; XferPage(toVP, fromVP)	.dusr	uBGetBase    = #67404	.dusr	uBPutBase    = #67405	.dusr	uBGetBase32  = #67406	.dusr	uBGetBasePtr = #67407	.dusr	uBPutBase32  = #67410	.dusr	XBITBLT      = #67416	.dusr	SWAT         = #77400	.ZRELBGetBase32:	.bgb32XGetBase32:	.xgb32BGetBasePtr:	.bgbPtrXGetBasePtr:	.xgbPtrAGetBasePtr:	.agbPtrBSetBR:		.bsBRXSetBR:		.xsBRRRead:		.rrdRWrite:		.rwtXGetBase:	.xgbsXGetBase1:	.xgbs1BGetBase:	.bgbsBGetBase1:	.bgbs1SGetBase:	.sgbsBPutBase:	.bpbsSPutBase:	.spbsXPutBase:	.xpbsAPutBase32:	.apbPtrBPutBase32:	.bpbPtrXPutBase32:	.xpbPtrAtomNotNIL:	.annIncMiscStats:	.imssBaseReg0:	  0BaseReg1:	  0MoveWordsBBT:	  0MoveWordsBBTAddr: 0	.SRELBP:		.bpMovePage:	.vmXpReadRP:		.rrpReadFlags:	.rfgSetFlags:	.sfgFault:		fault		; not called - makes Swat stack prettierMiscStatsAdd1:	.msa1BitBltSUBR:	.xbbtMoveWords:	.mw	.NREL; BP(i) returns a pointer to the ith real page descriptor.bp:	mov	0,1			; computing 3*i as offset	add	0,1			; 2*i	add	0,1			; 3*i	lda	0, Bpt			; start of table	add	1,0			; + offset 	jmp	1,3; MovePage(toVP, fromVP); Uses ucode routines to move contents of one virtual page to another.vmXp:	uXferPage	SWAT			; shouldn't fault	jmp	1,3; *** The following are for vmem access to the hardware map ***; ReadRP(Vp) -> RP.rrp:	uReadFlags	jmp	1,3; ReadFlags(Vp) -> flags.rfg:	uReadFlags	mov	1,0		; get flags into ac0	jmp	1,3; SetFlags(vp, RP, flags).sfg:	uSetFlags	jmp	1,3; *** The following are for vmem read access ***; BSetBR(addr0, addr1) -> ()  Sets base register.bsBR:	sta	0, BaseReg0	sta	1, BaseReg1	jmp	1,3; XSetBR(ptr) -> ()  Sets base register.xsBR:	mov	3,1	mov	0,3	lda	0,0,3	sta	0, BaseReg0	lda	0,1,3	sta	0, BaseReg1	mov	3,0	mov	1,3	jmp	1,3; RRead(disp) -> value.rrd:	lda	1, BaseReg1	addz	0,1			; carry set if overflow segment	lda	0,BaseReg0	mov#	0,0 szc			; do nothing, skip if no carry	inc	0,0			; next segment; now an ordinary BGetBase, so fall on thru; BGetBase(addr0, addr1) -> hi order word.bgbs:	sta	3,1,2doRD1:	uBGetBase	jsr	fault	lda	3,1,2	jmp	1,3; SGetBase(stackAddr) -> word.sgbs:	mov	0,1	lda	0, StackSpaceHi	jmp	.bgbs; XGetBase(ptr) -> word.xgbs:	sta	3,1,2	mov	0,3	lda	0,0,3	lda	1,1,3	jmp	doRD1; BGetBase1(addr0, addr1) -> low order word.bgbs1: sta	3,1,2doRD1x: uBGetBasePtr	jsr	fault	mov	1,0	lda	3,1,2	jmp	1,3; XGetBase1(ptr) -> word.xgbs1: sta	3,1,2	mov	0,3	lda	0,0,3	lda	1,1,3	jmp	doRD1x; BGetBase32(addr0, addr1) -> {VPtr0,,VPtr1}.bgb32: sta	3, 1,2doRD32: uBGetBase32		; 32-bit value returned in AC0,,AC1	jsr	faultboxACs:	sta	0, VPtr0	sta	1, VPtr1	lda	0, lvVPtr	lda	3,1,2	jmp	1,3; XGetBase32(ptr) -> {VPtr0,,VPtr1}.xgb32: sta	3,1,2	mov	0,3	lda	0,0,3	lda	1,1,3	jmp	doRD32; AGetBasePtr(atom#) -> {VPtr0,,VPtr1}.agbPtr: movzl	0,1	lda	0, ValSpaceLow	add	0,1	lda	0, ValSpaceHi; falls thru to BGetBasePtr; BGetBasePtr(addr0, addr1) -> {VPtr0,,VPtr1}.bgbPtr: sta	3, 1,2doRD2:	uBGetBasePtr		; ptr value returned in AC0,,AC1	jsr	fault	jmp	boxACs; XGetBasePtr(ptr) -> {VPtr0,,VPtr1}.xgbPtr: sta	3,1,2	mov	0,3	lda	0,0,3	lda	1,1,3	jmp	doRD2; AtomNotNIL(atom#) -> true if atom is non NIL, else false.ann:	sta	3,3,2		; store return in 3rd arg slot!!!	movzl	0,1	lda	0, ValSpaceHi	uBGetBasePtr	jsr	fault	mov#	0,0, snr	; skip if not an atom, thus not NIL	mov	1,0		; ac1 whether zero or not will do as result	lda	3,3,2	jmp	1,3; *** Handler for Bcpl generated page faults ***; This is tricky. We don't want to make a Bcpl frame unless we are; calling PageFault, but the code must be reentrant b/c it can be called; from interrupt routines (e.g., for the mouse and keyboard). Thus we; have special purpose version of GetFrame here.  Points of note:; The ucode has left faulting addr in {AC0,,AC1} - any other arg is in AC2(3); The addr of the faulter is left in AC2(2); We no longer care but we used to determine whether it was a read or write; fault by comparing the fault addr with the address of this code. Thus; all read routines had to precede this code and write routines follow itfault:	sta	3,2,2		; addr of vmema routine that faulted	mov	2,3	lda	2,stksze	; negative number of words of stack needed	add	3,2		; we now have a new stack ptr in AC2	sta	1,5,2		; save AC1 for use in stk ovfl check	lda	1,#335		; #335 = StackLimit	subz#	1,2 snc		; skip unless we've gone too low	SWAT	sta	3,0,2		; link back to previous frame	sta	0,4,2		; save addr hi, low part already saved	lda	0,c4		; ac0 _ 4	add	2,0		; ac0 _ lv 4(ac2) = lvAddr	jsrii	pflt		; PageFault(lvAddr)		1	lda	0,4,2		; restore addr	lda	1,5,2	lda	2,0,2		; ditch frame	lda	3,2,2		; retrieve addr of fault	jmp	-2,3		; re-execute faulting instruction!!!!pflt:	PageFaultstksze:	-6c4:	4; *** The following provide vmem write access; RWrite(disp, value) -> ().rwt:	sta	1,3,2			; new value in AC2,3 for BPutBase	lda	1,BaseReg1	addz	0,1			; carry set if overflow segment	lda	0,BaseReg0	mov#	0,0 szc			; do nothing, skip if no carry	inc	0,0			; next segment; now an ordinary BPutBase, so fall on thru; BPutBase(addr0, addr1, word) -> ().bpbs:	sta	3, 1,2doRW1:	uBPutBase	jsr	fault	lda	3, 1,2	jmp	1,3; XPutBase(ptr, word) -> ().xpbs:	sta	3, 1,2	sta	1,3,2	mov	0,3	lda	0,0,3	lda	1,1,3	jmp	doRW1; SPutBase(stackAddr, word) -> ().spbs:	sta	1,3,2	mov	0,1	lda	0, StackSpaceHi	jmp	.bpbs; APutBase32(atom#, ptr) -> ().apbPtr: sta	1,3,2		; new value ptr in AC2,3	movzl	0,1	lda	0, ValSpaceLow	add	0,1	lda	0, ValSpaceHi; fall thru into BPutBase32; BPutBase32(addr0, addr1, ptr) -> ().bpbPtr: sta	3, 1,2doRW2:	uBPutBase32	jsr	fault	lda	3, 1,2	jmp	1,3; XPutBase32(VAptr, valptr) -> ().xpbPtr: sta	3, 1,2	sta	1,3,2		; valptr in AC2,3	mov	0,3	lda	0,0,3	lda	1,1,3	jmp	doRW2StackSpaceHi:	27ValSpaceHi:	22ValSpaceLow:	0; MiscStatsAdd1(i) increments the ith location in MISCSTATS by 1.msa1:	subzl	1,1		; set ac1 to 1; IncMiscStats(i,n) increment the ith location in MISCSTATS by n.imss:	sta	1, incTemp; must check for MISCSTATSbase having been initialized; the paging; routines try to keep stats, even before there are any pages in core	lda	1, MiscSTATSbase	mov	1, 1, snr	jmp	1, 3			; return	sta	3, incRtn		; save return addr	add	0, 1	sta	1, incAddr		; save addr in stats	lda	0, StatsSp	jsr	@BGetBase1incRtn:		0			; use as temp, nargs not checked	lda	1, incTemp	addz	0, 1, snc		; skip if overflow	jmp	noovl	sta	1, incTemp	lda	1, incAddr		; addr in stats	lda	0, StatsSp	jsr	@BGetBaseincAddr:	0			; use as temp, nargs not checked	inc	0, 0			; ovfl increment for hi word 	sta	0, 3,2			; new value as 3rd arg	lda	1, incAddr		; addr in stats	lda	0, StatsSp	jsr	@BPutBase		; store into hi order wordincTemp:	0			; use as temp, nargs not checked	lda	1, incTempnoovl:	sta	1, 3,2			; new value as 3rd arg	lda	1, incAddr		; addr in stats	inc	1, 1			; low word	lda	0, StatsSp 	lda	3, incRtn		; load our return addr and JMP	jmp	@BPutBase		; store into low order wordStatsSp:	26			; use for constant, nargs not checked; BitBltSUBR(Ebbt).xbbt:	sta	3, xbtrtn	sta	2, xbtAC2.dxbb0:	sta	0, xbtAC0	sub	3,3 skp		; AC3 _ 0 and skip into loop.dxbb2:	lda	0, xbtAC0	XBITBLT	 jmp	.dxbb2		; Nww int	 jmp	.dxbb1		; Page fault	lda	2, xbtAC2	; restore stack	sub	1,1		; *** Strictly for debugging ***		sta	1, xbtAC2	; *** Strictly for debugging ***	lda	3, xbtrtn	jmp	1,3.dxbb1:	lda	2, xbtAC2	; restore stack	sta	3, xbtT		; store scan line count	jmp	.dxbb4	jmp	.dxbb3		; return from JSR fault comes here.dxbb4:	jsr	fault.dxbb3:	lda	3, xbtT	jmp	.dxbb2xbtAC0:	0xbtAC2:	0xbtT:	0xbtrtn:	0; MoveWords(src, dst, n).mw:	sta	3, xbtrtn	; xbbt save sequence - gives us temps	sta	2, xbtAC2	; ditto	mov	0, 3		; = lv src	lda	0, 3,2		; = n.	#60004			; = n*16 = width in bits	lda	2, MoveWordsBBT	; = lv MoveWords BB table	sta	0, 6,2		; = width in bits	lda	0, 0,3	sta	0, 21,2		; = src lo	lda	0, 1,3	sta	0, 20,2		; = src hi	mov	1, 3	lda	0, 0,3	sta	0, 23,2		; = dst lo	lda	0, 1,3	sta	0, 22,2		; = dst hi	lda	0, MoveWordsBBTAddr	jmp	.dxbb0		; jump into BitBltSubr	.END