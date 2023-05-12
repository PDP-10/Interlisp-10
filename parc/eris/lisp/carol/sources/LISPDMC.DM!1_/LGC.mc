   :Title[LGC.mc, December 6, 1982  1:44 PM, Masinter];   KnowRBase[LTEMP0];   TOP LEVEL;   InsSet[LispInsSet, 1];:if[Reduced];	UfnOps[25];	UfnOps[24];:else;*--------------------------------------------------------------------opGCREF:	* modify reference count of DATUM according to CASE*--------------------------------------------------------------------   T_ (fetch_ TSP) + 1;   CASE_ (Id) + (100000c), call[GCLOOKUP];   pd_ T, memBase_ StackM2BR;   branch[.+2, alu#0], pd_ T and (htstkcnt);	branch[.htnil];   branch[.+2, alu#0];	NextOpCode;* new entry created, return NIL.htnil:   TSP_ (store_ TSP) + 1, dbuf_ 0c;   TSP_ (store_ TSP) - 1, dbuf_ AT.NIL, NextOpCode;   regOP2[25, StackM2BR, opGCREF, noNData];*--------------------------------------------------------------------opRPLPTR:	* takes (PTR VAL) on stack, alpha byte is offset		* replace pointer at PTR+offset with VAL, doing		* two reference counts*--------------------------------------------------------------------   T_ (TSP) - (4c);   T_ (fetch_ T) + 1;   T_ Md, fetch_ T;   LTEMP1_ (Id) + (Md);   branch[.rplptr1, carry'], memBase_ LScratchBR, LEFT_ (LEFT) + 1;	T_ T + 1, branch[.rplptr1];.rplptr1:   BrLo_ LTEMP1;   BrHi_ T;	PAGEFAULTOK;   T_ (fetch_ 0s) + 1;* RPLPTR1: * call with LScratchBR pointing to cell containing old value* T_ (fetch_ 0s) + 1 just done* TSP contains new valueRPLPTR1:   Case_ 1c, call[GCLOOKUP];	* deleteref old pointer   TSP _ (TSP) - (2c);   memBase_ StackBR;RPLPTRTAIL:   T_ (fetch_ TSP) + 1;   Case_ 0c, call[GCLOOKUP];	* addref new value   memBase_ LScratchBR;   fetch_ 0s;   T_ Md;   T_ T and (lhmask);   T_ T + (LTEMP0);		* put high bits back   store_ 0s, dbuf_ T;		* store new value   store_ 1s, dbuf_ LTEMP1;GCOPTAIL:   pd_ (PSTATE) and (or[PS.HTCNTFULL!, PS.HTOVERFLOW!]c);   branch[.+2, alu#0], PSTATE_ (PSTATE) and not (PS.HTOVERFLOW);	 NextOpCode;   branch[.+2, alu#0], A_ Id, NARGS_ 1c;      DEFLO_ AT.GCSCAN, branch[DOCALLPUNT];   PSTATE_ (PSTATE) and not (PS.HTCNTFULL);   DEFLO_ AT.GCOVERFLOW, branch[DOCALLPUNT];regOP2[24, StackBR, opRPLPTR, noNData];*--------------------------------------------------------------------   SUBROUTINE;*--------------------------------------------------------------------* called with CASE * T_ (fetch_ hi word) + 1 done* return pointer counted in LTEMP0,,LTEMP1, with T = entry in htableGCLOOKUP:   T_ MD, fetch_ T;				* could fault	PAGEFAULTNOTOK;   T_ T and (rhmask), LTEMP1_ Md;   memBase_ tyBaseBR, LTEMP0_ T, branch[.+2];GCLOOKT1:	* called with CASE 	* pointer to reference in in T, LTEMP1	* return pointer counted in LTEMP0,,LTEMP1, with T = entry in htable   memBase_ tyBaseBR, LTEMP0_ T;   T_ rcy[T, LTEMP1, 11];   fetch_ T;   PROBE_ Md, memBase_ htMainBR;   branch[.+2, R>=0], pd_ (PROBE) and (TT.LISPREF);	T_ A0, return;				* no reference   branch[.+2, alu=0], T_ (LTEMP1) rsh 1;	LTEMP2_ Link, branch[.htpunt];		* always do in lisp   PROBE _ fetch _ T;				* fetch main table entry   ENTRY _ Md, T_ (LTEMP0) + (LTEMP0);   branch[.+2, R even], pd_ ENTRY;	LTEMP2_ Link, branch[.htpunt];		* collision   branch[.htnotempty, alu#0], LTEMP2_ Link;TOP LEVEL;   bdispatch_ CASE;   T_ T or (ht1cnt), branch[.htprobe];.htnotempty:   T_ ldf[ENTRY, 10, 1];			* get hi bits of entry   pd_ T xor (LTEMP0);				* compare hi bits of pointer   branch[.+2, alu=0], pd_ (ENTRY) + (ht1cnt);	branch[.htpunt];			* collision   goto[.htoverflow, carry], Link_ LTEMP2;   bdispatch_ CASE;   T_ ENTRY, branch[.htprobe];.htprobe:   DISPTABLE[5],   T_ T + (ht1cnt), branch[.htstore];		* case 0: addref   T_ T - (ht1cnt), branch[.htstore];		* case 1: delref   T_ T or (htstkbit), branch[.htstore];	* case 2: stkref.htstore:   LTEMP3_ T and (htStkCnt);   pd_ (LTEMP3) xor (ht1cnt);SUBROUTINE;   branch[.+2, alu=0], Link_ LTEMP2;   store_ PROBE, dbuf_ T, return;   store_ PROBE, T_ (dbuf_ 0c), return;.htoverflow:   T_ ENTRY, return;TOP LEVEL;.htpunt:   MemBase_ htOfloBR, T_ A0, branch[.+2, R>=0], CASE;	CallUFN;	* if CASE negative, do UFN if not fit.htpuntloop:   T_ (fetch_ T) + 1;   pd_ Md;   branch[.+2, alu=0], PSTATE_ (PSTATE) or (PS.HTOVERFLOW);	T_ T + 1, branch[.htpuntloop];   LTEMP3_ (store_ T) - 1, dbuf_ LTEMP1;   T_ LSH[CASE, 10];   T_ T + (LTEMP0);   store_ LTEMP3, dbuf_ T; SUBROUTINE;   Link_ LTEMP2;   return;:endif;	* Reduced