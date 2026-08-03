with AUnit.Test_Cases;

package Awk_Tests.Process_Language is
   --  Process-level AWK language-surface integration cases.

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class);
   --  Register process tests that exercise awklib language behavior through awk.
end Awk_Tests.Process_Language;
