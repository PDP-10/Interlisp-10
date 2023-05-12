:Title[LFloat];** Edit history* January 26, 1985  7:36 PM, Masinter, add UBFLOAT scaffolding*   and unboxed greaterp* March 5, 1984  5:22 PM, JonL, opFGREATERP was not adjusting TSP enough* January 12, 1984  3:54 AM, JonL, passed NARGS of 2 to TL.CREATECELL *		in .storefloat* January 4, 1984  10:40 PM, JonL, .storefloat tails into TL.CREATECELL,*		and exits from FP code reset the HardWare stack to empty.*		Fleshed-out opFGREATERP.  floatfail becomes CallUFN* November 29, 1983  2:14 PM, JonL*  - - - , Masinter, Taft*-----------------------------------------------------------   InsSet[LispInsSet, 1];TOPLEVEL;* Local R-register usage:SetRMRegion[BBRegs];	* Overlay BitBlt registers	RVN[ExpSign1];	* Exponent and sign of argument 1	RVN[Frac1H];	* Fraction of argument 1 (high part)	RVN[Frac1L];	* (low part)	RVN[ExpSign2];	* Argument 2 ...	RVN[Frac2H];	RVN[Frac2L];	RVN[FTemp0];	* Temporaries	RVN[FTemp1];	RVN[FTemp2];KnowRBase[LTEMP0];*-----------------------------------------------------------opUBFLOAT1:*-----------------------------------------------------------	T_ ID; BDispatch_ T;   branch[.xx1disp];.xx1disp: DispTable[10];	branch[.xxbox];	branch[.xxunbox];	branch[.xxabs];	branch[.xxnegate];	branch[.xxround];	CallUFN;	CallUFN;	CallUFN;.xxbox: CallUFN;.xxunbox: CallUFN;.xxabs: CallUFN;.xxnegate: CallUFN;.xxround: CallUFN;regOP2[355, StackM2BR, opUBFLOAT1, NoNData];KnowRBase[LTEMP0];*-----------------------------------------------------------opUBFLOAT2:*-----------------------------------------------------------	LTEMP0_ 1C;	STKP_ LTEMP0;	LEFT_ (LEFT) + 1;	T_ (TSP) - 1;	T_ (fetch_ T) - 1;	Stack&+1_ Md, T_ (fetch_ T) + (3c);	Stack&+1_ Md, T_ (fetch_ T) - 1;	Stack&+1_ Md, fetch_ T;	T_ Stack&-1_ Md;	LTEMP0_ ID;	BDispatch_ LTEMP0;	branch[.xx2disp];.xx2disp: DISPTABLE[10];	branch[.xxadd];	BRANCH[.xxsub];	BRANCH[.xxIsub];	BRANCH[.xxmul];	BRANCH[.xxdiv]; 	BRANCH[.XXGTP]; 	BRANCH[.xxmax];	BRANCH[.xxmin];.xxadd: callUfn;.xxsub: callUFN;.xxIsub: callUfn;.xxmul: callUfn;.xxdiv: callUfn;.XXGTP: RBase_ RBase[FTEMP0], SCall[FUnPack2];	T_ Stack&+2, Branch[FGT2];	T_ Stack&+2, Branch[FGT2]; .xxmax: callUfn;.xxmin: callUfn;regOP2[354, StackM2BR, opUBFLOAT2, NoNData];KnowRBase[LTEMP0];*-----------------------------------------------------------opFDIFFERENCE:*-----------------------------------------------------------*	Just flip sign of 2nd arg and join fplus code	T_ (fetch_ TSP) + 1; LEFT_ (LEFT) + 1, SCall[.FUNBOX2];KnowRBase[FTemp0];    		ExpSign2_ (ExpSign2) + 1, Branch[FAddZeroR]; * one arg = 0	ExpSign2_ (ExpSign2) + 1, Branch[FAddNonZero];	 * both non-0regOP1[351, StackM2BR, opFDIFFERENCE, 0];KnowRBase[LTEMP0];*-----------------------------------------------------------opFPLUS2:*-----------------------------------------------------------   T_ (fetch_ TSP) + 1; LEFT_ (LEFT) + 1, SCall[.FUNBOX2];KnowRBase[FTemp0];FAddZeroR:														 * one arg = 0    pd_ (Stack&+2) + (Stack&+2), Branch[FAddZero];regOP1[350, StackM2BR, opFPLUS2, 0];%Difference between exponents is the amount of unnormalization required. The low 7 bits of ExpSign1 contain either 4 or 5, whereas the low 7 bits of ExpSign2 contain 0, 1, or 2.  Thus subtracting ExpSign2 from ExpSign1 cannot cause a carry out of the low 7 bits. Furthermore, the low bit gets the xor of the two signs, useful later when determining whether to add or subtract the fractions.%FAddNonZero:	T_ ExpSign1;FAddNZ2:	ExpSign2_ T_ T - (Q_ ExpSign2);	FTemp1_ A0, Q RSH 1;	T_ T + T, DblBranch[UnNorm1, UnNorm2, Carry'];* Un-normalize operand 1.  T[0:7] has negative of right-shift count.UnNorm1:	ExpSign1_ (B_ Q) LSH 1, Branch[.+2, R even]; * Result exponent is Exp2	ExpSign1_ (ExpSign1)+1;		* But preserve Sign1	T_ T+(LShift[20, 10]C);	T_ T+(LShift[20, 10]C), Branch[UnNorm1le20, Carry];	T_ T+(LShift[20, 10]C), Branch[UnNorm1le40, Carry];* Exponents differ by more than 40.* Just zero operand 1, but be sure to set the sticky bit.	Frac1L_ 1C;ZeroFrac1H:	Frac1H_ A0, Branch[UnNormDone];* Exponent difference IN [1..20].  Let n = the difference.* T[0:7] now has 40 - n, i.e., IN [20..37], so SHA=R, SHB=T.* This is correct shift control for LCY[R, T, 20-n] = RCY[T, R, n]UnNorm1le20:	T_ Frac1L, ShC_ T;	PD_ ShiftNoMask[FTemp1];	* PD_ RCY[Frac1L, 0, [1..20]]	T_ Frac1H, FreezeBC;	Frac1L_ ShiftNoMask[Frac1L],	* Frac1L_ RCY[Frac1H, Frac1L, [1..20]]		Branch[.+2, ALU=0];	* Test bits shifted out of Frac1L	Frac1L_ (Frac1L) OR (1C);	* Nonzero bits lost, set sticky bit	T_ A0, Q_ Frac2L;	Frac1H_ ShiftNoMask[Frac1H],	* Frac1H_ RCY[0, Frac1H, [1..20]]		Branch[UnNormDone1];* Exponent difference IN [21..40].  Let n = the difference.* T[0:7] now has 60 - n, i.e., IN [20..37], so SHA=R, SHB=T.* This is correct shift control for LCY[R, T, 40-n] = RCY[T, R, n-20]UnNorm1le40:	T_ Frac1H, ShC_ T;	T_ ShiftNoMask[FTemp1];		* T_ RCY[Frac1H, 0, [1..20]]	PD_ T OR (Frac1L);		* Bits lost from Frac1H and Frac1L	T_ A0, FreezeBC;	Frac1L_ ShiftNoMask[Frac1H],	* Frac1L_ RCY[0, Frac1H, [1..20]]		Branch[ZeroFrac1H, ALU=0];	Frac1L_ (Frac1L) OR (1C),	* Nonzero bits lost, set sticky bit		Branch[ZeroFrac1H];* Un-normalize operand 2.  T[0:7] has right-shift count, and T[8:15] is IN [0..12].UnNorm2:	T_ (12S)-T;		* Negate count; ensure no borrow by ALU[8:15]	T_ T+(LShift[20, 10]C), Branch[UnNormDone, Carry]; * Branch if exponents equal	T_ T+(LShift[20, 10]C), Branch[UnNorm2le20, Carry];	T_ T+(LShift[20, 10]C), Branch[UnNorm2le40, Carry];* Exponents differ by more than 40.* Just zero operand 2, but be sure to set the sticky bit.	Frac2L_ 1C, Branch[ZeroFrac2H];UnNorm2gr40:	Frac2L_ 1C;ZeroFrac2H:	Frac2H_ A0, Branch[UnNormDone];* Exponent difference in [1..20].  Let n = the difference.* T[0:7] now has 40 - n, i.e., in [20..37], so SHA=R, SHB=T.* This is correct shift control for LCY[R, T, 20-n] = RCY[T, R, n]UnNorm2le20:	T_ Frac2L, ShC_ T;	PD_ ShiftNoMask[FTemp1];	* PD_ RCY[Frac2L, 0, [1..20]]	T_ Frac2H, FreezeBC;	Frac2L_ ShiftNoMask[Frac2L],	* Frac2L_ RCY[Frac2H, Frac2L, [1..20]]		Branch[.+2, ALU=0];	* Test bits shifted out of Frac2L	Frac2L_ (Frac2L) OR (1C);	* Nonzero bits lost, set sticky bit	T_ A0, Q_ Frac2L;	T_ Frac2H_ ShiftNoMask[Frac2H],	* Frac2H_ RCY[0, Frac2H, [1..20]]		Branch[UnNormDone2];* Exponent difference IN [21..40].  Let n = the difference.* T[0:7] now has 60 - n, i.e., IN [20..37], so SHA=R, SHB=T.* This is correct shift control for LCY[R, T, 40-n] = RCY[T, R, n-20]UnNorm2le40:	T_ Frac2H, ShC_ T;	T_ ShiftNoMask[FTemp1];		* T_ RCY[Frac2H, 0, [1..20]]	PD_ T OR (Frac2L);		* Bits lost from Frac2H and Frac2L	T_ A0, FreezeBC;	Frac2L_ ShiftNoMask[Frac2H],	* Frac1L_ RCY[0, Frac1H, [1..20]]		Branch[ZeroFrac2H, ALU=0];	Frac2L_ (Frac2L) OR (1C),	* Nonzero bits lost, set sticky bit		Branch[ZeroFrac2H];* Now decide whether fractions are to be added or subtracted.UnNormDone:	Q_ Frac2L;UnNormDone1:	T_ Frac2H;UnNormDone2:* 	Subtract if signs differ	ExpSign2, DblBranch[SubFractions, AddFractions, R odd];* Signs equal, add fractions.  T = Frac2H, Q = Frac2L.AddFractions:	Frac1L_ (Frac1L)+Q;	Frac1H_ T_ (Frac1H)+T, XorSavedCarry;	PD_ (Frac1L) AND (377C), Branch[FRePackNZ1, Carry'];* If carry out of high result, must normalize right 1 position.* Need not restore leading "1", since rounding cannot cause a carry into this* position, and the leading bit is otherwise ignored during repacking.	Frac1H_ (Frac1H) RSH 1;	Frac1L_ RCY[T, Frac1L, 1], Branch[.+2, R even];	Frac1L_ (Frac1L) OR (1C);	* Preserve sticky bit	ExpSign1_ (ExpSign1)+(LShift[1, 7]C), Branch[FRePackNonzero];* Signs differ, subtract fractions.  T = Frac2H, Q = Frac2L.SubFractions:	Frac1L_ (Frac1L)-Q;	T_ (Frac1H)-T-1, XorSavedCarry;	Frac1H_ A0, FreezeBC, Branch[Normalize, Carry];* If carry, Frac1 was >= Frac2, so result sign is Sign1.* If no carry, sign of the result changed.  Must negate fraction and* complement sign to restore sign-magnitude representation.	ExpSign1_ (ExpSign1)+1;	Frac1L_ (0S)-(Frac1L);	T_ (Frac1H)-T-1, XorSavedCarry, Branch[Normalize];* Add/Subtract with zeroes:* One or both of the operands is zero.  ALU = (high word of arg1) LSH 1.  This is* zero iff arg1 is zero (note that we don't need to worry about denormalized numbers,* since they have been filtered out already).* StkP has been advanced to point to high word of arg2.FAddZero:	T_ (Stack&-1)+(Q_ Stack&-1),	* T_ (high word of arg2) LSH 1		Branch[FAddArg2Zero, ALU#0]; * arg1#0 => arg2=0	Cnt_ Stack&-1,			* Cnt_ low word of arg2		Branch[FAddArg1Zero, ALU#0]; * arg2#0 => arg1=0* Both args are zero: result is -0 if both args negative, else +0.	Stack_ (Stack) AND Q, branch[.StoreFloat];* Arg 1 is zero and arg 2 nonzero: result is arg 2.* Note: must re-pack sign explicitly, since FSub might have flipped it.FAddArg1Zero:	T_ RCY[ExpSign2, T, 1];		* Insert Sign2 into high result	Stack&-1_ T;	Stack&+1_ Cnt, branch[.StoreFloat];* Arg 2 is zero and arg 1 nonzero: result is arg 1.FAddArg2Zero:	StkP-1, branch[.StoreFloat];		* Result already on stackregOP1[352, StackM2BR, opFTIMES2, 0];KnowRBase[LTEMP0];*-----------------------------------------------------------opFTIMES2:*-----------------------------------------------------------   T_ (fetch_ TSP) + 1; LEFT_ (LEFT) + 1, SCall[.FUNBOX2];KnowRBase[FTemp0];		T_ ExpSign2, Branch[MulArgZero]; 							* one arg = 0* XOR signs and add exponents.  Subtract 200 from exponent to correct*  for doubling bias, and add 1 to correct for 1-bit right shift of*  binary point during multiply (binary point of product is between bits*  1 and 2 rather than between 0 and 1).	T_ (ExpSign2)-(LShift[200, 7]C); 	* Subtract 200 from ExpSign2[0:8]MulNormal:	T_ T+(LShift[1, 7]C);					*  and add 1 	ExpSign1_ (ExpSign1)+T;* Now do the multiplications.  Initial registers:*   Frac1H = F1H (high 16 bits of arg 1)*   Frac1L = F1L,,0 (low 8 bits of arg 1)*   Frac2H = F2H (high 16 bits of arg 2)*   Frac2L = F2L,,0 (low 8 bits of arg 2)* Intermediate register usage:*   Frac1L and FTemp0 accumulate sticky bits*   FTemp2 is the initial product register for the Multiply subroutines.* Do 8-step multiply of F1L*F2L, with initial product of zero.	Frac1L_ T_ RSH[Frac1L, 10];	* Frac1L_ 0,,F1L	Frac2L_ RSH[Frac2L, 10],	* Frac2L_ 0,,F2L		Call[MultTx2L8I];	* Force 8 iterations,initial product 0* Low product is FTemp2[8:15],,Q[0:7].  FTemp2[0:7] = Q[8:15] = 0.* Do 8-step multiply of F2H*F1L, using high 8 bits of previous result as initial product.	FTemp0_ Q;			* Save low 8 bits for later use as sticky bits	T_ Frac2H, Cnt_ 6S, Call[MultTx1L];* Cross product is FTemp2[0:15]..Q[0:7].  Q[8:15] = 0.* Do 8-step multiply of F1H*F2L, with initial product of zero.	Frac1L_ Q;			* Frac1L_ low 8 bits of cross product	T_ Frac1H, ShC_ T,		* ShC_ high 16 bits of cross product		Call[MultTx2L8I];	* Force 8 iterations,initial product 0* Cross product is FTemp2[0:15]..Q[0:7].  Q[8:15] = 0.* Add cross products, propagate carries, and merge sticky bits.	T_ (Frac1L)+Q;			* Add low 8 bits of cross products	Frac1L_ (FTemp0) OR T;		* Merge with sticky bits from low product	T_ ShC, Branch[.+2, ALU=0];	* Collapse to single sticky bit in Frac1L[15]	Frac1L_ 1C; * Add high 16 bits of cross products	FTemp2_ (FTemp2)+T, XorSavedCarry;* Do 16-step multiply of F1H*F2H, using high 16 bits of previous result*  as initial product.* Frac1H_ (-1)+(carry out of sum of low and cross products).	T_ B_ Frac1H, Cnt_ 16S;	Frac1H_ T-T-1, XorSavedCarry, Call[MultTx2H];* Final result is T,,Q.  Merge in the sticky bit from low-order products*  and exit.	Frac1L_ (Frac1L) OR Q, DispTable[1, 2, 2];	T_ (Frac1H)+T+1, Branch[Normalize], DispTable[1, 2, 2];* One or both arguments = zero.  Return zero with appropriate sign.* T = ExpSign2MulArgZero:	ExpSign1_ (ExpSign1) XOR T, Branch[FRePackZero];*-----------------------------------------------------------* Unsigned multiply subroutines* Entry conditions (except as noted):*	Cnt = n-2, where n is the number of iterations*	T = multiplicand*	FracXX = multiplier (register depends on entry point);*		leftmost (16D-n) bits must be zero.*	FTemp2 = initial product (to be added to low 16 bits of final product)* Exit conditions:*	Product right-justified in T[0:15],,Q[0:n-1]*	Q[n:15] = 0*	FTemp2 = copy of T*	Carry = 1 iff T[0] = 1* If n = 16D, caller must squash Multiply dispatches in the 2 instructions* following the Call.* Timing: n+2*-----------------------------------------------------------SUBROUTINE;* Entry point for multiplier = Frac1LMultTx1L:	Q_ Frac1L, DblBranch[MultiplierO, MultiplierE, R odd];* Entry point for multiplier = Frac2L.* This entry forces 8 iterations with an initial product of zero.MultTx2L8I:	FTemp2_ A0, Cnt_ 6S;	Q_ Frac2L, DblBranch[MultiplierO, MultiplierE, R odd];* Entry point for multiplier = Frac2HMultTx2H:	Q_ Frac2H, DblBranch[MultiplierO, MultiplierE, R odd];* Execute first Multiply purely for side-effects (dispatch and shift Q)MultiplierE:	PD_ A0, Multiply, Branch[FM0];MultiplierO:	PD_ A0, Multiply, Branch[FM1];DispTable[4];* here after Q[14] was 0 (no add) and continueFM0:	FTemp2_ A_ FTemp2, Multiply, DblBranch[FM0E, FM0, Cnt=0&-1];* here after Q[14] was 0 (no add) and exitFM0E:	FTemp2_ T_ A_ FTemp2, Multiply, Return;* here after Q[14] was 1 (add) and continueFM1:	FTemp2_ (FTemp2)+T, Multiply, DblBranch[FM0E, FM0, Cnt=0&-1];* here after Q[14] was 1 (add) and exit	FTemp2_ T_ (FTemp2)+T, Multiply, Return;TOPLEVEL;regOP1[353, StackM2BR, opFQUOTIENT, 0]; KnowRBase[LTEMP0];*-----------------------------------------------------------opFQUOTIENT:*-----------------------------------------------------------   T_ (fetch_ TSP) + 1; LEFT_ (LEFT) + 1, SCall[.FUNBOX2];KnowRBase[FTemp0];		 T_ ExpSign2, Branch[DivArgZero]; 					* one arg = 0* XOR signs and subtract exponents.* Add 200 to resulting exponent to correct for cancellation of bias.	T_ (ExpSign2)-(LShift[200, 7]C); * Subtract 200 from ExpSign2[0:8]FDivNormal:	ExpSign1_ (ExpSign1)-T;* First, transfer dividend to Frac2H,,Frac2L and divisor to T,,Q, and*  unnormalize both of them by one bit so that significant dividend bits*  aren't lost during the division.	Frac1H_ (Frac1H) rsh 1, Branch[.+2, R odd];		T_ (Frac1L) RSH 1, Branch[.+2];	T_ ((Frac1L) + 1) rcy 1;			* Know Frac1L is even here	Frac2L_ T, Q_ Frac2L;	T_ A_ Frac2H, Multiply;				* T,,Q _ (Frac2H ,, Frac2L) RSH 1												* Know Q[14]=0, so can't dispatch* Now do the division.* Must do total of 26 iterations: 24 for quotient bits, plus one more*  significant bit in case we need to normalize, +1 bit for rounding.	Frac2H_ Frac1H, Call[DivFrac];	* Do 16 iterationsSUBROUTINE;* Preserve high quotient; do 10 more iterations	Frac1H_ Frac1L, CoReturn;	* We may have subtracted too much (or not added enough) in the last*  iteration.  If so, adjust the remainder by adding back the divisor. * Since the remainder got shifted left one bit, we must double the*  divisor first.	T_ A_ T, Divide, Frac1L, Branch[NoRemAdjust, R odd]; 						* T,,Q _ (T,,Q) lsh 1	Frac2L_ (Frac2L) + Q;	Frac2H_ T_ (Frac2H) + T, XorSavedCarry, Branch[.+2];* Left-justify low quotient bits and zero sticky bit.* Then, if the remainder is nonzero, set the sticky bit.* Then normalize if necessary.  Should have to left-shift at most once,*  since the original operands were normalized.NoRemAdjust:	T_ Frac2H;	pd_ (Frac2L) or T;	Frac1L_ LSH[Frac1L, 6], Branch[.+2, alu=0];	Frac1L_ (Frac1L) + 1;								* Set sticky bit	T_ Frac1H, Branch[Normalize];* Trap if divisor is zero; return zero with appropriate sign otherwise.DivArgZero:	Frac2H, Branch[MulArgZero, R<0];		TOPLEVEL; callUFN; SUBROUTINE;				* Division by zero*-----------------------------------------------------------DivFrac:	* Divide fractions* Enter: Frac2H ,, Frac2L = dividend (high-order bit must be zero)*	T ,, Q = divisor (high-order bit must be zero)* Exit:	Frac2H ,, Frac2L = remainder, left-justified*	Frac1L = quotient bits (see below)*	T and Q unchanged* When first called, executes 16 iterations and returns 16 high-order*  quotient bits.* When resumed with CoReturn, executes 10 more iterations and returns *  10 low-order quotient bits right-justified (other bits garbage).* Timing: first call: 66; resumption: 41*-----------------------------------------------------------SUBROUTINE;	Cnt_ 17S;* Previous quotient bit was a 1, i.e., dividend was >= divisor.* Subtract divisor from dividend and left shift dividend.DivSubStep:	Frac2L_ ((Frac2L)-Q) LSH 1;DivSubStep1:	Frac2H_ (Frac2H)-T-1, XorSavedCarry, 					DblBranch[DivSh1, DivSh0, ALU<0];* Previous quotient bit was a 0, i.e., dividend was < divisor*  (subtracted too much).  Add divisor to dividend and left shift*  dividend.DivAddStep:	Frac2L_ ((Frac2L)+Q) LSH 1;DivAddStep1:	Frac2H_ (Frac2H)+T, XorSavedCarry, DblBranch[DivSh1, DivSh0, ALU<0];* Shifted a zero out of low dividend (ALU<0 tested unshifted result).DivSh0:	Frac2H_ (Frac2H)+(Frac2H), DblBranch[DivQuot1, DivQuot0, Carry];* Shifted a one out of low dividend (ALU<0 tested unshifted result).DivSh1:	Frac2H_ (Frac2H)+(Frac2H)+1, DblBranch[DivQuot1, DivQuot0, Carry];* If the operation generated no carry then we have subtracted too much.* Shift a zero into the quotient and add the divisor next iteration.DivQuot0:	Frac1L_ (Frac1L)+(Frac1L),	* Shift zero into quotient		Branch[DivAddStep, Cnt#0&-1];	Cnt_ 11S, CoReturn;	Frac2L_ ((Frac2L)+Q) LSH 1, Branch[DivAddStep1];* If the operation generated a carry then we haven't subtracted too much* Shift a one into the quotient and subtract the divisor next iteration.DivQuot1:	Frac1L_ (Frac1L)+(Frac1L)+1,	* Shift one into quotient		Branch[DivSubStep, Cnt#0&-1];	Cnt_ 11S, CoReturn;	Frac2L_ ((Frac2L)-Q) LSH 1, Branch[DivSubStep1];TOPLEVEL;KnowRBase[LTEMP0];regOP1[362, StackM2BR, opFGREATERP, noNData];*-----------------------------------------------------------opFGREATERP:*-----------------------------------------------------------	T_ (fetch_ TSP) + 1; LEFT_ (LEFT) + 1, SCall[.FUNBOX2];KnowRBase[FTemp0];		T_ Stack&+2, Branch[FGT2];						* one arg = 0	T_ Stack&+2, Branch[FGT2];							* T_ high arg1* First compare the signsFGT2:		pd_ T xor (Q_ Stack&-1);								* Q_ high arg2	T_ Stack&-1, FreezeBC, 								* T_ low arg2				Branch[FCompSignsDiff, alu<0];* Signs equal, compare magnitudes.  *		Q = high arg2, T = low arg2, StkP -> high arg1	pd_ (Stack&-1) - Q, Branch[.+2, alu#0]; * Compute high (arg1 - arg2)		pd_ (Stack) - T;	* If equal, compute low (arg1 - arg2)* Carry = 1 if arg1 >= arg2 when treated as unsigned numbers.* The sense of this is inverted if the arguments are in fact negative,*  since the representation is sign-magnitude rather than 2s-complement.FCompTest:	ExpSign1_ (ExpSign1)+1, XorSavedCarry, Branch[FCompE, alu=0];	ExpSign1, DblBranch[FCompL, FCompG, R odd];* Signs unequal.  Unless both arguments are zero, return "less" if arg1*  is negative, else "greater".  Q = high arg2.FCompSignsDiff:	pd_ T - T, StkP-1, Q lsh 1;				* Carry_ 1	pd_ (Frac1H) or Q, Branch[FCompTest];	* alu=0 iff both args are zeroFCompL:	Stack_ A0, memBase_ StackBR, Branch[.fgtpret];		* arg1 < arg2FCompE:	Stack_ A0, memBase_ StackBR, Branch[.fgtpret];		* arg1 = arg2FCompG:	Stack_ (Stack) - (Stack) - 1, 		memBase_ StackBR, Branch[.fgtpret];		* arg1 > arg2:if[StackEmpty!];.fgtpret:		T_ (StackEmpty);	RBase_ RBase[LTEMP0];:else;.fgtpret:		T_ A0, RBase_ RBase[LTEMP0];:endif;KnowRBase[LTEMP0];	TSP_ (TSP) - (4c);					*  Adjust TSP back over args	pd _ (Stack) + 1, StkP_ T, Branch[TL.GREATERP];KnowRBase[LTEMP0];*-----------------------------------------------------------SUBROUTINE;	.FUNBOX2: GLOBAL, *-----------------------------------------------------------* "unpack" two floating-point arguments.* Call: memBase_ StackM2BR;*  	  T_ (fetch_ TSP) + 1; LEFT_ (LEFT) + 1, SCall[.FUNBOX2];* Exit:	ExpSign2, Frac2H, Frac2L set up with argument 2 (right);*			 ExpSign2[13:14]=00*	ExpSign1, Frac1H, Frac1L set up with argument 1 (left);*			 ExpSign1[13:14]=10*	StkP addresses high word of arg 1 (i.e., =2 if minimal stack)* Returns +1: at least one argument is zero*			 +2: both arguments are nonzero* Returns only for normal numbers or true zero.* Traps if denormalized, infinity, or Not-a-Number.* Clobbers Q	LTEMP2_ Md, T_ (fetch_ T) - (3c);		* LTEMP2_ YHi	LTEMP3_ Md, T_ (fetch_ T) + 1;			* LTEMP3_ YLo	T_ LTEMP0_ Md, fetch_ T;						* T, LTEMP0_ XHi	LTEMP1_ Md, memBase_ tyBaseBR; 			* LTEMP1_ XLo	T_ rcy[T, LTEMP1, 11];							* T _ type table ptr for X	fetch_ T, T_ (2c);								* Also shuffle a 2 into Q	stkP_ T;	T_ Md, memBase_ ScratchLZBR;			* T _ ntypx(X)	pd_ (T) xor (floatptype);	branch[.+2, alu=0], BrHi_ LTEMP0;		TOPLEVEL; CallUFN; SUBROUTINE;		* nope, not floatpPAGEFAULTOK;	T_ (FETCH_ LTEMP1) + 1;		Stack&-1_ MD, fetch_ T;	Stack&+3_ Md;										* push unboxed XPAGEFAULTNOTOK;	T_ LTEMP2, memBase_ tyBaseBR;			* T_ YHi	T_ rcy[T, LTEMP3, 11];							* T _ type table ptr for Y	fetch_ T;	T_ Md, memBase_ ScratchLZBR;	pd_ (T) xor (floatptype);	branch[.+2, alu=0], BrHi_ LTEMP2;		TOPLEVEL; CallUFN; SUBROUTINE;		* nope, not floatpPAGEFAULTOK;   T_ (FETCH_ LTEMP3) + 1;   T_ Stack&-1_ MD, fetch_ T;PAGEFAULTNOTOK;   Stack_ Md, RBase_ RBase[FTEMP0];   ExpSign2_ T AND (177600C), branch[FunPack2a];FUnPack2:* Pop and unpack two floating-point arguments.* Enter: T = top-of-stack, StkP points to TOS-1* Exit:	ExpSign2, Frac2H, Frac2L set up with argument 2 (right); ExpSign2[13:14]=00*	ExpSign1, Frac1H, Frac1L set up with argument 1 (left); ExpSign1[13:14]=10*	StkP addresses high word of arg 1 (i.e., =2 if minimal stack)* Call by: SCall[FUnPack2]* Returns +1: at least one argument is zero*	+2: both arguments are nonzero* Returns only for normal numbers or true zero.* Traps if denormalized, infinity, or Not-a-Number.* Clobbers Q*-----------------------------------------------------------	ExpSign2_ T AND (177600C);funpack2a:	T_ RCY[T, Stack, 10];		* Garbage bit and top 15 fraction bits	ExpSign2_ (ExpSign2) AND (77777C), * Exponent in bits 1:8, all else zero		Branch[.+2, R<0];	* Branch if negative	ExpSign2_ (ExpSign2)+(200C),	* Positive, add 1 to exponent, B15 _ 0		DblBranch[Exp2Zero, .+2, ALU=0]; * Branch if exponent zero	ExpSign2_ (ExpSign2)+(201C),	* Negative, add 1 to exponent, B15 _ 1		Branch[Exp2Zero, ALU=0]; * Branch if exponent zero	Frac2H_ T OR (100000C),		* Prefix explicit "1." to fraction		Branch[Exp2NaN, ALU<0];	* Branch if exponent was 377	T_ LSH[Stack&-1, 10];		* Left-justify low 8 fraction bits	Frac2L_ T;	T_ Stack&-1;			* Now do arg 1	ExpSign1_ T AND (177600C), Branch[FUnPack1a];Exp2Zero:	Frac2H_ (Stack&-1) OR T;	* See if entire fraction is zero	Frac2L_ A0, Branch[Arg2DeNorm, ALU#0]; * Branch if not true zeroTopLevel;	T_ Stack&-1, Q_ Link, SCall[FUnPack1]; * Zero, unpack other arg	Link_ Q, Branch[.+2];		* Return +1 regardless of what FUnpack1 did	Link_ Q;Subroutine;	ExpSign2_ (ExpSign2) AND (1C), Return;TOPLEVEL;Arg2DeNorm:	CallUFN;				* Denormalized numberExp2NaN:	CallUFN;				* Not-a-NumberSUBROUTINE;*-----------------------------------------------------------FUnPack1:* Pop and unpack one floating-point argument.* Enter: T = top-of-stack, StkP points to TOS-1* Exit:	ExpSign1, Frac1H, Frac1L set up with argument*	StkP addresses high word of arg 1 (i.e., =2 if minimal stack)* Call by: SCall[FUnPack1]* Returns +1: argument is zero*	+2: argument is nonzero* Returns only for normal numbers or true zero.* Traps if denormalized, infinity, or Not-a-Number.* Timing: 7 cycles normally.*-----------------------------------------------------------	ExpSign1_ T AND (177600C), Global;FUnPack1a:	T_ RCY[T, Stack, 10];		* Garbage bit and top 15 fraction bits	ExpSign1_ (ExpSign1) AND (77777C), * Exponent in bits 1:8, all else zero		Branch[.+2, R<0];	* Branch if negative	ExpSign1_ (ExpSign1)+(204C),	* Positive, add 1 to exponent, [13:14]_10, [15]_0		DblBranch[Exp1Zero, .+2, ALU=0]; * Branch if exponent zero	ExpSign1_ (ExpSign1)+(205C),	* Negative, add 1 to exponent, [13:14]_10, [15]_1		Branch[Exp1Zero, ALU=0]; * Branch if exponent zero	Frac1H_ T OR (100000C),		* Prefix explicit "1" to fraction		Branch[Exp1NaN, ALU<0];	* Branch if exponent was 377	T_ LSH[Stack&+1, 10];		* Left-justify low 8 fraction bits	Frac1L_ T, Return[Carry'];	* Always skip (carry is always zero here)Exp1Zero:	Frac1H_ (Stack&+1) OR T;	* See if entire fraction is zero	Frac1L_ A0, Branch[Arg1DeNorm, ALU#0]; * Branch if not true zero	ExpSign1_ (ExpSign1) AND (1C), Return; * Zero, return +1TOPLEVEL;Arg1DeNorm:	CallUFN;						* Denormalized numberExp1NaN:	CallUFN;						* Not-a-Number*-----------------------------------------------------------Normalize:* Normalize and re-pack floating-point result.* Enter: ExpSign1, T, Frac1L contain unpacked result*			T = ALU = high fraction.*			StkP addresses high word of result (i.e., =2 if minimal stack)* Timing: for nonzero result: 11 cycles minimum, +3 if need to normalize*			 at all, +2*(n MOD 16) if n>1, where n is the number of*			 normalization steps, +3 if n>15, +5 if need to round, +2 if*			 rounding causes a carry out of Frac1L, +1 or 2 in extremely*			 rare cases.	For zero result: 6 cycles*-----------------------------------------------------------* See if result is already normalized or entirely zero.* Note that we want the cases of no normalization, one-step*  normalization, and result entirely zero to be the fastest, since they*  are by far the most common. So, do the first left shift in-line while*  branching on the other conditions.	PD_ T OR (Q_ Frac1L),		* ALU_ 0 iff entire fraction is 0		Branch[NormAlready, ALU<0]; * Branch if already normalized	Frac1H_ A_ T, Divide,		* (Frac1H,,Q) _ (T,,Q) LSH 1		Branch[NormalizeZero, ALU=0]; * Branch if fraction is zero	ExpSign1_ (ExpSign1)-(LShift[1, 7]C), * Subtract one from exponent		Branch[NormBegin, ALU#0]; * Branch if high fraction was nonzero* If the high word of the fraction was zero, we discover that after*  having left-shifted the fraction once.  Effectively, left-shift the*  fraction 16 bits and subtract 16D from the exponent.  Actually, undo*  the first left shift and subtract only 15D from the exponent, in case*  the first left shift moved a one into the high fraction.	ExpSign1_ (ExpSign1)+(LShift[1, 7]C);	ExpSign1_ (ExpSign1)-(LShift[20, 7]C);	Frac1H_ Frac1L;				* Left-shift original fraction 16 bits	Q_ T, Branch[NormLoop];		* Q_ 0* In this loop, the exponent is in ExpSign1[0:8] and the fraction in*  Frac1H ,, Q.  Left shift the fraction and decrement the exponent*  until the high-order bit of the fraction is a one.NormBegin:	T_ A0, Frac1H, Branch[NormDone1, R<0]; * One shift enough ?NormLoop:	Frac1H_ A_ Frac1H, Divide, Branch[NormDone, R<0]; 					* (Frac1H,,Q) _ (Frac1H,,Q) LSH 1	ExpSign1_ (ExpSign1) - (LShift[1, 7]C), Branch[NormLoop];* When we bail out of the loop, the exponent is correct, but we have*  left-shifted the fraction one too many times.  Right-shift the*  fraction and exit.NormDone:	Frac1H_ (Frac1H)-T, Multiply;	* (Frac1H,,Q) _ 1,,((Frac1H,,Q) RSH 1)NormDone1:	Frac1L_ Q, Branch[FRePackNonzero]; * Multiply dispatch pending!!NormAlready:	Frac1H_ T, Branch[FRePackNonzero]; * Placement (sigh)* Result was exactly zero: push +0 as answer.NormalizeZero:	ExpSign1_ A0, Branch[FRePackZero];*-----------------------------------------------------------FRePackNonzero:* Re-pack nonzero floating-point result.* Enter: ExpSign1, Frac1H, Frac1L contain unpacked result, which must *  be normalized but need not have its leading "1" so long as rounding*  can't carry into this bit.* StkP addresses high word of result (i.e., =2 if minimal stack)* Timing: 9 cycles minimum, *		+5 if need to round, +2 if rounding causes a carry*	out of Frac1L, +1 or 2 in extremely rare cases.*-----------------------------------------------------------* Prepare to round according to Round-to-Nearest convention. *  Frac1L[8:15] are fraction bits that will be rounded off; result *  is exact only if these bits are zero.	PD_ (Frac1L) AND (377C), DispTable[1, 2, 2];FRePackNZ1:	ExpSign1_ (ExpSign1) OR (176C),	* unused bits of ExpSign1 get 1's		Branch[NoRounding, ALU=0];* Inexact result.  Round up if result is greater than halfway between*  representable numbers, down if less than halfway.  If exactly*  halfway, round in direction that makes least significant bit of*  result zero. Adding 1 at the Frac1L[8] position causes a carry into*  bit 7 iff the result is >= halfway between representable numbers.	PD_ (Frac1L) AND (177C);	Frac1L_ (Frac1L)+(200C), Branch[.+2, ALU#0];* Exactly halfway.  But we have already rounded up.* If the least significant bit was 1, it is now 0 (correct).* If it was 0, it is now 1 (incorrect).  But in the latter case, no*  carries have propagated beyond the least significant bit, so...	Frac1L_ (Frac1L) AND NOT (400C); * Just zero the bit to fix it* Now set the sticky flag and trap if appropriate.* Note we have not propagated the carry out of the low word yet, so *  we must perform only logical ALU operations that don't clobber the*  carry flag.	T_ B_ Frac1H;	T_ T+1, RBase_ RBase[FTemp0],	* Prepare to do carry if appropriate		Branch[DoneRounding, Carry'];* There was a carry out of Frac1L.  Propagate it to Frac1H.* If this causes a carry out of Frac1H, the rounded fraction is *  exactly 2.0, which we must normalize to 1.0; i.e., set fraction *  to 1.0 and increment exponent.	Frac1H_ T, Branch[.+2, Carry'];	ExpSign1_ (ExpSign1)+(LShift[1, 7]C);	ExpSign1_ (ExpSign1)-(LShift[2, 7]C), 						DblBranch[ExpOverflow, .+3, R<0];* Done rounding.  Check for exponent over/underflow, and repack and *  push result.DoneRounding:	ExpSign1_ (ExpSign1)-(LShift[2, 7]C), 						DblBranch[ExpOverflow, .+2, R<0];NoRounding:* Subtract 2 from exponent; Branch if exponent > 377B originally	ExpSign1_ (ExpSign1)-(LShift[2, 7]C), 	Branch[ExpOverflow, R<0]; * Extract high 7 fraction bits, exclude leading 1, *  Branch if exponent < 2 originally	T_ LDF[Frac1H, 7, 10], Branch[ExpUnderflow, ALU<0];  	* Here, ExpSign1[1:8] = desired exponent -1, and [9:15] = 176 if*  the sign is positive, 177 if negative.  Thus adding 2 (if positive)*  or 1 (negative) will correctly adjust the exponent and clear [9:15].	* Merge exponent with fraction and add 1.  Branch if negative	T_ (ExpSign1)+T+1, Branch[.+2, R odd];			* Positive, add 1 more to finish fixing exponent		Stack&-1_ T+1, Branch[.+2];				Stack&-1_ T or (signBit);	* Negative, set sign bit of result	T_ Frac1H;								* Construct low fraction	T_ rcy[T, Frac1L, 10];	Stack&+1_ T, branch[.StoreFloat];ExpOverflow:	CallUFN;ExpUnderflow:	CallUFN;*-----------------------------------------------------------FRePackZero:* Push a result of zero with the correct sign* Enter: ExpSign1 has correct sign*	StkP addresses high word of result (i.e., =2 if minimal stack)*-----------------------------------------------------------	T_ LSH[ExpSign1, 17];				* Slide sign to bit 0	Stack&-1_ T;							* Push true zero with correct signFRePackZ2:	Stack&+1_ A0, branch[.StoreFloat];*-----------------------------------------------------------* .StoreFloat:   * StackBr in effect*-----------------------------------------------------------:if[StackEmpty!];.StoreFloat:	T_ (StackEmpty);	RBase_ RBase[LTEMP0];:else;.StoreFloat:	T_ A0, RBase_ RBase[LTEMP0];:endif;KnowRBase[LTEMP0];	CELLHINUM_ Stack&-1;	CELLLONUM_ Stack;	StkP_ T;								* Resets the hardware stack	NARGS_ 2c;							* All floating ops have two args, or 4	memBase_ dtdBR; 					*  wds on stack;  2c must come off.	T_ (LShift[floatpType!, 4]c), Branch[TL.CREATECELL];