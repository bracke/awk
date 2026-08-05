with AUnit.Assertions;

with Awk_Tests.Process_Support;
with Project_Tools.Text;

package body Awk_Tests.Process_Diagnostics.Usage_Cases.Option_Cases.Basic_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Usage_Status (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments ([Argument ("--bad-option")]);
   begin
      declare
         Result : constant Captured_Process := Run_Awk_Err_To_Out (Args);
         Output : constant String := Output_String (Result);
      begin
         Assert (Result.Status = 2, "unknown option exits with usage status");
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

   procedure Test_Process_No_Arguments_Missing_Program
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : constant Process_Arguments := No_Arguments;
   begin
      declare
         Result : constant Captured_Process := Run_Awk_Err_To_Out (Args);
         Output : constant String := Output_String (Result);
      begin
         Assert (Result.Status = 2, "no arguments exits with usage status");
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

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Process_Usage_Status'Access, "process usage status");
      Registration.Register_Routine
        (T, Test_Process_No_Arguments_Missing_Program'Access,
         "process no arguments missing program");
   end Register;
end Awk_Tests.Process_Diagnostics.Usage_Cases.Option_Cases.Basic_Cases;
