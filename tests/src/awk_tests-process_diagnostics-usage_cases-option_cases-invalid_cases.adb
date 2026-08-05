with AUnit.Assertions;

with Awk_Tests.Process_Support;
with Project_Tools.Text;

package body Awk_Tests.Process_Diagnostics.Usage_Cases.Option_Cases.Invalid_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Invalid_Color_Status (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      procedure Expect_Invalid (Option_Text, Value, Message : String) is
         Args : constant Process_Arguments :=
           Arguments ([Argument (Option_Text)]);
      begin
         declare
            Result : constant Captured_Process := Run_Awk_Err_To_Out (Args);
            Output : constant String := Output_String (Result);
         begin
            Assert (Result.Status = 2, Message & " exits with usage status");
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

   procedure Test_Process_Invalid_V_Assignment
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Expect_Invalid
        (Args    : Process_Arguments;
         Message : String)
      is
      begin
         declare
            Result : constant Captured_Process := Run_Awk_Err_To_Out (Args);
            Output : constant String := Output_String (Result);
         begin
            Assert (Result.Status = 2, Message & " exits with usage status");
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
         Separate_Args : constant Process_Arguments :=
           Arguments
             ([Argument ("-v"),
               Argument ("1bad=value"),
               Argument ("BEGIN { print 1 }")]);
         Attached : constant Process_Arguments :=
           Arguments
             ([Argument ("-v1bad=value"),
               Argument ("BEGIN { print 1 }")]);
      begin
         Expect_Invalid (Separate_Args, "separate invalid -v");
         Expect_Invalid (Attached, "attached invalid -v");
      end;
   end Test_Process_Invalid_V_Assignment;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Process_Invalid_Color_Status'Access,
         "process invalid color status");
      Registration.Register_Routine
        (T, Test_Process_Invalid_V_Assignment'Access,
         "process invalid -v");
   end Register;
end Awk_Tests.Process_Diagnostics.Usage_Cases.Option_Cases.Invalid_Cases;
