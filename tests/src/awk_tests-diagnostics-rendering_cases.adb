with AUnit.Assertions;

with Awk_CLI.Diagnostics;
with Awk_CLI.Localization;
with Awk_CLI.Output;
with Project_Tools.Text;

package body Awk_Tests.Diagnostics.Rendering_Cases is
   use AUnit.Assertions;

   LF : constant String := [1 => ASCII.LF];

   procedure Test_Diagnostic_Source_Rendering
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Catalog : Awk_CLI.Localization.Catalog;
      Escape  : constant String := [1 => Character'Val (27)];
   begin
      Awk_CLI.Localization.Initialize
        (Catalog, "../resources/messages/catalog.txt", "en");
      declare
         Item : constant Awk_CLI.Diagnostics.Diagnostic :=
           Awk_CLI.Diagnostics.With_Source
             (Awk_CLI.Diagnostics.Make
                ("awk.interpreter.parse_failed",
                 Awk_CLI.Diagnostics.Error,
                 Awk_CLI.Diagnostics.Interpreter,
                 Detail => "near print"),
              "bad" & LF & "file" & Escape & "[2J.awk",
              12,
              3);
         Text : constant String := Awk_CLI.Output.Diagnostic_Text (Catalog, Item, False);
      begin
         Assert
           (Project_Tools.Text.Contains (Text, "bad\nfile\e[2J.awk:12:3"),
            "source location is escaped and compact");
         Assert
           (Project_Tools.Text.Contains (Text, "near print"),
            "technical detail is retained");
         Assert
           (not Project_Tools.Text.Contains (Text, Escape),
            "source rendering has no raw escape");
      end;

      Awk_CLI.Localization.Initialize
        (Catalog, "../resources/messages/catalog.txt", "da");
      declare
         Item : constant Awk_CLI.Diagnostics.Diagnostic :=
           Awk_CLI.Diagnostics.With_Source
             (Awk_CLI.Diagnostics.Make
                ("awk.interpreter.parse_failed",
                 Awk_CLI.Diagnostics.Error,
                 Awk_CLI.Diagnostics.Interpreter),
              "awk.source.command_line",
              1);
         Text : constant String := Awk_CLI.Output.Diagnostic_Text (Catalog, Item, False);
      begin
         Assert
           (Project_Tools.Text.Contains (Text, "kommandolinje:1"),
            "catalog source display key is localized in diagnostics");
      end;
   end Test_Diagnostic_Source_Rendering;
end Awk_Tests.Diagnostics.Rendering_Cases;
