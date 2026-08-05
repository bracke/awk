with Awk_Catalog_Policy;
with Project_Tools.Release_Checks;
with Project_Tools.Text;

package body Awk_Workflow_Catalogs.Completeness is
   package Text renames Project_Tools.Text;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Project_Tools.Release_Checks.Fail (Message);
      end if;
   end Require;

   procedure Run (Catalog, English, Danish : String) is
      procedure Require_Key (Key : String) is
      begin
         Require (Text.Contains (Catalog, Key & " ="),
                  "message catalog missing key: " & Key);
         Require (Text.Line_Value (Catalog, Key) /= "",
                  "message catalog has empty key: " & Key);
      end Require_Key;

      procedure Require_Shard_Key (Shard, Key, Name : String) is
      begin
         Require (Text.Contains (Shard, Key & " ="),
                  Name & " catalog shard missing key: " & Key);
         Require (Text.Line_Value (Shard, Key) /= "",
                  Name & " catalog shard has empty key: " & Key);
      end Require_Shard_Key;
   begin
      Require (Catalog /= "", "message catalog is missing or empty");
      Require (English /= "", "English catalog shard is missing or empty");
      Require (Danish /= "", "Danish catalog shard is missing or empty");

      Require
        (Awk_Catalog_Policy.Failure_Message (Catalog) = "",
         Awk_Catalog_Policy.Failure_Message (Catalog));
      Require
        (Awk_Catalog_Policy.Failure_Message
           (English, Combined_Catalog => False, Locale => "en") = "",
         Awk_Catalog_Policy.Failure_Message
           (English, Combined_Catalog => False, Locale => "en"));
      Require
        (Awk_Catalog_Policy.Failure_Message
           (Danish, Combined_Catalog => False, Locale => "da") = "",
         Awk_Catalog_Policy.Failure_Message
           (Danish, Combined_Catalog => False, Locale => "da"));

      for Index in 1 .. Awk_Catalog_Policy.Required_Key_Count loop
         declare
            Suffix : constant String := Awk_Catalog_Policy.Required_Key (Index);
         begin
            for Locale_Index in 1 .. Awk_Catalog_Policy.Supported_Locale_Count loop
               declare
                  Locale : constant String :=
                    Awk_Catalog_Policy.Supported_Locale (Locale_Index);
               begin
                  Require_Key (Locale & "." & Suffix);
                  Require
                    (Awk_Catalog_Policy.Placeholders
                       (Text.Line_Value (Catalog, "en." & Suffix))
                     =
                     Awk_Catalog_Policy.Placeholders
                       (Text.Line_Value (Catalog, Locale & "." & Suffix)),
                     "placeholder mismatch between en and " & Locale
                     & " for " & Suffix);
               end;
            end loop;

            Require_Shard_Key (English, "en." & Suffix, "English");
            Require_Shard_Key (Danish, "da." & Suffix, "Danish");
         end;
      end loop;
   end Run;
end Awk_Workflow_Catalogs.Completeness;
