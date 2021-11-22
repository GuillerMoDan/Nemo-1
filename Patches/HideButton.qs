//===================================================//
// Patch Functions wrapping over HideButton function //
//===================================================//

function HideNavButton()
{
    if (UseNewIcons())
        return HideButton2("navigation");
    return HideButtonOld(
        ["navigation_interface\\btn_Navigation", "RO_menu_icon\\navigation"],
        ["\x00", "\x00"]
    );
}

function HideBgButton()
{
    if (UseNewIcons())
        return HideButton2("battle");
    return HideButtonOld(
        ["basic_interface\\btn_battle_field", "RO_menu_icon\\battle"],
        ["\x00", "\x00"]
    );
}

function HideBankButton()
{
    if (UseNewIcons())
        return HideButton2("bank");
    return HideButtonOld(
        ["basic_interface\\btn_bank", "RO_menu_icon\\bank"],
        ["\x00", "\x00"]
    );
}

function HideBooking()
{
    if (UseNewIcons())
        return HideButton2("booking");
    return HideButtonOld(
        ["basic_interface\\booking", "RO_menu_icon\\booking"],
        ["\x00", "\x00"]
    );
}

function HideRodex()
{
    if (UseNewIcons())
        return HideButton2("mail");
    return HideButtonOld("RO_menu_icon\\mail", "\x00");
}

function HideAchieve()
{
    if (UseNewIcons())
        return HideButton2("achievement");
    return HideButtonOld("RO_menu_icon\\achievement", "\x00");
}

function HideRecButton()
{
    if (UseNewIcons())
        return HideButton2("rec");
    return HideButtonOld(
        ["replay_interface\\rec", "RO_menu_icon\\rec"],
        ["\x00", "\x00"]
    );
}

//===================================================//
// Patch Functions wrapping over HideButton2 function //
//===================================================//

function HideMapButton()
{
    return HideButton2("map");
}

function HideQuest()
{
    return HideButton2("quest");
}

function HideSNSButton()
{
    return HideButton2("sns");
}

function HideKeyboardButton()
{
    return HideButton2("keyboard");
}

function HideStatusButton()
{
    return HideButton2("status");
}

function HideEquipButton()
{
    return HideButton2("equip");
}

function HideItemButton()
{
    return HideButton2("item");
}

function HideSkillButton()
{
    return HideButton2("skill");
}

function HidePartyButton()
{
    return HideButton2("party");
}

function HideGuildButton()
{
    return HideButton2("guild");
}

function HideOptionButton()
{
    return HideButton2("option");
}

function HideTipButton()
{
    return HideButton2("tip");
}

function HideShopButton()
{
    return HideButton2("shop");
}

function HideAttendanceButton()
{
    return HideButton2("attendance");
}

function HideAdventurerAgencyButton()
{
    return HideButton2("adventurerAgency");
}

function HideReputationButton()
{
    return HideButton2("repute");
}

//##########################################################
//# Purpose: Find the first match amongst the src prefixes #
//#          and replace it with corresponding tgt prefix  #
//##########################################################

function HideButtonOld(src, tgt)
{
    consoleLog("Step 1a - Ensure both are lists/arrays");
    if (typeof(src) === "string")
        src = [src];

    if (typeof(tgt) === "string")
        tgt = [tgt];

    consoleLog("Step 1b - Loop through and find first match");
    var offset = -1;
    for (var i = 0; i < src.length; i++)
    {
        offset = pe.halfStringRaw(src[i]);
        if (offset !== -1)
            break;
    }

    if (offset === -1)
        return "Failed in Step 1";

    consoleLog("Step 2 - Replace with corresponding value in tgt");
    exe.replace(offset, tgt[i], PTYPE_STRING);

    return true;
}

function HideButton2(prefix)
{
    if (UseNewIcons())
        return HideButtonNew("equip", prefix);
    else
        return HideButtonNew("info", prefix);
}

