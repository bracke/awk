with Awk_Tests.Inputs.Context_Cases;
with Awk_Tests.Inputs.Load_Cases;

package body Awk_Tests.Inputs is
   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk inputs");
   end Name;

   overriding procedure Register_Tests (T : in out Case_Type) is
   begin
      --  Inventory note: child registrars below own the Register_Routine calls.
      Awk_Tests.Inputs.Load_Cases.Register (T);
      Awk_Tests.Inputs.Context_Cases.Register (T);
   end Register_Tests;
end Awk_Tests.Inputs;
