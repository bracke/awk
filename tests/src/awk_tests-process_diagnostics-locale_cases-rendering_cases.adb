with Awk_Tests.Process_Diagnostics.Locale_Cases.Rendering_Cases.Locale_Selection_Cases;
with Awk_Tests.Process_Diagnostics.Locale_Cases.Rendering_Cases.Safety_Cases;

package body Awk_Tests.Process_Diagnostics.Locale_Cases.Rendering_Cases is
   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Awk_Tests.Process_Diagnostics.Locale_Cases.Rendering_Cases.Locale_Selection_Cases.Register (T);
      Awk_Tests.Process_Diagnostics.Locale_Cases.Rendering_Cases.Safety_Cases.Register (T);
   end Register;
end Awk_Tests.Process_Diagnostics.Locale_Cases.Rendering_Cases;
