; LoadRam.asm. ; Procedures defined	.ent	LoadRam; statics used	.extd	TopLevelFrame, uPCTraceAddr, lvNIL; Lisp extended Nova instructions - dispatch into microcode	.dusr	LRJ = #61036	.SRELLoadRam:	lrj	.NRELlrj:	sta 3, savAc3		; loadram smashes ac3	LRJ	lda 3, savAc3	jmp 1,3savAc3:	0	.END