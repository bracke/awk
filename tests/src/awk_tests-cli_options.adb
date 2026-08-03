with AUnit;

with Awk_Tests.CLI_Options.Core_Cases;
with Awk_Tests.CLI_Options.Failure_Cases;
with Awk_Tests.CLI_Options.Operand_Cases;

package body Awk_Tests.CLI_Options is
   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk cli options");
   end Name;

   overriding procedure Register_Tests (T : in out Case_Type) is
   begin
      --  Inventory note: child registrars below own the Register_Routine calls.
      Awk_Tests.CLI_Options.Core_Cases.Register (T);
      Awk_Tests.CLI_Options.Operand_Cases.Register (T);
      Awk_Tests.CLI_Options.Failure_Cases.Register (T);
   end Register_Tests;
end Awk_Tests.CLI_Options;
