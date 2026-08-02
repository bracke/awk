with AUnit.Assertions;

with Ada.Strings.Fixed;

with Project_Tools.Files;
with Project_Tools.Test_Fixtures;
with Project_Tools.Text;

with Awk_Catalog_Policy;
with Awk_CLI;
with Awk_CLI.Localization;

package body Awk_Tests.Localization is
   use AUnit.Assertions;
   package Fixtures renames Project_Tools.Test_Fixtures;

   LF : constant String := [1 => ASCII.LF];

   use type Awk_CLI.Exit_Code;

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk localization");
   end Name;

   procedure Test_Catalog_Key_Coverage (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Catalog : constant String := Fixtures.Read_Text_File ("../resources/messages/catalog.txt");
      English : constant String := Fixtures.Read_Text_File ("../resources/messages/en/catalog.txt");
      Danish  : constant String := Fixtures.Read_Text_File ("../resources/messages/da/catalog.txt");

      procedure Require_Key (Key : String) is
      begin
         Assert (Project_Tools.Text.Contains (Catalog, Key & " ="), "catalog contains " & Key);
      end Require_Key;
   begin
      Assert (Awk_Catalog_Policy.Failure_Message (Catalog) = "",
              "combined catalog has only expected keys and valid placeholders");
      Assert
        (Awk_Catalog_Policy.Failure_Message
           (English, Combined_Catalog => False, Locale => "en") = "",
         "English shard has only expected keys and valid placeholders");
      Assert
        (Awk_Catalog_Policy.Failure_Message
           (Danish, Combined_Catalog => False, Locale => "da") = "",
         "Danish shard has only expected keys and valid placeholders");

      for Index in 1 .. Awk_Catalog_Policy.Required_Key_Count loop
         declare
            Suffix : constant String := Awk_Catalog_Policy.Required_Key (Index);
         begin
            for Locale_Index in 1 .. Awk_Catalog_Policy.Supported_Locale_Count loop
               Require_Key (Awk_Catalog_Policy.Supported_Locale (Locale_Index) & "." & Suffix);
            end loop;
         end;
      end loop;
   end Test_Catalog_Key_Coverage;

   procedure Test_Catalog_Policy_Failures (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert
        (Project_Tools.Text.Contains
           (Awk_Catalog_Policy.Failure_Message
              ("en.awk.usage.unknown_option = bad {option"),
            "malformed placeholder"),
         "unclosed placeholder is rejected");
      Assert
        (Project_Tools.Text.Contains
           (Awk_Catalog_Policy.Failure_Message
              ("en.awk.extra = extra"),
            "unknown catalog key"),
         "unknown message key is rejected");
      Assert
        (Project_Tools.Text.Contains
           (Awk_Catalog_Policy.Failure_Message
              ("en.awk.usage.unknown_option: bad"),
            "malformed catalog line"),
         "malformed assignment syntax is rejected");
      Assert
        (Project_Tools.Text.Contains
           (Awk_Catalog_Policy.Failure_Message
              ("default_locale = da" & LF &
               "en.awk.usage.unknown_option = bad {option}"),
            "invalid default locale"),
         "combined catalog default locale is fixed to English");
   end Test_Catalog_Policy_Failures;

   procedure Test_Localized_Diagnostics (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "--bad");
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Awk_CLI.Set_Locale (Context, "da");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 2, "Danish usage error status");
      Assert (Project_Tools.Text.Contains (Awk_CLI.Standard_Error (Context), "ukendt tilvalg"),
              "Danish diagnostic is selected");
   end Test_Localized_Diagnostics;

   procedure Test_European_Locale_Diagnostics (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "--bad");
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Awk_CLI.Set_Locale (Context, "fr_FR.UTF-8");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 2, "French usage error status");
      Assert (Project_Tools.Text.Contains (Awk_CLI.Standard_Error (Context), "option inconnue"),
              "French diagnostic is selected through locale fallback");
   end Test_European_Locale_Diagnostics;

   procedure Test_All_Supported_Locales_Render_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Catalog : constant String := Fixtures.Read_Text_File ("../resources/messages/catalog.txt");
      Escape  : constant String := [1 => Character'Val (27)];

      function Catalog_Value (Key : String) return String is
         Prefix : constant String := Key & " = ";
         Start  : constant Natural := Ada.Strings.Fixed.Index (Catalog, Prefix);
         Stop   : Natural;
      begin
         Assert (Start /= 0, "catalog contains " & Key);
         Stop := Ada.Strings.Fixed.Index
           (Catalog (Start + Prefix'Length .. Catalog'Last), LF);
         if Stop = 0 then
            return Catalog (Start + Prefix'Length .. Catalog'Last);
         end if;
         return Catalog (Start + Prefix'Length .. Stop - 1);
      end Catalog_Value;

      function Before_Option (Text : String) return String is
         Mark : constant Natural := Ada.Strings.Fixed.Index (Text, "{option}");
      begin
         if Mark <= Text'First then
            return "";
         end if;
         return Text (Text'First .. Mark - 1);
      end Before_Option;
   begin
      for Index in 1 .. Awk_Catalog_Policy.Supported_Locale_Count loop
         declare
            Locale  : constant String := Awk_Catalog_Policy.Supported_Locale (Index);
            Context : Awk_CLI.Invocation_Context;
            Status  : Awk_CLI.Exit_Code;
            Prefix  : constant String :=
              Before_Option (Catalog_Value (Locale & ".awk.usage.unknown_option"));
         begin
            Awk_CLI.Add_Argument (Context, "--bad");
            Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
            Awk_CLI.Set_Locale (Context, Locale);
            Status := Awk_CLI.Run (Context);
            Assert (Status = 2, Locale & " usage diagnostic status");
            Assert
              (Prefix = "" or else Project_Tools.Text.Contains (Awk_CLI.Standard_Error (Context), Prefix),
               Locale & " diagnostic renders localized catalog prefix");
            Assert (Project_Tools.Text.Contains (Awk_CLI.Standard_Error (Context), "--bad"),
                    Locale & " diagnostic interpolates option argument");
            Assert
              (not Project_Tools.Text.Contains (Awk_CLI.Standard_Error (Context), "awk.usage.unknown_option"),
               Locale & " diagnostic does not expose raw message key");
            Assert
              (not Project_Tools.Text.Contains (Awk_CLI.Standard_Error (Context), "localization_failed"),
               Locale & " diagnostic does not use localization failure fallback");
            Assert
              (not Project_Tools.Text.Contains (Awk_CLI.Standard_Error (Context), Escape),
               Locale & " diagnostic emits no raw escape character");
         end;
      end loop;
   end Test_All_Supported_Locales_Render_Diagnostics;

   procedure Test_All_Supported_Locales_Render_Help
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Escape : constant String := [1 => Character'Val (27)];

      procedure Require_Token (Output, Locale, Token : String) is
      begin
         Assert (Project_Tools.Text.Contains (Output, Token), Locale & " help contains " & Token);
      end Require_Token;
   begin
      for Index in 1 .. Awk_Catalog_Policy.Supported_Locale_Count loop
         declare
            Locale  : constant String := Awk_Catalog_Policy.Supported_Locale (Index);
            Context : Awk_CLI.Invocation_Context;
            Status  : Awk_CLI.Exit_Code;
         begin
            Awk_CLI.Add_Argument (Context, "--color=never");
            Awk_CLI.Add_Argument (Context, "--help");
            Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
            Awk_CLI.Set_Locale (Context, Locale);
            Status := Awk_CLI.Run (Context);
            declare
               Output : constant String := Awk_CLI.Standard_Output (Context);
            begin
               Assert (Status = 0, Locale & " help status");
               Assert (Awk_CLI.Standard_Error (Context) = "",
                       Locale & " help writes no standard error");
               Require_Token (Output, Locale, "awk");
               Require_Token (Output, Locale, "-F");
               Require_Token (Output, Locale, "-v");
               Require_Token (Output, Locale, "-f");
               Require_Token (Output, Locale, "--help");
               Require_Token (Output, Locale, "--version");
               Require_Token (Output, Locale, "--color=auto|always|never");
               Require_Token (Output, Locale, "BEGIN");
               Require_Token (Output, Locale, "getline");
               Require_Token (Output, Locale, "POSIX");
               Assert (not Project_Tools.Text.Contains (Output, "awk.help."),
                       Locale & " help does not expose raw help keys");
               Assert (not Project_Tools.Text.Contains (Output, "localization_failed"),
                       Locale & " help does not use localization failure fallback");
               Assert (not Project_Tools.Text.Contains (Output, Escape),
                       Locale & " color=never help emits no raw escape character");
            end;
         end;
      end loop;
   end Test_All_Supported_Locales_Render_Help;

   procedure Test_Unsupported_Locale_Fallback (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "--bad");
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Awk_CLI.Set_Locale (Context, "zz_ZZ.UTF-8");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 2, "unsupported locale usage status");
      Assert (Project_Tools.Text.Contains (Awk_CLI.Standard_Error (Context), "unknown option"),
              "unsupported locale falls back to catalog default");
   end Test_Unsupported_Locale_Fallback;

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
         & "en.awk.internal.localization_failed = localization failed for message key: {detail}" & LF
         & "da.awk.internal.localization_failed = lokalisering fejlede for beskednoegle: {detail}" & LF);

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
      Awk_CLI.Add_Argument (Context, "BEGIN { print ""not localized"" }");
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Awk_CLI.Set_Locale (Context, "da");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "localized context execution succeeds");
      Assert (Awk_CLI.Standard_Output (Context) = "not localized" & LF,
              "AWK output is not localized");
   end Test_Awk_Output_Unchanged_By_Locale;

   procedure Test_Version_Uses_Localized_Labels (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "--version");
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Awk_CLI.Set_Locale (Context, "da");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 0, "localized version succeeds");
      Assert (Project_Tools.Text.Contains (Awk_CLI.Standard_Output (Context), "awk 0.1.0"),
              "program version is catalog-rendered");
      Assert (Project_Tools.Text.Contains (Awk_CLI.Standard_Output (Context), "awklib 0.1.0"),
              "interpreter version is catalog-rendered");
      Assert (Project_Tools.Text.Contains (Awk_CLI.Standard_Output (Context), "licens MIT"),
              "license label follows selected locale");
   end Test_Version_Uses_Localized_Labels;

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Catalog_Key_Coverage'Access, "catalog key coverage");
      Registration.Register_Routine (T, Test_Catalog_Policy_Failures'Access, "catalog policy failures");
      Registration.Register_Routine (T, Test_Localized_Diagnostics'Access, "localized diagnostics");
      Registration.Register_Routine
        (T, Test_European_Locale_Diagnostics'Access,
         "European locale diagnostics");
      Registration.Register_Routine
        (T, Test_All_Supported_Locales_Render_Diagnostics'Access,
         "all supported locale diagnostics render");
      Registration.Register_Routine
        (T, Test_All_Supported_Locales_Render_Help'Access,
         "all supported locale help renders");
      Registration.Register_Routine
        (T, Test_Unsupported_Locale_Fallback'Access,
         "unsupported locale fallback");
      Registration.Register_Routine
        (T, Test_Localized_Parameters_Are_Escaped'Access,
         "localized parameter escaping");
      Registration.Register_Routine
        (T, Test_Render_Failure_Uses_Catalog_Fallback'Access,
         "render failure catalog fallback");
      Registration.Register_Routine (T, Test_Awk_Output_Unchanged_By_Locale'Access, "AWK output locale separation");
      Registration.Register_Routine
        (T, Test_Version_Uses_Localized_Labels'Access,
         "version localized labels");
   end Register_Tests;
end Awk_Tests.Localization;
