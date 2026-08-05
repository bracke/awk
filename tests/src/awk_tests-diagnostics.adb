with Awk_Tests.Diagnostics.Context_Cases;
with Awk_Tests.Diagnostics.Model_Cases;
with Awk_Tests.Diagnostics.Rendering_Cases;

package body Awk_Tests.Diagnostics is
   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk diagnostics");
   end Name;

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Awk_Tests.Diagnostics.Context_Cases.Test_Context_Diagnostics'Access,
         "context diagnostics");
      Registration.Register_Routine
        (T, Awk_Tests.Diagnostics.Context_Cases.Test_Context_Diagnostic_Sanitizing'Access,
         "context diagnostic sanitizing");
      Registration.Register_Routine
        (T, Awk_Tests.Diagnostics.Rendering_Cases.Test_Diagnostic_Source_Rendering'Access,
         "diagnostic source rendering");
      Registration.Register_Routine
        (T, Awk_Tests.Diagnostics.Model_Cases.Test_Diagnostic_Escape_Control_Characters'Access,
         "diagnostic escape control characters");
      Registration.Register_Routine
        (T, Awk_Tests.Diagnostics.Model_Cases.Test_Diagnostic_Status_Registry'Access,
         "diagnostic status registry");
   end Register_Tests;
end Awk_Tests.Diagnostics;
