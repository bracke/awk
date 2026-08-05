with AUnit.Assertions;

with Awk_Tests.Process_Support;
with Project_Tools.Text;

package body Awk_Tests.Process_Diagnostics.Locale_Cases.Interpreter_Failure_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Parse_Failure (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments ([Argument ("BEGIN {")]);
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
      Args   : constant Process_Arguments :=
        Arguments ([Argument ("BEGIN { print 1 / 0 }")]);
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
        (T, Test_Process_Parse_Failure'Access, "process parse failure");
      Registration.Register_Routine
        (T, Test_Process_Runtime_Failure'Access, "process runtime failure");
   end Register;
end Awk_Tests.Process_Diagnostics.Locale_Cases.Interpreter_Failure_Cases;
