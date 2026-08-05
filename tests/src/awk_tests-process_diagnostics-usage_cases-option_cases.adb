with Awk_Tests.Process_Diagnostics.Usage_Cases.Option_Cases.Basic_Cases;
with Awk_Tests.Process_Diagnostics.Usage_Cases.Option_Cases.Color_Cases;
with Awk_Tests.Process_Diagnostics.Usage_Cases.Option_Cases.Value_Cases;

package body Awk_Tests.Process_Diagnostics.Usage_Cases.Option_Cases is
   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      --  Inventory note: child registrars below own the Register_Routine calls.
      Awk_Tests.Process_Diagnostics.Usage_Cases.Option_Cases.Basic_Cases.Register (T);
      Awk_Tests.Process_Diagnostics.Usage_Cases.Option_Cases.Color_Cases.Register (T);
      Awk_Tests.Process_Diagnostics.Usage_Cases.Option_Cases.Value_Cases.Register (T);
   end Register;
end Awk_Tests.Process_Diagnostics.Usage_Cases.Option_Cases;
