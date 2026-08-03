with AUnit.Assertions;

with Ada.Strings.Unbounded;

with Awk_Tests.Process_Diagnostics;
with Awk_Tests.Process_Harness;
with Awk_Tests.Process_IO;
with Awk_Tests.Process_Language;
with Awk_Tests.Process_Support;
with Project_Tools.Text;

package body Awk_Tests.Process is
   use AUnit.Assertions;
   package U renames Ada.Strings.Unbounded;
   use Awk_Tests.Process_Support;

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk process");
   end Name;

   procedure Test_Process_Version (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("--version")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk --version",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process version exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "awk 0.1.0" & LF),
              "process version includes awk version");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "awklib 0.1.0" & LF),
              "process version includes awklib version");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "license MIT" & LF),
              "process version includes license");
      Assert (not Project_Tools.Text.Contains (U.To_String (Output), Character'Val (27) & "["),
              "version output is not terminal-styled");
   end Test_Process_Version;

   procedure Test_Process_Localized_Version_From_Locale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Env    : constant String := Awk_Tests.Process_Harness.Locate_Command ("env");
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 3) :=
        [new String'("LC_ALL=da"),
         new String'(Awk_From_Repository_Root),
         new String'("--version")];
      Status : Integer;
   begin
      Assert (Env /= "", "env executable is available for localized version process test");
      Status :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk localized version",
           Dir     => "..",
           Program => Env,
           Args    => Args,
           Output  => Output);
      Assert (Status = 0, "localized process version exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "awk 0.1.0"),
              "localized version includes awk version");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "awklib 0.1.0"),
              "localized version includes awklib version");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "licens MIT"),
              "process version follows LC_ALL locale");
   end Test_Process_Localized_Version_From_Locale;


   procedure Test_Process_Empty_Direct_Program
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 1) :=
        [new String'("")];
   begin
      if not Process_Harness_Preserves_Empty_Arguments then
         return;
      end if;

      declare
         Status : constant Integer :=
           Awk_Tests.Process_Harness.Run_Status
             (Label   => "awk empty direct program",
              Dir     => "..",
              Program => Awk_From_Repository_Root,
              Args    => Args,
              Output  => Output);
      begin
         Assert (Status = 0, "empty direct program is passed to the interpreter");
         Assert (U.To_String (Output) = "", "empty direct program writes no stdout");
      end;
   end Test_Process_Empty_Direct_Program;


   procedure Test_Process_Option_Terminator_Long_Operands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 5) :=
        [new String'("--"),
         new String'("BEGIN { print ARGV[1]; print ARGV[2]; print ARGV[3] }"),
         new String'("--help"),
         new String'("--version"),
         new String'("--color=always")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process terminator long operands",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "option terminator long operands exit successfully");
      Assert
        (Project_Tools.Text.Contains
           (U.To_String (Output),
            "--help" & LF & "--version" & LF & "--color=always" & LF),
         "long-option-looking values after -- remain AWK operands");
      Assert (not Project_Tools.Text.Contains (U.To_String (Output), "Usage: awk"),
              "--help after -- does not request help");
      Assert (not Project_Tools.Text.Contains (U.To_String (Output), "awk 0.1.0"),
              "--version after -- does not request version output");
      Assert (not Project_Tools.Text.Contains (U.To_String (Output), Character'Val (27) & "["),
              "--color after -- does not style AWK output");
   end Test_Process_Option_Terminator_Long_Operands;





   procedure Test_Process_Help_Color_Never (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("--color=never"), new String'("--help")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk help no color",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process help exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "Usage: awk"), "help includes usage");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "--                     end option processing"),
              "help documents the option terminator");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "Operands after the program"),
              "help documents operand classification");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "standard input is used implicitly"),
              "help documents implicit standard input");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "Exit statuses: 0 success"),
              "help documents exit statuses");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "does not claim complete POSIX conformance"),
              "help documents the compatibility position");
      Assert (not Project_Tools.Text.Contains (U.To_String (Output), Character'Val (27) & "["),
              "color=never suppresses ANSI escapes");
   end Test_Process_Help_Color_Never;

   procedure Test_Process_Help_Short_Circuits_Runtime
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 4) :=
        [new String'("--help"),
         new String'("-f"),
         new String'("tests/fixtures/programs/no-such-program.awk"),
         new String'("BEGIN {")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk help short circuit",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "help ignores later runtime failures");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "Usage: awk"), "help text is emitted");
   end Test_Process_Help_Short_Circuits_Runtime;

   procedure Test_Process_Help_Color_Always (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("--color=always"), new String'("--help")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk help color always",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process help color always exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), Character'Val (27) & "["),
              "color=always styles CLI-owned help");
   end Test_Process_Help_Color_Always;

   procedure Test_Process_Help_Auto_Respects_No_Color
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Env    : constant String := Awk_Tests.Process_Harness.Locate_Command ("env");
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 4) :=
        [new String'("NO_COLOR=1"),
         new String'(Awk_From_Repository_Root),
         new String'("--color=auto"),
         new String'("--help")];
      Status : Integer;
   begin
      Assert (Env /= "", "env executable is available for environment-bound process test");
      Status :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk help auto no color",
           Dir     => "..",
           Program => Env,
           Args    => Args,
           Output  => Output);
      Assert (Status = 0, "process help auto with NO_COLOR exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "Usage: awk"), "help includes usage");
      Assert (not Project_Tools.Text.Contains (U.To_String (Output), Character'Val (27) & "["),
              "color=auto honors NO_COLOR through terminal_styles");
   end Test_Process_Help_Auto_Respects_No_Color;

   procedure Test_Process_Version_Short_Circuits_Runtime
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 3) :=
        [new String'("--version"),
         new String'("-f"),
         new String'("tests/fixtures/programs/no-such-program.awk")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk version short circuit",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "version ignores later runtime failures");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "awk 0.1.0"), "version text is emitted");
   end Test_Process_Version_Short_Circuits_Runtime;

   procedure Test_Process_Awk_Output_Unstyled_With_Color_Always
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("--color=always"),
         new String'("BEGIN { print ""plain"" }")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk output color always",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process AWK output color always exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "plain" & LF), "AWK output is present");
      Assert (not Project_Tools.Text.Contains (U.To_String (Output), Character'Val (27) & "["),
              "color=always does not style AWK output");
   end Test_Process_Awk_Output_Unstyled_With_Color_Always;













   procedure Test_Process_Field_Separator (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 4) :=
        [new String'("-F"),
         new String'(" "),
         new String'("{ print $1 ""/"" $2 }"),
         new String'("tests/fixtures/input/basic.txt")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process -F",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process -F exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "one/two" & LF & "three/four"),
              "process -F splits fields");
   end Test_Process_Field_Separator;

   procedure Test_Process_Attached_Field_Separator_Final_Wins
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 4) :=
        [new String'("-F:"),
         new String'("-F "),
         new String'("{ print $2 }"),
         new String'("tests/fixtures/input/basic.txt")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process attached -F final wins",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "attached -F process run exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "two" & LF & "four"),
              "later attached -F value wins at process boundary");
   end Test_Process_Attached_Field_Separator_Final_Wins;

   procedure Test_Process_V_Assignment (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 2) :=
        [new String'("-vX=41"),
         new String'("BEGIN { print X + 1 }")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process -v",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process -v exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "42" & LF), "process -v is visible before BEGIN");
   end Test_Process_V_Assignment;

   procedure Test_Process_Repeated_V_Assignments
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 5) :=
        [new String'("-vX=first"),
         new String'("-v"),
         new String'("X=second"),
         new String'("-vY=a=b"),
         new String'("BEGIN { print X; print Y }")];
      Status : constant Integer :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process repeated -v",
           Dir     => "..",
           Program => Awk_From_Repository_Root,
           Args    => Args,
           Output  => Output);
   begin
      Assert (Status = 0, "process repeated -v exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "second" & LF & "a=b"),
              "process -v assignments are applied in order and preserve extra equals");
   end Test_Process_Repeated_V_Assignments;


   procedure Test_Process_Environment_Propagation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Env    : constant String := Awk_Tests.Process_Harness.Locate_Command ("env");
      Output : Awk_Tests.Process_Harness.Output_Text;
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 5) :=
        [new String'("AWK_PROCESS_ENV=visible"),
         new String'("AWK_PROCESS_EMPTY="),
         new String'(Awk_From_Repository_Root),
         new String'("BEGIN { print ENVIRON[""AWK_PROCESS_ENV""]; print ""empty="" ENVIRON[""AWK_PROCESS_EMPTY""] }"),
         new String'("unused=value")];
      Status : Integer;
   begin
      Assert (Env /= "", "env executable is available for environment-bound process test");
      Status :=
        Awk_Tests.Process_Harness.Run_Status
          (Label   => "awk process environment",
           Dir     => "..",
           Program => Env,
           Args    => Args,
           Output  => Output);
      Assert (Status = 0, "process environment propagation exits successfully");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "visible" & LF),
              "process environment reaches awklib ENVIRON");
      Assert (Project_Tools.Text.Contains (U.To_String (Output), "empty=" & LF),
              "empty process environment values are preserved");
   end Test_Process_Environment_Propagation;













   overriding procedure Register_Tests (T : in out Case_Type) is
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
      Awk_Tests.Process_IO.Register (T);
      Awk_Tests.Process_Diagnostics.Register (T);
      Registration.Register_Routine (T, Test_Process_Field_Separator'Access, "process -F");
      Registration.Register_Routine
        (T, Test_Process_Attached_Field_Separator_Final_Wins'Access,
         "process attached -F final wins");
      Registration.Register_Routine (T, Test_Process_V_Assignment'Access, "process -v");
      Registration.Register_Routine
        (T, Test_Process_Repeated_V_Assignments'Access,
         "process repeated -v");
      Registration.Register_Routine
        (T, Test_Process_Environment_Propagation'Access,
         "process environment propagation");
      Awk_Tests.Process_Language.Register (T);
   end Register_Tests;
end Awk_Tests.Process;
