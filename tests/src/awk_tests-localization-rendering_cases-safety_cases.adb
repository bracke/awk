with AUnit.Assertions;

with Project_Tools.Files;
with Project_Tools.Text;

with Awk_CLI;
with Awk_CLI.Localization;
with Awk_CLI.Testing;

package body Awk_Tests.Localization.Rendering_Cases.Safety_Cases is
   use AUnit.Assertions;
   package Harness renames Awk_CLI.Testing;

   LF : constant String := [1 => ASCII.LF];

   use type Awk_CLI.Exit_Code;

   procedure Test_Localized_Parameters_Are_Escaped
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Catalog : Awk_CLI.Localization.Catalog;
      Escape  : constant String := [1 => Character'Val (27)];
   begin
      Awk_CLI.Localization.Initialize
        (Catalog, "../resources/messages/catalog.txt", "en");
      declare
         Text : constant String :=
           Awk_CLI.Localization.Text
             (Catalog,
              "awk.usage.unknown_option",
              "option",
              "--bad" & LF & "awk: error: forged" & Escape & "[2J");
      begin
         Assert
           (Project_Tools.Text.Contains (Text, "--bad\nawk: error: forged\e[2J"),
            "localized parameter interpolation renders unsafe characters visibly");
         Assert
           (not Project_Tools.Text.Contains (Text, LF & "awk: error: forged"),
            "localized parameter cannot forge a diagnostic line");
         Assert (not Project_Tools.Text.Contains (Text, Escape),
                 "localized parameter interpolation emits no raw escape");
      end;
   end Test_Localized_Parameters_Are_Escaped;

   procedure Test_Render_Failure_Uses_Catalog_Fallback
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Catalog_Path : constant String :=
        Project_Tools.Files.Temp_Dir & "/awk-localization-fallback.catalog";
      Catalog      : Awk_CLI.Localization.Catalog;
   begin
      Project_Tools.Files.Write_Text_File
        (Catalog_Path,
         "default_locale = en" & LF
         & "en.awk.internal.localization_failed = localization failed for message"
         & " key: {detail}" & LF
         & "da.awk.internal.localization_failed = lokalisering fejlede for"
         & " beskednoegle: {detail}" & LF);

      Awk_CLI.Localization.Initialize (Catalog, Catalog_Path, "en");
      Assert
        (Awk_CLI.Localization.Text (Catalog, "awk.missing.key") =
         "localization failed for message key: awk.missing.key",
         "missing message key uses catalog-backed English fallback");

      Awk_CLI.Localization.Initialize (Catalog, Catalog_Path, "da");
      Assert
        (Awk_CLI.Localization.Text (Catalog, "awk.missing.key") =
         "lokalisering fejlede for beskednoegle: awk.missing.key",
         "missing message key uses selected-locale fallback");
   end Test_Render_Failure_Uses_Catalog_Fallback;

   procedure Test_Awk_Output_Unchanged_By_Locale (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument (Context, "BEGIN { print ""not localized"" }");
      Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Harness.Set_Locale (Context, "da");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "localized context execution succeeds");
      Assert (Harness.Standard_Output (Context) = "not localized" & LF,
              "AWK output is not localized");
   end Test_Awk_Output_Unchanged_By_Locale;

   procedure Test_Version_Uses_Localized_Labels (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Harness.Add_Argument (Context, "--version");
      Harness.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Harness.Set_Locale (Context, "da");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "localized version succeeds");
      Assert (Project_Tools.Text.Contains (Harness.Standard_Output (Context), "awk 0.1.0"),
              "program version is catalog-rendered");
      Assert (Project_Tools.Text.Contains (Harness.Standard_Output (Context), "awklib 0.1.0"),
              "interpreter version is catalog-rendered");
      Assert (Project_Tools.Text.Contains (Harness.Standard_Output (Context), "licens MIT"),
              "license label follows selected locale");
   end Test_Version_Uses_Localized_Labels;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Localized_Parameters_Are_Escaped'Access,
         "localized parameter escaping");
      Registration.Register_Routine
        (T, Test_Render_Failure_Uses_Catalog_Fallback'Access,
         "render failure catalog fallback");
      Registration.Register_Routine
        (T, Test_Awk_Output_Unchanged_By_Locale'Access,
         "AWK output locale separation");
      Registration.Register_Routine
        (T, Test_Version_Uses_Localized_Labels'Access,
         "version localized labels");
   end Register;

end Awk_Tests.Localization.Rendering_Cases.Safety_Cases;
