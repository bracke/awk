with Ada.Strings.Unbounded;
with Awk_CLI.Diagnostics;
with Messages.Runtime;

package Awk_CLI.Localization is
   package U renames Ada.Strings.Unbounded;

   type Catalog is tagged limited private;

   procedure Initialize
     (Item         : in out Catalog;
      Catalog_Path : String;
      Locale       : String);

   function Text
     (Item : Catalog;
      Key  : String;
      Name : String := "";
      Value : String := "";
      Detail : String := "") return String;

   function Primary (Item : Catalog; Diagnostic : Awk_CLI.Diagnostics.Diagnostic) return String;
   function Label (Item : Catalog; Severity : Awk_CLI.Diagnostics.Diagnostic_Severity) return String;

private
   type Catalog is tagged limited record
      Runtime : Messages.Runtime.Runtime;
      Locale  : U.Unbounded_String;
   end record;
end Awk_CLI.Localization;
