with AUnit.Assertions;

with Awk_Tests.Process_Support;
with Project_Tools.Text;

package body Awk_Tests.Process_Diagnostics.Usage_Cases.File_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Program_File_Stdin_Unsupported
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Expect_Unsupported
        (Args    : Process_Arguments;
         Message : String)
      is
      begin
         declare
            Result : constant Captured_Process := Run_Awk_Err_To_Out (Args);
            Output : constant String := Output_String (Result);
         begin
            Assert (Result.Status = 2, Message & " exits with usage status");
            Assert
              (Project_Tools.Text.Contains
                 (Output,
                  English_Text ("awk.usage.program_file_stdin_unsupported")),
               Message & " explains why stdin program files are rejected");
            Assert (Project_Tools.Text.Contains
                      (Output, English_Hint ("awk.hint.option_terminator")),
                    Message & " emits the option-terminator hint");
         end;
      end Expect_Unsupported;
   begin
      declare
         Separate_Args : constant Process_Arguments :=
           Arguments ([Argument ("-f"), Argument ("-")]);
         Attached : constant Process_Arguments :=
           Arguments ([Argument ("-f-")]);
      begin
         Expect_Unsupported (Separate_Args, "separate -f -");
         Expect_Unsupported (Attached, "attached -f-");
      end;
   end Test_Process_Program_File_Stdin_Unsupported;

   procedure Test_Process_Missing_Program_File (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("-f"),
            Argument ("tests/fixtures/programs/no-such-program.awk")]);
   begin
      declare
         Result : constant Captured_Process := Run_Awk_Err_To_Out (Args);
         Output : constant String := Output_String (Result);
      begin
         Assert (Result.Status = 3, "missing process program file exits with host I/O status");
         Assert
           (Project_Tools.Text.Contains
              (Output,
               English_Text
                 ("awk.program_file.open_failed",
                  "path",
                  "tests/fixtures/programs/no-such-program.awk")),
            "missing process program file reports the original path");
         Assert (Project_Tools.Text.Contains
                   (Output,
                    English_Error_Header
                      (English_Text
                         ("awk.program_file.open_failed",
                          "path",
                          "tests/fixtures/programs/no-such-program.awk"))),
                 "missing process program file uses the CLI diagnostic wrapper");
         Assert (not Project_Tools.Text.Contains (Output, Character'Val (27) & "["),
                 "default captured program-file diagnostic is unstyled");
      end;
   end Test_Process_Missing_Program_File;

   procedure Test_Process_Missing_Input_File (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("{ print }"),
            Argument ("tests/fixtures/input/no-such-input.txt")]);
   begin
      declare
         Result : constant Captured_Process := Run_Awk_Err_To_Out (Args);
         Output : constant String := Output_String (Result);
      begin
         Assert (Result.Status = 3, "missing process input file exits with host I/O status");
         Assert
           (Project_Tools.Text.Contains
              (Output,
               English_Text
                 ("awk.input_file.open_failed",
                  "path",
                  "tests/fixtures/input/no-such-input.txt")),
            "missing process input file reports the original path");
         Assert (Project_Tools.Text.Contains
                   (Output,
                    English_Error_Header
                      (English_Text
                         ("awk.input_file.open_failed",
                          "path",
                          "tests/fixtures/input/no-such-input.txt"))),
                 "missing process input file uses the CLI diagnostic wrapper");
         Assert (not Project_Tools.Text.Contains (Output, Character'Val (27) & "["),
                 "default captured input-file diagnostic is unstyled");
      end;
   end Test_Process_Missing_Input_File;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Process_Program_File_Stdin_Unsupported'Access,
         "process -f stdin unsupported");
      Registration.Register_Routine
        (T, Test_Process_Missing_Program_File'Access,
         "process missing program file");
      Registration.Register_Routine
        (T, Test_Process_Missing_Input_File'Access,
         "process missing input file");
   end Register;
end Awk_Tests.Process_Diagnostics.Usage_Cases.File_Cases;
