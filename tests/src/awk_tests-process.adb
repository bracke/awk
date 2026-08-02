with AUnit.Assertions;

with Ada.Strings.Unbounded;

with GNAT.Expect;
with GNAT.OS_Lib;

with Project_Tools.Files;
with Project_Tools.Processes;
with Awk_Tests.Support;

package body Awk_Tests.Process is
   use AUnit.Assertions;
   use Awk_Tests.Support;
   package U renames Ada.Strings.Unbounded;

   LF : constant String := [1 => ASCII.LF];

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk process");
   end Name;

   procedure Test_Process_Version (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("--version")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk --version",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process version exits successfully");
      Assert (Contains (U.To_String (Output), "awk 0.1.0"), "process version includes awk version");
      Assert (Contains (U.To_String (Output), "awklib 0.1.0"), "process version includes awklib version");
   end Test_Process_Version;

   procedure Test_Process_Direct_File_Input (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("{ print $2 }"),
         new String'("tests/fixtures/input/basic.txt")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk direct file input",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process direct file input exits successfully");
      Assert (U.To_String (Output) = "two" & LF & "four" & LF & LF,
              "process direct file input output");
   end Test_Process_Direct_File_Input;

   procedure Test_Process_Dash_Filename_After_Terminator
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Target : constant String := "tests/fixtures/filesystem/-dash-input.txt";
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("--"),
         new String'("{ print FILENAME "":"" $1 }"),
         new String'(Target)];
      Status : Integer;
   begin
      Write_Text_File ("../" & Target, "dash data" & LF);
      Status :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process dash filename",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
      Assert (Status = 0, "dash-leading filename exits successfully after --");
      Assert
        (Contains (U.To_String (Output), Target & ":dash"),
         "dash-leading filename is treated as an operand");
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
   end Test_Process_Dash_Filename_After_Terminator;

   procedure Test_Process_Program_Files (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 6) :=
        [new String'("-f"),
         new String'("tests/fixtures/programs/begin.awk"),
         new String'("-ftests/fixtures/programs/print-first.awk"),
         new String'("tests/fixtures/input/basic.txt"),
         new String'("tests/fixtures/input/second.txt"),
         new String'("name=value")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process -f",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process -f exits successfully");
      Assert (Contains (U.To_String (Output), "begin" & LF & "one" & LF & "three"),
              "process -f loads files in order and reads first input");
      Assert (Contains (U.To_String (Output), "five" & LF),
              "process -f reads second input after runtime assignment operand");
   end Test_Process_Program_Files;

   procedure Test_Process_Help_Color_Never (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("--color=never"), new String'("--help")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk help no color",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process help exits successfully");
      Assert (Contains (U.To_String (Output), "Usage: awk"), "help includes usage");
      Assert (not Contains (U.To_String (Output), Character'Val (27) & "["),
              "color=never suppresses ANSI escapes");
   end Test_Process_Help_Color_Never;

   procedure Test_Process_Help_Short_Circuits_Runtime
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 4) :=
        [new String'("--help"),
         new String'("-f"),
         new String'("tests/fixtures/programs/no-such-program.awk"),
         new String'("BEGIN {")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk help short circuit",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "help ignores later runtime failures");
      Assert (Contains (U.To_String (Output), "Usage: awk"), "help text is emitted");
   end Test_Process_Help_Short_Circuits_Runtime;

   procedure Test_Process_Help_Color_Always (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("--color=always"), new String'("--help")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk help color always",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process help color always exits successfully");
      Assert (Contains (U.To_String (Output), Character'Val (27) & "["),
              "color=always styles CLI-owned help");
   end Test_Process_Help_Color_Always;

   procedure Test_Process_Help_Auto_Respects_No_Color
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Env    : constant String := Project_Tools.Processes.Locate_Command ("env");
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 4) :=
        [new String'("NO_COLOR=1"),
         new String'("./bin/awk"),
         new String'("--color=auto"),
         new String'("--help")];
      Status : Integer;
   begin
      Assert (Env /= "", "env executable is available for environment-bound process test");
      Status :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk help auto no color",
           Dir     => "..",
           Program => Env,
           Args    => Args,
           Output  => Output,
           Quiet   => True);
      Assert (Status = 0, "process help auto with NO_COLOR exits successfully");
      Assert (Contains (U.To_String (Output), "Usage: awk"), "help includes usage");
      Assert (not Contains (U.To_String (Output), Character'Val (27) & "["),
              "color=auto honors NO_COLOR through terminal_styles");
   end Test_Process_Help_Auto_Respects_No_Color;

   procedure Test_Process_Version_Short_Circuits_Runtime
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("--version"),
         new String'("-f"),
         new String'("tests/fixtures/programs/no-such-program.awk")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk version short circuit",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "version ignores later runtime failures");
      Assert (Contains (U.To_String (Output), "awk 0.1.0"), "version text is emitted");
   end Test_Process_Version_Short_Circuits_Runtime;

   procedure Test_Process_Awk_Output_Unstyled_With_Color_Always
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("--color=always"),
         new String'("BEGIN { print ""plain"" }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk output color always",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process AWK output color always exits successfully");
      Assert (Contains (U.To_String (Output), "plain" & LF), "AWK output is present");
      Assert (not Contains (U.To_String (Output), Character'Val (27) & "["),
              "color=always does not style AWK output");
   end Test_Process_Awk_Output_Unstyled_With_Color_Always;

   procedure Test_Process_Usage_Status (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("--bad-option")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk usage failure",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 2, "unknown option exits with usage status");
   end Test_Process_Usage_Status;

   procedure Test_Process_Missing_Program_File (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("-f"),
         new String'("tests/fixtures/programs/no-such-program.awk")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk missing program file",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 3, "missing process program file exits with host I/O status");
      Assert (U.To_String (Output) = "", "missing process program file writes no stdout");
   end Test_Process_Missing_Program_File;

   procedure Test_Process_Missing_Input_File (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("{ print }"),
         new String'("tests/fixtures/input/no-such-input.txt")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk missing input file",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 3, "missing process input file exits with host I/O status");
      Assert (U.To_String (Output) = "", "missing process input file writes no stdout");
   end Test_Process_Missing_Input_File;

   procedure Test_Process_Redirection (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Target : constant String := "tests/fixtures/filesystem/process_redir.txt";
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { print ""saved"" > """ & Target & """ }")];
      Status : Integer;
   begin
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);

      Status :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process redirection",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);

      Assert (Status = 0, "process redirection exits successfully");
      Assert (U.To_String (Output) = "", "process redirected output not on stdout");
      Assert (File_Text ("../" & Target) = "saved", "process redirection file content");

      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
   end Test_Process_Redirection;

   procedure Test_Process_Append_Redirection (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Target : constant String := "tests/fixtures/filesystem/process_append.txt";
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { print ""first"" >> """ & Target & """; print ""second"" >> """ & Target & """ }")];
      Status : Integer;
   begin
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
      Write_Text_File ("../" & Target, "existing" & LF);

      Status :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process append redirection",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);

      Assert (Status = 0, "process append redirection exits successfully");
      Assert (U.To_String (Output) = "", "process append redirection not on stdout");
      Assert
        (Contains (File_Text ("../" & Target), "existing") and then
         Contains (File_Text ("../" & Target), "first" & LF & "second"),
         "append redirection preserves existing file content");

      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
   end Test_Process_Append_Redirection;

   procedure Test_Process_Field_Separator (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 4) :=
        [new String'("-F"),
         new String'(" "),
         new String'("{ print $1 ""/"" $2 }"),
         new String'("tests/fixtures/input/basic.txt")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process -F",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process -F exits successfully");
      Assert (Contains (U.To_String (Output), "one/two" & LF & "three/four"),
              "process -F splits fields");
   end Test_Process_Field_Separator;

   procedure Test_Process_V_Assignment (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("-vX=41"),
         new String'("BEGIN { print X + 1 }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process -v",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process -v exits successfully");
      Assert (Contains (U.To_String (Output), "42" & LF), "process -v is visible before BEGIN");
   end Test_Process_V_Assignment;

   procedure Test_Process_Environment_Propagation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Env    : constant String := Project_Tools.Processes.Locate_Command ("env");
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 4) :=
        [new String'("AWK_PROCESS_ENV=visible"),
         new String'("./bin/awk"),
         new String'("BEGIN { print ENVIRON[""AWK_PROCESS_ENV""] }"),
         new String'("unused=value")];
      Status : Integer;
   begin
      Assert (Env /= "", "env executable is available for environment-bound process test");
      Status :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process environment",
           Dir     => "..",
           Program => Env,
           Args    => Args,
           Output  => Output,
           Quiet   => True);
      Assert (Status = 0, "process environment propagation exits successfully");
      Assert (Contains (U.To_String (Output), "visible" & LF),
              "process environment reaches awklib ENVIRON");
   end Test_Process_Environment_Propagation;

   procedure Test_Process_Explicit_Stdin_Eof
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("{ print }"),
         new String'("-")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process explicit stdin eof",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "explicit stdin operand accepts EOF");
      Assert (U.To_String (Output) = "", "EOF stdin produces no records");
   end Test_Process_Explicit_Stdin_Eof;

   procedure Test_Process_Explicit_Stdin_Data
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("{ print NR "":"" $2 }"),
         new String'("-")];
      Status : aliased Integer := -1;
      Output : constant String :=
        GNAT.Expect.Get_Command_Output
          (Command   => "../bin/awk",
           Arguments => Args,
           Input     => "one two" & LF & "three four" & LF,
           Status    => Status'Access);
   begin
      Assert (Status = 0, "explicit stdin data exits successfully");
      Assert (Output = "1:two" & LF & "2:four",
              "process stdin data reaches installed executable");
   end Test_Process_Explicit_Stdin_Data;

   procedure Test_Process_Runtime_Assignment_Argv
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("BEGIN { print ARGC; print ARGV[1]; print ARGV[2] }"),
         new String'("name=value"),
         new String'("tests/fixtures/input/basic.txt")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process runtime assignment argv",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process runtime assignment ARGV exits successfully");
      Assert (Contains (U.To_String (Output), "3" & LF & "name=value" & LF),
              "runtime assignment spelling is preserved in ARGV");
      Assert (Contains (U.To_String (Output), "tests/fixtures/input/basic.txt"),
              "input filename remains ordered after runtime assignment");
   end Test_Process_Runtime_Assignment_Argv;

   procedure Test_Process_Parse_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN {")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process parse failure",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 1, "process parse failure exits with interpreter status");
      Assert (U.To_String (Output) = "", "parse failure does not write stdout");
   end Test_Process_Parse_Failure;

   procedure Test_Process_Runtime_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { print 1 / 0 }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process runtime failure",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 1, "process runtime failure exits with interpreter status");
      Assert (not Contains (U.To_String (Output), "successful"),
              "runtime failure does not report false success");
   end Test_Process_Runtime_Failure;

   procedure Test_Process_Multiple_Files (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("{ print FILENAME "":"" FNR "":"" $1 }"),
         new String'("tests/fixtures/input/basic.txt"),
         new String'("tests/fixtures/input/second.txt")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process multiple files",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process multiple files exits successfully");
      Assert (Contains (U.To_String (Output), "tests/fixtures/input/basic.txt:1:one"),
              "first file FILENAME/FNR visible");
      Assert (Contains (U.To_String (Output), "tests/fixtures/input/second.txt:1:five"),
              "second file FILENAME/FNR visible");
   end Test_Process_Multiple_Files;

   procedure Test_Process_Command_Getline (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { ""printf x"" | getline value; print value }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process command getline",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process command getline exits successfully");
      Assert (Contains (U.To_String (Output), "x"),
              "process command getline reads command output");
   end Test_Process_Command_Getline;

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Process_Version'Access, "process version");
      Registration.Register_Routine (T, Test_Process_Direct_File_Input'Access, "process direct file input");
      Registration.Register_Routine
        (T, Test_Process_Dash_Filename_After_Terminator'Access,
         "process dash filename after terminator");
      Registration.Register_Routine (T, Test_Process_Program_Files'Access, "process -f program files");
      Registration.Register_Routine (T, Test_Process_Help_Color_Never'Access, "process help color never");
      Registration.Register_Routine
        (T, Test_Process_Help_Short_Circuits_Runtime'Access,
         "process help short circuit");
      Registration.Register_Routine (T, Test_Process_Help_Color_Always'Access, "process help color always");
      Registration.Register_Routine
        (T, Test_Process_Help_Auto_Respects_No_Color'Access,
         "process help auto NO_COLOR");
      Registration.Register_Routine
        (T, Test_Process_Version_Short_Circuits_Runtime'Access,
         "process version short circuit");
      Registration.Register_Routine
        (T, Test_Process_Awk_Output_Unstyled_With_Color_Always'Access,
         "process AWK output color always");
      Registration.Register_Routine (T, Test_Process_Usage_Status'Access, "process usage status");
      Registration.Register_Routine
        (T, Test_Process_Missing_Program_File'Access,
         "process missing program file");
      Registration.Register_Routine
        (T, Test_Process_Missing_Input_File'Access,
         "process missing input file");
      Registration.Register_Routine (T, Test_Process_Redirection'Access, "process redirection");
      Registration.Register_Routine (T, Test_Process_Append_Redirection'Access, "process append redirection");
      Registration.Register_Routine (T, Test_Process_Field_Separator'Access, "process -F");
      Registration.Register_Routine (T, Test_Process_V_Assignment'Access, "process -v");
      Registration.Register_Routine
        (T, Test_Process_Environment_Propagation'Access,
         "process environment propagation");
      Registration.Register_Routine
        (T, Test_Process_Explicit_Stdin_Eof'Access,
         "process explicit stdin eof");
      Registration.Register_Routine
        (T, Test_Process_Explicit_Stdin_Data'Access,
         "process explicit stdin data");
      Registration.Register_Routine
        (T, Test_Process_Runtime_Assignment_Argv'Access,
         "process runtime assignment ARGV");
      Registration.Register_Routine (T, Test_Process_Parse_Failure'Access, "process parse failure");
      Registration.Register_Routine (T, Test_Process_Runtime_Failure'Access, "process runtime failure");
      Registration.Register_Routine (T, Test_Process_Multiple_Files'Access, "process multiple files");
      Registration.Register_Routine (T, Test_Process_Command_Getline'Access, "process command getline");
   end Register_Tests;
end Awk_Tests.Process;
