with Awk_Tests.Localization.Rendering_Cases.Diagnostic_Cases;
with Awk_Tests.Localization.Rendering_Cases.Help_Cases;
with Awk_Tests.Localization.Rendering_Cases.Safety_Cases;

package body Awk_Tests.Localization.Rendering_Cases is

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      --  Inventory note: child registrars below own the Register_Routine calls.
      Awk_Tests.Localization.Rendering_Cases.Diagnostic_Cases.Register (T);
      Awk_Tests.Localization.Rendering_Cases.Help_Cases.Register (T);
      Awk_Tests.Localization.Rendering_Cases.Safety_Cases.Register (T);
   end Register;

end Awk_Tests.Localization.Rendering_Cases;
