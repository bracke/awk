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

   --  @param Item Catalog runtime to initialize.
   --  @param Catalog_Path Message catalog path.
   --  @param Locale Requested locale name.
   procedure Initialize
     (Item         : in out Catalog;
      Catalog_Path : String;
      Locale       : String);
   --  Load the catalog and select the effective locale for CLI text.
   --  @param Item Catalog runtime to initialize.
   --  @param Catalog_Path Message catalog path.
   --  @param Locale Requested locale name.

   --  @param Item Initialized catalog runtime.
   --  @param Key Stable message key.
   --  @param Name Optional structured name argument.
   --  @param Value Optional structured value argument.
   --  @param Detail Optional structured detail argument.
   --  @return Localized formatted message text.
   function Text
     (Item : Catalog;
      Key  : String;
      Name : String := "";
      Value : String := "";
      Detail : String := "") return String;
   --  Format a catalog message by stable key and structured parameters.
   --  @param Item Initialized catalog runtime.
   --  @param Key Stable message key.
   --  @param Name Optional structured name argument.
   --  @param Value Optional structured value argument.
   --  @param Detail Optional structured detail argument.
   --  @return Localized formatted message text.

   --  @param Item Initialized catalog runtime.
   --  @param Diagnostic Structured diagnostic to render.
   --  @return Localized primary diagnostic text.
   function Primary (Item : Catalog; Diagnostic : Awk_CLI.Diagnostics.Diagnostic) return String;
   --  Format the primary localized message for Diagnostic.
   --  @param Item Initialized catalog runtime.
   --  @param Diagnostic Structured diagnostic to render.
   --  @return Localized primary diagnostic text.

   --  @param Item Initialized catalog runtime.
   --  @param Severity Diagnostic severity to label.
   --  @return Localized severity label.
   function Label (Item : Catalog; Severity : Awk_CLI.Diagnostics.Diagnostic_Severity) return String;
   --  Return the localized label for Severity.
   --  @param Item Initialized catalog runtime.
   --  @param Severity Diagnostic severity to label.
   --  @return Localized severity label.

private
   type Catalog is tagged limited record
      Runtime : Messages.Runtime.Runtime;
      Locale  : U.Unbounded_String;
   end record;
end Awk_CLI.Localization;
