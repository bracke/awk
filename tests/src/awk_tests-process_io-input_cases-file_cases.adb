with AUnit.Assertions;

with Awk_Tests.Process_Support;
with Project_Tools.Files;
with Project_Tools.Text;

package body Awk_Tests.Process_IO.Input_Cases.File_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Direct_File_Input (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("{ print $2 }"),
            Argument ("tests/fixtures/input/basic.txt")]);
      Result : constant Captured_Process := Run_Awk ("awk direct file input", Args);
   begin
      Assert (Result.Status = 0, "process direct file input exits successfully");
      Assert (Output_String (Result) = "two" & LF & "four" & LF,
              "process direct file input output");
   end Test_Process_Direct_File_Input;

   procedure Test_Process_Dash_Filename_After_Terminator
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Temp   : constant String := Fresh_Process_Temp_Dir ("dash_filename");
      Target : constant String := Project_Tools.Files.Join (Temp, "-dash-input.txt");
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("--"),
            Argument ("{ print FILENAME "":"" $1 }"),
            Argument (Target)]);
   begin
      Write_Text_File (Target, "dash data" & LF);
      declare
         Result : constant Captured_Process := Run_Awk ("awk process dash filename", Args);
      begin
         Assert (Result.Status = 0, "dash-leading filename exits successfully after --");
         Assert
           (Project_Tools.Text.Contains (Output_String (Result), Target & ":dash"),
            "dash-leading filename is treated as an operand");
      end;
      Cleanup_Process_Temp_Dir (Temp);
   end Test_Process_Dash_Filename_After_Terminator;

   procedure Test_Process_Option_Looking_File_After_Program
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Temp   : constant String := Fresh_Process_Temp_Dir ("long_option_file");
      Target : constant String := "--version";
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("{ print FILENAME "":"" $1 }"),
            Argument (Target)]);
   begin
      Write_Text_File (Project_Tools.Files.Join (Temp, Target), "operand-file" & LF);
      declare
         Result : constant Captured_Process :=
           Run_Awk_In_Directory ("awk option-looking file after program", Temp, Args);
      begin
         Assert (Result.Status = 0, "option-looking filename after program exits successfully");
         Assert
           (Project_Tools.Text.Contains (Output_String (Result), Target & ":operand-file" & LF),
            "post-program --version is read as an input file");
      end;
      Cleanup_Process_Temp_Dir (Temp);
   end Test_Process_Option_Looking_File_After_Program;

   procedure Test_Process_Short_Option_Looking_File_After_Program
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Temp   : constant String := Fresh_Process_Temp_Dir ("short_option_file");
      Target : constant String := "-F";
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("{ print FILENAME "":"" $1 }"),
            Argument (Target)]);
   begin
      Write_Text_File (Project_Tools.Files.Join (Temp, Target), "short-option-file" & LF);
      declare
         Result : constant Captured_Process :=
           Run_Awk_In_Directory ("awk short option-looking file after program", Temp, Args);
      begin
         Assert
           (Result.Status = 0,
            "short option-looking filename after program exits successfully");
         Assert
           (Project_Tools.Text.Contains
              (Output_String (Result), Target & ":short-option-file" & LF),
            "post-program -F is read as an input file");
      end;
      Cleanup_Process_Temp_Dir (Temp);
   end Test_Process_Short_Option_Looking_File_After_Program;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Process_Direct_File_Input'Access, "process direct file input");
      Registration.Register_Routine
        (T, Test_Process_Dash_Filename_After_Terminator'Access,
         "process dash filename after terminator");
      Registration.Register_Routine
        (T, Test_Process_Option_Looking_File_After_Program'Access,
         "process option-looking file after program");
      Registration.Register_Routine
        (T, Test_Process_Short_Option_Looking_File_After_Program'Access,
         "process short option-looking file after program");
   end Register;
end Awk_Tests.Process_IO.Input_Cases.File_Cases;
