with Awk_CLI.Diagnostics;
with Awk_CLI.Localization;
with Awk_CLI.Options;

package Awk_CLI.Output is
   --  Presentation layer for CLI-owned text.
   --
   --  AWK program output must bypass this package except for raw stream
   --  forwarding performed by the top-level runner.

   procedure Set_Color (Mode : Awk_CLI.Options.Color_Mode);
   --  Set the process-wide color policy used for subsequent CLI presentation.

   function Help
     (Catalog : Awk_CLI.Localization.Catalog;
      Destination_Is_Terminal : Boolean) return String;
   --  Return localized help text for the destination styling policy.

   function Version (Catalog : Awk_CLI.Localization.Catalog) return String;
   --  Return localized version metadata text.

   function Diagnostic_Text
     (Catalog : Awk_CLI.Localization.Catalog;
      Item    : Awk_CLI.Diagnostics.Diagnostic;
      Destination_Is_Terminal : Boolean) return String;
   --  Render one structured diagnostic with localized text and safe escaping.
end Awk_CLI.Output;
