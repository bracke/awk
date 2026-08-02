with AUnit.Assertions;

with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Awk_Catalog_Policy;
with Awk_CLI;

package body Awk_Tests.Localization is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;

   LF : constant String := [1 => ASCII.LF];

   use type Awk_CLI.Exit_Code;

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk localization");
   end Name;

   function File_Text (Path : String) return String is
      File   : Ada.Text_IO.File_Type;
      Result : U.Unbounded_String;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         U.Append (Result, Ada.Text_IO.Get_Line (File));
         if not Ada.Text_IO.End_Of_File (File) then
            U.Append (Result, LF);
         end if;
      end loop;
      Ada.Text_IO.Close (File);
      return U.To_String (Result);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return "";
   end File_Text;

   function Contains (Text, Pattern : String) return Boolean is
   begin
      if Pattern'Length = 0 then
         return True;
      end if;
      if Text'Length < Pattern'Length then
         return False;
      end if;
      for Index in Text'First .. Text'Last - Pattern'Length + 1 loop
         if Text (Index .. Index + Pattern'Length - 1) = Pattern then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

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
            Require_Key ("en." & Suffix);
            Require_Key ("da." & Suffix);
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

   procedure Test_Unsupported_Locale_Fallback (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Context : Awk_CLI.Invocation_Context;
      Status  : Awk_CLI.Exit_Code;
   begin
      Awk_CLI.Add_Argument (Context, "--bad");
      Awk_CLI.Set_Catalog_Path (Context, "../resources/messages/catalog.txt");
      Awk_CLI.Set_Locale (Context, "fr_FR.UTF-8");
      Status := Awk_CLI.Run (Context);
      Assert (Status = 2, "unsupported locale usage status");
      Assert (Contains (Awk_CLI.Standard_Error (Context), "unknown option"),
              "unsupported locale falls back to catalog default");
   end Test_Unsupported_Locale_Fallback;

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
        (T, Test_Unsupported_Locale_Fallback'Access,
         "unsupported locale fallback");
      Registration.Register_Routine (T, Test_Awk_Output_Unchanged_By_Locale'Access, "AWK output locale separation");
      Registration.Register_Routine
        (T, Test_Version_Uses_Localized_Labels'Access,
         "version localized labels");
   end Register_Tests;
end Awk_Tests.Localization;
