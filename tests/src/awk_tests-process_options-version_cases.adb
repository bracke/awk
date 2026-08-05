with AUnit.Assertions;

with Awk_Tests.Process_Support;
with Project_Tools.Text;

package body Awk_Tests.Process_Options.Version_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Version (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments := Arguments ([Argument ("--version")]);
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
      Args : constant Process_Arguments :=
        Arguments ([Argument ("--version")]);
   begin
      declare
         Result : constant Captured_Process :=
           Run_Awk_With_Environment
             ("awk localized version", [Argument ("LC_ALL=da")], Args);
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

   procedure Test_Process_Version_Short_Circuits_Runtime
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : constant Process_Arguments :=
        Arguments
          ([Argument ("--version"),
            Argument ("-f"),
            Argument ("tests/fixtures/programs/no-such-program.awk")]);
      Result : constant Captured_Process := Run_Awk ("awk version short circuit", Args);
   begin
      Assert (Result.Status = 0, "version ignores later runtime failures");
      Assert (Project_Tools.Text.Contains
                (Output_String (Result),
                 English_Text ("awk.version.program", "version", "0.1.0")),
              "version text is emitted");
   end Test_Process_Version_Short_Circuits_Runtime;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Process_Version'Access, "process version");
      Registration.Register_Routine
        (T, Test_Process_Localized_Version_From_Locale'Access,
         "process localized version from locale");
      Registration.Register_Routine
        (T, Test_Process_Version_Short_Circuits_Runtime'Access,
         "process version short circuit");
   end Register;
end Awk_Tests.Process_Options.Version_Cases;
