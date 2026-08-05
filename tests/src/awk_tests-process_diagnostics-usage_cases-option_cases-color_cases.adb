with AUnit.Assertions;

with Awk_Tests.Process_Support;
with Project_Tools.Text;

package body Awk_Tests.Process_Diagnostics.Usage_Cases.Option_Cases.Color_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

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
         Args : constant Process_Arguments :=
           Arguments ([Argument (Color_Option), Argument ("--bad")]);
      begin
         declare
            Result : constant Captured_Process := Run_Awk_Err_To_Out (Args);
            Output : constant String := Output_String (Result);
         begin
            Assert (Result.Status = 2, Message & " exits with usage status");
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
         Args : constant Process_Arguments :=
           Arguments
             ([Argument (First_Color), Argument (Second_Color), Argument ("--bad")]);
      begin
         declare
            Result : constant Captured_Process := Run_Awk_Err_To_Out (Args);
            Output : constant String := Output_String (Result);
         begin
            Assert (Result.Status = 2, Message & " exits with usage status");
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

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Process_Diagnostic_Color_Policy'Access,
         "process diagnostic color policy");
      Registration.Register_Routine
        (T, Test_Process_Repeated_Diagnostic_Color_Final_Wins'Access,
         "process repeated diagnostic color final wins");
   end Register;
end Awk_Tests.Process_Diagnostics.Usage_Cases.Option_Cases.Color_Cases;
