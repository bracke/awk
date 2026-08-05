with AUnit.Assertions;

with Awk_Tests.Process_Support;
with Project_Tools.Text;

package body Awk_Tests.Process_Language is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Multiple_Files (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("{ print FILENAME "":"" FNR "":"" $1 }"),
            Argument ("tests/fixtures/input/basic.txt"),
            Argument ("tests/fixtures/input/second.txt")]);
      Result : constant Captured_Process := Run_Awk ("awk process multiple files", Args);
   begin
      Assert (Result.Status = 0, "process multiple files exits successfully");
      Assert (Project_Tools.Text.Contains
                (Output_String (Result), "tests/fixtures/input/basic.txt:1:one"),
              "first file FILENAME/FNR visible");
      Assert (Project_Tools.Text.Contains
                (Output_String (Result), "tests/fixtures/input/second.txt:1:five"),
              "second file FILENAME/FNR visible");
   end Test_Process_Multiple_Files;

   procedure Test_Process_Filter_Expression_Smoke
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument
              ("/^[a-z]+ [a-z]+$/ { print $1, length($2), substr($2, 1, 1) }"),
            Argument ("tests/fixtures/input/basic.txt")]);
   begin
      declare
         Result : constant Captured_Process :=
           Run_Awk ("awk process filter expression smoke", Args);
      begin
         Assert (Result.Status = 0, "process filter expression smoke exits successfully");
         Assert (Project_Tools.Text.Contains (Output_String (Result), "one 3 t"),
                 "representative pattern, expression, and builtin output is forwarded");
         Assert (Project_Tools.Text.Contains (Output_String (Result), "three 4 f"),
                 "representative expression processes later records");
      end;
   end Test_Process_Filter_Expression_Smoke;

   procedure Test_Process_Command_Getline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments ([Argument ("BEGIN { ""printf x"" | getline value; print value }")]);
      Result : constant Captured_Process := Run_Awk ("awk process command getline", Args);
   begin
      Assert (Result.Status = 0, "process command getline exits successfully");
      Assert (Project_Tools.Text.Contains (Output_String (Result), "x"),
              "process command getline reads command output");
   end Test_Process_Command_Getline;

   procedure Test_Process_Auxiliary_File_Getline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("BEGIN { getline line < ""tests/fixtures/input/basic.txt""; print line }")]);
      Result : constant Captured_Process := Run_Awk ("awk process auxiliary getline", Args);
   begin
      Assert (Result.Status = 0, "process auxiliary file getline exits successfully");
      Assert (Project_Tools.Text.Contains (Output_String (Result), "one two" & LF),
              "process getline < file reads registered host file");
   end Test_Process_Auxiliary_File_Getline;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Process_Multiple_Files'Access,
         "process multiple files");
      Registration.Register_Routine
        (T, Test_Process_Filter_Expression_Smoke'Access,
         "process filter expression smoke");
      Registration.Register_Routine
        (T, Test_Process_Command_Getline'Access,
         "process command getline");
      Registration.Register_Routine
        (T, Test_Process_Auxiliary_File_Getline'Access,
         "process auxiliary file getline");
   end Register;
end Awk_Tests.Process_Language;
