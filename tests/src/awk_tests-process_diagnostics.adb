with Awk_Tests.Process_Diagnostics.Locale_Cases;
with Awk_Tests.Process_Diagnostics.Usage_Cases;

package body Awk_Tests.Process_Diagnostics is
   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Awk_Tests.Process_Diagnostics.Usage_Cases.Register (T);
      Awk_Tests.Process_Diagnostics.Locale_Cases.Register (T);
   end Register;
end Awk_Tests.Process_Diagnostics;
