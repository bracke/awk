with AUnit.Assertions;

with Awk_Tests.Process_Support;
with Project_Tools.Processes;
with Project_Tools.Text;

package body Awk_Tests.Process_Diagnostics.Locale_Cases.Rendering_Cases.Locale_Selection_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Danish_Diagnostic_From_Locale
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Env    : constant String := Project_Tools.Processes.Locate_Command ("env");
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("LC_ALL=da"),
            Argument (Awk_From_Tests_Directory),
            Argument ("--bad")]);
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
      Args    : constant Process_Arguments :=
        Arguments
          ([Argument ("LC_ALL=el"),
            Argument (Awk_From_Tests_Directory),
            Argument ("--bad")]);
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
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("LC_ALL=zz_ZZ.UTF-8"),
            Argument (Awk_From_Tests_Directory),
            Argument ("--bad")]);
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
   end Register;
end Awk_Tests.Process_Diagnostics.Locale_Cases.Rendering_Cases.Locale_Selection_Cases;
