with Awk_Tests.Localization.Rendering_Cases.Diagnostic_Cases.All_Locale_Cases;
with Awk_Tests.Localization.Rendering_Cases.Diagnostic_Cases.Selected_Locale_Cases;

package body Awk_Tests.Localization.Rendering_Cases.Diagnostic_Cases is
   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Awk_Tests.Localization.Rendering_Cases.Diagnostic_Cases.Selected_Locale_Cases.Register (T);
      Awk_Tests.Localization.Rendering_Cases.Diagnostic_Cases.All_Locale_Cases.Register (T);
   end Register;

end Awk_Tests.Localization.Rendering_Cases.Diagnostic_Cases;
