Insert[DisplayDefs];	*Defs file common to DisplayInit and Display:IF[LFKeyBoard];	*Ed Fiala 3 June 1982  TITLE[LFDisplay];:ELSE;  TITLE[Display];:ENDIF;* Included vFrameRate unconditionally June 21, 1982  12:19 PM van MelleLoca[IZTab0,DisplayPage,20];	*1st Dispatch for initial zeroesLoca[IZTab4,DisplayPage,40];	*2nd Dispatch for initial zeroesLoca[dSendMem,DisplayPage,60];	*2-way Dispatch avoiding branch burpLoca[FZTab0,DisplayPage,100];	*1st Dispatch for final zeroesLoca[FZTab4,DisplayPage,120];	*2nd Dispatch for final zeroesLoca[dNL16,DisplayPage,140];	*Dispatch for final data IOFetch4'sSetTask[0];:IF[or[LFKeyBoard, NotDpyOverlay]]; ******************************%Alto.Mc jumps here on opcode 61027b.  T contains AC0, the new frame-fillparameter.  The old frame-fill parameter is returned in AC0.  The valuesnormally used are 11b (normal 77 Hz.) and 213b (videotaping 60 Hz.).Only assemble this code for the resident to avoid overwriting xoPage inthe overlay.%OnPage[xoPage];vFrameRate:	RTemp _ IP[vFieldFill]C;	StkP _ RTemp;	MNBR _ Stack, Stack _ T, NoRegILockOK;	T _ MNBR, GoTo[TtoAC0CSR];	*In Alto.Mc:ENDIF; ***************************************%Alto.Mc jumps here on opcode 61033b.  AC0 is -1 to make the full monitorwidth available, 0 to revert to Alto-size picture.  The resulting maximumdisplay width is returned in AC0.  This code presently always returns 38d(i.e., the Alto-compatible words/scanline) as the result even on LF monitorsbecause huge extra overhead would result unless the horizontal RAM isreloaded when changing the width.  The implementation is put here ratherthan on xoPage to allow variant implementations for Lisp and Smalltalk,if desired.%OnPage[DisplayPage];dpDspWid:	AC0 _ WordsPerLine, Return, At[dpWidthLoc];SetTask[DpTask];*Initialization and end-of-field come to vFDone. vFDone must be absolutely*placed at an odd location so that the exit from display initialization*to here will be the same for both LF and CSL keyboard microcode.:IF[LFKeyBoard]; ******************************Macro[KBCheck,GoTo[vChkMsg]];vFDone:	T _ LdF[vCR,15,1], At[FldDoneLoc];*Set up to load cursor memory--mask Field bit.	vCursorY _ (Zero) xnor T, GoTo[.+3,ALU#0];	*Test field	  vCursorControl _ 0C;		*Even scan lines next	  T _ (vFieldFill) - 1, GoTo[.+3];	  vCursorControl _ 4000C;		*Odd scan lines next	  T _ vFieldFill;	vCnt _ T;	vNWrds _ lfSyncLength;*vLink_lfBlankLength done below.*Complement even/odd field bit and turn on blanking	vCR _ (vCR) xor (OddFld&Blank), Call[vKBOut];*Two extra scanlines for LF keyboard to post results*1st scanline posts mouse x,y and buttons; vMouseXY contains two signed*7-bit numbers in bits 0:6 and 9:15 added to VM 424 and 425, respectively.	PFetch4[vMDS420,vDBuf0,4];	*Mouse X,Y, --, --	T _ LdF[vMouseXY,0,7];	vMouseXY _ LCy[vMouseXY,11], Skip[R>=0];	  vDBuf0 _ (vDBuf0) - (200C);	vDBuf0 _ (vDBuf0) + T;	T _ LdF[vMouseXY,0,7], Skip[R>=0];	  vDBuf1 _ (vDBuf1) - (200C);	vDBuf1 _ (vDBuf1) + T;	vMouseXY _ 0C;	PStore4[vMDS420,vDBuf0,4];*Mouse buttons; vDBuf0 and vTemp stored into 177030 and 177033 by PStore4.*Here the mouse buttons are in vButtons[11:13d]; power supply normal, VS,*and video are in vButtons[8:10] but not used.	T _ (vButtons) and (4C);	T _ (LdF[vButtons,13,2]) or T;	T _ vDBuf0 _ (Zero) xnor T;	vTemp _ T;	T _ (vZero) - (350C);		*177030-177400	PStore4[vMDS177400,vDBuf0], Call[vKBIn];	*Check input & task*Have 0 to 2 characters represented in vKeyBuffer; determine the bit and*word position in the bit table in VM 177034 - 177043 by lookup in IM*KeyTable; set/clear that bit according to key down/up.*Smashes vTemp, vDBA (= vSize), and vBase; initializes vLink.@vVB0:	LU _ LHMask[vKeyBuffer], Call[vPostKey];:ELSE; ****************************************Macro[KBCheck,DblGoTo[vM1,vM0,IOAtten']];Set[DisplayPage2,DisplayPage];Set[DisplayPage3,DisplayPage];vFDone:	Input[vTemp,0,vTemp], At[FldDoneLoc];	*Controller ID in bits 10:14b	T _ LdF[vCR,15,1];	vCursorY _ (Zero) xnor T, Skip[ALU#0];	*Test field	  vCursorControl _ 0C, Skip;	*Even scan lines next	  vCursorControl _ 4000C;		*Odd scan lines next	T _ (vFieldFill) + T;	LU _ (vTemp) and (40C);	*value 3 or 11 for LF, 5 for CSL display	vCnt _ T, GoTo[vCSLMon,ALU#0];*Here if LF (Ball) monitor	vNWrds _ lfSyncLength;	vLink _ lfBlankLength, GoTo[vCSLKB];vCSLMon:	vNWrds _ cslSyncLength;	vLink _ cslBlankLength;vCSLKB:	vCR _ (vCR) xor (OddFld&Blank), Call[vKBOut];	*Start blanking:ENDIF; ****************************************Repeat VSStart+1 or +2 times (-1 if LF KB) for blank lines at end of fieldvVB1:	Input[vTemp,0,vCnt], GoTo[vKBIOS,R>=0];*Start VSync	PFetch2[vMDS420,vDBA,6];	*Fetch Cursor X and Y from 426b-427b	vCR _ (vCR) or (VS);	vCnt _ 7C, Call[vKBOut];@vVS0:	T _ vSLC, Skip[R Even];		*Cursor Y coordinate*Y odd => invert earlier decision on which scanline of the cursor goes first.	  vCursorControl _ (vCursorControl) xor (4000C); *vCursorY init to Ycoord - (1 if B,2 if A); counts down by 2/scanline*until negative; shows cursor for 8 scan-lines; finally, sets vCursorY*to large pos. number to disable until end-of-field	vCursorY _ (vCursorY) + T;	vDBA _ (vDBA) xnor (0C), Call[.+1];	*vDBA _ cursor X'*Continue VSync; load 1st 8 words of cursor memory in 8 scanlines@vVS1:	T _ 11C, A _ vCnt, NoRegILockOK, GoTo[vLdCur,R>=0];	vDBA _ (vDBA) + (4C), Call[.+1];	*increment in nibble number*Continue VSync; repeats vSyncLength+1 scanlines@vVS2:	Input[vTemp,0,vNWrds], Skip[R<0];	  vNWrds _ (vNWrds) - 1, IOStrobe, KBCheck;	vNWrds _ Add[40000,vStart]C;	Output[vNWrds,vBufStart];	*Start_vBufSt, ForceIARLoad'_0	vCR _ (vCR) and not (VS);	Output[vZero,vLdIAR];		*IAR_Start (resynchronize)	vCurrentY _ vMaxYh;*End VSync	vCurrentY _ (vCurrentY) + (vMaxYl), Call[vKBOut];*Repeat vBlankLength+1 blank scanlines at top of field@vVB2:	Input[vTemp,0,vLink], Skip[R<0];	  vLink _ (vLink) - 1, IOStrobe, KBCheck;*Start frame@vStF:	vCR _ (vCR) and not (Blank);*Fetch chain head (vLink) & interrupt word (vNWrds).  Here IOAtten is setup*by the two low address bits of vLink being 00.	PFetch2[vMDS420,vLink,0];	T _ (vDBA) and not (176000C), Call[vSF1];	*save low ten bits	vTemp _ Add[140000,vStart]C;	*ReSync IAR	Output[vTemp,vBufStart];	*Start_vBufSt, ForceIARLoad'_1**NOTE: Must check IOAtten for the backchannel prior to posting the interrupt**request with DoInt--these output to RS232 device disturbing IOAtten.*Field interrupt bits in T; DoInt tasks, smashes vDBuf0 and vDBuf1.	LoadPageExternal[DoIntPage];	T _ vNWrds, IOStrobe, CallExternal[DoIntLoc];*Set CEnable bit; set cursor word number to largest line, so that it will*count to 0/1 when cursor is first shown.	vCursorControl _ (vCursorControl) or (172000C), GoTo[vNextDCB];*Add X to initial Y.vSF1:	vCursorControl _ (LHMask[vCursorControl]) + T, KBCheck;vKBOut:	Output[vCR,vCReg];	*Avoid Output-Output-PStore4 problem by	Nop;			*waiting here for 5 mi	IOStrobe, GoTo[vChkMsg];*SUBROUTINE vLdCur loads one word of the cursor memory, then goes to vChkMsg.vLdCur:	T _ (LdF[vCursorControl,1,4]) + T;	PFetch1[vMDS420,vDBuf1];	*Fetch word to load (VM 431+vSLC.1..4)	vCursorControl _ LHMask[vCursorControl];	vTemp _ 2C, Skip;*Loop 4 times (one nibble each time)vLdCLp:	vCursorControl _ (vCursorControl) + (4C);*vTemp as base reg. prevents abort	Output[vCursorControl,vCursor0,vTemp];	vDBuf1 _ LCy[vDBuf1,4];	Output[vDBuf1,vCursorMem0,vTemp], Skip[R<0];	  vTemp _ (vTemp) - 1, GoTo[vLdCLp];	vCursorControl _ (vCursorControl) + (10000C);vKBIn:	Input[vTemp,0];	*Set up IAddr.6..7 = 0 to make IOAtten reference			*channel 0 for vChkMsgvKBIOS:	vCnt _ (vCnt) - 1, IOStrobe, KBCheck;*Here when DCB chain is exhausted but not done with field yet.vFrameDone:	T _ vCurrentY, Call[vCyg0];*For zero-width DCBs send two scan lines of zeroes (to fill the two ping-pong*buffers), then do only cursor and message checking until the next DCB.vWidZ:	Output[vCR,vCReg];	Call[vFZ38];	*Fill 1st buffer (Avoid Output here for vCR write)	Call[vFZ38];	*Fill 2nd buffer*Loop checking for messages & cursor.  Since only 16x16 of the hardware's*32x32 cursor is used, it is shown 8 scanlines/field and then disabled on*the following scanline.**Should figure a way to avoid checking both vCursorY and vSLC here**vFZ38x:	vCursorY _ (vCursorY) - (2C), GoTo[NoCursor,R>=0];	vCursorControl _ (vCursorControl) + (10000C);	LU _ (vCursorControl) + (10000C), Skip[ALU>=0];*Last was final cursor line--disable cursor now.	  vCursorControl _ (vCursorControl) and not (102000C);	Output[vCursorControl,vCursor0], Skip[ALU>=0];*Set vCursorY to count to a large positive number after one more iteration.	  vCursorY _ 100000C;	vSLC, DblGoTo[Cursn,Cursm,R<0];NoCursor:	Input[vTemp,0,vSLC], Skip[R<0];	*Skip if DCB or field exhaustedCursm:	  vSLC _ (vSLC) - 1, IOStrobe, KBCheck;Cursn:	vSLC _ (vSLC) - 1, IOStrobe, Call[vChkMsg];%Worst timing and wakeup requirements for a scanline begin here: a long DCBcoincident with final cursor line, mouse XY end-of-message on backchannel,unfavorable data alignment so no IOFetch16's can be used, 5-word tab,and 3 final zero words/scanline.  DCB setup and the 1st scanline must completein about 29 us (LF) or 38 us (CSL), and worst timing for any one lower and allhigher priority tasks must also be allowed for.  The emulator is presentlyrestricted to about 44 cycles between tasks, and the timer task to about 38cycles; disk and ethernet controllers unfortunately have some code thatruns even longer without tasking.On one Bravo display, it was observed that tasking once after setting up thescanline loop worked for CSL monitors but seemed solidly too slow for LFmonitor/keyboards; since the cursor was not being shown at the same time,nor the slow mouse XY end-of-message code for the CSL monitor being executed,we can infer cases worse than the one observed--removing the task aftersetting up the scanline fixed this problem.  After this observation, the DCBsetup microcode has been improved about 10 cycles and worst cases inend-of-message code about 8 cycles; however, it does not seem desirable toput the task after DCB setup back into the code unless additionalimprovements are made in worst case timing.NOTE RESTRICTIONS:1) No bitmap is permitted to cross a 64k boundary;2) DCB's all must be located in MDS.DCB format (Check this out):word   0	Link to next DCB (Zero terminates DCB chain)word   1	Bit 1 is 0 for white background, 1 for black background		Bits 3:7 are tab count (nzeroes sent before memory data).		Bits 8:15 are the no. data words/scanline; must be even.word   2	Pointer to DCB if scan line count sign is 0 else a password		(177423b) enabling the long pointer; if password is wrong,		DCB chain terminates.word   3	scan line count (sign bit 1 means "long")words 4-5	Long pointer to DCB if scan line count sign is 1%vNextDCB:vCurrentY _ (vCurrentY) - 1;vDoDCB:	T _ (vLink) + (2C), GoTo[vFDone,ALU<0];	PFetch2[vMDS,vDBA];	*Fetch DBA and SLC (spurious fetch from				*location 2 if Link=0):IF[AltoXMMode]; **************************	vBase _ T, LoadPage[DisplayPage2];	*Bypass kludge to get Link+2	T _ 351C;		*Add bits 14:15b of 177751 to vMDShiOnPage[DisplayPage2];	PFetch1[vMDS177400,vTemp];	T _ vLink, LoadPage[DisplayPage];	PFetch2[vMDS,vLink];	*Fetch Link & NWrdsOnPage[DisplayPage];:ELSE; ************************************	vBase _ T;		*Bypass kludge to get Link+2	T _ vLink;	PFetch2[vMDS,vLink];	*Fetch Link & NWrds:ENDIF; ***********************************	T _ vMDShi, Skip[ALU#0];	*Skip if Link .ne. 0	  GoTo[vFrameDone];	vBasehi _ T;*Bias the scan line count, clear and branch on the long DCB flag	vSLC _ (LdF[vSLC,1,17]) - 1, GoTo[LongDCB,R<0];:IF[SingleDCBMode]; ***********************	vSingleDCBFlag _ 0C;:ENDIF; ***********************************:IF[AltoXMMode]; **************************	T _ vDBA, LoadPage[DisplayPage3];	vBase _ T, LoadPage[DisplayPage];OnPage[DisplayPage3];	vTemp _ T _ RSh[vTemp,2];OnPage[DisplayPage];	T _ (LSh[vTemp,10]) or T;	vBasehi _ (vBasehi) + T;:ELSE; ************************************	T _ vDBA;	vBase _ T;:ENDIF; ************************************Timing = 25 cycles (short pointer) or 39 cycles (long pointer) to here.*vSLC _ Min(vCurrentY,vSLC)-1; vCurrentY _ vCurrentY-vSLC+1ChkBkgnd:	vSLC _ T _ (vSLC) - 1;	vCurrentY _ (vCurrentY) - T - 1;	LU _ Dispatch[vNWrds,1,1], GoTo[ChkBk1,ALU>=0];	  T _ (vCurrentY) + T, Call[vCyg0];	  LU _ Dispatch[vNWrds,1,1];ChkBk1:	T _ RHMask[vNWrds], Disp[.+1]; *Field bit	vCR _ (vCR) and not (BlackBackground), DblGoTo[vWidNZ,vWidZ,ALU#0], DispTable[2];	vCR _ (vCR) or (BlackBackground), DblGoTo[vWidNZ,vWidZ,ALU#0];vCyg0:	vSLC _ T, UseCTask;	vCurrentY _ Zero, Return;LongDCB:	PFetch2[vBase,vBase,2];	*Fetch long pointer at Link+4:IF[SingleDCBMode]; ***********************	vSingleDCBFlag _ 1C;:ENDIF; ***********************************	LU _ (vDBA) xnor (354C);	*do the dcb only if DCB[3] = 177423b	vBasehi _ LSh[vBasehi,10], DblGoTo[vFrameDone,ChkBkgnd,ALU#0];**Since 64k-boundary crossings aren't handled correctly in the code which**follows, this initialization is pointless.*	vBasehi _ T _ LSh[vBasehi,10];*	T _ vBasehi _ (RSh[vBasehi,10]) + T + 1;	*Fix up long pointer*	vBasehi _ (FixVA[vBasehi]) or T, GoTo[ChkBkgnd];:IF[IFG[WordsPerLine!,46,1,0]]; ***********vFZ38:	IOFetch16[vMDS177400,vfBuf0,0];	IOFetch16[vMDS177400,vfBuf0,0];	IOFetch16[vMDS177400,vfBuf0,0];	IOFetch16[vMDS177400,vfBuf0,0], GoTo[vFZ38x];:ELSE; ************************************vFZ38:	Output[vZero,vBuf0];	Output[vZero,vBuf0];	IOFetch4[vMDS177400,vfBuf0,0];	IOFetch16[vMDS177400,vfBuf0,0];	IOFetch16[vMDS177400,vfBuf0,0], GoTo[vFZ38x];:ENDIF; ***********************************%Original vNWrds contains the following:vNWrds: [0]			unused	[1]			BlackBackground	[2]			unused	[3:7]	TabCount	nzeroes to send before sending memory data	[8:15]	WordCount	No. data words/scanline.  Unused if DCB.Width				= 0; might exceed 46b; must be EVEN because				each bitmap must start on even word.Compute values for vNWrds and vSize as follows:vNWrds: [0:2]			unused	[3:7]	TabCount	no. of initial zero words	[8:15]	BaseAdjust	nwords to add to vBase to get start of next				scanline's bitmap.  Because of interleaving				this will be 2*WordCount - words transmitted				which will be EVEN.vSize:	[0]	FinalFillIsZero	means FinalFill is uninteresting	[1]			unused	[2:7]	FinalFill	number of zeros to fill out the scanline	[8]			unused	[9:15]	DataCount	nwords to send to controller from bitmap;				will be EVENNOTES:(1) Since each bitmap starts on an even word, interleaved scanlines will bespaced by 4*n words, so the decision about whether a scanline is quadalignedcould be done during DCB setup rather than on each scanline.%*DCB setup timing is 36 to 50 cycles to here (+9 if last DCB overflows field)*vCR[0] = complement of vCR[15b] so that ALU<0 test can be used here.vWidNZ:	Dispatch[vCR,15,1];	vSize _ WordsPerLine, Disp[.+1];	vBase _ (vBase) + T, DispTable[2];	*Odd field--offset by WordCount	LU _ LdF[vNWrds,3,5], Call[vWidthSetup];	*Even field--no offset*DCB setup timing is 53 to 78 cycles to here (+9 if last DCB overflows field):IF[SingleDCBMode]; ***********************	Output[vCR,vCReg], Call[.+1];:ENDIF; ************************************Wakeup here once/scanline in the DCB when there are no leading 0's**Note: every cycle here degrades emulator performance about 0.3%.	Dispatch[vBase,16,1], GoTo[vDSend];:IF[SingleDCBMode]; ************************Subtract desired number of words from 46b to get number of trailing 0'svWidthSetup:	vSize _ (vSize) - T, GoTo[vTabNZ,ALU#0];:ELSE; ************************************vWidthSetup:	Output[vCR,vCReg], GoTo[vTabNZ,ALU#0];*Subtract desired number of words from 46b to get number of trailing 0's	  vSize _ (vSize) - T;:ENDIF; ***********************************	  LU _ vSize, GoTo[vEndSz,ALU>=0];	*Go if it fits*Specified size is too big--truncate to 38d words	  vNWrds _ (vNWrds) + T;	  T _ vSize _ WordsPerLine;	*size = 46b = 38d*vNWrds[10:17] _ 2 x vNWrds - WordsPerLine	  vNWrds _ (vNWrds) - T, GoTo[vEndSa];*DCB setup timing is 60 to 82 cycles to here.:IF[SingleDCBMode]; ***********************vTabNZ:	T _ LdF[vNWrds,3,5], Call[vScanI];	Output[vCR,vCReg], Call[.+1];:ELSE; ************************************vTabNZ:	T _ (LdF[vNWrds,3,5]) + T, Call[vScanI];:ENDIF; ************************************Wakeup here once/scanline in the DCB when there are leading 0's	Dispatch[vNWrds,6,2], GoTo[vIZSnd];*DCB setup timing is 48 to 64 cycles to herevScanI:	vSize _ (vSize) - T;	*WordsPerLine - WordCount - TabCount	T _ RHMask[vNWrds], Skip[ALU<0];	*check for fit	  LU _ vSize, GoTo[vEndSz];		*it fits*Scanline too big--truncate to WordsPerLine words; one final zero if TabCount*odd.  BaseAdjust is 2*WordCount - [WordsPerLine - TC] =*2*nwords desired sent - nwords sent, where TC is TabCount+1 if TabCount odd.	vNWrds _ (vNWrds) + T + 1;		*TabCount,,2*WordCount+1	T _ vSize _ (vSize) + T, Skip[R Odd];	*WordsPerLine-TabCount	  vNWrds _ (vNWrds) - T - 1, GoTo[vEndSa];	*2*WordCount-(WordsPerLine-TabCount)	vSize _ (vSize) + (400C);		*Final zero if TabCount odd	vNWrds _ (vNWrds) - T, GoTo[vEndSb];	*2*WordCount-(WordsPerLine-TabCount-1)vEndSz:	vSize _ (LSh[vSize,10]) or T, Skip[ALU#0];vEndSa:	  vSize _ (vSize) or (100000C);		*Set FinalFillIsZero:IF[SingleDCBMode]; ***********************vEndSb:	Input[vTemp,0,vSingleDCBFlag], Skip[R Odd];	  vCnt _ T, UseCTask, GoTo[vNoMsg];	vCnt _ T, IOStrobe, KBCheck;:ELSE; ************************************vEndSb:	vCnt _ T, UseCTask, GoTo[vNoMsg];:ENDIF; ************************************Dispatch Table for initial zero memory references.vIZSnd:	Dispatch[vNWrds,3,3], Disp[.+1];	*Tab if necessary	Output[vZero,vBuf0], At[IZTab0,3];	Output[vZero,vBuf0], At[IZTab0,2];	Dispatch[vNWrds,3,3];	Output[vZero,vBuf0], Disp[.+2], At[IZTab0,1];	Disp[.+1], At[IZTab0,0];	IOFetch4[vMDS177400,vfBuf0,0], At[IZTab4,7];	IOFetch4[vMDS177400,vfBuf0,0], At[IZTab4,6];	IOFetch4[vMDS177400,vfBuf0,0], At[IZTab4,5];	IOFetch16[vMDS177400,vfBuf0,0], At[IZTab4,4], GoTo[vIZ00];	IOFetch4[vMDS177400,vfBuf0,0], At[IZTab4,3];	IOFetch4[vMDS177400,vfBuf0,0], At[IZTab4,2];	IOFetch4[vMDS177400,vfBuf0,0], At[IZTab4,1];vIZ00:	Dispatch[vBase,16,1], At[IZTab4,0];*Have 170b in T; know that vCnt .gr. 0 words will be sent (must be EVEN)vDSend:	vCnt _ (vCnt) - (20C), Disp[.+1];	PFetch2[vBase,vDBuf0,0], At[dSendMem,1];	vBase _ (vBase) + (2C);	vCnt _ (vCnt) - (2C);**NOTE: vCnt as the base register below prevents a 6 cycle abort.	Output[vDBuf0,vBuf0,vCnt], Skip[ALU>=0];	  Output[vDBuf1,vBuf0,vCnt], GoTo[vNL16];	Output[vDBuf1,vBuf0,vZero];*Now vBase is quadaligned; do IOFetch16's so long as vBase[10:17b] .le. 360b*(HW manual indicates a hex-aligned restriction, but it is wrong) and there*are 20b or more words left to transfer.vNLQ3:	LU _ (LdF[vBase,10,7]) - T - 1, GoTo[vNL16,ALU<0], At[dSendMem,0];vNLQ4:	vCnt _ (vCnt) - (4C), GoTo[vNLQ2,Carry'];	  IOFetch4[vBase,vfBuf0,0], Skip[ALU>=0];	    vBase _ (vBase) + (4C), GoTo[vNL16];	  vBase _ (vBase) + (4C);	  LU _ (LdF[vBase,10,7]) - T - 1, GoTo[vNLQ4];vNLQ2:	IOFetch16[vBase,vfBuf0,0];	vBase _ (vBase) + (20C);	vCnt _ (vCnt) - (14C), GoTo[vNLQ3];*Usually get here following an IOFetch16, when MC1 is busy for 16d cycles,*so do the cursor check here.  Following an IOFetch4, showing the cursor*adds 11 cycles; following IOFetch16, it adds 11 or 14 cycles.vNL16:	vCursorY _ (vCursorY) - (2C), GoTo[vNL16b,R>=0];	  vCursorControl _ (vCursorControl) + (10000C);	  LU _ (vCursorControl) + (10000C), Skip[ALU>=0];	    vCursorControl _ (vCursorControl) and not (102000C);	  Output[vCursorControl,vCursor0,vCnt], Skip[ALU>=0];	    vCursorY _ 100000C;	*Next scanline, disable cursor	  vSLC _ (vSLC) - 1, IOStrobe, DblGoTo[vNL16c,vNL16d,R<0];vNL16b:	vSLC _ (vSLC) - 1, IOStrobe, GoTo[vNL16d,R>=0];*Last scanline of DCB; change TPC to initiate DCB setup.vNL16c:	  T _ LdF[vSize,11,7], Call[vNL16e];	  vCurrentY _ (vCurrentY) - 1, GoTo[vDoDCB];vNL16d:	T _ LdF[vSize,11,7];vNL16e:	vCnt _ T, Dispatch[vCnt,14,3], NoRegILockOK;	T _ RHMask[vNWrds], Disp[.+1];*In the common case, 17 cycles intervene between the preceding IOFetch16*and the first IOFetch4 in this dispatch table, and MC1 has been busy for*16 of the 17 cycles.	IOFetch4[vBase,vfBuf0,0], At[dNL16,7];	vBase _ (vBase) + (4C);	IOFetch4[vBase,vfBuf0,0], At[dNL16,5];	vBase _ (vBase) + (4C);	IOFetch4[vBase,vfBuf0,0], At[dNL16,3];	vBase _ (vBase) + (4C);	PFetch2[vBase,vDBuf0,0], At[dNL16,1];	vBase _ (vBase) + (2C);**NOTE: vCnt as the base register below prevents a 6 cycle abort.**Careful to ensure 5 mi after final Output to avoid Gotcha	Output[vDBuf0,vBuf0,vCnt];	Dispatch[vSize,6,2];	Output[vDBuf1,vBuf0,vCnt], Disp[vFin0s];	IOFetch4[vBase,vfBuf0,0], At[dNL16,6];	vBase _ (vBase) + (4C);	IOFetch4[vBase,vfBuf0,0], At[dNL16,4];	vBase _ (vBase) + (4C);	IOFetch4[vBase,vfBuf0,0], At[dNL16,2];	vBase _ (vBase) + (4C);*Dispatch on 2 low bits of final-zero count and the FinalFillIsZero bit	Dispatch[vSize,6,2], Skip[R>=0], At[dNL16,0];	  vBase _ (vBase) + T, KBCheck;	*No final fill	Disp[vFin0s];*Dispatch Table for final zero memory references.vFin0s:	Output[vZero,vBuf0], At[FZTab0,3];*Careful to ensure 5 mi after Output, Output to the Return, avoiding*Output-Output-PStore4 problem	Output[vZero,vBuf0], At[FZTab0,2];	Output[vZero,vBuf0], At[FZTab0,1];	Dispatch[vSize,2,4], At[FZTab0,0];	vBase _ (vBase) + T, Disp[.+1];*Entries 12 to 17 in this table are not needed since max. count is 36dIFG[WordsPerLine!,100,ER[WordsPerLine.Too.Large]];:IF[IFG[WordsPerLine!,46,1,0]]; ***********	IOFetch4[vMDS177400,vfBuf0,0], At[FZTab4,17];	IOFetch4[vMDS177400,vfBuf0,0], At[FZTab4,16];	IOFetch4[vMDS177400,vfBuf0,0], At[FZTab4,15];	IOFetch16[vMDS177400,vfBuf0,0], At[FZTab4,14], GoTo[vFZ32];	IOFetch4[vMDS177400,vfBuf0,0], At[FZTab4,13];	IOFetch4[vMDS177400,vfBuf0,0], At[FZTab4,12];:ENDIF; ***********************************	IOFetch4[vMDS177400,vfBuf0,0], At[FZTab4,11];vFZ32:	IOFetch16[vMDS177400,vfBuf0,0], At[FZTab4,10], GoTo[vFZ16];	IOFetch4[vMDS177400,vfBuf0,0], At[FZTab4,7];	IOFetch4[vMDS177400,vfBuf0,0], At[FZTab4,6];	IOFetch4[vMDS177400,vfBuf0,0], At[FZTab4,5];vFZ16:	IOFetch16[vMDS177400,vfBuf0,0], At[FZTab4,4], KBCheck;	IOFetch4[vMDS177400,vfBuf0,0], At[FZTab4,3];	IOFetch4[vMDS177400,vfBuf0,0], At[FZTab4,2];	IOFetch4[vMDS177400,vfBuf0,0], At[FZTab4,1], KBCheck;vChkMsg:	LU _ vMsgStatus, DblGoTo[vM1,vM0,IOAtten'], At[FZTab4,0];:IF[LFKeyBoard]; ******************************%LF KEYBOARD SUBROUTINE vChkMsg:vMsgStatus holds keyboard process state information.  The count field isinitialized to minus number of bits in the field and incremented as each bitcomes in.  When count reaches zero, the carry-out of the count incrementsthe state.  The field sizes and their associated state are: state size   0        idle   1     4  x mouse delta, twos complement   2     4  y mouse delta   3     3  mouse buttons (and status are lumped together in single field)         4  status (video, VS, power supply normal, key data follows)   4    10  key data (7 bits of key, 1 bit of up/down)   5        post key dataThe mouse resolves 200 pixels/inch.  35 inches/sec is the maximum speedrequired for tracking the mouse.  We update the mouse position once everyfield, ~77 times a second.  Therefore tracking the mouse at maximum velocityrequires a field large enough hold 35*200/77 = 91d counts.  Adding 1 bit forsign mandates an 8 bit field for x and another 8 bit field for y.  Note thatthis uses 7 bit fields.Timing = 4 cycles when idle, 6 cycles for the 1st bit in a message, 12 or 14cycles for non-transition bits of the message, 15 or 17 cycles for key data,19 to 24 cycles for mouse X or Y, and 17 to 20 cycles for buttons and status.%MC[keyStart,75];	*initial state, count=-4+1, state=1vM1:	vMsg _ RSh[vMsg,1], GoTo[vMsgContinue,ALU#0];	*Zeroes herevNoMsg:	T _ 170C, Return;vM0:	vMsg _ RSh[vMsg,1], Skip[ALU#0];	*Ones here	  vMsgStatus _ keyStart, GoTo[vNoMsg];	vMsg _ (vMsg) + (100000C);vMsgContinue:	LU _ LdF[vMsgStatus,13,5];	Dispatch[vMsgStatus,10,3], Skip[ALU=0];	*Dispatch on state bits	  vMsgStatus _ (vMsgStatus) + 1, GoTo[vNoMsg];	T _ RSh[vMsg,10], Disp[.+1];	vMsgStatus _ (vMsgStatus) or (35C), GoTo[keyX], DispTable[4,17,2]; *X	vMsgStatus _ (vMsgStatus) or (32C), GoTo[keyY];	*Y	T _ RSh[vMsg,7], DblGoTo[keyBS,keyBSI,R<0];	*Buttons/status	vKeyBuffer _ (LSh[vKeyBuffer,10]) or T;		*key data	vMsgStatus _ 0C, GoTo[vNoMsg];keyX:	vMsg _ RSh[vMsg,14], Skip[R>=0];	  vMsg _ (vMsg) or (170C);	*neg., extend sign to seven bits	T _ LSh[vMsg,11], GoTo[keyX1];keyY:	T _ vMsg _ RSh[vMsg,14], Skip[R>=0];	  T _ vMsg _ (vMsg) or (170C);	*neg., extend sign to seven bits	vMouseXY _ (vMouseXY) and not (400C);keyX1:	vMouseXY _ (vMouseXY) + T, GoTo[vNoMsg];keyBS:	vMsgStatus _ (vMsgStatus) or (31C), Skip;keyBSI:	vMsgStatus _ 0C;		*Message ends here	vButtons _ T, GoTo[vNoMsg];*KeyBoard Translation Table from Level III to Alto*Entry in the table is bitnumber*8+wordnumberSet[ByteLoc,KeyTable];Macro[Byte,IMData[LH[LShift[#1,10],#2] RH[LShift[#3,10],#4] At[ByteLoc]]    Set[ByteLoc,ADD[ByteLoc,1]]];KTable:Byte[177,177,177,177];	*00Byte[177,177,177,177];Byte[177,177,177,177];Byte[177,177,177,177];			*04:Byte[005,115,150,105];	* D1, T10(\), T9, T8.Byte[075,171,065,163];	* T7, R6(BW), T6, L12(FL4).Byte[172,160,055,045];	* L9(FL3), L6(LF), T5, T4.Byte[035,012,025,177];	* T3, T2, T1(esc), .			*10:Byte[164,177,173,144];	* R4, , R1, R2.Byte[004,125,177,024];	* R5, R3(FR5), , L10.Byte[034,044,054,177];	* L7, L4, L1.Byte[177,064,177,177];	* , A9, , .			*14:Byte[154,074,161,155];	* R7, R10, R11, R8.Byte[014,153,113,042];	* R9(FR4), R12(swat), A7(space), L11(CTL).Byte[114,124,134,162];	* L8, L5, L2, L3(DEL).Byte[104,165,177,177];	* A8, A11, , .			*20:Byte[177,175,143,140];	* , A12, A6(shift-R), /.Byte[122,131,073,063];	* ., (comma), m, n.Byte[072,070,052,101];	* b, v, c, x.Byte[102,177,135,177];	* z, , 47, .			*24:Byte[142,152,141,132];	* A4(Return), 46(_), (quote), :.Byte[121,110,062,043];	* l, k, j, h.Byte[023,032,050,041];	* g, f, d, s.Byte[051,177,103,112];	* a, , A3(lock), A5(shift-L).			*30:Byte[145,151,123,130];	* A10, 45(]) , 42([), p.Byte[111,071,060,033];	* o, i, u, y.Byte[013,003,030,021];	* t, r, e, w.Byte[031,022,177,174];	* q, A1(tab), , D2.			*34:Byte[170,133,120,100];	* A2(bs), =, -, 0Byte[061,053,040,020];	* 9, 8, 7, 6.Byte[000,010,001,011];	* 5, 4, 3, 2.Byte[002,015,177,177];	* 1, 48, , .OnPage[DisplayPage];vPostKey:	vTemp _ HiA[KeyTable], GoTo[vPKey2,ALU#0];	*if no data, Return right away	  vKeyBuffer _ LSh[vKeyBuffer,10];	*shift to other KB char	  vTemp _ (vTemp) or (LoA[KeyTable]), GoTo[vPKey3,ALU#0];vPKey1:	  vLink _ lfBlankLength, GoTo[vVB1];vPKey2:	vTemp _ (vTemp) or (LoA[KeyTable]);vPKey3:	T _ LdF[vKeyBuffer,1,5];	*Get word number (4 bytes per word)	vTemp _ (vTemp) + T;		*Form final address	T _ LdF[vKeyBuffer,6,1];	*Set h2 to high/low word	APCTask&APC _ vTemp;		*Address to read in Control Store	ReadCS;		*Get the word	T _ CSData, DispTable[1,1,0];	*Even loc after ReadCS	vLink _ T, LoadPage[lfKBPage];	LU _ LdF[vKeyBuffer,7,1];	*low or high byteOnPage[lfKBPage];	T _ (vZero) - (344C), Skip[ALU#0];	*T _ 177034 - 177400	  vLink _ RSh[vLink,10];	*Need upper byte	T _ (LdF[vLink,15,3]) + T;	*Get word number	PFetch1[vMDS177400,vDBA];	*vDBA is a temp--fetch Alto kbd word*T _ vTemp _ 100000b rshift vLink[11b:14b].	Dispatch[vLink,13,2];	vLink _ T, Dispatch[vLink,11,2], NoRegILockOK, Disp[.+1];	T _ vTemp _ 100000C, Disp[vPK1], DispTable[4];	T _ vTemp _ 40000C, Disp[vPK1];	T _ vTemp _ 20000C, Disp[vPK1];	T _ vTemp _ 10000C, Disp[vPK1];*Test for key down (0) or up (1).vPK1:	vKeyBuffer _ RHMask[vKeyBuffer], DblGoTo[vPKNZ,vPKZ,R<0], DispTable[4];	T _ vTemp _ RSh[vTemp,4], GoTo[vPK1];	T _ vTemp _ RSh[vTemp,10], GoTo[vPK1];	T _ vTemp _ RSh[vTemp,14], GoTo[vPK1];vPKZ:	vDBA _ (vDBA) and not T, Skip;	*key down, clear bitvPKNZ:	vDBA _ (vDBA) or T;		*key up, set bit	T _ vLink, LoadPage[DisplayPage];	PStore1[vMDS177400,vDBA], GoToP[vPKey1];	*store wordOnPage[DisplayPage];:ELSE; ****************************************%CSL KEYBOARD vChkMsg collects and posts incoming messages from keyboardmicrocomputer.  Form of message is 1xxxxtttmmmmmmmmmmmmmmmm1, wheret = type bit, m = message bit, x = unused, and 1's represent the leadingand trailing flags.  IOAtten encodes the bits, delivered one/scanline.At message start, vMsgStatus>=0 and the leading 1 has just been shifted outof vMsg; in this case vMsg is saved in vMsgStatus with a sign bit of 1.At message end, vMsgStatus<0 and the trailing 1 has just been shifted intothe low bit of vMsg.Timing here to return = 4 cycles usually; 13 on message start;32 on KB0 to KB3 end-of-msg; 29 on KSMS; or 43 on Mouse XY end.%vM0:	vMsg _ LSh[vMsg,1], DblGoTo[vMsgA,vNoMsg,R<0];vM1:	vMsg _ (LSh[vMsg,1]) + 1, DblGoTo[vMsgA,vNoMsg,R<0];vNoMsg:	T _ 170C, Return;vMsgA:	T _ LSh[vMsgStatus,7], GoTo[vMsgEnd,R<0];*Just collected 1st word of message; save it in vMsgStatus with sign of 1vMsgBg:	T _ (vMsg) or (100000C);	vMsgStatus _ T;	vMsg _ 400C, GoTo[vNoMsg];vMsgEnd:	*End-of-message--rebuild message body	T _ vMsg _ (RSh[vMsg,1]) or T, Skip[R Odd];	  vMsgStatus _ 0C, GoTo[vEOMs];*Dispatch on type bits, setup for next message.	vMsgStatus _ Dispatch[vMsgStatus,4,3];	vDBuf0 _ T, Disp[.+1];*Timing from VM0/VM1 to here = 13 cycles*Reject type 0 (possibly noise)	vMsg _ 0C, GoTo[vNoMsg], DispTable[10];	T _ (vZero) - (344C), GoTo[vKBn];	*KB0 (VM 177034)	T _ (vZero) - (343C), GoTo[vKBn];	*KB1 (VM 177035)	T _ (vZero) - (342C), GoTo[vKBn];	*KB2 (VM 177036)	T _ (vZero) - (341C), GoTo[vKBn];	*KB3 (VM 177037)	vTemp _ T, GoTo[vKSMS];			*KSMS (keyset/mouse switches)	PFetch4[vMDS420,vDBuf0,4], GoTo[vMXY];	*MouseX,Y from 424b,425b*Depressing the boot button causes an endless stream of IOAtten' which*manifests as an endless stream of 1's here; for a message in which both*the body and type are all 1's (to eliminate noise) boot the machine.*On keyboard boot, KB0 is 177776b for BS or 177577b for 0; KB0 is passed*through the activity of Initial to the microcode being booted in BootTask's*T register, which is not smashed.	vMsg _ (vMsg) + 1;		*Boot button	T _ (vZero) - (344C), Skip[ALU=0];vEOMs:	  vMsg _ 0C, GoTo[vNoMsg];	PFetch1[vMDS177400,vMsg];	*Fetch KB0 as parameter for Boot	vTemp _ And[BootSV,377]C;	vTemp _ (vTemp) or (Or[LShift[BootTask,14],And[BootSV,7400]]C);	APCTask&APC _ vTemp;	LU _ MNBR _ vMsg, Return;	*Continue in BootTask at SuckADuck*Stores KSMS in 177030 and 177033, junk in other 2 regs.vKSMS:	T _ (vZero) - (350C);	PStore4[vMDS177400,vDBuf0], GoTo[vEOMs];vKBn:	PStore1[vMDS177400,vDBuf0], GoTo[vEOMs];vMXY:	T _ 200C;	T _ (RHMask[vMsg]) - T;	*delta Y (sent as excess 128d)	vMsg _ RSh[vMsg,10];	vDBuf1 _ (vDBuf1) + T;	T _ (vMsg) - (200C);	*delta X (sent as excess 128d)	vDBuf0 _ (vDBuf0) + T;	vMsg _ 0C;	PStore4[vMDS420,vDBuf0,4], GoTo[vNoMsg]; *Store updated X,Y SetTask[BootTask];*Only the T-registers of unused tasks (Possibly MNBR or SALUF also) will*survive across the boot, so we tuck away KB0 so that microcode being booted*can decide what kind of boot to do.SuckADuck:	T _ MNBR, At[BootSV];	Boot, GoTo[.];:ENDIF; ***************************************:END[Display];