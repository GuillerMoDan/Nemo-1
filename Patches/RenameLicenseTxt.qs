//##################################################################
//# Purpose: Change the "..\\licence.txt" reference to custom file #
//#          specified by user and Update "No EULA " reference     #
//##################################################################

function RenameLicenseTxt()
{

  //Step 1a - Find address of licence.txt string
  var offset = pe.stringVa("..\\licence.txt");
  if (offset === -1)
    return "Failed in Step 1 - File string missing";

  //Step 1b - Find its reference
  offset = pe.findCode(" C7 05 ?? ?? ?? 00" + offset.packToHex(4));//MOV DWORD PTR DS:[g_licence], stringAddr
  if (offset === -1)
    return "Failed in Step 1 - String reference missing";

  //Step 2a - Get new Filename from user
  var txtFile = exe.getUserInput("$licenseTXT", XTYPE_STRING, _("String Input"), _("Enter the name of the Txt file"), "..\\licence.txt", 1, 20);
  if (txtFile === "" || txtFile === "..\\licence.txt")
    return "Failed in Step 2 - Patch Cancelled";

  txtFile += "\x00";

  //Step 2b - Allocate space for the new name
  var free = alloc.find(txtFile.length);
  if (free === -1)
    return "Failed in Step 2 - Not enough free space";

  //Step 2c - Insert the new name
  pe.insertAt(free, txtFile.length, txtFile);

  //Step 2d - Update the reference to point to new name
  pe.replaceDWord(offset + 6, pe.rawToVa(free));

  //Step 3a - Find the Error string address
  offset = pe.stringVa("No EULA text file. (licence.txt)");
  if (offset === -1)
    return "Failed in Step 3 - Error string missing";

  //Step 3b - Make the new string using the new licence filename
  txtFile = "No EULA text file. (" + txtFile.replace("..\\", "").replace("\x00", ")\x00");

  //Step 3c - Allocate space for the error string
  free = alloc.find(txtFile.length);
  if (free === -1)
    return "Failed in Step 3 - Not enough free space";

  //Step 3d - Insert the string
  pe.insertAt(free, txtFile.length, txtFile);

  //Step 3e - Update all the Error string references
  var prefixes = [" 6A 20 68", " BE", " BF"];
  var freeRva = pe.rawToVa(free);

  for (var i = 0; i < prefixes.length; i++)
  {
    var offsets = pe.findCodes(prefixes[i] + offset.packToHex(4));
    for (var j = 0; j < offsets.length; j++)
    {
      pe.replaceDWord(offsets[j] + prefixes[i].hexlength(), freeRva);
    }
  }

  return true;
}
