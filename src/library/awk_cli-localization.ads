with Ada.Strings.Unbounded;
with Awk_CLI.Diagnostics;
with Messages.Runtime;

package Awk_CLI.Localization is
   --  Adapter for localized CLI-authored messages.
   --
   --  This is the only package that should depend on the message catalog
   --  formatting surface.

   package U renames Ada.Strings.Unbounded;

   type Catalog is tagged limited private;

   procedure Initialize
     (Item         : in out Catalog;
      Catalog_Path : String;
      Locale       : String);
   --  Load the catalog and select the effective locale for CLI text.

   function Text
     (Item : Catalog;
      Key  : String;
      Name : String := "";
      Value : String := "";
      Detail : String := "") return String;
   --  Format a catalog message by stable key and structured parameters.

   function Primary (Item : Catalog; Diagnostic : Awk_CLI.Diagnostics.Diagnostic) return String;
   --  Format the primary localized message for Diagnostic.

   function Label (Item : Catalog; Severity : Awk_CLI.Diagnostics.Diagnostic_Severity) return String;
   --  Return the localized label for Severity.

private
   type Catalog is tagged limited record
      Runtime : Messages.Runtime.Runtime;
      Locale  : U.Unbounded_String;
   end record;
end Awk_CLI.Localization;
