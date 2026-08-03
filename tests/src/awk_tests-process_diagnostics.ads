with AUnit.Test_Cases;

package Awk_Tests.Process_Diagnostics is
   --  Process-level diagnostic, failure, and localized error cases.

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class);
   --  Register process tests for diagnostics and non-success exit behavior.
end Awk_Tests.Process_Diagnostics;