//#######################################################################
//# Purpose: Find the prefix assignment inside UIBasicWnd::OnCreate and #
//#          assign address of NULL after the prefix instead            #
//#######################################################################
function HideButtonNew(reference, prefix)
{
    consoleLog("Step 1a - Find the address of the reference prefix \"info\" (needed since some prefixes are matching multiple areas)");
    var refAddr = pe.stringVa(reference);
    if (refAddr === -1)
        return "Failed in Step 1 - info missing";

    consoleLog("Step 1b - Find the address of the string");
    var strAddr = pe.stringVa(prefix);
    if (strAddr === -1)
        return "Failed in Step 1 - Prefix missing";

    consoleLog("Step 2a - Find assignment of \"info\" inside UIBasicWnd::OnCreate");
    var suffix = " C7";
    var offset = pe.findCode(refAddr.packToHex(4) + suffix);

    if (offset === -1)
    {
        suffix = " 8D";
        offset = pe.findCode(refAddr.packToHex(4) + suffix);
    }

    if (offset === -1)
        return "Failed in Step 2 - info assignment missing";

    consoleLog("Step 2b - Find the assignment of prefix after \"info\" assignment");
    offset = pe.find(strAddr.packToHex(4) + suffix, offset + 5, offset + 0x570);
    if (offset === -1)
        return "Failed in Step 2 - Prefix assignment missing";

    consoleLog("Step 2c - Update the address to point to NULL");
    exe.replaceDWord(offset, strAddr + prefix.length);

    return true;
}

//#######################################################################
//# Purpose: Determine whether this client uses new menu icons          #
//#######################################################################
function UseNewIcons()
{
    return (pe.stringVa("\xC0\xAF\xC0\xFA\xC0\xCE\xC5\xCD\xC6\xE4\xC0\xCC\xBD\xBA\\menu_icon\\bt_%s.bmp") !== -1);
}

//========================================================//
// Disable for Unsupported Clients - Check for Button bmp //
//========================================================//

function HideRodex_()
{
    return (pe.stringRaw("\xC0\xAF\xC0\xFA\xC0\xCE\xC5\xCD\xC6\xE4\xC0\xCC\xBD\xBA\\RO_menu_icon\\mail") !== -1 || (UseNewIcons() && pe.stringVa("navigation") !== -1));
}

function HideAchieve_()
{
    return (pe.stringRaw("\xC0\xAF\xC0\xFA\xC0\xCE\xC5\xCD\xC6\xE4\xC0\xCC\xBD\xBA\\RO_menu_icon\\achievement") !== -1 || (UseNewIcons() && pe.stringVa("achievement") !== -1));
}

function HideSNSButton_()
{
    return (pe.stringVa("sns") !== -1);
}

function HideKeyboardButton_()
{
    return (pe.stringVa("keyboard") !== -1);
}

function HideStatusButton_()
{
    return (pe.stringVa("status") !== -1);
}

function HideEquipButton_()
{
    return (pe.stringVa("equip") !== -1);
}

function HideItemButton_()
{
    return (pe.stringVa("item") !== -1);
}

function HideSkillButton_()
{
    return (pe.stringVa("skill") !== -1);
}

function HidePartyButton_()
{
    return (pe.stringVa("party") !== -1);
}

function HideGuildButton_()
{
    return (pe.stringVa("guild") !== -1);
}

function HideOptionButton_()
{
    return (pe.stringVa("option") !== -1);
}

function HideTipButton_()
{
    return (pe.stringVa("tip") !== -1);
}

function HideShopButton_()
{
    return (pe.stringVa("shop") !== -1);
}

function HideAttendanceButton_()
{
    return (pe.stringVa("attendance") !== -1);
}

function HideAdventurerAgencyButton_()
{
    return (pe.stringVa("adventurerAgency") !== -1);
}

function HideReputationButton_()
{
    return (pe.stringVa("repute") !== -1);
}
