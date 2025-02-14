//
// Copyright (C) 2017-2022  Andrei Karas (4144)
//
// Hercules is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//###########################################################################
//# Purpose: Remove hardcoded otp / login addreses and ports                #
//###########################################################################

// older than 2019-02-13
function RemoveHardcodedAddressOld(offset, overrideAddressOffset)
{
    consoleLog("step 1b - replace call to nop");
    var overrideAddr = offset + overrideAddressOffset + 4 + pe.fetchDWord(offset + overrideAddressOffset);  // rva to va

    consoleLog("step 2a - find string 127.0.0.1");
    var offset = pe.find("31 32 37 2E 30 2E 30 2E 31 00");
    if (offset === -1)
        return "Failed in search 127.0.0.1 (old)";
    offset = pe.rawToVa(offset);

    consoleLog("step 2b - find otp_addr");
    var code = " " +
        offset.packToHex(4) + // offset 127.0.0.1
        " 26 1B 00 00"        // 6950
    var otpAddr = pe.find(code);
    if (otpAddr === -1)
        return "Failed in step 2b (old)";
    otpAddr = pe.rawToVa(otpAddr);
    var otpPort = otpAddr + 4
    var clientinfo_addr = table.getValidated(table.g_accountAddr);
    var clientinfo_port = table.getValidated(table.g_accountPort);

    consoleLog("step 3a - find otp_addr usage");
    var code =
        " FF 35" + otpAddr.packToHex(4) + // 0  push otp_addr
        " 8B ?? ?? ?? ?? 00" +            // 6  mov esi, ds:_snprintf_s
        " 68 ?? ?? ?? 00" +               // 12 push offset "%s"
        " 6A FF" +                        // 17 push 0FFFFFFFFh
        " 8D ?? ?? ?? FF FF" +            // 19 lea eax, [ebp+buf]
        " 6A 10"                          // 25 push 10h
    var offset = pe.findCode(code);
    var snprintfOffset = 8;
    if (offset === -1)
        return "Failed in step 3a (old)";

    logRawFunc("snprintf_s", offset, snprintfOffset);

    consoleLog("step 3b - replace otp_addr to clientinfo_addr");
    pe.replaceHex(offset + 2, clientinfo_addr.packToHex(4));

    var atoi = imports.ptrHexValidated("atoi");

    consoleLog("step 4b - change function override_address_port");
    var newCode =
        "FF 35 " + clientinfo_port.packToHex(4) +  // push clientinfo_port
        "FF 15 " + atoi +                          // call ds:atoi
        "A3" + otpPort.packToHex(4) +              // mov otp_port, eax
        "83 C4 04" +                               // add esp, 4
        "C3"                                       // retn
    pe.replaceHex(overrideAddr, newCode);

    return true;
}

// 2019-02-13+
function RemoveHardcodedAddressNew(overrideAddr, retAddr)
{
    consoleLog("step 2a - find string 127.0.0.1");
    var offset = pe.find("31 32 37 2E 30 2E 30 2E 31 00");
    if (offset === -1)
        return "Failed in search 127.0.0.1 (old)";
    offset = pe.rawToVa(offset);

    consoleLog("step 2b - find loop addr");
    var code = " " +
        offset.packToHex(4) + // offset 127.0.0.1
        " 26 1B 00 00"        // 6950
    var otpAddr = pe.find(code);
    if (otpAddr === -1)
        return "Failed in step 2b (new)";
    otpAddr = pe.rawToVa(otpAddr);
    var otpPort = otpAddr + 4
    var clientinfo_addr = table.getValidated(table.g_accountAddr);
    var clientinfo_port = table.getValidated(table.g_accountPort);

    if (exe.getClientDate() >= 20200630)
        return RemoveHardcodedAddress20207(overrideAddr, retAddr, clientinfo_addr, clientinfo_port)
    consoleLog("step 3a - find otp_addr usage");
    var code =
        "FF 35" + otpAddr.packToHex(4) + // 0 push otp_addr
        "8D ?? ?? ?? ?? FF " +        // 6 lea eax, [ebp+Dst]
        "68 ?? ?? ?? 00 " +           // 12 push offset aS
        "6A FF " +                    // 17 push 0FFFFFFFFh
        "6A 10 " +                    // 19 push 10h
        "50 ";                        // 21 push eax
    var authAddrOffset = 2;

    var offset = pe.findCode(code);
    if (offset === -1)
        return "Failed in step 3a (new)";

    logVaVar("g_auth_addr", offset, authAddrOffset);

    consoleLog("step 3b - replace otp_addr to clientinfo_addr");
    pe.replaceHex(offset + 2, clientinfo_addr.packToHex(4));

    var atoi = imports.ptrHexValidated("atoi");

    consoleLog("step 4b - change function override_address_port");
    var jmpOffset = 21;
    var continueAddr = retAddr - overrideAddr - jmpOffset - 4; // va to rva

    var newCode =
        "FF 35 " + clientinfo_port.packToHex(4) +  // 0 push clientinfo_port
        "FF 15 " + atoi +                          // 6 call ds:atoi
        " A3" + otpPort.packToHex(4) +             // 12 mov otp_port, eax
        " 83 C4 04" +                              // 17 add esp, 4
        " E9" + continueAddr.packToHex(4)          // 20 jmp continue

    pe.replaceHex(overrideAddr, newCode);

    return true;
}

