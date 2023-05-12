:Title[LISPDEFS.mc];** Edit History* February 2, 1984  9:53 AM, JonL, let CallUFN also do SaveLink_ Link* January 19, 1984  8:53 PM, JonL, added PS.INBLT flag* January 13, 1984  11:25 PM, JonL, RME's for Fvar lookup, new RAM number* January 9, 1984  9:17 PM, JonL, moved "DebugEachInst" conditional stuff*		to under "Debugging".* January 3, 1984  9:20 PM, JonL, added both "switched" GC punt names, *		so this file can server both pre Dec 15 and Post Jan 3 files* December 31, 1983  1:20 PM, JonL, CallUFN only branches to ufnPC,*		for simpler usage; added RM defs for SignQR and SaveLink* December 30, 1983  1:16 PM, JonL, Added NotReduced flag, and signBit constant* December 20, 1983  8:54 AM, JonL, renamed AT.GCMAPTABLE and AT.HANDLEOVERFLOW*			and added rme's for CELLHINUM, CELLLONUM* November 9, 1983  4:18 PM, JonL, updated RamVersion number*:insert[LParams.mc];set[Debugging, 0];					* 0 means NOT debugging, 1 means debuggingset[BreakPoints, 0];					* debugging with midasset[FNStats, sub[1,Debugging]];	* can gather function stats unless debuggingset[UPCStats, sub[1,Debugging]];	* cant gather microcode pc stats if debuggingset[Reduced,0];						* reduced instruction set*	set[NOFLOATING, add[Reduced, Debugging]];	set[NOFLOATING, 0];	set[NOBIN, Reduced];	set[NOCREATECELL, Reduced];	set[NORPLACS, Reduced];	set[NotReduced, sub[1,Reduced]];*--------------------------------------------------------------------* version numbers - VERSION PILOTBITBLT + 0*--------------------------------------------------------------------set[RamVersion, add[12004, Debugging]];				* version number (+ 1 if debugging)				* fix StampD1uCode.cm when these changeset[RamMinBcplVersion, 21000];set[RamMinLispVersion, 110400];* check against values imported from LPARAMS.dmcIFG[MinRamVersion!,RamVersion,ER[RamVersionTooLow]];IFG[MinBcplVersion!,RamMinBcplVersion,set[RamMinBcplVersion,MinBcplVersion!]];IFG[RamMinLispVersion, LispVersion!, ER[LispVersionTooLow]];*--------------------------------------------------------------------* RM regions*--------------------------------------------------------------------   SetRMRegion[RMForIFU];		*Lisp Emulator Registersrvn[ESP];		* 0	next stack blockrvn[FNStatsPtr];	* 1	pointer to fn stat bufferrvn[AllOnes];		* 2    always -1 (not used much)rvn[PSTATE];		* 3rvn[NARGS];		* 4	#argsrvn[DEFHI];		* 5	virtual address of function calledrvn[DEFLO];		* 6rvn[TSP];		* 7	pointer to next available stack regionrvn[IVAR];		* 10	pointer to current IVAR arearvn[LEFT];		* 11	number of (double words) of stack leftrvn[PVAR];		* 12	pointer to current PVAR arearvn[LTEMP4];		* 13rvn[LTEMP3];		* 14 rvn[LTEMP2];		* 15rvn[LTEMP1];		* 16	= DivTemp2  in DivSub from AEmu codervn[LTEMP0];		* 17	= MulTemp, DivTemp1	rme[DivTemp1, LTEMP0];   * for GC	rme[PROBE, NARGS];	rme[CASE, DEFHI];	rme[ENTRY, DEFLO];* for CREATECELL	rme[CELLHINUM, DEFHI];	rme[CELLLONUM, DEFLO];* for Free Variable lookup	rme[FVEP, LTEMP1];	rme[FVNAME, LTEMP2];	rme[FVTMP, LTEMP3];	rme[FVCHAIN, LTEMP4];	rme[FVINDEX, NARGS];	rme[FVHI, DEFHI];	rme[FVLO, DEFLO];* for numerical routines	rme[SignQR, DEFLO];		* Remembers the Sign of result in Mul and Div usages	rme[SaveLink, DEFHI]; 	* unboxing subroutines need to save link over callSetRMRegion[Region14]; 	RVN[InstCount];	RVN[InstBreak];	RVN[RANDNUM];* REGISTER CONVENTIONS:*  at "safe" points (i.e., after every opcode, whenever a page fault*  can occur, and whenever a punt can occur,*  the following conventions*  hold:*  IVAR  points to first IVAR word in basic frame*  PVAR  points to first PVAR word in frame extension*  TSP   points to the left word of the next slot in the current stack*  ESP   points to the first (left) word of the next stack block*	 (i.e., tsp1+1 = esp means stack is empty)*  PSTATE is 0 normally: -1 means in call, *	If debugging, 	1 means PCX is invalid, *			2 means that a page fault is ok	mc[PS.HTCNTFULL, 20];	mc[PS.HTOVERFLOW, 10];	mc[PS.INBCPL, 4];	mc[PS.PFOK, 2];	mc[PS.PCXBAD, 1];	mc[PS.INBITBLT, 40];	mc[PS.INBLT, 100];*   In addition, between opcodes, *   Left = (((ESP)-(TSP)) rsh 1) - LeftOffset;	mc[LeftOffset, 10];	mc[MyFrameOffset, 100];	mc[BfPadded, 400];	mc[BfResidual, 1000];	mc[FXFastReturn, 4000];	mc[FXInCall, 2000];	mc[FXNTValid, 1000];	mc[FXNoPushReturn, 400];* FX Fields:	mc[FX.BFLAGS, -2];	mc[FX.IVAR, -1];	mc[FX.FLAGS, 0];	mc[FX.ALINK, 1];	mc[FX.DEFLO, 2];	mc[FX.DEFHI, 3];	mc[FX.NEXT, 4];	mc[FX.PC, 5];	mc[FX.NTLO, 6];	mc[FX.NTHI, 7];	mc[FX.BLINK, 10];	mc[FX.CLINK, 11];	mc[FX.PVAR, 12];	m[FXDIF, sub[FX.#1!, FX.#2!]c];	m[FXBACK, sub[FX.PVAR!, FX.#1!]c];* FNHEADER fields	mc[FNH.STK, 0];	mc[FNH.NA, 1];	mc[FNH.PV, 2];	mc[FNH.START, 3];	mc[FNH.NTSIZE, 6];	mc[FNH.NLFV, 7];	mc[FNH.FIRSTNAME, 10];*  DTD fields	mc[DTD.NAME, 0];	mc[DTD.SIZE, 1];	mc[DTD.FREE, 2];	mc[DTD.COUNTER, 14];	mc[DTD.NEXTPAGE, 15];*--------------------------------------------------------------------* Base Registers*--------------------------------------------------------------------	brx[StackBR, 0];			* beginning of stack	brx[StackM2BR, 1];		* StackBR-2	brx[ScratchLZBR, 2];		* BrLo= 0*	brx[unused, 3];			* 	br[DefBR, 4];				* beginning of Def space	br[dtdBR, 5];				* pointer to DTD space	br[ufnBR, 6];				* UFN table 	br[ListpDTDBR, 7];		* pointer to LISTP's DTD	br[tybaseBR, 10];			* MDS type table	br[ZeroBR, 11];			* always zero	br[interfaceBR, 12];		* points to interface page	br[BBTableBR, 13];		* pointer to bitblt table*	br[, 14];					* unused*	br[, 15];					* unused* the following must be an even-odd pair	br[htMainBR, 16];			* GC main reference count table	br[htOfloBR, 17];			* GC overflow table*	br[AChannelBR, 20];*	br[TChannelBR, 21];   *	br[BBDstBR, 22];			* BitBlt destination base register*	br[BBSrcBR, 23];			* BitBlt source base register*	br[BChannelBR, 24];		* used by display	*	br[Page1BR, 25];			* {mds, 400b},*	br[ScratchBR, 26];		* general-purpose scratch register*	br[PCHistBR, 27];*	br[DiskBR, 30];			* Disk task base register*	br[ECBR, 31];				* Ethernet Command base register*	br[EIBR, 32];				* Ethernet Input base register*	br[EOBR, 33];				* Ethernet Output base register	br[LScratchBR, 34];		* Lisp scratch register	br[ValSpaceBR, 35];		* point to value space	br[MDS, 36];				* {mds, 0} for Alto and Mesa	br[ifuBR, 37];				* code base (used by IFU)*--------------------------------------------------------------------* Various constants*--------------------------------------------------------------------* RESERVED ATOM NUMBERS	mc[AT.NIL, 0];	mc[AT.NOBIND, 1];	mc[AT.T, 114];	mc[AT.EVALFORM, 370];	mc[AT.GCMAPTABLE, 377];	mc[AT.MAKENUMBER, 374];	mc[AT.SETFVAR, 376];	mc[AT.HANDLEOVERFLOW, 371];	mc[AT.INTERPRETER, 400];	mc[AT.MAKEFLOAT, 401];* for GC	mc[htStkCnt, add[htstkbit!, htcntmask!]];	mc[AT.GCSCAN, 371];									* Former "switched" meaning	mc[AT.GCOVERFLOW, 377];								* Former "switched" meaning* number spaces:	mc[SmallHi, smallpl!];	mc[SmallNegHi, smallneg!];* other random things	mc[MaxConsCount, 10000];	mc[StackEmpty, 0];	* Stkp for Stack Empty	mc[signBit, 100000];	mc[rhmask, 377];	mc[lhmask, 177400];* bcpl communication area	mc[StatsBufferPtr, 200];	mc[StatsBufferBoundary, 1400];	mc[AemuRestartLoc, 206];	mc[SubrArgArea, 210];	mc[CALL.EVENT, 140000];		* hi pointer for a fn call	mc[RETURN.EVENT, 177400];	* hi pointer for a return*--------------------------------------------------------------------* IFU definitions*--------------------------------------------------------------------:if[Debugging];	m[NextOpCode, Branch[NextOp]];									* go check PSTATE	m[PAGEFAULTOK, PSTATE_ (PSTATE) or (PS.PFOK)];	m[PAGEFAULTNOTOK, PSTATE_ (PSTATE) and (not[PS.PFOK!]c)];	m[PCXBAD, PSTATE_ (PSTATE) or (PS.PCXBAD)];	m[CHECKPCX, Call[CHECKPCXSUBR]];:else;	m[NextOpCode, IFUjump[0]];	* dispatch to next instruction	m[PAGEFAULTOK,];	m[PAGEFAULTNOTOK,];	m[PCXBAD,];	m[CHECKPCX,];:endif;	mc[NoNdata, 17];		* no encoded data in IFU	m[regOP1, ifuREG[#1, 1, #2, 0, #3, #4, 0, 0]];	* reg. 1 byte 	m[regOP2, ifuREG[#1, 2, #2, 0, #3, #4, 0, 0]];	* reg. 2 byte 	m[regOP3, ifuREG[#1, 3, #2, 0, #3, #4, 0, 0]];	* reg. 3 byte * ufn opcode - no microcode	M[UfnOps, IFUpause[#1, 1, ifuBR, 0, opUFN, NoNData, 0, 0]];   Set[LispInsSet, 1];	M[CallUFN, (SaveLink_ Link, Branch[ufnPC])];:if[breakpoints];	M[StackCheck, (Breakpoint) (RESCHEDULE)];	M[UCodeCheck, (Breakpoint) Branch[UCODECHECKPUNT]];:else;	M[StackCheck, RESCHEDULE];	M[UCodeCheck, (SaveLink_ Link, Branch[UCODECHECKPUNT])];:endif;z20256(635)\f8