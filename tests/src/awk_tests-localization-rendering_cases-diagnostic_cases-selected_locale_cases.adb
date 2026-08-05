with AUnit.Assertions;

with Project_Tools.Text;

with Awk_CLI;
with Awk_CLI.Testing;

package body Awk_Tests.Localization.Rendering_Cases.Diagnostic_Cases.Selected_Locale_Cases is
   use AUnit.Assertions;
   package Harness renames Awk_CLI.Testing;

   use type Awk_CLI.Exit_Code;

   procedure Test_Localized_Diagnostics (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument (Context, "--bad");
      Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Harness.Set_Locale (Context, "da");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 2, "Danish usage error status");
      Assert (Project_Tools.Text.Contains (Harness.Standard_Error (Context), "ukendt tilvalg"),
              "Danish diagnostic is selected");
   end Test_Localized_Diagnostics;

   procedure Test_European_Locale_Diagnostics (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument (Context, "--bad");
      Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Harness.Set_Locale (Context, "fr_FR.UTF-8");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 2, "French usage error status");
      Assert (Project_Tools.Text.Contains (Harness.Standard_Error (Context), "option inconnue"),
              "French diagnostic is selected through locale fallback");
   end Test_European_Locale_Diagnostics;

   procedure Test_Unsupported_Locale_Fallback (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument (Context, "--bad");
      Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Harness.Set_Locale (Context, "zz_ZZ.UTF-8");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 2, "unsupported locale usage status");
      Assert (Project_Tools.Text.Contains (Harness.Standard_Error (Context), "unknown option"),
              "unsupported locale falls back to catalog default");
   end Test_Unsupported_Locale_Fallback;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Localized_Diagnostics'Access, "localized diagnostics");
      Registration.Register_Routine
        (T, Test_European_Locale_Diagnostics'Access,
         "European locale diagnostics");
      Registration.Register_Routine
        (T, Test_Unsupported_Locale_Fallback'Access,
         "unsupported locale fallback");
   end Register;
end Awk_Tests.Localization.Rendering_Cases.Diagnostic_Cases.Selected_Locale_Cases;