// 2020-07-01+
function RemoveHardcodedAddress20207(overrideAddr, retAddr, clientinfo_addr, clientinfo_port)
{
    consoleLog("search kro-agency.ragnarok.co.kr");
    var offset = pe.stringVa("kro-agency.ragnarok.co.kr");
    if (offset === -1)
        return "kro-agency.ragnarok.co.kr not found";
    var hostHex = offset.packToHex(4);

    consoleLog("search %s:%d");
    offset = pe.stringVa("%s:%d");
    if (offset === -1)
        return "string '%s:%d' not found";
    var sdHex = offset.packToHex(4);

    consoleLog("search snprintf_s call");
    var code =
        "52 " +                       // 0 push edx
        "68 " + hostHex +             // 1 push offset aKroAgency_ragn
        "68 " + sdHex +               // 6 push offset aSD_6
        "6A FF " +                    // 11 push 0FFFFFFFFh
        "68 81 00 00 00 " +           // 13 push 81h
        "68 ?? ?? ?? ?? " +           // 18 push offset g_auth_host_port
        "E8 ?? ?? ?? ?? " +           // 23 call snprintf_s
        "83 C4 18 ";                  // 28 add esp, 18h
    var authHostOffset = 19;
    var snprintfOffset = [24, 4];
    var offset = pe.find(code, overrideAddr, overrideAddr + 0x300);

    if (offset === -1)
        return "Failed in search snprintf_s call";

    logVaVar("g_auth_host_port", offset, authHostOffset);

    var authHostVa = pe.fetchDWord(offset + authHostOffset);

    consoleLog("create format string %s:%s");

    var formatStr = pe.rawToVa(pe.insertString("%s:%s"))

    consoleLog("create code for build new connection string");

    var vars = {
        "clientinfo_addr": clientinfo_addr,
        "clientinfo_port": clientinfo_port,
        "formatStr": formatStr,
        "g_auth_host_port": authHostVa,
        "snprintf_s": pe.fetchRelativeValue(offset, snprintfOffset),
        "continue": pe.rawToVa(retAddr)
    };

    pe.replaceAsmFile(overrideAddr, "RemoveHardcodedAddress2020", vars);

    return true;
}

function RemoveHardcodedAddress()
{
    consoleLog("step 1a - Find the code where we will remove call");
    var code =
        " 80 3D ?? ?? ?? ?? 00" + // cmp byte_addr1, 0
        " 75 ??" +                // jnz short addr2
        " E8 ?? ?? 00 00" +       // call override_address_port
        " E9 ?? ?? 00 00";        // jmp addr3
    var overrideAddressOffset = 10;

    var offset = pe.findCode(code);

    if (offset !== -1)
        return RemoveHardcodedAddressOld(offset, overrideAddressOffset);

    consoleLog("search for clients 2019-02-13+");
    var g_serverType = GetServerType();

    consoleLog("search 6900");
    var offset = pe.find("36 39 30 30 00");
    if (offset === -1)
        return "Failed in search '6900' (new)";
    var portStrHex = pe.rawToVa(offset).packToHex(4);

    consoleLog("search override address");

    var code =
        "80 3D ?? ?? ?? ?? 00 " +     // 0 cmp byte_F64F5B, 0
        "0F 85 ?? ?? ?? 00 " +        // 7 jnz loc_716084
        "8B 15 " + g_serverType.packToHex(4) + // 13 mov edx, g_serverType
        "A1 ?? ?? ?? ?? " +           // 19 mov eax, _dword_F09838
        "8B 0D ?? ?? ?? ?? " +        // 24 mov ecx, _dword_F097F0
        "C7 05 ?? ?? ?? ?? " + portStrHex; // 30 mov _off_CCF968, offset a6900
    var overrideAddressOffset = 13;
    var retAddrOffset = 9;
    var cmdHaveAccountOffset = 2;

    var offset = pe.findCode(code);
    if (offset === -1)
        return "Failed in step 1 (new)";

    logVaVar("g_cmd_have_account", offset, cmdHaveAccountOffset);

    var retAddr = offset + retAddrOffset + 4 + pe.fetchDWord(offset + retAddrOffset);  // rva to va

    return RemoveHardcodedAddressNew(offset + overrideAddressOffset, retAddr);
}

//====================================================================//
// Disable for Unneeded Clients. Start from first zero client version //
//====================================================================//
function RemoveHardcodedAddress_()
{
    return (pe.stringRaw(".?AVUILoginOTPWnd@@") !== -1);
}
