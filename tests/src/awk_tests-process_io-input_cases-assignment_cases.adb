with AUnit.Assertions;

with Awk_Tests.Process_Support;
with Project_Tools.Text;

package body Awk_Tests.Process_IO.Input_Cases.Assignment_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Runtime_Assignment_Argv
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("BEGIN { print ARGC; print ARGV[1]; print ARGV[2] }"),
            Argument ("name=value"),
            Argument ("tests/fixtures/input/basic.txt")]);
      Result : constant Captured_Process := Run_Awk ("awk process runtime assignment argv", Args);
   begin
      Assert (Result.Status = 0, "process runtime assignment ARGV exits successfully");
      Assert (Project_Tools.Text.Contains (Output_String (Result), "3" & LF & "name=value" & LF),
              "runtime assignment spelling is preserved in ARGV");
      Assert (Project_Tools.Text.Contains
                (Output_String (Result), "tests/fixtures/input/basic.txt"),
              "input filename remains ordered after runtime assignment");
   end Test_Process_Runtime_Assignment_Argv;

   procedure Test_Process_Runtime_Assignment_Positions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument
              ("BEGIN { print ""begin"", X }"
               & " { print FILENAME, FNR, X, $0 } END { print ""end"", X }"),
            Argument ("tests/fixtures/input/basic.txt"),
            Argument ("X=42"),
            Argument ("tests/fixtures/input/second.txt"),
            Argument ("X=99")]);
      Result : constant Captured_Process :=
        Run_Awk ("awk process runtime assignment positions", Args);
   begin
      Assert (Result.Status = 0, "process runtime assignment positions exits successfully");
      Assert (Project_Tools.Text.Contains (Output_String (Result), "begin " & LF),
              "initial runtime assignment value is empty before input");
      Assert
        (Project_Tools.Text.Contains
           (Output_String (Result), "tests/fixtures/input/basic.txt 1  one two"),
         "first file is processed before interspersed assignment");
      Assert
        (Project_Tools.Text.Contains
           (Output_String (Result), "tests/fixtures/input/second.txt 1 42 five six"),
         "interspersed assignment affects following input file");
      Assert (Project_Tools.Text.Contains (Output_String (Result), "end 99" & LF),
              "final runtime assignment is visible in END");
   end Test_Process_Runtime_Assignment_Positions;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Process_Runtime_Assignment_Argv'Access,
         "process runtime assignment ARGV");
      Registration.Register_Routine
        (T, Test_Process_Runtime_Assignment_Positions'Access,
         "process runtime assignment positions");
   end Register;
end Awk_Tests.Process_IO.Input_Cases.Assignment_Cases;
