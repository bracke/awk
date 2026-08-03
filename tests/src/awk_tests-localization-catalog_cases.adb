with AUnit.Assertions;

with Project_Tools.Test_Fixtures;
with Project_Tools.Text;

with Awk_Catalog_Policy;

package body Awk_Tests.Localization.Catalog_Cases is
   use AUnit.Assertions;
   package Fixtures renames Project_Tools.Test_Fixtures;

   LF : constant String := [1 => ASCII.LF];

   procedure Test_Catalog_Key_Coverage (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Catalog : constant String := Fixtures.Read_Text_File ("../resources/messages/catalog.txt");
      English : constant String :=
        Fixtures.Read_Text_File ("../resources/messages/en/catalog.txt");
      Danish  : constant String :=
        Fixtures.Read_Text_File ("../resources/messages/da/catalog.txt");

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

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Catalog_Key_Coverage'Access, "catalog key coverage");
      Registration.Register_Routine
        (T, Test_Catalog_Policy_Failures'Access, "catalog policy failures");
   end Register;
end Awk_Tests.Localization.Catalog_Cases;
