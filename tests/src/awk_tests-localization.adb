with AUnit.Assertions;

with Ada.Strings.Fixed;

with Awk_Catalog_Policy;
with Awk_CLI;
with Awk_CLI.Localization;
with Awk_Tests.Support;

package body Awk_Tests.Localization is
   use AUnit.Assertions;
   use Awk_Tests.Support;

   LF : constant String := [1 => ASCII.LF];

   use type Awk_CLI.Exit_Code;

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk localization");
   end Name;

   procedure Test_Catalog_Key_Coverage (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Catalog : constant String := File_Text ("../resources/messages/catalog.txt");
      English : constant String := File_Text ("../resources/messages/en/catalog.txt");
      Danish  : constant String := File_Text ("../resources/messages/da/catalog.txt");

      procedure Require_Key (Key : String) is
      begin
         Assert (Contains (Catalog, Key & " ="), "catalog contains " & Key);
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
        (Contains
           (Awk_Catalog_Policy.Failure_Message
              ("en.awk.usage.unknown_option = bad {option"),
            "malformed placeholder"),
         "unclosed placeholder is rejected");
      Assert
        (Contains
           (Awk_Catalog_Policy.Failure_Message
              ("en.awk.extra = extra"),
            "unknown catalog key"),
         "unknown message key is rejected");
      Assert
        (Contains
           (Awk_Catalog_Policy.Failure_Message
              ("en.awk.usage.unknown_option: bad"),
            "malformed catalog line"),
         "malformed assignment syntax is rejected");
      Assert
        (Contains
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
      Assert (Contains (Awk_CLI.Standard_Error (Context), "ukendt tilvalg"),
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
      Assert (Contains (Awk_CLI.Standard_Error (Context), "option inconnue"),
              "French diagnostic is selected through locale fallback");
   end Test_European_Locale_Diagnostics;

   procedure Test_All_Supported_Locales_Render_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Catalog : constant String := File_Text ("../resources/messages/catalog.txt");
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
              (Prefix = "" or else Contains (Awk_CLI.Standard_Error (Context), Prefix),
               Locale & " diagnostic renders localized catalog prefix");
            Assert (Contains (Awk_CLI.Standard_Error (Context), "--bad"),
                    Locale & " diagnostic interpolates option argument");
            Assert
              (not Contains (Awk_CLI.Standard_Error (Context), "awk.usage.unknown_option"),
               Locale & " diagnostic does not expose raw message key");
            Assert
              (not Contains (Awk_CLI.Standard_Error (Context), "localization_failed"),
               Locale & " diagnostic does not use localization failure fallback");
            Assert
              (not Contains (Awk_CLI.Standard_Error (Context), Escape),
               Locale & " diagnostic emits no raw escape character");
         end;
      end loop;
   end Test_All_Supported_Locales_Render_Diagnostics;

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
      Assert (Contains (Awk_CLI.Standard_Error (Context), "unknown option"),
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
           (Contains (Text, "--bad\nawk: error: forged\e[2J"),
            "localized parameter interpolation renders unsafe characters visibly");
         Assert
           (not Contains (Text, LF & "awk: error: forged"),
            "localized parameter cannot forge a diagnostic line");
         Assert (not Contains (Text, Escape),
                 "localized parameter interpolation emits no raw escape");
      end;
   end Test_Localized_Parameters_Are_Escaped;

   procedure Test_Render_Failure_Uses_Catalog_Fallback
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Catalog_Path : constant String := "/tmp/awk-localization-fallback.catalog";
      Catalog      : Awk_CLI.Localization.Catalog;
   begin
      Write_Text_File
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
      Assert (Contains (Awk_CLI.Standard_Output (Context), "awk 0.1.0"),
              "program version is catalog-rendered");
      Assert (Contains (Awk_CLI.Standard_Output (Context), "awklib 0.1.0"),
              "interpreter version is catalog-rendered");
      Assert (Contains (Awk_CLI.Standard_Output (Context), "licens MIT"),
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
