with AUnit.Assertions;

with Awk_CLI.Diagnostics;
with Project_Tools.Text;

package body Awk_Tests.Diagnostics.Model_Cases is
   use AUnit.Assertions;

   procedure Test_Diagnostic_Escape_Control_Characters
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Escape : constant String := [1 => Character'Val (27)];
      Raw    : constant String :=
        "a" & ASCII.CR & "b" & ASCII.HT & "c" & Escape &
        "d" & Character'Val (0) & "e" & Character'Val (127);
      Text   : constant String := Awk_CLI.Diagnostics.Escape (Raw);
   begin
      Assert
        (Text = "a\rb\tc\ed?e?",
         "diagnostic escaping renders unsafe controls deterministically");
      Assert
        (not Project_Tools.Text.Contains (Text, [1 => ASCII.CR]),
         "raw carriage return is not emitted");
      Assert
        (not Project_Tools.Text.Contains (Text, [1 => ASCII.HT]),
         "raw tab is not emitted");
      Assert
        (not Project_Tools.Text.Contains (Text, Escape),
         "raw escape is not emitted");
      Assert
        (not Project_Tools.Text.Contains (Text, [1 => Character'Val (0)]),
         "raw NUL is not emitted");
      Assert
        (not Project_Tools.Text.Contains (Text, [1 => Character'Val (127)]),
         "raw DEL is not emitted");
   end Test_Diagnostic_Escape_Control_Characters;

   procedure Test_Diagnostic_Status_Registry
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      package D renames Awk_CLI.Diagnostics;
      use type D.Exit_Code;

      function Status (Category : D.Diagnostic_Category) return D.Exit_Code is
        (D.Status_For (D.Make ("awk.test", D.Error, Category)));
   begin
      Assert (Status (D.Usage) = D.Usage_Exit, "usage diagnostics exit 2");
      Assert
        (Status (D.Program_Source) = D.IO_Exit,
         "program-source diagnostics exit 3");
      Assert (Status (D.Input) = D.IO_Exit, "input diagnostics exit 3");
      Assert (Status (D.Output) = D.IO_Exit, "output diagnostics exit 3");
      Assert
        (Status (D.Environment) = D.IO_Exit,
         "environment diagnostics exit 3");
      Assert (Status (D.Platform) = D.IO_Exit, "platform diagnostics exit 3");
      Assert
        (Status (D.Interpreter) = D.Interpreter_Exit,
         "interpreter diagnostics exit 1");
      Assert
        (Status (D.Internal) = D.Internal_Exit,
         "internal diagnostics exit 70");
   end Test_Diagnostic_Status_Registry;
end Awk_Tests.Diagnostics.Model_Cases;
