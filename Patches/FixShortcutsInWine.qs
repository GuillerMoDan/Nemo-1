//
// Copyright (C) 2018-2022  Andrei Karas (4144)
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
//#############################################################
//# Purpose: Fix shortcuts in wine in ragexeRE 2019-03-20+    #
//#############################################################

function FixShortcutsInWine()
{
    // search in UIWindowMgr_handleShortcuts
    var code =
        "0F 57 C0 " +                 // 0 xorps xmm0, xmm0
        "66 0F 13 45 ?? " +           // 3 movlpd [ebp+var_8], xmm0
        "8B 55 ?? " +                 // 8 mov edx, dword ptr [ebp+var_8]
        "85 D2 " +                    // 11 test edx, edx
        "0F 8F ?? ?? ?? 00 " +        // 13 jg loc_6FBE67
        "83 BE ?? ?? ?? 00 00 " +     // 19 cmp dword ptr [esi+34F0h], 0
        "0F 85 ?? ?? ?? 00 " +        // 26 jnz loc_6FBE67
        "81 FF ?? ?? 00 00 " +        // 32 cmp edi, 0DBh
        "0F 87 ?? ?? ?? 00 " +        // 38 ja loc_6FBE67
        "0F B6 87 ";                  // 44 movzx eax, ds:byte_6FBF54[edi]
    var patchOffset = 13;
    var offset = pe.findCode(code);
    if (offset === -1)
        return "Failed in step 1 - pattern not found";

    pe.replaceHex(offset + patchOffset, "90 90 90 90 90 90");  // replace jg to nops
    return true;
}

function FixShortcutsInWine_()
{
    return (exe.getClientDate() > 20190306 && IsSakray()) || exe.getClientDate() >= 20190401;
}
