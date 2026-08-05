with Awk_Tests.Process_Options.Help_Cases;
with Awk_Tests.Process_Options.Operand_Cases;
with Awk_Tests.Process_Options.Version_Cases;

package body Awk_Tests.Process_Options.Short_Circuit_Cases is
   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Awk_Tests.Process_Options.Version_Cases.Register (T);
      Awk_Tests.Process_Options.Help_Cases.Register (T);
      Awk_Tests.Process_Options.Operand_Cases.Register (T);
   end Register;
end Awk_Tests.Process_Options.Short_Circuit_Cases;
