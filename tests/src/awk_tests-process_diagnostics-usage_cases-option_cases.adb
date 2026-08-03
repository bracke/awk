with AUnit.Assertions;

with GNAT.OS_Lib;

with Awk_Tests.Process_Support;
with Project_Tools.Text;

package body Awk_Tests.Process_Diagnostics.Usage_Cases.Option_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Usage_Status (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
        [new String'("--bad-option")];
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
         Args : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
           [new String'(Color_Option), new String'("--bad")];
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
         Args : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
           [new String'(First_Color), new String'(Second_Color), new String'("--bad")];
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

   procedure Test_Process_No_Arguments_Missing_Program
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args : constant GNAT.OS_Lib.Argument_List (1 .. 0) := [];
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

   procedure Test_Process_Invalid_Color_Status (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      procedure Expect_Invalid (Argument, Value, Message : String) is
         Args : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
           [new String'(Argument)];
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

   procedure Test_Process_Missing_Option_Argument_Status
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Expect_Missing (Option : String) is
         Args : constant GNAT.OS_Lib.Argument_List (1 .. 1) :=
           [new String'(Option)];
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

   procedure Test_Process_Invalid_V_Assignment
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Expect_Invalid
        (Args    : GNAT.OS_Lib.Argument_List;
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
         Separate_Args : constant GNAT.OS_Lib.Argument_List (1 .. 3) :=
           [new String'("-v"),
            new String'("1bad=value"),
            new String'("BEGIN { print 1 }")];
         Attached : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
           [new String'("-v1bad=value"),
            new String'("BEGIN { print 1 }")];
      begin
         Expect_Invalid (Separate_Args, "separate invalid -v");
         Expect_Invalid (Attached, "attached invalid -v");
      end;
   end Test_Process_Invalid_V_Assignment;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Process_Usage_Status'Access, "process usage status");
      Registration.Register_Routine
        (T, Test_Process_Diagnostic_Color_Policy'Access,
         "process diagnostic color policy");
      Registration.Register_Routine
        (T, Test_Process_Repeated_Diagnostic_Color_Final_Wins'Access,
         "process repeated diagnostic color final wins");
      Registration.Register_Routine
        (T, Test_Process_No_Arguments_Missing_Program'Access,
         "process no arguments missing program");
      Registration.Register_Routine
        (T, Test_Process_Invalid_Color_Status'Access,
         "process invalid color status");
      Registration.Register_Routine
        (T, Test_Process_Missing_Option_Argument_Status'Access,
         "process missing option argument status");
      Registration.Register_Routine
        (T, Test_Process_Invalid_V_Assignment'Access,
         "process invalid -v");
   end Register;
end Awk_Tests.Process_Diagnostics.Usage_Cases.Option_Cases;
