with AUnit.Assertions;

with GNAT.OS_Lib;

with Awk_Tests.Process_Support;
with Project_Tools.Processes;
with Project_Tools.Text;

package body Awk_Tests.Process_Diagnostics.Locale_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Danish_Diagnostic_From_Locale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Env    : constant String := Project_Tools.Processes.Locate_Command ("env");
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("LC_ALL=da"),
         new String'(Awk_From_Tests_Directory),
         new String'("--bad")];
   begin
      Assert (Env /= "", "env executable is available for locale-bound process test");
      declare
         Result : constant Captured_Process := Run_Command_Err_To_Out (Env, Args);
         Output : constant String := Output_String (Result);
      begin
         Assert (Result.Status = 2, "Danish process diagnostic exits with usage status");
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
      Env     : constant String := Project_Tools.Processes.Locate_Command ("env");
      Doubled : constant String :=
        Character'Val (16#C3#) & Character'Val (16#83#)
        & Character'Val (16#C2#);
      Args    : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("LC_ALL=el"),
         new String'(Awk_From_Tests_Directory),
         new String'("--bad")];
   begin
      Assert (Env /= "", "env executable is available for UTF-8 locale process test");
      declare
         Result : constant Captured_Process := Run_Command_Err_To_Out (Env, Args);
         Output : constant String := Output_String (Result);
      begin
         Assert (Result.Status = 2, "Greek process diagnostic exits with usage status");
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
      Env    : constant String := Project_Tools.Processes.Locate_Command ("env");
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
        [new String'("LC_ALL=zz_ZZ.UTF-8"),
         new String'(Awk_From_Tests_Directory),
         new String'("--bad")];
   begin
      Assert (Env /= "", "env executable is available for unsupported-locale process test");
      declare
         Result : constant Captured_Process := Run_Command_Err_To_Out (Env, Args);
         Output : constant String := Output_String (Result);
      begin
         Assert (Result.Status = 2, "unsupported locale diagnostic exits with usage status");
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
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("--bad" & LF & "awk: error: forged" & Escape & "[2J")];
   begin
      declare
         Result : constant Captured_Process := Run_Awk_Err_To_Out (Args);
         Output : constant String := Output_String (Result);
      begin
         Assert (Result.Status = 2, "hostile process argument exits with usage status");
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
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN {")];
   begin
      declare
         Result : constant Captured_Process := Run_Awk_Err_To_Out (Args);
         Output : constant String := Output_String (Result);
      begin
         Assert (Result.Status = 1, "process parse failure exits with interpreter status");
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
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("BEGIN { print 1 / 0 }")];
   begin
      declare
         Result : constant Captured_Process := Run_Awk_Err_To_Out (Args);
         Output : constant String := Output_String (Result);
      begin
         Assert (Result.Status = 1, "process runtime failure exits with interpreter status");
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
      Registration.Register_Routine
        (T, Test_Process_Parse_Failure'Access, "process parse failure");
      Registration.Register_Routine
        (T, Test_Process_Runtime_Failure'Access, "process runtime failure");
   end Register;
end Awk_Tests.Process_Diagnostics.Locale_Cases;
