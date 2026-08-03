with AUnit.Assertions;

with Awk_Tests.Process_Harness;
with Awk_Tests.Process_Support;
with Project_Tools.Text;

package body Awk_Tests.Process_Options is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Version (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("--version")];
      Result : constant Captured_Process := Run_Awk ("awk --version", Args);
   begin
      Assert (Result.Status = 0, "process version exits successfully");
      Assert (Project_Tools.Text.Contains
                (Output_String (Result),
                 English_Text ("awk.version.program", "version", "0.1.0") & LF),
              "process version includes awk version");
      Assert (Project_Tools.Text.Contains
                (Output_String (Result),
                 English_Text ("awk.version.interpreter", "version", "0.1.0") & LF),
              "process version includes awklib version");
      Assert (Project_Tools.Text.Contains
                (Output_String (Result), English_Text ("awk.version.license") & LF),
              "process version includes license");
      Assert (not Project_Tools.Text.Contains (Output_String (Result), Character'Val (27) & "["),
              "version output is not terminal-styled");
   end Test_Process_Version;
   procedure Test_Process_Localized_Version_From_Locale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Env    : constant String := Awk_Tests.Process_Harness.Locate_Command ("env");
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 3) :=
        [new String'("LC_ALL=da"),
         new String'(Awk_From_Repository_Root),
         new String'("--version")];
   begin
      Assert (Env /= "", "env executable is available for localized version process test");
      declare
         Result : constant Captured_Process :=
           Run_Process ("awk localized version", "..", Env, Args);
      begin
         Assert (Result.Status = 0, "localized process version exits successfully");
         Assert (Project_Tools.Text.Contains
                   (Output_String (Result),
                    Locale_Text ("awk.version.program", "da", "version", "0.1.0")),
                 "localized version includes awk version");
         Assert (Project_Tools.Text.Contains
                   (Output_String (Result),
                    Locale_Text ("awk.version.interpreter", "da", "version", "0.1.0")),
                 "localized version includes awklib version");
         Assert (Project_Tools.Text.Contains
                   (Output_String (Result), Locale_Text ("awk.version.license", "da")),
                 "process version follows LC_ALL locale");
      end;
   end Test_Process_Localized_Version_From_Locale;
   procedure Test_Process_Empty_Direct_Program
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("")];
   begin
      if not Process_Harness_Preserves_Empty_Arguments then
         return;
      end if;

      declare
         Result : constant Captured_Process := Run_Awk ("awk empty direct program", Args);
      begin
         Assert (Result.Status = 0, "empty direct program is passed to the interpreter");
         Assert (Output_String (Result) = "", "empty direct program writes no stdout");
      end;
   end Test_Process_Empty_Direct_Program;
   procedure Test_Process_Option_Terminator_Long_Operands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 5) :=
        [new String'("--"),
         new String'("BEGIN { print ARGV[1]; print ARGV[2]; print ARGV[3] }"),
         new String'("--help"),
         new String'("--version"),
         new String'("--color=always")];
      Result : constant Captured_Process := Run_Awk ("awk process terminator long operands", Args);
   begin
      Assert (Result.Status = 0, "option terminator long operands exit successfully");
      Assert
        (Project_Tools.Text.Contains
           (Output_String (Result),
            "--help" & LF & "--version" & LF & "--color=always" & LF),
         "long-option-looking values after -- remain AWK operands");
      Assert (not Project_Tools.Text.Contains
                (Output_String (Result), English_Text ("awk.help.usage.direct_program")),
              "--help after -- does not request help");
      Assert (not Project_Tools.Text.Contains
                (Output_String (Result),
                 English_Text ("awk.version.program", "version", "0.1.0")),
              "--version after -- does not request version output");
      Assert (not Project_Tools.Text.Contains (Output_String (Result), Character'Val (27) & "["),
              "--color after -- does not style AWK output");
   end Test_Process_Option_Terminator_Long_Operands;
   procedure Test_Process_Help_Color_Never (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("--color=never"), new String'("--help")];
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
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 4) :=
        [new String'("--help"),
         new String'("-f"),
         new String'("tests/fixtures/programs/no-such-program.awk"),
         new String'("BEGIN {")];
      Result : constant Captured_Process := Run_Awk ("awk help short circuit", Args);
   begin
      Assert (Result.Status = 0, "help ignores later runtime failures");
      Assert (Project_Tools.Text.Contains
                (Output_String (Result), English_Text ("awk.help.usage.direct_program")),
              "help text is emitted");
   end Test_Process_Help_Short_Circuits_Runtime;
   procedure Test_Process_Help_Color_Always (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("--color=always"), new String'("--help")];
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
      Env    : constant String := Awk_Tests.Process_Harness.Locate_Command ("env");
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 4) :=
        [new String'("NO_COLOR=1"),
         new String'(Awk_From_Repository_Root),
         new String'("--color=auto"),
         new String'("--help")];
   begin
      Assert (Env /= "", "env executable is available for environment-bound process test");
      declare
         Result : constant Captured_Process := Run_Process ("awk help auto no color", "..", Env, Args);
      begin
         Assert (Result.Status = 0, "process help auto with NO_COLOR exits successfully");
         Assert (Project_Tools.Text.Contains
                   (Output_String (Result), English_Text ("awk.help.usage.direct_program")),
                 "help includes usage");
         Assert (not Project_Tools.Text.Contains (Output_String (Result), Character'Val (27) & "["),
                 "color=auto honors NO_COLOR through terminal_styles");
      end;
   end Test_Process_Help_Auto_Respects_No_Color;
   procedure Test_Process_Version_Short_Circuits_Runtime
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 3) :=
        [new String'("--version"),
         new String'("-f"),
         new String'("tests/fixtures/programs/no-such-program.awk")];
      Result : constant Captured_Process := Run_Awk ("awk version short circuit", Args);
   begin
      Assert (Result.Status = 0, "version ignores later runtime failures");
      Assert (Project_Tools.Text.Contains
                (Output_String (Result),
                 English_Text ("awk.version.program", "version", "0.1.0")),
              "version text is emitted");
   end Test_Process_Version_Short_Circuits_Runtime;
   procedure Test_Process_Awk_Output_Unstyled_With_Color_Always
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("--color=always"),
         new String'("BEGIN { print ""plain"" }")];
      Result : constant Captured_Process := Run_Awk ("awk output color always", Args);
   begin
      Assert (Result.Status = 0, "process AWK output color always exits successfully");
      Assert (Project_Tools.Text.Contains (Output_String (Result), "plain" & LF), "AWK output is present");
      Assert (not Project_Tools.Text.Contains (Output_String (Result), Character'Val (27) & "["),
              "color=always does not style AWK output");
   end Test_Process_Awk_Output_Unstyled_With_Color_Always;
   procedure Test_Process_Field_Separator (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 4) :=
        [new String'("-F"),
         new String'(" "),
         new String'("{ print $1 ""/"" $2 }"),
         new String'("tests/fixtures/input/basic.txt")];
      Result : constant Captured_Process := Run_Awk ("awk process -F", Args);
   begin
      Assert (Result.Status = 0, "process -F exits successfully");
      Assert (Project_Tools.Text.Contains (Output_String (Result), "one/two" & LF & "three/four"),
              "process -F splits fields");
   end Test_Process_Field_Separator;
   procedure Test_Process_Attached_Field_Separator_Final_Wins
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 4) :=
        [new String'("-F:"),
         new String'("-F "),
         new String'("{ print $2 }"),
         new String'("tests/fixtures/input/basic.txt")];
      Result : constant Captured_Process := Run_Awk ("awk process attached -F final wins", Args);
   begin
      Assert (Result.Status = 0, "attached -F process run exits successfully");
      Assert (Project_Tools.Text.Contains (Output_String (Result), "two" & LF & "four"),
              "later attached -F value wins at process boundary");
   end Test_Process_Attached_Field_Separator_Final_Wins;
   procedure Test_Process_V_Assignment (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("-vX=41"),
         new String'("BEGIN { print X + 1 }")];
      Result : constant Captured_Process := Run_Awk ("awk process -v", Args);
   begin
      Assert (Result.Status = 0, "process -v exits successfully");
      Assert (Project_Tools.Text.Contains (Output_String (Result), "42" & LF),
              "process -v is visible before BEGIN");
   end Test_Process_V_Assignment;
   procedure Test_Process_Repeated_V_Assignments
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 5) :=
        [new String'("-vX=first"),
         new String'("-v"),
         new String'("X=second"),
         new String'("-vY=a=b"),
         new String'("BEGIN { print X; print Y }")];
      Result : constant Captured_Process := Run_Awk ("awk process repeated -v", Args);
   begin
      Assert (Result.Status = 0, "process repeated -v exits successfully");
      Assert (Project_Tools.Text.Contains (Output_String (Result), "second" & LF & "a=b"),
              "process -v assignments are applied in order and preserve extra equals");
   end Test_Process_Repeated_V_Assignments;


   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Process_Version'Access, "process version");
      Registration.Register_Routine
        (T, Test_Process_Localized_Version_From_Locale'Access,
         "process localized version from locale");
      Registration.Register_Routine
        (T, Test_Process_Empty_Direct_Program'Access,
         "process empty direct program");
      Registration.Register_Routine
        (T, Test_Process_Option_Terminator_Long_Operands'Access,
         "process option terminator long operands");
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
      Registration.Register_Routine (T, Test_Process_Field_Separator'Access, "process -F");
      Registration.Register_Routine
        (T, Test_Process_Attached_Field_Separator_Final_Wins'Access,
         "process attached -F final wins");
      Registration.Register_Routine (T, Test_Process_V_Assignment'Access, "process -v");
      Registration.Register_Routine
        (T, Test_Process_Repeated_V_Assignments'Access,
         "process repeated -v");
   end Register;
end Awk_Tests.Process_Options;
