with AUnit;

with Awk_Tests.Context.Language_Cases;
with Awk_Tests.Context.Run_Cases;
with Awk_Tests.Context.State_Cases;

package body Awk_Tests.Context is
   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk context");
   end Name;

   overriding procedure Register_Tests (T : in out Case_Type) is
   begin
      --  Inventory note: child registrars below own the Register_Routine calls.
      Awk_Tests.Context.Run_Cases.Register (T);
      Awk_Tests.Context.State_Cases.Register (T);
      Awk_Tests.Context.Language_Cases.Register (T);
   end Register_Tests;
end Awk_Tests.Context;
