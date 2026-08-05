with Awk_Tests.Terminal_Styles.Auto_Cases;
with Awk_Tests.Terminal_Styles.Explicit_Cases;

package body Awk_Tests.Terminal_Styles is
   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk terminal styles");
   end Name;

   overriding procedure Register_Tests (T : in out Case_Type) is
   begin
      --  Inventory note: child registrars below own the Register_Routine calls.
      Awk_Tests.Terminal_Styles.Auto_Cases.Register (T);
      Awk_Tests.Terminal_Styles.Explicit_Cases.Register (T);
   end Register_Tests;
end Awk_Tests.Terminal_Styles;
