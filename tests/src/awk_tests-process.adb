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
      Assert (Contains (U.To_String (Output), "awk 0.1.0" & LF),
              "process version includes awk version");
      Assert (Contains (U.To_String (Output), "awklib 0.1.0" & LF),
              "process version includes awklib version");
      Assert (Contains (U.To_String (Output), "license MIT" & LF),
              "process version includes license");
      Assert (not Contains (U.To_String (Output), Character'Val (27) & "["),
              "version output is not terminal-styled");
   end Test_Process_Version;

   procedure Test_Process_Localized_Version_From_Locale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Env    : constant String := Project_Tools.Processes.Locate_Command ("env");
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("LC_ALL=da"),
         new String'("./bin/awk"),
         new String'("--version")];
      Status : Integer;
   begin
      Assert (Env /= "", "env executable is available for localized version process test");
      Status :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk localized version",
           Dir     => "..",
           Program => Env,
           Args    => Args,
           Output  => Output,
           Quiet   => True);
      Assert (Status = 0, "localized process version exits successfully");
      Assert (Contains (U.To_String (Output), "awk 0.1.0"),
              "localized version includes awk version");
      Assert (Contains (U.To_String (Output), "awklib 0.1.0"),
              "localized version includes awklib version");
      Assert (Contains (U.To_String (Output), "licens MIT"),
              "process version follows LC_ALL locale");
   end Test_Process_Localized_Version_From_Locale;

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

   procedure Test_Process_Empty_Direct_Program
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk empty direct program",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "empty direct program is passed to the interpreter");
      Assert (U.To_String (Output) = "", "empty direct program writes no stdout");
   end Test_Process_Empty_Direct_Program;

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

   procedure Test_Process_Option_Terminator_Long_Operands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 5) :=
        [new String'("--"),
         new String'("BEGIN { print ARGV[1]; print ARGV[2]; print ARGV[3] }"),
         new String'("--help"),
         new String'("--version"),
         new String'("--color=always")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process terminator long operands",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "option terminator long operands exit successfully");
      Assert
        (Contains
           (U.To_String (Output),
            "--help" & LF & "--version" & LF & "--color=always" & LF),
         "long-option-looking values after -- remain AWK operands");
      Assert (not Contains (U.To_String (Output), "Usage: awk"),
              "--help after -- does not request help");
      Assert (not Contains (U.To_String (Output), "awk 0.1.0"),
              "--version after -- does not request version output");
      Assert (not Contains (U.To_String (Output), Character'Val (27) & "["),
              "--color after -- does not style AWK output");
   end Test_Process_Option_Terminator_Long_Operands;

   procedure Test_Process_Option_Looking_File_After_Program
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Target : constant String := "--version";
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("{ print FILENAME "":"" $1 }"),
         new String'(Target)];
      Status : Integer;
   begin
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
      Write_Text_File ("../" & Target, "operand-file" & LF);
      Status :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk option-looking file after program",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
      Assert (Status = 0, "option-looking filename after program exits successfully");
      Assert
        (Contains (U.To_String (Output), Target & ":operand-file" & LF),
         "post-program --version is read as an input file");
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
   end Test_Process_Option_Looking_File_After_Program;

   procedure Test_Process_Short_Option_Looking_File_After_Program
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Target : constant String := "-F";
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("{ print FILENAME "":"" $1 }"),
         new String'(Target)];
      Status : Integer;
   begin
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
      Write_Text_File ("../" & Target, "short-option-file" & LF);
      Status :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk short option-looking file after program",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
      Assert (Status = 0, "short option-looking filename after program exits successfully");
      Assert
        (Contains (U.To_String (Output), Target & ":short-option-file" & LF),
         "post-program -F is read as an input file");
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
   end Test_Process_Short_Option_Looking_File_After_Program;

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

   procedure Test_Process_Option_Looking_Operand_After_File_Mode_Input
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Target : constant String := "-vX=late";
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 5) :=
        [new String'("-f"),
         new String'("tests/fixtures/programs/print-first.awk"),
         new String'("tests/fixtures/input/basic.txt"),
         new String'(Target),
         new String'("tests/fixtures/input/second.txt")];
      Status : Integer;
   begin
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
      Write_Text_File ("../" & Target, "late-option-file" & LF);
      Status :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process file-mode late option operand",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
      Assert (Status = 0, "file-mode late option-looking operand exits successfully");
      Assert (Contains (U.To_String (Output), "one" & LF & "three"),
              "first input file is processed");
      Assert (Contains (U.To_String (Output), "late-option-file" & LF),
              "late option-looking operand is processed as a filename");
      Assert (Contains (U.To_String (Output), "five" & LF),
              "input after late runtime assignment is processed");
      Project_Tools.Files.Delete_File_If_Present ("../" & Target);
   end Test_Process_Option_Looking_Operand_After_File_Mode_Input;

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
      Assert (Contains (U.To_String (Output), "--                     end option processing"),
              "help documents the option terminator");
      Assert (Contains (U.To_String (Output), "Operands after the program"),
              "help documents operand classification");
      Assert (Contains (U.To_String (Output), "standard input is used implicitly"),
              "help documents implicit standard input");
      Assert (Contains (U.To_String (Output), "Exit statuses: 0 success"),
              "help documents exit statuses");
      Assert (Contains (U.To_String (Output), "does not claim complete POSIX conformance"),
              "help documents the compatibility position");
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
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("--bad-option")];
   begin
      declare
         Status : aliased Integer := -1;
         Output : constant String :=
           GNAT.Expect.Get_Command_Output
             (Command    => "../bin/awk",
              Arguments  => Args,
              Input      => "",
              Status     => Status'Access,
              Err_To_Out => True);
      begin
         Assert (Status = 2, "unknown option exits with usage status");
         Assert (Contains (Output, "awk: error: unknown option: --bad-option"),
                 "unknown option reports the offending option");
         Assert (Contains (Output, "hint: use --help for command-line syntax"),
                 "unknown option emits the usage hint");
         Assert (not Contains (Output, Character'Val (27) & "["),
                 "default captured usage diagnostic is unstyled");
      end;
   end Test_Process_Usage_Status;

   procedure Test_Process_Diagnostic_Color_Policy
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Escape : constant String := [1 => Character'Val (27)];

      procedure Expect
        (Color_Option : String;
         Styled       : Boolean;
         Message      : String)
      is
         Args : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
           [new String'(Color_Option), new String'("--bad")];
      begin
         declare
            Status : aliased Integer := -1;
            Output : constant String :=
              GNAT.Expect.Get_Command_Output
                (Command    => "../bin/awk",
                 Arguments  => Args,
                 Input      => "",
                 Status     => Status'Access,
                 Err_To_Out => True);
         begin
            Assert (Status = 2, Message & " exits with usage status");
            Assert (Contains (Output, "unknown option: --bad"),
                    Message & " includes localized diagnostic text");
            Assert ((Contains (Output, Escape & "[") = Styled),
                    Message & " follows diagnostic color policy");
         end;
      end Expect;
   begin
      Expect ("--color=always", True, "color=always diagnostic");
      Expect ("--color=never", False, "color=never diagnostic");
   end Test_Process_Diagnostic_Color_Policy;

   procedure Test_Process_Repeated_Diagnostic_Color_Final_Wins
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Escape : constant String := [1 => Character'Val (27)];

      procedure Expect
        (First_Color  : String;
         Second_Color : String;
         Styled       : Boolean;
         Message      : String)
      is
         Args : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
           [new String'(First_Color), new String'(Second_Color), new String'("--bad")];
      begin
         declare
            Status : aliased Integer := -1;
            Output : constant String :=
              GNAT.Expect.Get_Command_Output
                (Command    => "../bin/awk",
                 Arguments  => Args,
                 Input      => "",
                 Status     => Status'Access,
                 Err_To_Out => True);
         begin
            Assert (Status = 2, Message & " exits with usage status");
            Assert (Contains (Output, "unknown option: --bad"),
                    Message & " includes localized diagnostic text");
            Assert ((Contains (Output, Escape & "[") = Styled),
                    Message & " follows final color option");
         end;
      end Expect;
   begin
      Expect ("--color=always", "--color=never", False,
              "final color=never diagnostic");
      Expect ("--color=never", "--color=always", True,
              "final color=always diagnostic");
   end Test_Process_Repeated_Diagnostic_Color_Final_Wins;

   procedure Test_Process_No_Arguments_Missing_Program
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : constant GNAT.OS_Lib.Argument_List (1 .. 0) := [];
   begin
      declare
         Status : aliased Integer := -1;
         Output : constant String :=
           GNAT.Expect.Get_Command_Output
             (Command    => "../bin/awk",
              Arguments  => Args,
              Input      => "",
              Status     => Status'Access,
              Err_To_Out => True);
      begin
         Assert (Status = 2, "no arguments exits with usage status");
         Assert (Contains (Output, "missing AWK program"),
                 "no arguments reports missing program");
         Assert (Contains (Output, "hint: use --help"),
                 "no arguments emits the usage hint");
         Assert (not Contains (Output, Character'Val (27) & "["),
                 "no-argument diagnostic is not styled by default capture");
      end;
   end Test_Process_No_Arguments_Missing_Program;

   procedure Test_Process_Invalid_Color_Status (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      procedure Expect_Invalid (Argument, Value, Message : String) is
         Args : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
           [new String'(Argument)];
      begin
         declare
            Status : aliased Integer := -1;
            Output : constant String :=
              GNAT.Expect.Get_Command_Output
                (Command    => "../bin/awk",
                 Arguments  => Args,
                 Input      => "",
                 Status     => Status'Access,
                 Err_To_Out => True);
         begin
            Assert (Status = 2, Message & " exits with usage status");
            Assert (Contains (Output, "invalid color mode: " & Value),
                    Message & " reports the invalid color value");
            Assert (Contains (Output, "hint: use --help"),
                    Message & " emits the usage hint");
         end;
      end Expect_Invalid;
   begin
      Expect_Invalid ("--color=sparkles", "sparkles", "non-empty invalid color");
      Expect_Invalid ("--color=", "", "empty invalid color");
   end Test_Process_Invalid_Color_Status;

   procedure Test_Process_Missing_Option_Argument_Status
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Expect_Missing (Option : String) is
         Args : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
           [new String'(Option)];
      begin
         declare
            Status : aliased Integer := -1;
            Output : constant String :=
              GNAT.Expect.Get_Command_Output
                (Command    => "../bin/awk",
                 Arguments  => Args,
                 Input      => "",
                 Status     => Status'Access,
                 Err_To_Out => True);
         begin
            Assert (Status = 2, Option & " exits with usage status");
            Assert (Contains (Output, "missing argument for " & Option),
                    Option & " explains the missing argument");
            Assert (Contains (Output, "hint: use --help"),
                    Option & " emits the usage hint");
         end;
      end Expect_Missing;
   begin
      Expect_Missing ("-F");
      Expect_Missing ("-v");
      Expect_Missing ("-f");
   end Test_Process_Missing_Option_Argument_Status;

   procedure Test_Process_Program_File_Stdin_Unsupported
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Expect_Unsupported
        (Args    : GNAT.OS_Lib.Argument_List;
         Message : String)
      is
      begin
         declare
            Status : aliased Integer := -1;
            Output : constant String :=
              GNAT.Expect.Get_Command_Output
                (Command    => "../bin/awk",
                 Arguments  => Args,
                 Input      => "",
                 Status     => Status'Access,
                 Err_To_Out => True);
         begin
            Assert (Status = 2, Message & " exits with usage status");
            Assert
              (Contains
                 (Output,
                  "program file '-' is unsupported because standard input is reserved for AWK data"),
               Message & " explains why stdin program files are rejected");
            Assert (Contains (Output, "hint: use -- before filenames that begin with '-'"),
                    Message & " emits the option-terminator hint");
         end;
      end Expect_Unsupported;
   begin
      declare
         Separate_Args : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
           [new String'("-f"),
            new String'("-")];
         Attached : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
           [new String'("-f-")];
      begin
         Expect_Unsupported (Separate_Args, "separate -f -");
         Expect_Unsupported (Attached, "attached -f-");
      end;
   end Test_Process_Program_File_Stdin_Unsupported;

   procedure Test_Process_Missing_Program_File (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("-f"),
         new String'("tests/fixtures/programs/no-such-program.awk")];
   begin
      declare
         Status : aliased Integer := -1;
         Output : constant String :=
           GNAT.Expect.Get_Command_Output
             (Command    => "../bin/awk",
              Arguments  => Args,
              Input      => "",
              Status     => Status'Access,
              Err_To_Out => True);
      begin
         Assert (Status = 3, "missing process program file exits with host I/O status");
         Assert
           (Contains
              (Output,
               "cannot open program file: tests/fixtures/programs/no-such-program.awk"),
            "missing process program file reports the original path");
         Assert (Contains (Output, "awk: error:"),
                 "missing process program file uses the CLI diagnostic wrapper");
         Assert (not Contains (Output, Character'Val (27) & "["),
                 "default captured program-file diagnostic is unstyled");
      end;
   end Test_Process_Missing_Program_File;

   procedure Test_Process_Missing_Input_File (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("{ print }"),
         new String'("tests/fixtures/input/no-such-input.txt")];
   begin
      declare
         Status : aliased Integer := -1;
         Output : constant String :=
           GNAT.Expect.Get_Command_Output
             (Command    => "../bin/awk",
              Arguments  => Args,
              Input      => "",
              Status     => Status'Access,
              Err_To_Out => True);
      begin
         Assert (Status = 3, "missing process input file exits with host I/O status");
         Assert
           (Contains
              (Output,
               "cannot open input file: tests/fixtures/input/no-such-input.txt"),
            "missing process input file reports the original path");
         Assert (Contains (Output, "awk: error:"),
                 "missing process input file uses the CLI diagnostic wrapper");
         Assert (not Contains (Output, Character'Val (27) & "["),
                 "default captured input-file diagnostic is unstyled");
      end;
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
      Write_Text_File ("../" & Target, "old" & LF & "content" & LF);

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
      Assert (not Contains (File_Text ("../" & Target), "old"),
              "overwrite redirection replaces existing file content");

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
         "append redirection preserves existing content and write order");
      Assert (File_Text ("../" & Target) /= "first" & LF & "second",
              "append redirection does not replace existing file content");

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

   procedure Test_Process_Attached_Field_Separator_Final_Wins
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 4) :=
        [new String'("-F:"),
         new String'("-F "),
         new String'("{ print $2 }"),
         new String'("tests/fixtures/input/basic.txt")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process attached -F final wins",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "attached -F process run exits successfully");
      Assert (Contains (U.To_String (Output), "two" & LF & "four"),
              "later attached -F value wins at process boundary");
   end Test_Process_Attached_Field_Separator_Final_Wins;

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

   procedure Test_Process_Repeated_V_Assignments
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 5) :=
        [new String'("-vX=first"),
         new String'("-v"),
         new String'("X=second"),
         new String'("-vY=a=b"),
         new String'("BEGIN { print X; print Y }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process repeated -v",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process repeated -v exits successfully");
      Assert (Contains (U.To_String (Output), "second" & LF & "a=b"),
              "process -v assignments are applied in order and preserve extra equals");
   end Test_Process_Repeated_V_Assignments;

   procedure Test_Process_Invalid_V_Assignment
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Expect_Invalid
        (Args    : GNAT.OS_Lib.Argument_List;
         Message : String)
      is
      begin
         declare
            Status : aliased Integer := -1;
            Output : constant String :=
              GNAT.Expect.Get_Command_Output
                (Command    => "../bin/awk",
                 Arguments  => Args,
                 Input      => "",
                 Status     => Status'Access,
                 Err_To_Out => True);
         begin
            Assert (Status = 2, Message & " exits with usage status");
            Assert (Contains (Output, "invalid assignment: 1bad=value"),
                    Message & " explains the invalid assignment");
            Assert (Contains (Output, "hint: use --help"),
                    Message & " emits the usage hint");
            Assert (not Contains (Output, "1" & LF),
                    Message & " does not execute the AWK program");
         end;
      end Expect_Invalid;
   begin
      declare
         Separate_Args : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
           [new String'("-v"),
            new String'("1bad=value"),
            new String'("BEGIN { print 1 }")];
         Attached : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
           [new String'("-v1bad=value"),
            new String'("BEGIN { print 1 }")];
      begin
         Expect_Invalid (Separate_Args, "separate invalid -v");
         Expect_Invalid (Attached, "attached invalid -v");
      end;
   end Test_Process_Invalid_V_Assignment;

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

   procedure Test_Process_Danish_Diagnostic_From_Locale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Env    : constant String := Project_Tools.Processes.Locate_Command ("env");
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("LC_ALL=da"),
         new String'("../bin/awk"),
         new String'("--bad")];
   begin
      Assert (Env /= "", "env executable is available for locale-bound process test");
      declare
         Status : aliased Integer := -1;
         Output : constant String :=
           GNAT.Expect.Get_Command_Output
             (Command    => Env,
              Arguments  => Args,
              Input      => "",
              Status     => Status'Access,
              Err_To_Out => True);
      begin
         Assert (Status = 2, "Danish process diagnostic exits with usage status");
         Assert (Contains (Output, "ukendt tilvalg"),
                 "process diagnostic follows LC_ALL locale");
         Assert (Contains (Output, "tip:"),
                 "localized process hint is emitted");
      end;
   end Test_Process_Danish_Diagnostic_From_Locale;

   procedure Test_Process_Unsupported_Locale_Fallback
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Env    : constant String := Project_Tools.Processes.Locate_Command ("env");
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("LC_ALL=fr_FR.UTF-8"),
         new String'("../bin/awk"),
         new String'("--bad")];
   begin
      Assert (Env /= "", "env executable is available for unsupported-locale process test");
      declare
         Status : aliased Integer := -1;
         Output : constant String :=
           GNAT.Expect.Get_Command_Output
             (Command    => Env,
              Arguments  => Args,
              Input      => "",
              Status     => Status'Access,
              Err_To_Out => True);
      begin
         Assert (Status = 2, "unsupported locale diagnostic exits with usage status");
         Assert (Contains (Output, "unknown option"),
                 "unsupported locale falls back to English at process boundary");
         Assert (Contains (Output, "hint:"),
                 "fallback process hint is emitted");
      end;
   end Test_Process_Unsupported_Locale_Fallback;

   procedure Test_Process_Diagnostic_Sanitizes_Hostile_Argument
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Escape : constant String := [1 => Character'Val (27)];
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("--bad" & LF & "awk: error: forged" & Escape & "[2J")];
   begin
      declare
         Status : aliased Integer := -1;
         Output : constant String :=
           GNAT.Expect.Get_Command_Output
             (Command    => "../bin/awk",
              Arguments  => Args,
              Input      => "",
              Status     => Status'Access,
              Err_To_Out => True);
      begin
         Assert (Status = 2, "hostile process argument exits with usage status");
         Assert
           (not Contains (Output, LF & "awk: error: forged"),
            "process diagnostic cannot be forged with an embedded newline");
         Assert (not Contains (Output, Escape),
                 "process diagnostic emits no raw terminal escape");
         Assert
           (Contains (Output, "\nawk: error: forged\e[2J"),
            "process diagnostic renders unsafe characters visibly");
      end;
   end Test_Process_Diagnostic_Sanitizes_Hostile_Argument;

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

   procedure Test_Process_Implicit_Stdin_Data
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("{ print NR "":"" $1 }")];
      Status : aliased Integer := -1;
      Output : constant String :=
        GNAT.Expect.Get_Command_Output
          (Command   => "../bin/awk",
           Arguments => Args,
           Input     => "red blue" & LF & "green yellow" & LF,
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
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("{ print NR "":"" $0 }"),
         new String'("-"),
         new String'("-")];
      Status : aliased Integer := -1;
      Output : constant String :=
        GNAT.Expect.Get_Command_Output
          (Command   => "../bin/awk",
           Arguments => Args,
           Input     => "alpha" & LF & "beta" & LF,
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

   procedure Test_Process_Runtime_Assignment_Positions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 5) :=
        [new String'("BEGIN { print ""begin"", X } { print FILENAME, FNR, X, $0 } END { print ""end"", X }"),
         new String'("tests/fixtures/input/basic.txt"),
         new String'("X=42"),
         new String'("tests/fixtures/input/second.txt"),
         new String'("X=99")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process runtime assignment positions",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process runtime assignment positions exits successfully");
      Assert (Contains (U.To_String (Output), "begin " & LF),
              "initial runtime assignment value is empty before input");
      Assert
        (Contains (U.To_String (Output), "tests/fixtures/input/basic.txt 1  one two"),
         "first file is processed before interspersed assignment");
      Assert
        (Contains (U.To_String (Output), "tests/fixtures/input/second.txt 1 42 five six"),
         "interspersed assignment affects following input file");
      Assert (Contains (U.To_String (Output), "end 99" & LF),
              "final runtime assignment is visible in END");
   end Test_Process_Runtime_Assignment_Positions;

   procedure Test_Process_Parse_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN {")];
   begin
      declare
         Status : aliased Integer := -1;
         Output : constant String :=
           GNAT.Expect.Get_Command_Output
             (Command    => "../bin/awk",
              Arguments  => Args,
              Input      => "",
              Status     => Status'Access,
              Err_To_Out => True);
      begin
         Assert (Status = 1, "process parse failure exits with interpreter status");
         Assert (Contains (Output, "awk: error: AWK execution failed"),
                 "parse failure reports localized interpreter context");
         Assert (Contains (Output, "expected '}'"),
                 "parse failure preserves interpreter detail");
         Assert (not Contains (Output, Character'Val (27) & "["),
                 "default captured parse diagnostic is unstyled");
      end;
   end Test_Process_Parse_Failure;

   procedure Test_Process_Runtime_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { print 1 / 0 }")];
   begin
      declare
         Status : aliased Integer := -1;
         Output : constant String :=
           GNAT.Expect.Get_Command_Output
             (Command    => "../bin/awk",
              Arguments  => Args,
              Input      => "",
              Status     => Status'Access,
              Err_To_Out => True);
      begin
         Assert (Status = 1, "process runtime failure exits with interpreter status");
         Assert (Contains (Output, "awk: error: AWK execution failed"),
                 "runtime failure reports localized interpreter context");
         Assert (Contains (Output, "division by zero"),
                 "runtime failure preserves interpreter detail");
         Assert (not Contains (Output, "successful"),
                 "runtime failure does not report false success");
         Assert (not Contains (Output, Character'Val (27) & "["),
                 "default captured runtime diagnostic is unstyled");
      end;
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

   procedure Test_Process_Regex_Arithmetic_And_Builtins
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("/^[a-z]+ [0-9]+$/ { print $1, $2 + 3, substr($1, 2, 2), length($1) }"),
         new String'("tests/fixtures/input/regex_numbers.txt")];
      Status : Integer;
   begin
      Write_Text_File
        ("../tests/fixtures/input/regex_numbers.txt",
         "alpha 7" & LF &
         "skip me" & LF &
         "beta 11" & LF);
      Status :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process regex arithmetic builtins",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
      Assert (Status = 0, "process regex arithmetic builtins exits successfully");
      Assert (Contains (U.To_String (Output), "alpha 10 lp 5"),
              "regex pattern, arithmetic, substr, and length process first record");
      Assert (Contains (U.To_String (Output), "beta 14 et 4"),
              "regex pattern, arithmetic, substr, and length process second record");
      Assert (not Contains (U.To_String (Output), "skip"),
              "non-matching process input is not emitted");
      Project_Tools.Files.Delete_File_If_Present ("../tests/fixtures/input/regex_numbers.txt");
   end Test_Process_Regex_Arithmetic_And_Builtins;

   procedure Test_Process_Printf_Formatting
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { printf ""%s:%03d\n"", ""n"", 7 }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process printf formatting",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process printf formatting exits successfully");
      Assert (Contains (U.To_String (Output), "n:007"),
              "process printf formatted text is forwarded");
   end Test_Process_Printf_Formatting;

   procedure Test_Process_Comparisons
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { if (""beta"" > ""alpha"") print ""string""; if (5 >= 3) print ""number""; if (""7"" == 7) print ""coerce"" }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process comparisons",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process comparisons exit successfully");
      Assert (Contains (U.To_String (Output), "string" & LF),
              "process string comparison is evaluated by awklib");
      Assert (Contains (U.To_String (Output), "number" & LF),
              "process numeric comparison is evaluated by awklib");
      Assert (Contains (U.To_String (Output), "coerce" & LF),
              "process mixed comparison follows awklib conversion behavior");
   end Test_Process_Comparisons;

   procedure Test_Process_Sub_Replacement
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { s = ""aa""; sub(/a|aa/, ""X"", s); print s }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process sub replacement",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process sub replacement exits successfully");
      Assert (Contains (U.To_String (Output), "X" & LF),
              "process sub replacement follows awklib regex behavior");
   end Test_Process_Sub_Replacement;

   procedure Test_Process_String_Builtins
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { s = ""banana""; print gsub(/a/, ""A"", s), s; print index(s, ""nA""), toupper(""Ada"") }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process string builtins",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process string builtins exit successfully");
      Assert (Contains (U.To_String (Output), "3 bAnAnA" & LF),
              "process gsub replacement count and result follow awklib behavior");
      Assert (Contains (U.To_String (Output), "3 ADA" & LF),
              "process index and toupper follow awklib behavior");
   end Test_Process_String_Builtins;

   procedure Test_Process_Split_Builtin
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { n = split(""a:b:c"", parts, "":""); print n, parts[2] }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process split builtin",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process split builtin exits successfully");
      Assert (Contains (U.To_String (Output), "3 b" & LF),
              "process split populates array values through awklib");
   end Test_Process_Split_Builtin;

   procedure Test_Process_Match_And_Sprintf
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { print sprintf(""%s-%02d"", ""x"", 4); print match(""abc123"", /[0-9]+/), RSTART, RLENGTH }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process match and sprintf",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process match and sprintf exits successfully");
      Assert (Contains (U.To_String (Output), "x-04" & LF),
              "process sprintf result is forwarded");
      Assert (Contains (U.To_String (Output), "4 4 3" & LF),
              "process match updates RSTART and RLENGTH through awklib");
   end Test_Process_Match_And_Sprintf;

   procedure Test_Process_Output_Separators_And_Numeric_Builtins
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { OFS="":""; ORS=""|""; print tolower(""ADA""), int(3.9), sqrt(9) }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process separators and numeric builtins",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process separators and numeric builtins exit successfully");
      Assert (Contains (U.To_String (Output), "ada:3:3|"),
              "OFS, ORS, and numeric builtins are applied by awklib");
   end Test_Process_Output_Separators_And_Numeric_Builtins;

   procedure Test_Process_Math_Builtins
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { print sin(0), cos(0), exp(0), log(1), atan2(0, -1) }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process math builtins",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process math builtins exit successfully");
      Assert (Contains (U.To_String (Output), "0 1 1 0 3.14159" & LF),
              "process math builtins follow awklib output formatting");
   end Test_Process_Math_Builtins;

   procedure Test_Process_Arrays_Delete_And_While
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { a[""x""] = 1; a[""y""] = 2; delete a[""x""]; for (k in a) print k, a[k]; i = 0; while (i < 2) { print ""w"", i; i++ } }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process arrays delete and while",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process arrays delete and while exits successfully");
      Assert (Contains (U.To_String (Output), "y 2" & LF),
              "process array iteration observes deleted element");
      Assert (Contains (U.To_String (Output), "w 0" & LF),
              "process while loop emits first iteration");
      Assert (Contains (U.To_String (Output), "w 1" & LF),
              "process while loop emits second iteration");
      Assert (not Contains (U.To_String (Output), "x 1" & LF),
              "deleted array element is not emitted");
   end Test_Process_Arrays_Delete_And_While;

   procedure Test_Process_Next_Ternary_Break_And_Continue
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("BEGIN { for (i = 0; i < 4; i++) { if (i == 1) continue; if (i == 3) break; print ""loop"", i } } { if ($1 == ""one"") next; print (NF ? $1 : ""empty"") }"),
         new String'("tests/fixtures/input/basic.txt")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process next ternary break continue",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process next ternary break continue exits successfully");
      Assert (Contains (U.To_String (Output), "loop 0" & LF),
              "process for loop emits first retained iteration");
      Assert (Contains (U.To_String (Output), "loop 2" & LF),
              "process continue skips and break stops the loop");
      Assert (Contains (U.To_String (Output), "three" & LF),
              "process next skips the first input record");
      Assert (not Contains (U.To_String (Output), "one" & LF),
              "record skipped by next is not emitted");
   end Test_Process_Next_Ternary_Break_And_Continue;

   procedure Test_Process_Field_Assignment_Rebuilds_Record
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("BEGIN { FS="" ""; OFS=""|"" } { $2 = toupper($2); print $0, NF }"),
         new String'("tests/fixtures/input/basic.txt")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process field assignment rebuilds record",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process field assignment rebuild exits successfully");
      Assert (Contains (U.To_String (Output), "one|TWO|2" & LF),
              "first record is rebuilt by awklib after field assignment");
      Assert (Contains (U.To_String (Output), "three|FOUR|2" & LF),
              "second record is rebuilt by awklib after field assignment");
   end Test_Process_Field_Assignment_Rebuilds_Record;

   procedure Test_Process_Record_Assignment_Resplits_Fields
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("BEGIN { FS="" ""; OFS="":"" } { $0 = toupper($0); print $1, $2, NF }"),
         new String'("tests/fixtures/input/basic.txt")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process record assignment resplits fields",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process record assignment resplit exits successfully");
      Assert (Contains (U.To_String (Output), "ONE:TWO:2" & LF),
              "first record assignment is resplit by awklib");
      Assert (Contains (U.To_String (Output), "THREE:FOUR:2" & LF),
              "second record assignment is resplit by awklib");
   end Test_Process_Record_Assignment_Resplits_Fields;

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

   procedure Test_Process_Auxiliary_File_Getline
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Project_Tools.Processes.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { getline line < ""tests/fixtures/input/basic.txt""; print line }")];
      Status : constant Integer :=
        Project_Tools.Processes.Run_Status
          (Label   => "awk process auxiliary getline",
           Dir     => "..",
           Program => "./bin/awk",
           Args    => Args,
           Output  => Output,
           Quiet   => True);
   begin
      Assert (Status = 0, "process auxiliary file getline exits successfully");
      Assert (Contains (U.To_String (Output), "one two" & LF),
              "process getline < file reads registered host file");
   end Test_Process_Auxiliary_File_Getline;

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Process_Version'Access, "process version");
      Registration.Register_Routine
        (T, Test_Process_Localized_Version_From_Locale'Access,
         "process localized version from locale");
      Registration.Register_Routine (T, Test_Process_Direct_File_Input'Access, "process direct file input");
      Registration.Register_Routine
        (T, Test_Process_Empty_Direct_Program'Access,
         "process empty direct program");
      Registration.Register_Routine
        (T, Test_Process_Dash_Filename_After_Terminator'Access,
         "process dash filename after terminator");
      Registration.Register_Routine
        (T, Test_Process_Option_Terminator_Long_Operands'Access,
         "process option terminator long operands");
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
        (T, Test_Process_Diagnostic_Color_Policy'Access,
         "process diagnostic color policy");
      Registration.Register_Routine
        (T, Test_Process_Repeated_Diagnostic_Color_Final_Wins'Access,
         "process repeated diagnostic color final wins");
      Registration.Register_Routine
        (T, Test_Process_No_Arguments_Missing_Program'Access,
         "process no arguments missing program");
      Registration.Register_Routine
        (T, Test_Process_Invalid_Color_Status'Access,
         "process invalid color status");
      Registration.Register_Routine
        (T, Test_Process_Missing_Option_Argument_Status'Access,
         "process missing option argument status");
      Registration.Register_Routine
        (T, Test_Process_Program_File_Stdin_Unsupported'Access,
         "process -f stdin unsupported");
      Registration.Register_Routine
        (T, Test_Process_Missing_Program_File'Access,
         "process missing program file");
      Registration.Register_Routine
        (T, Test_Process_Missing_Input_File'Access,
         "process missing input file");
      Registration.Register_Routine (T, Test_Process_Redirection'Access, "process redirection");
      Registration.Register_Routine (T, Test_Process_Append_Redirection'Access, "process append redirection");
      Registration.Register_Routine (T, Test_Process_Field_Separator'Access, "process -F");
      Registration.Register_Routine
        (T, Test_Process_Attached_Field_Separator_Final_Wins'Access,
         "process attached -F final wins");
      Registration.Register_Routine (T, Test_Process_V_Assignment'Access, "process -v");
      Registration.Register_Routine
        (T, Test_Process_Repeated_V_Assignments'Access,
         "process repeated -v");
      Registration.Register_Routine
        (T, Test_Process_Invalid_V_Assignment'Access,
         "process invalid -v");
      Registration.Register_Routine
        (T, Test_Process_Environment_Propagation'Access,
         "process environment propagation");
      Registration.Register_Routine
        (T, Test_Process_Danish_Diagnostic_From_Locale'Access,
         "process Danish diagnostic from locale");
      Registration.Register_Routine
        (T, Test_Process_Unsupported_Locale_Fallback'Access,
         "process unsupported locale fallback");
      Registration.Register_Routine
        (T, Test_Process_Diagnostic_Sanitizes_Hostile_Argument'Access,
         "process diagnostic sanitizes hostile argument");
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
      Registration.Register_Routine (T, Test_Process_Parse_Failure'Access, "process parse failure");
      Registration.Register_Routine (T, Test_Process_Runtime_Failure'Access, "process runtime failure");
      Registration.Register_Routine (T, Test_Process_Multiple_Files'Access, "process multiple files");
      Registration.Register_Routine
        (T, Test_Process_Regex_Arithmetic_And_Builtins'Access,
         "process regex arithmetic builtins");
      Registration.Register_Routine
        (T, Test_Process_Printf_Formatting'Access,
         "process printf formatting");
      Registration.Register_Routine
        (T, Test_Process_Comparisons'Access,
         "process comparisons");
      Registration.Register_Routine
        (T, Test_Process_Sub_Replacement'Access,
         "process sub replacement");
      Registration.Register_Routine
        (T, Test_Process_String_Builtins'Access,
         "process string builtins");
      Registration.Register_Routine
        (T, Test_Process_Split_Builtin'Access,
         "process split builtin");
      Registration.Register_Routine
        (T, Test_Process_Match_And_Sprintf'Access,
         "process match and sprintf");
      Registration.Register_Routine
        (T, Test_Process_Output_Separators_And_Numeric_Builtins'Access,
         "process output separators and numeric builtins");
      Registration.Register_Routine
        (T, Test_Process_Math_Builtins'Access,
         "process math builtins");
      Registration.Register_Routine
        (T, Test_Process_Arrays_Delete_And_While'Access,
         "process arrays delete and while");
      Registration.Register_Routine
        (T, Test_Process_Next_Ternary_Break_And_Continue'Access,
         "process next ternary break continue");
      Registration.Register_Routine
        (T, Test_Process_Field_Assignment_Rebuilds_Record'Access,
         "process field assignment rebuilds record");
      Registration.Register_Routine
        (T, Test_Process_Record_Assignment_Resplits_Fields'Access,
         "process record assignment resplits fields");
      Registration.Register_Routine (T, Test_Process_Command_Getline'Access, "process command getline");
      Registration.Register_Routine
        (T, Test_Process_Auxiliary_File_Getline'Access,
         "process auxiliary file getline");
   end Register_Tests;
end Awk_Tests.Process;
