with AUnit.Assertions;

with GNAT.OS_Lib;

with Awk_Tests.Process_Support;
with Project_Tools.Files;
with Project_Tools.Text;

package body Awk_Tests.Process_IO.Input_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Direct_File_Input (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("{ print $2 }"),
         new String'("tests/fixtures/input/basic.txt")];
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
      Target : constant String := "tests/fixtures/filesystem/-dash-input.txt";
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("--"),
         new String'("{ print FILENAME "":"" $1 }"),
         new String'(Target)];
   begin
      Ensure_Filesystem_Fixture_Directory;
      Project_Tools.Files.Write_Raw_File ("../" & Target, "dash data" & LF);
      declare
         Result : constant Captured_Process := Run_Awk ("awk process dash filename", Args);
      begin
         Assert (Result.Status = 0, "dash-leading filename exits successfully after --");
         Assert
           (Project_Tools.Text.Contains (Output_String (Result), Target & ":dash"),
            "dash-leading filename is treated as an operand");
      end;
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
   end Test_Process_Dash_Filename_After_Terminator;

   procedure Test_Process_Option_Looking_File_After_Program
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Target : constant String := "--version";
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("{ print FILENAME "":"" $1 }"),
         new String'(Target)];
   begin
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
      Project_Tools.Files.Write_Raw_File ("../" & Target, "operand-file" & LF);
      declare
         Result : constant Captured_Process :=
           Run_Awk ("awk option-looking file after program", Args);
      begin
         Assert (Result.Status = 0, "option-looking filename after program exits successfully");
         Assert
           (Project_Tools.Text.Contains (Output_String (Result), Target & ":operand-file" & LF),
            "post-program --version is read as an input file");
      end;
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
   end Test_Process_Option_Looking_File_After_Program;

   procedure Test_Process_Short_Option_Looking_File_After_Program
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Target : constant String := "-F";
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("{ print FILENAME "":"" $1 }"),
         new String'(Target)];
   begin
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
      Project_Tools.Files.Write_Raw_File ("../" & Target, "short-option-file" & LF);
      declare
         Result : constant Captured_Process :=
           Run_Awk ("awk short option-looking file after program", Args);
      begin
         Assert
           (Result.Status = 0,
            "short option-looking filename after program exits successfully");
         Assert
           (Project_Tools.Text.Contains
              (Output_String (Result), Target & ":short-option-file" & LF),
            "post-program -F is read as an input file");
      end;
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
   end Test_Process_Short_Option_Looking_File_After_Program;

   procedure Test_Process_Program_Files (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 6) :=
        [new String'("-f"),
         new String'("tests/fixtures/programs/begin.awk"),
         new String'("-ftests/fixtures/programs/print-first.awk"),
         new String'("tests/fixtures/input/basic.txt"),
         new String'("tests/fixtures/input/second.txt"),
         new String'("name=value")];
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
      Target : constant String := "-vX=late";
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 5) :=
        [new String'("-f"),
         new String'("tests/fixtures/programs/print-first.awk"),
         new String'("tests/fixtures/input/basic.txt"),
         new String'(Target),
         new String'("tests/fixtures/input/second.txt")];
   begin
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
      Project_Tools.Files.Write_Raw_File ("../" & Target, "late-option-file" & LF);
      declare
         Result : constant Captured_Process :=
           Run_Awk ("awk process file-mode late option operand", Args);
      begin
         Assert (Result.Status = 0, "file-mode late option-looking operand exits successfully");
         Assert (Project_Tools.Text.Contains (Output_String (Result), "one" & LF & "three"),
                 "first input file is processed");
         Assert (Project_Tools.Text.Contains (Output_String (Result), "late-option-file" & LF),
                 "late option-looking operand is processed as a filename");
         Assert (Project_Tools.Text.Contains (Output_String (Result), "five" & LF),
                 "input after late runtime assignment is processed");
      end;
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
   end Test_Process_Option_Looking_Operand_After_File_Mode_Input;

   procedure Test_Process_Explicit_Stdin_Eof
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("{ print }"),
         new String'("-")];
      Result : constant Captured_Process := Run_Awk ("awk process explicit stdin eof", Args);
   begin
      Assert (Result.Status = 0, "explicit stdin operand accepts EOF");
      Assert (Output_String (Result) = "", "EOF stdin produces no records");
   end Test_Process_Explicit_Stdin_Eof;

   procedure Test_Process_Explicit_Stdin_Data
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("{ print NR "":"" $2 }"),
         new String'("-")];
      Result : constant Captured_Process :=
        Run_Awk_Err_To_Out (Args, "one two" & LF & "three four");
      Output : constant String := Output_String (Result);
   begin
      Assert (Result.Status = 0, "explicit stdin data exits successfully");
      Assert (Output = "1:two" & LF & "2:four",
              "process stdin data reaches installed executable");
   end Test_Process_Explicit_Stdin_Data;

   procedure Test_Process_Implicit_Stdin_Data
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("{ print NR "":"" $1 }")];
      Result : constant Captured_Process :=
        Run_Awk_Err_To_Out (Args, "red blue" & LF & "green yellow");
      Output : constant String := Output_String (Result);
   begin
      Assert (Result.Status = 0, "implicit stdin data exits successfully");
      Assert (Output = "1:red" & LF & "2:green",
              "missing input operands read standard input at process boundary");
   end Test_Process_Implicit_Stdin_Data;

   procedure Test_Process_Repeated_Stdin_Data
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("{ print NR "":"" $0 }"),
         new String'("-"),
         new String'("-")];
      Result : constant Captured_Process :=
        Run_Awk_Err_To_Out (Args, "alpha" & LF & "beta");
      Output : constant String := Output_String (Result);
   begin
      Assert (Result.Status = 0, "repeated stdin operands exit successfully");
      Assert (Output = "1:alpha" & LF & "2:beta",
              "first stdin operand consumes data and later stdin observes EOF");
   end Test_Process_Repeated_Stdin_Data;

   procedure Test_Process_Runtime_Assignment_Argv
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("BEGIN { print ARGC; print ARGV[1]; print ARGV[2] }"),
         new String'("name=value"),
         new String'("tests/fixtures/input/basic.txt")];
      Result : constant Captured_Process := Run_Awk ("awk process runtime assignment argv", Args);
   begin
      Assert (Result.Status = 0, "process runtime assignment ARGV exits successfully");
      Assert (Project_Tools.Text.Contains (Output_String (Result), "3" & LF & "name=value" & LF),
              "runtime assignment spelling is preserved in ARGV");
      Assert (Project_Tools.Text.Contains
                (Output_String (Result), "tests/fixtures/input/basic.txt"),
              "input filename remains ordered after runtime assignment");
   end Test_Process_Runtime_Assignment_Argv;

   procedure Test_Process_Runtime_Assignment_Positions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 5) :=
        [new String'
           ("BEGIN { print ""begin"", X }"
            & " { print FILENAME, FNR, X, $0 } END { print ""end"", X }"),
         new String'("tests/fixtures/input/basic.txt"),
         new String'("X=42"),
         new String'("tests/fixtures/input/second.txt"),
         new String'("X=99")];
      Result : constant Captured_Process :=
        Run_Awk ("awk process runtime assignment positions", Args);
   begin
      Assert (Result.Status = 0, "process runtime assignment positions exits successfully");
      Assert (Project_Tools.Text.Contains (Output_String (Result), "begin " & LF),
              "initial runtime assignment value is empty before input");
      Assert
        (Project_Tools.Text.Contains
           (Output_String (Result), "tests/fixtures/input/basic.txt 1  one two"),
         "first file is processed before interspersed assignment");
      Assert
        (Project_Tools.Text.Contains
           (Output_String (Result), "tests/fixtures/input/second.txt 1 42 five six"),
         "interspersed assignment affects following input file");
      Assert (Project_Tools.Text.Contains (Output_String (Result), "end 99" & LF),
              "final runtime assignment is visible in END");
   end Test_Process_Runtime_Assignment_Positions;

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
      Registration.Register_Routine
        (T, Test_Process_Program_Files'Access, "process -f program files");
      Registration.Register_Routine
        (T, Test_Process_Option_Looking_Operand_After_File_Mode_Input'Access,
         "process file-mode late option operand");
      Registration.Register_Routine
        (T, Test_Process_Explicit_Stdin_Eof'Access,
         "process explicit stdin eof");
      Registration.Register_Routine
        (T, Test_Process_Explicit_Stdin_Data'Access,
         "process explicit stdin data");
      Registration.Register_Routine
        (T, Test_Process_Implicit_Stdin_Data'Access,
         "process implicit stdin data");
      Registration.Register_Routine
        (T, Test_Process_Repeated_Stdin_Data'Access,
         "process repeated stdin data");
      Registration.Register_Routine
        (T, Test_Process_Runtime_Assignment_Argv'Access,
         "process runtime assignment ARGV");
      Registration.Register_Routine
        (T, Test_Process_Runtime_Assignment_Positions'Access,
         "process runtime assignment positions");
   end Register;
end Awk_Tests.Process_IO.Input_Cases;
