:Title[LCALLRET];** Edit History* March 13, 1985  9:45 AM, Masinter, remove calls to SAVEUCODESTATE* January 6, 1985  12:18 AM, JonL, let .ATOMICFN flipMembase when*     litatom index number has the 2^15 bit on* February 9, 1984  1:07 AM, JonL, fixed screwup in label ufnPC:* February 2, 1984  11:04 AM, JonL, fixes to callers of SAVEUCODESTATE* January 31, 1984  5:02 PM, temporarily add call to SAVEUCODESTATE*		to opUFN, ufnPC, and callers of DOCALLPUNT* January 24-27, 1984, JonL, Globalize DOCALLPUNT* January 13, 1984  8:07 PM, JonL, call and return code into one file* January 4, 1984  7:26 PM, JonL, moved in some subroutines from*		LSTACK.mc -- ADDSTK from LSTACK; ufnPC resets Hardware stack* December 31, 1983  12:51 PM, JonL, set memBase at ufnPC so code can*		branch directly to it; added some commentary* November 29, 1983  2:42 PM, JonL, removed spurious BrLo_ DEFLO.* December 7, 1982  4:38 PM, Masinter - - - *--------------------------------------------------------------------* Function call*--------------------------------------------------------------------KnowRBase[LTemp0];TOPLEVEL;InsSet[LispInsSet, 1];*--------------------------------------------------------------------opFN:				* FN0-4 operators*--------------------------------------------------------------------	NARGS_ Id;	T_ Id;	T_ LSH[T,10];	DEFLO_ (Id) + T;									* 16 bit atom index*--------------------------------------------------------------------.FNCALL1:			* Entry for DOCALLPUNT*--------------------------------------------------------------------	LTEMP0_ Id - (PCX') - 1;						* Return PC, for a n-byte op	CHECKPCX;*--------------------------------------------------------------------.FNCALL2:			* Entry for FNx and opUFN*--------------------------------------------------------------------   T_ (PVAR) - (FXBACK[PC]);						* Suspend the current frame   store_ T, dbuf_ LTEMP0, Branch[.ATOMICFN];	*  by saving the PC.atfXtnd:	memBase_ StackBR, Call[ADDSTK];*--------------------------------------------------------------------.ATOMICFN:			* Build a frame and start running the function whose *							index is DEFLO; NARGS args are on stack already.*--------------------------------------------------------------------	T_ (DEFLO) + (DEFLO), memBase_ DefBR;		* T_ word index of defcell   PSTATE_ T-T-1, branch[.+2, carry'];		flipMemBase;* CAN FAULT!!!	T_ (FETCH_ T) + 1;								* Fetch contents of defcell	LTEMP0_ MD, fetch_ T, T_ (rhmask);			* LTEMP0_ hi def	branch[.+2, R<0], LTEMP0_ T and (LTEMP0),	* SignBit of defcell is 					T_ Md, memBase_ ifuBR; 			*  flag for compiled code		DEFHI_ (atomHiVal), Branch[.notCCODE];	BrHi_ LTEMP0;	LTEMP1_ BrLo_ T;									* LTEMP1_ fnLo* CAN FAULT!!!	FETCH_ 0s;											* Fetch first word of	T_ LSH[LTEMP0, 10];								*  function header	LTEMP0_ (LTEMP0) + T;							* Recompute fnheader	T_ MD, fetch_ 1s;	T_ (ESP) - T;	pd_ T - (TSP);										* ESP - #WORDS - TSP	branch[.+2, carry], LTEMP2_ Md,				* LTEMP2_ def.na 				T_ (fetch_ 2s) + 1;		DEFHI_ (atomHiVal), Branch[.atfXtnd];:if[FNStats];	branch[.nofnstat, R<0], LTEMP3_ Md,						FnStatsPtr, fetch_ T; 		* LTEMP3_ def.pv		PCF_ Md, PSTATE_ A0; call[FNSTAT];		branch[.afterfnstat];:else;	LTEMP3_ Md, fetch_ T;							* LTEMP3_ def.pv:endif;.nofnstat:	PCF_ Md, PSTATE_ A0;								* start IFU early.afterfnstat:* No faults after here* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * **    KLUDGE FOR FINDING OUT WHO IS CALLED: SMASH DEF WITH BIT     **    FETCH_ (4S); IVAR_ MD;                                       **    BRANCH[.+2, R<0], IVAR_ IVAR OR (100000C);                   **    STORE_ (4S), DBUF_ IVAR;                                     ** * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *	T_ (NARGS) + (NARGS), memBase_ StackBR;PCXBAD;	IVAR_ (TSP) - T;	T_ (PVAR) - (FXBACK[NEXT]);	store_ T, dbuf_ IVAR;							* store FX.next	branch[.NoAdj, R<0], T_ LTEMP2;	T_ (NARGS) - T;.tryagain:	branch[.NoAdj', alu=0], pd_ T;	branch[.TooMany, alu>0];	TSP_ (store_ TSP) + 1, dbuf_ 0c;	TSP_ (store_ TSP) + 1, dbuf_ 0c;	T_ T+1, branch[.tryagain];.TooMany:	TSP_ (TSP) - (2c);	T_ T-1, branch[.tryagain];.NoAdj':	Branch[.+2], pd_ (TSP) and (2c);.NoAdj:	pd_ (TSP) and (2c);	branch[.QuadP,  alu=0], T_ (store_ TSP) + 1, dbuf_ BFBlock;		T_ (store_ TSP) + 1, dbuf_ 0c;		* Smash in a cell of 0's if not		T_ (store_ T) + 1, dbuf_ 0c;			*  quadword aligned; new BF wd		T_ (store_ T) + 1, dbuf_ (add[BFBlock!, BFPadded!]c);.QuadP:	T_ (store_ T) + 1, dbuf_ IVAR;					* new IVAR	T_ (store_ T) + 1, dbuf_ FxtnBlock;				* default flags	T_ (store_ T) + 1, dbuf_ PVAR;					* old PVAR	T_ (store_ T) + 1, dbuf_ LTEMP1;					* fn address hi	store_ T, dbuf_ LTEMP0;								* fn address lo	T_ PVAR_ T + (FXDIF[PVAR, DEFHI]);	dblbranch[.StorePVS, .endfn, R>=0], Cnt_ LTEMP3;	  .StorePVS:			T_ (store_ T) + 1, dbuf_ AllOnes;		* "Pvars", in multiples			T_ (store_ T) + 1, dbuf_ AllOnes;		*  of 2 cells			T_ (store_ T) + 1, dbuf_ AllOnes;			T_ (store_ T) + 1, dbuf_ AllOnes, 					dblbranch[.StorePVS, .endfn, Cnt#0&-1];.endfn:	T_ TSP_ T + (4c);	T_ ((ESP) - T) rsh 1;	LEFT_ T - (LeftOffset), NextOpCode;.notCCODE:	T_ (TSP), memBase_ StackBR;	T_ (store_ T) + 1, dbuf_ DEFHI;	TSP_ (store_ T) + 1, dbuf_ DEFLO;	NARGS_ (NARGS) + 1;	DEFLO_ AT.INTERPRETER, branch[.ATOMICFN];*--------------------------------------------------------------------SUBROUTINE;	ADDSTK:	 * add space to stack frame for FNCALL etc*--------------------------------------------------------------------	T_ (fetch_ ESP) + 1;									* next stack word	T_ Md, fetch_ T;	pd_ T xor (FreeStackBlock);	branch[.+2, alu=0];		TOP LEVEL;	Branch[STKOVPUNT];	 TOPLEVEL;	ESP_ (ESP) + (Md);.mergefree:	T_ (fetch_ ESP) + 1;	T_ Md, fetch_ T;	pd_ T xor (FreeStackBlock);	branch[.+2, alu=0], T_ ESP;		LEFT_ T - (TSP), Branch[FIXLEFT1];	ESP_ (ESP) + (Md), branch[.mergefree];TOPLEVEL; IFUpause[10, 3, StackBR, 0, opFN, 0, 0, 0];	*FN0IFUpause[11, 3, StackBR, 0, opFN, 1, 0, 0];	*FN1IFUpause[12, 3, StackBR, 0, opFN, 2, 0, 0];	*FN2IFUpause[13, 3, StackBR, 0, opFN, 3, 0, 0];	*FN3IFUpause[14, 3, StackBR, 0, opFN, 4, 0, 0];	*FN4*--------------------------------------------------------------------opFNX:*--------------------------------------------------------------------* Takes 3 argument bytes; first is NARGS, 2nd and 3rd are fn #.* since IFU won't handle 4 byte instructions, the first arg is* gotten from the IFU, and the fn is fetched directly. Things are* much simpler if the opcode happens to be word aligned. 	NARGS_ Id;	DEFLO_ T_ (Id)-(PCX')-1;		* Id is length- get byte# of 3rd byte	LTEMP0_ T rsh 1;					* word which contains hi byte of fnPAGEFAULTOK;	LTEMP0_ (FETCH_ LTEMP0) + 1;	branch[.+2, R odd], DEFLO_ MD, 					T_ T + (2c);		* T has new PC		LTEMP0_ T, memBase_ StackBR, branch[.FNCALL2];FNXsplit:	LTEMP0_ T, FETCH_ LTEMP0;				* save PC, fetch lo byte	memBase_ StackBR, T_ MD;				* T has lo byte of fn in hi bytePAGEFAULTNOTOK;	DEFLO_ Rcy[DEFLO, T, 10], branch[.FNCALL2];	* and fix upIFUpause[15, 2, ifuBR, 0, opFNX, noNData, 0, 0];*--------------------------------------------------------------------opAPPLYFN:*--------------------------------------------------------------------* TOS = FN TO CALL, TOS-1 = NARGS, TOS-... = arguments to FN	T_ (fetch_ TSP) + 1;							* fetch defhi	DEFHI_ Md, T_ (fetch_ T) - (3c);			* fetch deflo	DEFLO_ Md, T_ (fetch_ T) + 1;				* fetch narghi	T_ Md, fetch_ T, flipMemBase;	NARGS_ Md, pd_ T xor (SmallHi);	branch[.+2, alu=0], TSP_ (TSP) - (4c);		UCodeCheck[BadRetCall];	LTEMP0_ Id - (PCX') - 1;					* Save return PC	T_ (PVAR) - (FXBACK[PC]);	store_ T, dbuf_ LTEMP0;	pd_ (DEFHI) xor (AtomHiVal);				* Check for atomic fn	branch[.+2, alu=0];		branch[.notCCODE];	branch[.ATOMICFN];IFUpause[16, 1, StackM2BR, 0, opAPPLYFN, NoNData, 0, 0];	*APPLYFN:if[NotReduced];*--------------------------------------------------------------------opCKAPPLY:*--------------------------------------------------------------------* TOS = FN TO CALL	T_ (fetch_ TSP) + 1;		LTEMP0_ Md, fetch_ T;										* hiloc	T_ Md, memBase_ DefBR, pd_ LTEMP0;	branch[.+2, alu=0], T_ T + T;		CallUFN;														* not litatomPAGEFAULTOK;	FETCH_ T;	LTEMP0_ MD;PAGEFAULTNOTOK;	branch[.+2, R<0], pd_ (LTEMP0) and (20000c);		CallUFN;														* not CCODEP	branch[.+2, alu=0];		CallUFN;														* not argtype=0, 2	NextOpCode;regOP1[17, StackM2BR, opCKAPPLY, NoNData];	*CKAPPLY:else;	UfnOps[17];:endif;*--------------------------------------------------------------------opUFN:*--------------------------------------------------------------------* All "undefined" entries in the IFU memory come here, with *	a call is manufactured to the function fetched *  from the UFN table, according to byte at PC. * Format of table:	defindex[0:15]		left word;*							nargs[8:15]			right word.ufn0:	memBase_ ifuBR;	T_ LTEMP1_ not(PCX');					* T_ current PC (byte offset)	LTEMP0_ T rsh 1;							* LTEMP0_ current PC word address	CHECKPCX;PAGEFAULTOK;	LTEMP0_ (fetch_ LTEMP0) + 1;			* fetch word containing current op	T_ Md, fetch_ LTEMP0;	Branch[.ufnPCR, R odd], LTEMP1, LTEMP1_ Md;.ufnPCL:		LTEMP1_ RCY[T, LTEMP1, 10];		T_ RSH[T, 10], branch[.ufnPC2];.ufnPCR:	T_ (T) and (rhmask);.ufnPC2:	memBase_ ufnBR, T_ T + T;PAGEFAULTNOTOK;	T_ (fetch_ T) + 1;	DEFLO_ Md, fetch_ T;	NARGS_ Md, memBase_ StackBR;	T_ RSH[NARGS, 10];	LTEMP0_ BDispatch_ T;	NARGS_ (NARGS) and (rhmask), branch[.ufns];.ufns:   DISPTABLE[3],	branch[.ufnPC3];	T_ (store_ TSP) + 1, dbuf_ SmallHi, branch[.ufnpsh1];	T_ (store_ TSP) + 1, dbuf_ SmallHi, branch[.ufnpsh2];.ufnpsh1:	LTEMP1_ RSH[LTEMP1, 10];					* Only an "alpha" byte.ufnpsh2:	TSP_ (store_ T) + 1, dbuf_ LTEMP1;		* Push the opcode databytes.ufnPC3:	LTEMP0_ (LTEMP0) - (PCX'), call[FIXLEFT];	memBase_ StackBR, branch[.FNCALL2];*--------------------------------------------------------------------*  ufnPC:   GLOBAL,		*--------------------------------------------------------------------* CallUFN macro just turns into "SaveLink_ Link, Call[ufnPC]"ufnPC:   GLOBAL,	T_ A0, RBase_ RBase[LTEMP0];*	May come here from totally random places, so do a little cleanup:if[StackEmpty!];	T_ StackEmpty;* otherwise, T_ A0 handled it:endif;	StkP_ T, Branch[opUFN]; 						* Resets the hardware stack*--------------------------------------------------------------------DOCALLPUNT:		GLOBAL,			* Called from unbox, etc. *--------------------------------------------------------------------* Enter with DEFLO the atom index of fnname to call *				 NARGS has number of arguments to pass* Flush out Id, recompute up LEFT   T_ Id, call[FIXLEFT];   T_ Id, memBase_ StackBR, branch[.FNCALL1];*--------------------------------------------------------------------* RETURN*--------------------------------------------------------------------   KnowRBase[LTEMP0];   top level;   InsSet[LispInsSet, 1];opRETURN:   T_ (fetch_ TSP) - 1, FlipMemBase;   LTEMP0_ Md, fetch_ T, T_ (FXBACK[ALINK]);   LTEMP1_ Md, T_ (PVAR) - T;   fetch_ T, LTEMP3_ (rhmask);				* get alink field   LTEMP2_ Md;   branch[.nquick, R odd], LTEMP2, T_ (LTEMP2) - (FXBACK[IVAR]);   T_ (fetch_ T) + (FXDIF[DEFLO, IVAR]);   Q_ IVAR, IVAR_ Md, T_ (fetch_ T) + 1;		* new IVAR   DEFLO_ Md, T_ (fetch_ T) + (FXDIF[PC, DEFHI]);   T_ Md, PVAR_ (fetch_ T) + (FXDIF[PVAR, PC]);   T_ T and (LTEMP3), memBase_ ifuBR;			* new PVAR   BrLo_ DEFLO;:if[FNStats];   BrHi_ T, branch[.retstat, R>=0], FnStatsPtr;:else;   BrHi_ T;:endif;   T_ ESP, PCF_ Md;.finishret:   LEFT_ T - Q, memBase_ StackBR;   T_ (store_ Q) + 1, dbuf_ LTEMP0;   TSP_ (store_ T) + 1, dbuf_ LTEMP1;   LEFT_ (LEFT) rsh 1;   LEFT_ (LEFT) - (add[LeftOffset!, 1]c), NextOpCode;:if[FNStats];.retstat:   DEFHI_ T; PCF_ Md, call[.storeretstat];	* finish this operation   T_ ESP, branch[.finishret];:endif;IFUpause[20,1,StackM2BR,0,opReturn,noNData, 0, 0];*--------------------------------------------------------------------* NQUICK cases of return*--------------------------------------------------------------------	m[HardReturn, CallUFN];.nquick:	T_ (PVAR) - (FXBACK[ALINK]);	T_ (fetch_ T) + (FXDIF[CLINK, ALINK]);	LTEMP2_ Md, T_ (fetch_ T) + (FXDIF[BLINK, CLINK]);	pd_ (LTEMP2) - (Md) - 1, branch[.+2, R odd];		UCodeCheck[BadFrame];	branch[.+2, alu=0], LTEMP2_ (LTEMP2) - 1;		HardReturn;								* alink#clink* LTEMP2 is returnee	T_ (LTEMP2) - (FXBACK[FLAGS]);   	fetch_ T;									* flagword	T_ Md;:if[Debugging];	LTEMP3_ T and (StackMask);	pd_ (LTEMP3) xor (FxtnBlock);	branch[.+2, alu=0];		uCodeCheck[BadFrame];:endif;	pd_ T and (rhmask);	branch[.+2, alu=0], T_ (LTEMP2) - (FXBACK[NEXT]);		HardReturn;								* usecnt of returnee # 0	fetch_ T, T_ FreeStackBlock;	LTEMP3_ fetch_ Md;						* LTEMP3 points to returnee's next	pd_ T xor (Md);							* T _ flags	branch[.+2, alu#0], T_ IVAR;		branch[DORETURN];* check for contiguous BF   pd_ T xor (LTEMP3);						* is IVAR=returnee's next?   branch[.+2, alu=0], T_ (PVAR) - (FXBACK[BLINK]);		HardReturn;   fetch_ T;   T_ Md;   fetch_ T;   T_ Md;   pd_ T and (rhmask);   DblBranch[DORETURN, DOHARDRETURN, alu=0];DOHARDRETURN:	HardReturn;DORETURN:										* do return to LTEMP2	T_ (PVAR) - (FXBACK[BFLAGS]);	fetch_ T, T_ add[BfResidual!, rhmask!]c;	pd_ T and Md;	branch[.freefx, alu=0], T_ IVAR;:if[Debugging];.checkfreebf:	T_ (PVAR) - (FXBACK[ALINK]);	fetch_ T;	LTEMP3_ Md;	branch[.+2, R odd], LTEMP3;		UCodeCheck[ShouldBeSlowFrame];	T_ (PVAR) - (FXBACK[BLINK]);:else;.checkfreebf:	T_ (PVAR) - (FXBACK[BLINK]);:endif;	fetch_ T, T_ (rhmask);	LTEMP3_ fetch_ Md;					* get bf flags	LTEMP4_ Md, pd_ T and Md;	branch[.nqnz, alu#0], T_ (LTEMP3) + (2c);:if[Debugging];	T_ (LTEMP3) + 1;	T_ (fetch_ T) + 1;	pd_ (IVAR) - (Md);	branch[.+2, alu=0];		uCodeCheck[IVARWRONG];:endif;	T_ T - (IVAR);	IVAR_ (store_ IVAR) + 1, dbuf_ FreeStackBlock;	store_ IVAR, dbuf_ T, branch[.clresid];.nqnz:										* leave BF alone, decrement use count	T_ (LTEMP4) - 1;	store_ LTEMP3, dbuf_ T;.clresid:	T_ (PVAR) - (FXBACK[BFLAGS]);:if[Debugging];   fetch_ T;   LTEMP3_ Md;   pd_(LTEMP3) and (BFResidual);   branch[.+2, alu#0];	uCodeCheck[StackBad];   nop;:endif;.freefx:				* make from T to ESP into a free block   ESP_ (ESP) - T;   T_ (store_ T) + 1, dbuf_ FreeStackBlock;   store_ T, dbuf_ ESP;   PVAR_ LTEMP2;*--------------------------------------------------------------------RTN2:	* return to frame at PVAR with LTEMP0,,LTEMP1*--------------------------------------------------------------------   memBase_ StackBR;:if[Debugging];   T_ (PVAR) - (FXBACK[FLAGS]);   fetch_ T;   T_ Md;   T_ T and (StackMask);   pd_ T xor (FxtnBlock);   branch[.+2, alu=0];	uCodeCheck[BadFrame];:endif;   T_ (PVAR) - (FXBACK[IVAR]);   T_ (fetch_ T) + (FXDIF[NEXT,IVAR]);   IVAR_ Md, fetch_ T;   ESP_ Md;   TSP_ Md, fetch_ Md;.extend:   ESP_ (fetch_ ESP) + 1;   T_ Md;   pd_ T xor (FreeStackBlock);   branch[.+2, alu#0], T_ ESP_ (fetch_ ESP) - 1;	ESP_ (ESP) + (Md), branch[.extend];   T_ (T - (TSP)) rsh 1;   branch[.+2, carry], LEFT_ T - (LeftOffset);	uCodeCheck[noStackAtPunt];   T_ (PVAR) - (FXBACK[FLAGS]);   fetch_ T;   LTEMP2_ Md;   pd_ (LTEMP2) and (FXInCall);   branch[.retcall, alu#0], pd_ (LTEMP2) and (FXNoPushReturn);   branch[.nopush, alu#0], Q_ TSP;   T_ (store_ Q) + 1, dbuf_ LTEMP0;   TSP_ (store_ T) + 1, dbuf_ LTEMP1;   branch[.retfe2, R>=0], Left_ (Left) - 1;	uCodeCheck[NoStackAtPunt];.nopush:   LTEMP2_ (LTEMP2) and not (FXNoPushReturn);   store_ T, dbuf_ LTEMP2;			* turn off no pushbit   .retfe2:   T_ (PVAR) - (FXBACK[IVAR]);   T_ (fetch_ T) + (FXDIF[DEFLO, IVAR]);   IVAR_ Md, T_ (fetch_ T) + 1;   DEFLO_ Md, T_ (fetch_ T) + (FXDIF[PC, DEFHI]);   DEFHI_ Md, fetch_ T, T_ (rhmask);   DEFHI_ (DEFHI) and T, memBase_ ifuBR;   BrHi_ DEFHI;   BrLo_ DEFLO;   PCF_ Md;:if[FNStats];   branch[.+2, R<0], FnStatsPtr;   call[.storeretstat];   NextOpCode;:else;   nop;   NextOpCode;:endif;.retcall:   LTEMP2_ (LTEMP2) and not (FXInCall);   store_ T, dbuf_ LTEMP2;   T_ (TSP) - 1;   T_ (fetch_ T) - 1;   DEFLO_ Md, T_ (fetch_ T) - 1;   DEFHI_ Md, T_ (fetch_ T) - 1;   NARGS_ Md; fetch_ T;:if[Debugging];   pd_ DEFHI;   branch[.+2, alu=0], LTEMP0_ Md;	uCodeCheck[BadRetCall];   pd_ (LTEMP0) xor (SmallHi);   branch[.+2, alu=0];	uCodeCheck[BadRetCall];:endif;   TSP_ T, branch[.ATOMICFN];(635)\f8 5988g