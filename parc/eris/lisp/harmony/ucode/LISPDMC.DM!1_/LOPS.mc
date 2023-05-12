   :Title[LOPS];* Edit history:* March 5, 1984  7:30 PM, JonL, added opMISC1 (alpha 9) for opRWMufMan*		 (and retracted opRWMufMan as an opcode).  GLOBALized REPSMALLT* February 18, 1984  2:47 PM, JonL, added opRWMufMan* February 18, 1984  12:53 PM, JonL, fix parity of branch condition for*		 opEVAL of litatom; tried BDispatch in opEVAL again* February 2, 1984  5:08 PM, JonL, opBIN checks bits[4:7] of BR for zero* January 26, 1984  7:40 PM, JonL, spawned LLISTP off from this file;*		opEVAL uses BDispatch.* January 26, 1984  6:59 PM, JonL, opNOP and NEXTOP to LJUMP* January 7, 1984  5:38 PM, JonL, added commentary on TYPEP* January 6, 1984, 8:18 AM, JonL, fixed TL.CREATECELL to take an arg in*			NARGS which is the number of words to "pull back" on TSP* December 29, 1983  6:59 PM, JonL, "bubbled" inst in CREATECELL *		{memBase_ StackM2BR, T_ TSP} into previous inst, and replaced *		a few "0c"'s with (atomHiVal)'s;  changed (MaxConsCount) test in*		CREATECELL to use carry'; TYPEP tails into REPSMT2; shortened BIN *		by saving CCOFF in T over DOGETBYTE, and tailing into REPSMALLT*		Put error checking into WRITEPRINTERPORT; CDR tails into*		TL.PUSHNIL etc* December 27, 1983  6:30 PM, JonL, changed calls to GCLOOKT1 into calls *			to GCADDREF or GCDELREF* December 26, 1983  6:53 PM, JonL, move in opEQ and opNOP from LOW,*			let opEQ call ABFETCH and tail-out into TL.PUSHTRUE (or NIL)* December 26, 1983  6:40 PM, JonL, fixed callers of TYPREV to watch out *			for non-zero TT.*** bits* December 21, 1983  5:15 AM, JonL, opRCLK from LOW, NEXTOP from from *			LSTACK, moved opPOP to LSTACK, tailed opNTYPX into REPSMALLT* December 19, 1983  1:01 PM, JonL, TL.CREATECELL. Args in CELLHINUM and*			CELLLONUM * December 15, 1983  3:42 PM, JonL, Put in labels REPSMALLT and TL.REPT* November 29, 1983  4:42 PM, Masinter, change carry to < on createcell   KnowRBase[LTEMP0];   TOP LEVEL;   InsSet[LispInsSet, 1];*--------------------------------------------------------------------SUBROUTINE;	TYPREV:	* Get type of datum from cell being fetched from T*--------------------------------------------------------------------* Enter having done *  T_ (fetch_ <someLoc>) + 1,   call[TYPREV];* Exit with Ahi in LTEMP0*           Alo in LTEMP1*           typenumber in T   T_ LTEMP0_ Md, fetch_ T;   LTEMP1_ Md, memBase_ tybaseBR;   T_ RCY[T, LTEMP1, 11];   fetch_ T;   T_ Md, memBase_ StackM2BR, return;TOP LEVEL;*--------------------------------------------------------------------opEQ:*--------------------------------------------------------------------	T_ (fetch_ TSP) - 1, flipMemBase, call[ABFETCH];	T_ Md, TSP_ (fetch_ T) - 1;	T_ Md, pd_ T xor (LTEMP0);	branch[.+2, alu=0], pd_ (T) xor (LTEMP1);		LEFT_ (LEFT) + 1, branch[.neq];	branch[.neq, alu#0], LEFT_ (LEFT) + 1;		TSP_ (store_ TSP) + 1, dbuf_ (atomHiVal), branch[TL.PUSHTRUE];.neq:	TSP_ (store_ TSP) + 1, dbuf_ (atomHiVal), branch[TL.PUSHNIL];regOP1[360, StackM2BR, opEQ, noNData];*--------------------------------------------------------------------opNTYPX:*--------------------------------------------------------------------   T_ (fetch_ TSP) + 1,   call[TYPREV];   T_ T and (rhmask), Branch[REPSMALLT];*--------------------------------------------------------------------REPSMALLT:	GLOBAL,*--------------------------------------------------------------------*  Smashes a smallp into the Top-of-Stack slot;* 	Assumes TSP is correct and StackM2BR is memBase	TSP_ (store_ TSP) + 1, dbuf_ smallHi;REPSMT2:	TSP_ (store_ TSP) - 1, dbuf_ T, NextOpCode;regOP1[4, StackM2BR, opNTYPX, noNData];*--------------------------------------------------------------------opDTEST:		* test if type name of tos = arg, ufn if not*--------------------------------------------------------------------	T_ (fetch_ TSP) + 1, call[TYPREV];	memBase_ dtdBR;						* fetch type name of DTD	T_ LSH[T, 4];							* shifts TT.*** bits outPAGEFAULTOK;	FETCH_ T, T _ LTEMP0, RisID;		* This is really T_ (Id);	T_ LSH[T, 10];							* Get the litatom index	T_ (Id) + T;	pd_ T - (MD);PAGEFAULTNOTOK;	branch[.+2, alu=0];		CallUFN;									* type disagree	NextOpCode;regOP3[6, StackM2BR, opDTEST, noNData];*--------------------------------------------------------------------opTYPEP:		* TYPEP, LISTP same code*--------------------------------------------------------------------%	T_ (fetch_ TSP) + 1, call[TYPREV];	T_ T and (rhmask);	pd_ (Id) xor T;	branch[.+2, alu#0], T_ AT.NIL;		NextOpcode;											* Continue if type same	TSP_ (store_ TSP) + 1, dbuf_ (atomHiVal), 	* Otherwise, return NIL								branch[TL.REPNIL2];%*  Try this code, if a huge speedup and space savings for LITATOM is*   worth a 10% slowdown in the "true" cases of STRINGP, LISTP, etc	T_ (fetch_ TSP) + 1, call[TYPREV];	T_ T and (rhmask);	pd_ (Id) xor T;	branch[.typep1, alu#0], pd_ (LTEMP0) xor (atomHiVal);		branch[.+2, alu=0], T_ AT.T;			NextOpcode;									* Return arg if right type		TSP_ (store_ TSP) + 1, dbuf_ smallHi, 	* But on LITATOMs, return T							branch[REPSMT2]; .typep1:	TSP_ (store_ TSP) + 1, dbuf_ (atomHiVal), 	* Return NIL when not of 							branch[TL.REPNIL2];			*  the selected typeregOP1[3, StackM2BR, opTYPEP, listType!];regOP2[5, StackM2BR, opTYPEP, noNData];:if[Reduced];	UFNOPS[37];:else;*--------------------------------------------------------------------opCREATECELL:*--------------------------------------------------------------------	T_ (fetch_ TSP) + 1;	T_ Md, CELLHINUM _ (fetch_ T) - T;					* TOS = typenumber	pd_ NARGS_ T - (SmallHi);								* Kludgy way to set 	branch[.+2, alu=0], T_ Md, memBase_ dtdBR, 		*  NARGS to 0 in the						CELLLONUM _ T - T;					*  normal case.		CallUFN;	T_ LSH[T, 4];												* 2^4 wds per entryTL.CREATECELL:* Enter with T has the datatype number multiplied by the number of *						words per DTD entry;* 				 DEFHI has hiword value for first cell*				 DEFLO has loword value for first cell*				 NARGS has the number of words to "pull back" on TSP*				 memBase is dtdBR	T_ T + (DTD.FREE);									* fetch free list	LTEMP2_ T_ (fetch_ T) + 1;							* fetch head of free list	LTEMP0_ Md, T_ (fetch_ T) + 			(sub[DTD.SIZE!, add[DTD.FREE!, 1]]c); 	LTEMP1_ Md, fetch_ T;							* LTEMP0, 1 _ freelist head	LTEMP3_ Cnt_ Md;									* LTEMP3, Cnt _ size in wds	branch[.+2, Cnt#0&-1], memBase_ ScratchLZBR;		UCodeCheck[allocateZeroSizeCell];	BrHi_ LTEMP0;PAGEFAULTOK;	T_ (FETCH_ LTEMP1) + 1;								* fetch contents of free	branch[.+2, Cnt#0&-1], LTEMP4_ MD, T_ (fetch_ T) - (2c);		UCodeCheck[allocateOneSizeCell];PAGEFAULTNOTOK;	LTEMP3_ Md, T_ T + (LTEMP3);						* loloc+size-1.clearnew:PAGEFAULTOK;	T_ (STORE_ T) - 1, dbuf_ 0c, branch[., Cnt#0&-1];PAGEFAULTNOTOK;.cleardone:* All but first word has been cleared. Store args into 1st and 2nd word   T_ (store_ T) +1, dbuf_ CELLHINUM;   store_ T, dbuf_ CELLLONUM;	T_ LTEMP2, memBase_ dtdBR;							* store new free cell	T_ (store_ T) - 1, dbuf_ LTEMP3;	store_ T, pd_ dbuf_ LTEMP4;	branch[.+2, alu#0], LTEMP2_ (LTEMP2) +			 (sub[DTD.COUNTER!,add[1,DTD.FREE!]]c);	   PSTATE_ (PSTATE) or (PS.HTCNTFULL);			* freelist became empty ?   fetch_ LTEMP2;   T_ (Md) + 1;											* Add 1 to conscounter   store_ LTEMP2, dbuf_ T;   pd_ T - (MaxConsCount);	T_ NARGS, FreezeBC;   branch[.+2, carry'], T_ TSP_ (TSP) - T, memBase_ StackM2BR;				* Exceeded MaxConsCount allocations of this type ?	   PSTATE_ (PSTATE) or (PS.HTCNTFULL);	* Result is address of newly allocated cell, which is smashed onto TOS   T_ (store_ T) + 1, dbuf_ LTEMP0;   store_ T, dbuf_ LTEMP1;*		DELREF on new cell, so implicit refcnt of 1 goes to 0	Case_ 1c, Call[GCLOOKUP1];	   LTEMP4_ (4c), Branch[GCOPTAIL];regOP1[37, StackM2BR, opCREATECELL, noNData];:endif;	:if[Reduced];	UfnOps[40];:else;*--------------------------------------------------------------------opBIN:*--------------------------------------------------------------------	T_ (fetch_ TSP) + 1, call[TYPREV];			* returns with type in T	T_ T and (rhmask);								* Flush TT.*** bits	PD_ (Id) xor T, memBase_ ScratchLZBR;		* Set ScratchLZR to base of	Branch[.+2, alu=0], BrHi_ LTEMP0;			*  segment containg STREAMP	   CallUFN;											* Arg not a STREAMP ?PAGEFAULTOK;	T_ (FETCH_ LTEMP1) + 1;	LTEMP0_ MD, T_ (fetch_ T) + 1;				* LTEMP0 _ CCOFFPAGEFAULTNOTOK;	T_ Md, LTEMP2_ (fetch_ T) + 1;				* T _ NCCHARS	LTEMP0_ Md, pd_ T - (Q_ LTEMP0) - 1;		* LTEMP0 _ HiBuf, Q  _ CCOFF															* also pd_ NCCHARS-CCOFF-1	Branch[.+2, carry], LTEMP2_ (fetch_ LTEMP2) - (3c);	   CallUFN;											* Punt -- end of bufload	Branch[.+2, R<0], LTEMP0, memBase_ ScratchBR;	   CallUFN;											* Punt -- readable bit off	T_ Md, pd_ (LTEMP0) and (7400c);	Branch[.+2, alu=0], BrHi_ LTEMP0;		uCodeCheck[ExtraBitsInBufferAddress];	* BR setup to base of buffer	BrLo_ T, T_ LTEMP1_ Q, Call[.getByte];		*  and actually fetch byte	memBase_ ScratchLZBR, T_ T + 1;				* Now increment CCOFF	store_ LTEMP2, dbuf_ T;	memBase_ StackM2BR, T_ LTEMP1, Branch[REPSMALLT];regOP1[40, StackM2BR, opBIN, streamType!];:endif; *--------------------------------------------------------------------opMISC1:*--------------------------------------------------------------------* One arg miscellaneous opcode	T_ ID;	pd_ (T) - (11c);	Branch[opRWMufMan, alu=0];		ucodeCheck[BadMISC1AlphaByte];regOP2[170, StackM2BR, opMISC1, noNData];*--------------------------------------------------------------------opRWMufMan:*--------------------------------------------------------------------* One arg, a PosSMALLP, whose low-order 11 bits are a Muffler/Manifold*		address.  If the high-order bit (i.e., 2^15) is off, then read the*		the addressed muffler and return it's bit as the high-order bit of*		a PosSMALLP; if it is on, then execute the corresponding Manifold*		operation and return NIL.	T_ (fetch_ TSP) - 1, flipMemBase, Call[.UNBOX1];	T_ 13s;	pd_ LTEMP0, Cnt_ T;	Branch[.+2, alu=0],TSP_ (TSP) + (2c);		* Restore TSP		CallUfn;	flipMemBase;										* Both exits expect memBase 															*  to be StackM2Br.rwmmlp:		MidasStrobe_ Q;									* 11. iterations of strobe	Q lsh 1;												*  and shift	nop;	Branch[.rwmmlp, Cnt#0&-1];	Branch[.+2, R>=0], LTEMP1;						* Don't do flipMembase here, 		UseDMD, Branch[REPNIL];						*  because that constrains 	T_ ALUFMEM, Branch[REPSMALLT];				*  too many locations*--------------------------------------------------------------------opRCLK:*--------------------------------------------------------------------   T_ (fetch_ TSP) + 1;   LTEMP0_ Md, fetch_ T, T_ (30c);			* LTEMP0 _ HiAddr to clobber   LTEMP1_ Md, memBase_ MDS;					* LTEMP1 _ LoAddr to clobber   T_ T + (400c);   taskingOff;   fetch_ T;									* fetch word 430 for hi part of clock   LTEMP2_ Md, rbase_ rbase[RTClock];	* LTEMP2 _ hiword of clock   T_ RTClock;									* T _ loword of clock   taskingOn;	   rbase_ rbase[LTEMP0];   memBase_ ScratchLZBR;   BrHi_ LTEMP0;PAGEFAULTOK;   LTEMP1_ (store_ LTEMP1) + 1, dbuf_ Md;PAGEFAULTNOTOK;   store_ LTEMP1, dbuf_ T, nextOpCode;regOP1[167, StackM2BR, opRCLK, noNData];*--------------------------------------------------------------------opREADPRINTERPORT:*--------------------------------------------------------------------	T_ NOT(EventCntA'), branch[PUSHSMALLT];regOP1[164, StackM2BR, opREADPRINTERPORT, noNData];*--------------------------------------------------------------------opWRITEPRINTERPORT:*--------------------------------------------------------------------	T_ (fetch_ TSP) - 1, flipMemBase;					* Using .UNBOX1 here 	T_ Md, fetch_ T;											*  would only save 1	pd_ T - (SmallHi), T_ Md;								*  IM loc, but cost	Branch[.+2, alu=0];										*  an extra 3 cycles		CallUfn;   EventCntB_ T, NextOpCode;regOP1[165, StackM2BR, opWRITEPRINTERPORT, noNData];(635)\f8 3238G9g75G19g169G94g1417G94g:if[Reduced];	UfnOps[54];:else;regOP1[54, StackM2BR, opEVAL, noNData];*--------------------------------------------------------------------opEVAL:*--------------------------------------------------------------------	T_ (fetch_ TSP) + 1, call[TYPREV];	pd_ T and (370c);								* Only the first 8 type codes 	Branch[.+2, alu=0], T_ T and (7c);		*  are handled by ucode		CallUFN;	BDispatch_ T;	Branch[.evdispatch];.evdispatch:	DispTable[10],	CallUfn;												* Type 0 is randomness	NextOpCode;											* Smallp	NextOpCode;											* Fixp	NextOpCode;											* Floatp	FVNAME_ pd_ (LTEMP1), Branch[.evatom];		* Litatom.  "xor (AT.NIL)"	NARGS_ (1c), Branch[.evListp];				* Listp	NextOpCode;											* Arrayp	NextOpCode;											* Stringp%	pd_ T - (atomType);	branch[.evalatom, alu=0], pd_ T;	branch[.evalother, alu=0], pd_ T - (add[FixpType!, 1]c);	branch[.evalret, alu<0], pd_ T - (ListType);	branch[.evListp, alu=0], NARGS_ 1c;	CallUFN;										* not atom, fixp, listp.evalother:	CallUFN;													* let UFN decide.evalret: NextOpCode;									* return self.evalatom:	FVNAME_ pd_ (LTEMP1);								* "xor (AT.NIL)"%.evatom:	Branch[.+2, alu#0], pd_ (FVNAME) xor (AT.T);		NextOpCode;											* eval of NIL=NIL	Branch[.+2, alu#0], T_ (FX.PVAR);		NextOpCode;											* eval of T=T	nop;			* Call can be false target of conditional branch	FVEP_ (PVAR) - T, Call[DOLOOKUP];	memBase_ ScratchLZBR;	BrHi_ FVHI;PAGEFAULTOK;	T_ (FETCH_ FVLO) + 1;								* Might fault, since it 	T_ Md, fetch_ T;										*  may be global cellPAGEFAULTNOTOK;	pd_ (FVHI) - (StackHi);	Branch[.+2, alu#0], memBase_ StackM2BR;		Branch[REPTMD1];									* Stack-bound value is OK	pd_ (add[AT.NOBIND!]s) xor (Md);	Branch[REPTMD1, alu#0];								* Global binding ok	CallUFN;													* Hmmm, NOBIND in topcell.evListp:	DEFLO_ AT.EVALFORM, Branch[DOCALLPUNT];:endif;REPTMD:	memBase_ StackM2BR;* Replace value on top of stack with value in T,,MD:if[Debugging];REPTMD1:	pd_ T and not (77c);	branch[.+2, alu=0];		uCodeCheck[badpushval];	T_ Md, TSP_ (store_ TSP) + 1, dbuf_ T;:else;REPTMD1:	T_ Md, TSP_ (store_ TSP) + 1, dbuf_ T;:endif;	TSP_ (store_ TSP) - 1, dbuf_ T, NextOpcode;\f8