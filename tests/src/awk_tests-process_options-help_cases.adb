with AUnit.Assertions;

with Awk_Tests.Process_Support;
with Project_Tools.Text;

package body Awk_Tests.Process_Options.Help_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Help_Color_Never (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments ([Argument ("--color=never"), Argument ("--help")]);
      Result : constant Captured_Process := Run_Awk ("awk help no color", Args);
   begin
      Assert (Result.Status = 0, "process help exits successfully");
      Assert (Project_Tools.Text.Contains
                (Output_String (Result), English_Text ("awk.help.usage.direct_program")),
              "help includes usage");
      Assert (Project_Tools.Text.Contains
                (Output_String (Result), English_Text ("awk.help.options.terminator")),
              "help documents the option terminator");
      Assert (Project_Tools.Text.Contains
                (Output_String (Result), English_Text ("awk.help.operands")),
              "help documents operand classification");
      Assert (Project_Tools.Text.Contains
                (Output_String (Result), English_Text ("awk.help.stdin")),
              "help documents implicit standard input");
      Assert (Project_Tools.Text.Contains
                (Output_String (Result), English_Text ("awk.help.exit_statuses")),
              "help documents exit statuses");
      Assert (Project_Tools.Text.Contains
                (Output_String (Result), English_Text ("awk.help.compatibility.awklib_limitations")),
              "help documents the compatibility position");
      Assert (not Project_Tools.Text.Contains (Output_String (Result), Character'Val (27) & "["),
              "color=never suppresses ANSI escapes");
   end Test_Process_Help_Color_Never;

   procedure Test_Process_Help_Short_Circuits_Runtime
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : constant Process_Arguments :=
        Arguments
          ([Argument ("--help"),
            Argument ("-f"),
            Argument ("tests/fixtures/programs/no-such-program.awk"),
            Argument ("BEGIN {")]);
      Result : constant Captured_Process := Run_Awk ("awk help short circuit", Args);
   begin
      Assert (Result.Status = 0, "help ignores later runtime failures");
      Assert (Project_Tools.Text.Contains
                (Output_String (Result), English_Text ("awk.help.usage.direct_program")),
              "help text is emitted");
   end Test_Process_Help_Short_Circuits_Runtime;

   procedure Test_Process_Help_Color_Always (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments ([Argument ("--color=always"), Argument ("--help")]);
      Result : constant Captured_Process := Run_Awk ("awk help color always", Args);
   begin
      Assert (Result.Status = 0, "process help color always exits successfully");
      Assert (Project_Tools.Text.Contains (Output_String (Result), Character'Val (27) & "["),
              "color=always styles CLI-owned help");
   end Test_Process_Help_Color_Always;

   procedure Test_Process_Help_Auto_Respects_No_Color
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : constant Process_Arguments :=
        Arguments ([Argument ("--color=auto"), Argument ("--help")]);
   begin
      declare
         Result : constant Captured_Process :=
           Run_Awk_With_Environment
             ("awk help auto no color", [Argument ("NO_COLOR=1")], Args);
      begin
         Assert (Result.Status = 0, "process help auto with NO_COLOR exits successfully");
         Assert (Project_Tools.Text.Contains
                   (Output_String (Result), English_Text ("awk.help.usage.direct_program")),
                 "help includes usage");
         Assert (not Project_Tools.Text.Contains (Output_String (Result), Character'Val (27) & "["),
                 "color=auto honors NO_COLOR through terminal_styles");
      end;
   end Test_Process_Help_Auto_Respects_No_Color;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Process_Help_Color_Never'Access, "process help color never");
      Registration.Register_Routine
        (T, Test_Process_Help_Short_Circuits_Runtime'Access,
         "process help short circuit");
      Registration.Register_Routine (T, Test_Process_Help_Color_Always'Access, "process help color always");
      Registration.Register_Routine
        (T, Test_Process_Help_Auto_Respects_No_Color'Access,
         "process help auto NO_COLOR");
   end Register;
end Awk_Tests.Process_Options.Help_Cases;
