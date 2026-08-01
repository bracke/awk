with Awk_CLI.Diagnostics;
with Awk_CLI.Localization;
with Awk_CLI.Options;

package Awk_CLI.Output is
   procedure Set_Color (Mode : Awk_CLI.Options.Color_Mode);
   function Help (Catalog : Awk_CLI.Localization.Catalog) return String;
   function Version (Catalog : Awk_CLI.Localization.Catalog) return String;
   function Diagnostic_Text
     (Catalog : Awk_CLI.Localization.Catalog;
      Item    : Awk_CLI.Diagnostics.Diagnostic) return String;
end Awk_CLI.Output;
