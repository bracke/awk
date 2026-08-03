with AUnit.Assertions;

with Ada.Strings.Unbounded;

with Awk_Tests.Process_Harness;
with Awk_Tests.Process_Support;
with Project_Tools.Files;
with Project_Tools.Text;

package body Awk_Tests.Process_IO is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Direct_File_Input (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("{ print $2 }"),
         new String'("tests/fixtures/input/basic.txt")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk direct file input",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process direct file input exits successfully");
      Assert (U.To_String (Output) = "two" & LF & "four" & LF,
              "process direct file input output");
   end Test_Process_Direct_File_Input;
   procedure Test_Process_Dash_Filename_After_Terminator
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Target : constant String := "tests/fixtures/filesystem/-dash-input.txt";
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 3) :=
        [new String'("--"),
         new String'("{ print FILENAME "":"" $1 }"),
         new String'(Target)];
      Status : Integer;
   begin
      Ensure_Filesystem_Fixture_Directory;
      Project_Tools.Files.Write_Raw_File ("../" & Target, "dash data" & LF);
      Status :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process dash filename",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
      Assert (Status = 0, "dash-leading filename exits successfully after --");
      Assert
        (Project_Tools.Text.Contains (U.To_String (Output), Target & ":dash"),
         "dash-leading filename is treated as an operand");
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
   end Test_Process_Dash_Filename_After_Terminator;
   procedure Test_Process_Option_Looking_File_After_Program
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Target : constant String := "--version";
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("{ print FILENAME "":"" $1 }"),
         new String'(Target)];
      Status : Integer;
   begin
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
      Project_Tools.Files.Write_Raw_File ("../" & Target, "operand-file" & LF);
      Status :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk option-looking file after program",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
      Assert (Status = 0, "option-looking filename after program exits successfully");
      Assert
        (Project_Tools.Text.Contains (U.To_String (Output), Target & ":operand-file" & LF),
         "post-program --version is read as an input file");
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
   end Test_Process_Option_Looking_File_After_Program;
   procedure Test_Process_Short_Option_Looking_File_After_Program
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Target : constant String := "-F";
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("{ print FILENAME "":"" $1 }"),
         new String'(Target)];
      Status : Integer;
   begin
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
      Project_Tools.Files.Write_Raw_File ("../" & Target, "short-option-file" & LF);
      Status :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk short option-looking file after program",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
      Assert (Status = 0, "short option-looking filename after program exits successfully");
      Assert
        (Project_Tools.Text.Contains (U.To_String (Output), Target & ":short-option-file" & LF),
         "post-program -F is read as an input file");
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
   end Test_Process_Short_Option_Looking_File_After_Program;
   procedure Test_Process_Program_Files (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 6) :=
        [new String'("-f"),
         new String'("tests/fixtures/programs/begin.awk"),
         new String'("-ftests/fixtures/programs/print-first.awk"),
         new String'("tests/fixtures/input/basic.txt"),
         new String'("tests/fixtures/input/second.txt"),
         new String'("name=value")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process -f",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process -f exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "begin" & LF & "one" & LF & "three"),
              "process -f loads files in order and reads first input");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "five" & LF),
              "process -f reads second input after runtime assignment operand");
   end Test_Process_Program_Files;
   procedure Test_Process_Option_Looking_Operand_After_File_Mode_Input
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Target : constant String := "-vX=late";
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 5) :=
        [new String'("-f"),
         new String'("tests/fixtures/programs/print-first.awk"),
         new String'("tests/fixtures/input/basic.txt"),
         new String'(Target),
         new String'("tests/fixtures/input/second.txt")];
      Status : Integer;
   begin
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
      Project_Tools.Files.Write_Raw_File ("../" & Target, "late-option-file" & LF);
      Status :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process file-mode late option operand",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
      Assert (Status = 0, "file-mode late option-looking operand exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "one" & LF & "three"),
              "first input file is processed");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "late-option-file" & LF),
              "late option-looking operand is processed as a filename");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "five" & LF),
              "input after late runtime assignment is processed");
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
   end Test_Process_Option_Looking_Operand_After_File_Mode_Input;
   procedure Test_Process_Redirection (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Target : constant String := "tests/fixtures/filesystem/process_redir.txt";
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("--color=always"),
         new String'("BEGIN { print ""saved"" > """ & Target & """ }")];
      Status : Integer;
   begin
      Ensure_Filesystem_Fixture_Directory;
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
      Project_Tools.Files.Write_Raw_File ("../" & Target, "old" & LF & "content" & LF);

      Status :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process redirection",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);

      Assert (Status = 0, "process redirection exits successfully");
      Assert (U.To_String (Output) = "", "process redirected output not on stdout");
      Assert (Read_Text_File ("../" & Target) = "saved", "process redirection file content");
      Assert (not Project_Tools.Text.Contains (Read_Text_File ("../" & Target), "old"),
              "overwrite redirection replaces existing file content");
      Assert (not Project_Tools.Text.Contains (Read_Text_File ("../" & Target), Character'Val (27) & "["),
              "color=always does not style redirected output");

      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
   end Test_Process_Redirection;
   procedure Test_Process_Append_Redirection (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Target : constant String := "tests/fixtures/filesystem/process_append.txt";
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("--color=always"),
         new String'("BEGIN { print ""first"" >> """ & Target & """; print ""second"" >> """ & Target & """ }")];
      Status : Integer;
   begin
      Ensure_Filesystem_Fixture_Directory;
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
      Project_Tools.Files.Write_Raw_File ("../" & Target, "existing" & LF);

      Status :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process append redirection",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);

      Assert (Status = 0, "process append redirection exits successfully");
      Assert (U.To_String (Output) = "", "process append redirection not on stdout");
      Assert
        (Project_Tools.Text.Contains (Read_Text_File ("../" & Target), "existing") and then
         Project_Tools.Text.Contains (Read_Text_File ("../" & Target), "first" & LF & "second"),
         "append redirection preserves existing content and write order");
      Assert (Read_Text_File ("../" & Target) /= "first" & LF & "second",
              "append redirection does not replace existing file content");
      Assert (not Project_Tools.Text.Contains (Read_Text_File ("../" & Target), Character'Val (27) & "["),
              "color=always does not style appended redirected output");

      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
   end Test_Process_Append_Redirection;
   procedure Test_Process_Redirection_Target_Directory_Failure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Target : constant String := "tests/fixtures/filesystem";

      procedure Expect_Failure (Operator, Message : String) is
         Args : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
           [new String'
              ("BEGIN { print ""x"" " & Operator & " """ & Target & """; print ""after"" }")];
      begin
         declare
            Status : aliased Integer := -1;
            Output : constant String :=
              Awk_Tests.Process_Harness.Command_Output
                (Command    => Awk_From_Tests_Directory,
                 Arguments  => Args,
                 Input      => "",
                 Status     => Status'Access,
                 Err_To_Out => True);
         begin
            Assert (Status = 3, Message & " exits with host I/O status");
            Assert (Project_Tools.Text.Contains (Output, "awk: error: cannot write output file: " & Target),
                    Message & " reports the redirected output target");
            Assert (not Project_Tools.Text.Contains (Output, "after"),
                    Message & " does not continue after required output failure");
            Assert (not Project_Tools.Text.Contains (Output, Character'Val (27) & "["),
                    Message & " diagnostic is unstyled by default capture");
         end;
      end Expect_Failure;
   begin
      Ensure_Filesystem_Fixture_Directory;
      Expect_Failure (">", "overwrite redirection to directory");
      Expect_Failure (">>", "append redirection to directory");
   end Test_Process_Redirection_Target_Directory_Failure;
   procedure Test_Process_Explicit_Stdin_Eof
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("{ print }"),
         new String'("-")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process explicit stdin eof",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "explicit stdin operand accepts EOF");
      Assert (U.To_String (Output) = "", "EOF stdin produces no records");
   end Test_Process_Explicit_Stdin_Eof;
   procedure Test_Process_Explicit_Stdin_Data
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("{ print NR "":"" $2 }"),
         new String'("-")];
      Status : aliased Integer := -1;
      Output : constant String :=
        Awk_Tests.Process_Harness.Command_Output
          (Command    => Awk_From_Tests_Directory,
           Arguments => Args,
           Input     => "one two" & LF & "three four",
           Status    => Status'Access);
   begin
      Assert (Status = 0, "explicit stdin data exits successfully");
      Assert (Output = "1:two" & LF & "2:four",
              "process stdin data reaches installed executable");
   end Test_Process_Explicit_Stdin_Data;
   procedure Test_Process_Implicit_Stdin_Data
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("{ print NR "":"" $1 }")];
      Status : aliased Integer := -1;
      Output : constant String :=
        Awk_Tests.Process_Harness.Command_Output
          (Command    => Awk_From_Tests_Directory,
           Arguments => Args,
           Input     => "red blue" & LF & "green yellow",
           Status    => Status'Access);
   begin
      Assert (Status = 0, "implicit stdin data exits successfully");
      Assert (Output = "1:red" & LF & "2:green",
              "missing input operands read standard input at process boundary");
   end Test_Process_Implicit_Stdin_Data;
   procedure Test_Process_Repeated_Stdin_Data
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 3) :=
        [new String'("{ print NR "":"" $0 }"),
         new String'("-"),
         new String'("-")];
      Status : aliased Integer := -1;
      Output : constant String :=
        Awk_Tests.Process_Harness.Command_Output
          (Command    => Awk_From_Tests_Directory,
           Arguments => Args,
           Input     => "alpha" & LF & "beta",
           Status    => Status'Access);
   begin
      Assert (Status = 0, "repeated stdin operands exit successfully");
      Assert (Output = "1:alpha" & LF & "2:beta",
              "first stdin operand consumes data and later stdin observes EOF");
   end Test_Process_Repeated_Stdin_Data;
   procedure Test_Process_Runtime_Assignment_Argv
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 3) :=
        [new String'("BEGIN { print ARGC; print ARGV[1]; print ARGV[2] }"),
         new String'("name=value"),
         new String'("tests/fixtures/input/basic.txt")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process runtime assignment argv",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process runtime assignment ARGV exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "3" & LF & "name=value" & LF),
              "runtime assignment spelling is preserved in ARGV");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "tests/fixtures/input/basic.txt"),
              "input filename remains ordered after runtime assignment");
   end Test_Process_Runtime_Assignment_Argv;
   procedure Test_Process_Runtime_Assignment_Positions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 5) :=
        [new String'("BEGIN { print ""begin"", X } { print FILENAME, FNR, X, $0 } END { print ""end"", X }"),
         new String'("tests/fixtures/input/basic.txt"),
         new String'("X=42"),
         new String'("tests/fixtures/input/second.txt"),
         new String'("X=99")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process runtime assignment positions",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process runtime assignment positions exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "begin " & LF),
              "initial runtime assignment value is empty before input");
      Assert
        (Project_Tools.Text.Contains (U.To_String (Output), "tests/fixtures/input/basic.txt 1  one two"),
         "first file is processed before interspersed assignment");
      Assert
        (Project_Tools.Text.Contains (U.To_String (Output), "tests/fixtures/input/second.txt 1 42 five six"),
         "interspersed assignment affects following input file");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "end 99" & LF),
              "final runtime assignment is visible in END");
   end Test_Process_Runtime_Assignment_Positions;


   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Process_Direct_File_Input'Access, "process direct file input");
      Registration.Register_Routine
        (T, Test_Process_Dash_Filename_After_Terminator'Access,
         "process dash filename after terminator");
      Registration.Register_Routine
        (T, Test_Process_Option_Looking_File_After_Program'Access,
         "process option-looking file after program");
      Registration.Register_Routine
        (T, Test_Process_Short_Option_Looking_File_After_Program'Access,
         "process short option-looking file after program");
      Registration.Register_Routine (T, Test_Process_Program_Files'Access, "process -f program files");
      Registration.Register_Routine
        (T, Test_Process_Option_Looking_Operand_After_File_Mode_Input'Access,
         "process file-mode late option operand");
      Registration.Register_Routine (T, Test_Process_Redirection'Access, "process redirection");
      Registration.Register_Routine (T, Test_Process_Append_Redirection'Access, "process append redirection");
      Registration.Register_Routine
        (T, Test_Process_Redirection_Target_Directory_Failure'Access,
         "process redirection target directory failure");
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
end Awk_Tests.Process_IO;
