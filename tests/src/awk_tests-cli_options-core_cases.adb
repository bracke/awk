with Awk_Tests.CLI_Options.Core_Cases.Basic_Cases;
with Awk_Tests.CLI_Options.Core_Cases.Failure_Cases;
with Awk_Tests.CLI_Options.Core_Cases.Matrix_Cases;
with Awk_Tests.CLI_Options.Core_Cases.Ordering_Cases;

package body Awk_Tests.CLI_Options.Core_Cases is
   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Awk_Tests.CLI_Options.Core_Cases.Basic_Cases.Register (T);
      Awk_Tests.CLI_Options.Core_Cases.Failure_Cases.Register (T);
      Awk_Tests.CLI_Options.Core_Cases.Matrix_Cases.Register (T);
      Awk_Tests.CLI_Options.Core_Cases.Ordering_Cases.Register (T);
   end Register;
end Awk_Tests.CLI_Options.Core_Cases;
