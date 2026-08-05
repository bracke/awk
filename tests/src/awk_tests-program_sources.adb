with Awk_Tests.Program_Sources.Diagnostic_Cases;
with Awk_Tests.Program_Sources.Edge_Cases;
with Awk_Tests.Program_Sources.File_Cases;

package body Awk_Tests.Program_Sources is

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk program sources");
   end Name;

   overriding procedure Register_Tests (T : in out Case_Type) is
   begin
      --  Inventory note: child registrars below own the Register_Routine calls.
      Awk_Tests.Program_Sources.File_Cases.Register (T);
      Awk_Tests.Program_Sources.Edge_Cases.Register (T);
      Awk_Tests.Program_Sources.Diagnostic_Cases.Register (T);
   end Register_Tests;

end Awk_Tests.Program_Sources;
