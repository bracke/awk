with AUnit.Test_Cases;

package Awk_Tests.Process_Language is
   --  Process-level executable checks for selected awklib integration paths.

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class);
   --  Register process tests that exercise awklib language behavior through awk.
end Awk_Tests.Process_Language;
