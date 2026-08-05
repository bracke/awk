with AUnit.Assertions;

with Awk_Tests.Process_Support;
with Project_Tools.Files;
with Project_Tools.Text;

package body Awk_Tests.Process_IO.Input_Cases.Program_File_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Program_Files (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("-f"),
            Argument ("tests/fixtures/programs/begin.awk"),
            Argument ("-ftests/fixtures/programs/print-first.awk"),
            Argument ("tests/fixtures/input/basic.txt"),
            Argument ("tests/fixtures/input/second.txt"),
            Argument ("name=value")]);
      Result : constant Captured_Process := Run_Awk ("awk process -f", Args);
   begin
      Assert (Result.Status = 0, "process -f exits successfully");
      Assert (Project_Tools.Text.Contains
                (Output_String (Result), "begin" & LF & "one" & LF & "three"),
              "process -f loads files in order and reads first input");
      Assert (Project_Tools.Text.Contains (Output_String (Result), "five" & LF),
              "process -f reads second input after runtime assignment operand");
   end Test_Process_Program_Files;

   procedure Test_Process_Option_Looking_Operand_After_File_Mode_Input
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Temp   : constant String := Fresh_Process_Temp_Dir ("late_option_operand");
      Target : constant String := "-vX=late";
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("-f"),
            Argument (Repository_Path ("tests/fixtures/programs/print-first.awk")),
            Argument (Repository_Path ("tests/fixtures/input/basic.txt")),
            Argument (Target),
            Argument (Repository_Path ("tests/fixtures/input/second.txt"))]);
   begin
      Write_Text_File (Project_Tools.Files.Join (Temp, Target), "late-option-file" & LF);
      declare
         Result : constant Captured_Process :=
           Run_Awk_In_Directory ("awk process file-mode late option operand", Temp, Args);
      begin
         Assert (Result.Status = 0, "file-mode late option-looking operand exits successfully");
         Assert (Project_Tools.Text.Contains (Output_String (Result), "one" & LF & "three"),
                 "first input file is processed");
         Assert (Project_Tools.Text.Contains (Output_String (Result), "late-option-file" & LF),
                 "late option-looking operand is processed as a filename");
         Assert (Project_Tools.Text.Contains (Output_String (Result), "five" & LF),
                 "input after late runtime assignment is processed");
      end;
      Cleanup_Process_Temp_Dir (Temp);
   end Test_Process_Option_Looking_Operand_After_File_Mode_Input;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Process_Program_Files'Access, "process -f program files");
      Registration.Register_Routine
        (T, Test_Process_Option_Looking_Operand_After_File_Mode_Input'Access,
         "process file-mode late option operand");
   end Register;
end Awk_Tests.Process_IO.Input_Cases.Program_File_Cases;
