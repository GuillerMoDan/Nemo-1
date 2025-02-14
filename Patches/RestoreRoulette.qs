//#####################################################################
//# Purpose: Restore the Roulette Icon UIWindow creation (ID = 0x11D) #
//#####################################################################

function RestoreRoulette()
{
  //Step 1 - Get the Window Manager Info we need
  var movEcx  = getEcxWindowMgrHex();
  var makeWin = table.get(table.UIWindowMgr_MakeWindow);

  //Step 2a - Find the location where the roulette icon was supposed to be created
  var code =
    " 74 0F"           //JE addr; skips to location after the call for creating vend search window below
  + " 68 B5 00 00 00"  //PUSH 0B5
  + movEcx             //MOV ECX, OFFSET g_windowMgr
  + " E8"              //CALL UIWindowMgr::MakeWindow
  ;

  var offset = pe.findCode(code);
  if (offset === -1)
    return "Failed in Step 2";

  var offset2 = offset + code.hexlength() + 4;

  //Step 2b - Get mode constant based on client date.
  if (exe.getClientDate() > 20150800)
    var mode = 0x10C;
  else
    var mode = 0x11D;

  //Step 2c - Check if the roulette icon is already created (check for PUSH mode after the CALL)
  if (pe.fetchDWord(offset2 + 1) === mode)
    return "Patch Cancelled - Roulette is already enabled";

  //Step 3a - Prep insert code (starting portion is same as above hence we dont repeat it)
  code +=
    GenVarHex(1)         //CALL UIWindowMgr::MakeWindow ; E8 opcode is already there
  + " 68" + GenVarHex(2) //PUSH mode
  + movEcx               //MOV ECX, OFFSET g_windowMgr
  + " E8" + GenVarHex(3) //CALL UIWindowMgr::MakeWindow
  + " E9" + GenVarHex(4) //JMP offset2; jump back to offset2
  ;

  //Step 3b - Allocate space for it
  var free = alloc.find(code.hexlength());
  if (free === -1)
    return "Failed in Step 3 - Not enough free space";

  var refAddr = pe.rawToVa(free + (offset2 - offset));

  //Step 3c - Fill in the blanks.
  code = ReplaceVarHex(code, 1, makeWin - (refAddr));
  code = ReplaceVarHex(code, 2, mode);
  code = ReplaceVarHex(code, 3, makeWin - (refAddr + 15));// (PUSH + MOV + CALL)
  code = ReplaceVarHex(code, 4, pe.rawToVa(offset2) - (refAddr + 20));// (PUSH + MOV + CALL + JMP)

  //Step 4 - Insert the code and create the JMP to it.
  pe.insertHexAt(free, code.hexlength(), code);
  pe.replaceHex(offset, "E9" + (pe.rawToVa(free) - pe.rawToVa(offset + 5)).packToHex(4));

  return true;
}

//======================================================//
// Disable for Unsupported Clients - Check for Icon bmp //
//======================================================//
function RestoreRoulette_()
{
  return (pe.stringRaw("\xC0\xAF\xC0\xFA\xC0\xCE\xC5\xCD\xC6\xE4\xC0\xCC\xBD\xBA\\basic_interface\\roullette\\RoulletteIcon.bmp") !== -1);
}
