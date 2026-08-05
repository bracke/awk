with AUnit.Assertions;

with Awk_Tests.Process_Support;
with Project_Tools.Text;

package body Awk_Tests.Process_Diagnostics.Usage_Cases.Option_Cases.Missing_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Missing_Option_Argument_Status
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Expect_Missing (Option : String) is
         Args : constant Process_Arguments :=
           Arguments ([Argument (Option)]);
      begin
         declare
            Result : constant Captured_Process := Run_Awk_Err_To_Out (Args);
            Output : constant String := Output_String (Result);
         begin
            Assert (Result.Status = 2, Option & " exits with usage status");
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

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Process_Missing_Option_Argument_Status'Access,
         "process missing option argument status");
   end Register;
end Awk_Tests.Process_Diagnostics.Usage_Cases.Option_Cases.Missing_Cases;
