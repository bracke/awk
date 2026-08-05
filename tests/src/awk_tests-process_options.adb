with Awk_Tests.Process_Options.Assignment_Cases;
with Awk_Tests.Process_Options.Short_Circuit_Cases;

package body Awk_Tests.Process_Options is
   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Awk_Tests.Process_Options.Short_Circuit_Cases.Register (T);
      Awk_Tests.Process_Options.Assignment_Cases.Register (T);
   end Register;
end Awk_Tests.Process_Options;
