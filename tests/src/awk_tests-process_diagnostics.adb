with AUnit.Assertions;

with Awk_Tests.Process_Harness;
with Awk_Tests.Process_Support;
with Project_Tools.Text;

package body Awk_Tests.Process_Diagnostics is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Usage_Status (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("--bad-option")];
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
         Assert (Status = 2, "unknown option exits with usage status");
         Assert (Project_Tools.Text.Contains
                   (Output,
                    English_Error_Header
                      (English_Text
                         ("awk.usage.unknown_option",
                          "option",
                          "--bad-option"))),
                 "unknown option reports the offending option");
         Assert (Project_Tools.Text.Contains
                   (Output, English_Hint ("awk.hint.use_help")),
                 "unknown option emits the usage hint");
         Assert (not Project_Tools.Text.Contains (Output, Character'Val (27) & "["),
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
         Args : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
           [new String'(Color_Option), new String'("--bad")];
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
            Assert (Status = 2, Message & " exits with usage status");
            Assert (Project_Tools.Text.Contains
                      (Output,
                       English_Text
                         ("awk.usage.unknown_option", "option", "--bad")),
                    Message & " includes localized diagnostic text");
            Assert ((Project_Tools.Text.Contains (Output, Escape & "[") = Styled),
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
         Args : constant Awk_Tests.Process_Harness.Argument_List (1 .. 3) :=
           [new String'(First_Color), new String'(Second_Color), new String'("--bad")];
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
            Assert (Status = 2, Message & " exits with usage status");
            Assert (Project_Tools.Text.Contains
                      (Output,
                       English_Text
                         ("awk.usage.unknown_option", "option", "--bad")),
                    Message & " includes localized diagnostic text");
            Assert ((Project_Tools.Text.Contains (Output, Escape & "[") = Styled),
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
      Args : constant Awk_Tests.Process_Harness.Argument_List (1 .. 0) := [];
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
         Assert (Status = 2, "no arguments exits with usage status");
         Assert (Project_Tools.Text.Contains
                   (Output, English_Text ("awk.usage.missing_program")),
                 "no arguments reports missing program");
         Assert (Project_Tools.Text.Contains
                   (Output, English_Hint ("awk.hint.use_help")),
                 "no arguments emits the usage hint");
         Assert (not Project_Tools.Text.Contains (Output, Character'Val (27) & "["),
                 "no-argument diagnostic is not styled by default capture");
      end;
   end Test_Process_No_Arguments_Missing_Program;
   procedure Test_Process_Invalid_Color_Status (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      procedure Expect_Invalid (Argument, Value, Message : String) is
         Args : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
           [new String'(Argument)];
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
            Assert (Status = 2, Message & " exits with usage status");
            Assert (Project_Tools.Text.Contains
                      (Output,
                       English_Text
                         ("awk.usage.invalid_color_mode", "value", Value)),
                    Message & " reports the invalid color value");
            Assert (Project_Tools.Text.Contains
                      (Output, English_Hint ("awk.hint.use_help")),
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
         Args : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
           [new String'(Option)];
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
            Assert (Status = 2, Option & " exits with usage status");
            Assert (Project_Tools.Text.Contains
                      (Output,
                       English_Text
                         ("awk.usage.missing_option_argument", "option", Option)),
                    Option & " explains the missing argument");
            Assert (Project_Tools.Text.Contains
                      (Output, English_Hint ("awk.hint.use_help")),
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
        (Args    : Awk_Tests.Process_Harness.Argument_List;
         Message : String)
      is
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
            Assert (Status = 2, Message & " exits with usage status");
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
         Separate_Args : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
           [new String'("-f"),
            new String'("-")];
         Attached : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
           [new String'("-f-")];
      begin
         Expect_Unsupported (Separate_Args, "separate -f -");
         Expect_Unsupported (Attached, "attached -f-");
      end;
   end Test_Process_Program_File_Stdin_Unsupported;
   procedure Test_Process_Missing_Program_File (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("-f"),
         new String'("tests/fixtures/programs/no-such-program.awk")];
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
         Assert (Status = 3, "missing process program file exits with host I/O status");
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
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("{ print }"),
         new String'("tests/fixtures/input/no-such-input.txt")];
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
         Assert (Status = 3, "missing process input file exits with host I/O status");
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
   procedure Test_Process_Invalid_V_Assignment
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Expect_Invalid
        (Args    : Awk_Tests.Process_Harness.Argument_List;
         Message : String)
      is
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
            Assert (Status = 2, Message & " exits with usage status");
            Assert (Project_Tools.Text.Contains
                      (Output,
                       English_Text
                         ("awk.usage.invalid_assignment",
                          "assignment",
                          "1bad=value")),
                    Message & " explains the invalid assignment");
            Assert (Project_Tools.Text.Contains
                      (Output, English_Hint ("awk.hint.use_help")),
                    Message & " emits the usage hint");
            Assert (not Project_Tools.Text.Contains (Output, "1" & LF),
                    Message & " does not execute the AWK program");
         end;
      end Expect_Invalid;
   begin
      declare
         Separate_Args : constant Awk_Tests.Process_Harness.Argument_List (1 .. 3) :=
           [new String'("-v"),
            new String'("1bad=value"),
            new String'("BEGIN { print 1 }")];
         Attached : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
           [new String'("-v1bad=value"),
            new String'("BEGIN { print 1 }")];
      begin
         Expect_Invalid (Separate_Args, "separate invalid -v");
         Expect_Invalid (Attached, "attached invalid -v");
      end;
   end Test_Process_Invalid_V_Assignment;
   procedure Test_Process_Danish_Diagnostic_From_Locale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Env    : constant String := Awk_Tests.Process_Harness.Locate_Command ("env");
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 3) :=
        [new String'("LC_ALL=da"),
         new String'(Awk_From_Tests_Directory),
         new String'("--bad")];
   begin
      Assert (Env /= "", "env executable is available for locale-bound process test");
      declare
         Status : aliased Integer := -1;
         Output : constant String :=
           Awk_Tests.Process_Harness.Command_Output
             (Command    => Env,
              Arguments  => Args,
              Input      => "",
              Status     => Status'Access,
              Err_To_Out => True);
      begin
         Assert (Status = 2, "Danish process diagnostic exits with usage status");
         Assert (Project_Tools.Text.Contains (Output, "ukendt tilvalg"),
                 "process diagnostic follows LC_ALL locale");
         Assert (Project_Tools.Text.Contains (Output, "tip:"),
                 "localized process hint is emitted");
      end;
   end Test_Process_Danish_Diagnostic_From_Locale;
   procedure Test_Process_Localized_UTF8_Diagnostic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Env     : constant String := Awk_Tests.Process_Harness.Locate_Command ("env");
      Doubled : constant String :=
        Character'Val (16#C3#) & Character'Val (16#83#)
        & Character'Val (16#C2#);
      Args    : constant Awk_Tests.Process_Harness.Argument_List (1 .. 3) :=
        [new String'("LC_ALL=el"),
         new String'(Awk_From_Tests_Directory),
         new String'("--bad")];
   begin
      Assert (Env /= "", "env executable is available for UTF-8 locale process test");
      declare
         Status : aliased Integer := -1;
         Output : constant String :=
           Awk_Tests.Process_Harness.Command_Output
             (Command    => Env,
              Arguments  => Args,
              Input      => "",
              Status     => Status'Access,
              Err_To_Out => True);
      begin
         Assert (Status = 2, "Greek process diagnostic exits with usage status");
         Assert (Project_Tools.Text.Contains (Output, "άγνωστη επιλογή"),
                 "process diagnostic renders Greek catalog text");
         Assert (not Project_Tools.Text.Contains (Output, Doubled),
                 "localized process diagnostic is not doubled UTF-8");
      end;
   end Test_Process_Localized_UTF8_Diagnostic;
   procedure Test_Process_Unsupported_Locale_Fallback
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Env    : constant String := Awk_Tests.Process_Harness.Locate_Command ("env");
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 3) :=
        [new String'("LC_ALL=zz_ZZ.UTF-8"),
         new String'(Awk_From_Tests_Directory),
         new String'("--bad")];
   begin
      Assert (Env /= "", "env executable is available for unsupported-locale process test");
      declare
         Status : aliased Integer := -1;
         Output : constant String :=
           Awk_Tests.Process_Harness.Command_Output
             (Command    => Env,
              Arguments  => Args,
              Input      => "",
              Status     => Status'Access,
              Err_To_Out => True);
      begin
         Assert (Status = 2, "unsupported locale diagnostic exits with usage status");
         Assert (Project_Tools.Text.Contains
                   (Output,
                    English_Text ("awk.usage.unknown_option", "option", "--bad")),
                 "unsupported locale falls back to English at process boundary");
         Assert (Project_Tools.Text.Contains
                   (Output, English_Hint ("awk.hint.use_help")),
                 "fallback process hint is emitted");
      end;
   end Test_Process_Unsupported_Locale_Fallback;
   procedure Test_Process_Diagnostic_Sanitizes_Hostile_Argument
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Escape : constant String := [1 => Character'Val (27)];
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("--bad" & LF & "awk: error: forged" & Escape & "[2J")];
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
         Assert (Status = 2, "hostile process argument exits with usage status");
         Assert
           (not Project_Tools.Text.Contains (Output, LF & "awk: error: forged"),
            "process diagnostic cannot be forged with an embedded newline");
         Assert (not Project_Tools.Text.Contains (Output, Escape),
                 "process diagnostic emits no raw terminal escape");
         Assert
           (Project_Tools.Text.Contains (Output, "\nawk: error: forged\e[2J"),
            "process diagnostic renders unsafe characters visibly");
      end;
   end Test_Process_Diagnostic_Sanitizes_Hostile_Argument;
   procedure Test_Process_Parse_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("BEGIN {")];
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
         Assert (Status = 1, "process parse failure exits with interpreter status");
         Assert (Project_Tools.Text.Contains
                   (Output,
                    English_Error_Header
                      (English_Text ("awk.interpreter.runtime_failed"))),
                 "parse failure reports localized interpreter context");
         Assert (Project_Tools.Text.Contains (Output, "expected '}'"),
                 "parse failure preserves interpreter detail");
         Assert (not Project_Tools.Text.Contains (Output, Character'Val (27) & "["),
                 "default captured parse diagnostic is unstyled");
      end;
   end Test_Process_Parse_Failure;
   procedure Test_Process_Runtime_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("BEGIN { print 1 / 0 }")];
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
         Assert (Status = 1, "process runtime failure exits with interpreter status");
         Assert (Project_Tools.Text.Contains
                   (Output,
                    English_Error_Header
                      (English_Text ("awk.interpreter.runtime_failed"))),
                 "runtime failure reports localized interpreter context");
         Assert (Project_Tools.Text.Contains (Output, "division by zero"),
                 "runtime failure preserves interpreter detail");
         Assert (not Project_Tools.Text.Contains (Output, "successful"),
                 "runtime failure does not report false success");
         Assert (not Project_Tools.Text.Contains (Output, Character'Val (27) & "["),
                 "default captured runtime diagnostic is unstyled");
      end;
   end Test_Process_Runtime_Failure;


   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
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
      Registration.Register_Routine
        (T, Test_Process_Invalid_V_Assignment'Access,
         "process invalid -v");
      Registration.Register_Routine
        (T, Test_Process_Danish_Diagnostic_From_Locale'Access,
         "process Danish diagnostic from locale");
      Registration.Register_Routine
        (T, Test_Process_Localized_UTF8_Diagnostic'Access,
         "process localized UTF-8 diagnostic");
      Registration.Register_Routine
        (T, Test_Process_Unsupported_Locale_Fallback'Access,
         "process unsupported locale fallback");
      Registration.Register_Routine
        (T, Test_Process_Diagnostic_Sanitizes_Hostile_Argument'Access,
         "process diagnostic sanitizes hostile argument");
      Registration.Register_Routine (T, Test_Process_Parse_Failure'Access, "process parse failure");
      Registration.Register_Routine (T, Test_Process_Runtime_Failure'Access, "process runtime failure");
   end Register;
end Awk_Tests.Process_Diagnostics;
