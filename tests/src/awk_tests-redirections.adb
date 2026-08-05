with Awk_Tests.Redirections.Context_Cases;
with Awk_Tests.Redirections.Failure_Cases;
with Awk_Tests.Redirections.Materialize_Cases;

package body Awk_Tests.Redirections is

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk redirections");
   end Name;

   overriding procedure Register_Tests (T : in out Case_Type) is
   begin
      --  Inventory note: child registrars below own the Register_Routine calls.
      Awk_Tests.Redirections.Materialize_Cases.Register (T);
      Awk_Tests.Redirections.Context_Cases.Register (T);
      Awk_Tests.Redirections.Failure_Cases.Register (T);
   end Register_Tests;

end Awk_Tests.Redirections;
