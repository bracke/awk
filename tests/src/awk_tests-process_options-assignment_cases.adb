with AUnit.Assertions;

with Awk_Tests.Process_Support;
with Project_Tools.Text;

package body Awk_Tests.Process_Options.Assignment_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Field_Separator (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("-F"),
            Argument (" "),
            Argument ("{ print $1 ""/"" $2 }"),
            Argument ("tests/fixtures/input/basic.txt")]);
      Result : constant Captured_Process := Run_Awk ("awk process -F", Args);
   begin
      Assert (Result.Status = 0, "process -F exits successfully");
      Assert (Project_Tools.Text.Contains (Output_String (Result), "one/two" & LF & "three/four"),
              "process -F splits fields");
   end Test_Process_Field_Separator;

   procedure Test_Process_Attached_Field_Separator_Final_Wins
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("-F:"),
            Argument ("-F "),
            Argument ("{ print $2 }"),
            Argument ("tests/fixtures/input/basic.txt")]);
      Result : constant Captured_Process := Run_Awk ("awk process attached -F final wins", Args);
   begin
      Assert (Result.Status = 0, "attached -F process run exits successfully");
      Assert (Project_Tools.Text.Contains (Output_String (Result), "two" & LF & "four"),
              "later attached -F value wins at process boundary");
   end Test_Process_Attached_Field_Separator_Final_Wins;

   procedure Test_Process_V_Assignment (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("-vX=41"),
            Argument ("BEGIN { print X + 1 }")]);
      Result : constant Captured_Process := Run_Awk ("awk process -v", Args);
   begin
      Assert (Result.Status = 0, "process -v exits successfully");
      Assert (Project_Tools.Text.Contains (Output_String (Result), "42" & LF),
              "process -v is visible before BEGIN");
   end Test_Process_V_Assignment;

   procedure Test_Process_Repeated_V_Assignments
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("-vX=first"),
            Argument ("-v"),
            Argument ("X=second"),
            Argument ("-vY=a=b"),
            Argument ("BEGIN { print X; print Y }")]);
      Result : constant Captured_Process := Run_Awk ("awk process repeated -v", Args);
   begin
      Assert (Result.Status = 0, "process repeated -v exits successfully");
      Assert (Project_Tools.Text.Contains (Output_String (Result), "second" & LF & "a=b"),
              "process -v assignments are applied in order and preserve extra equals");
   end Test_Process_Repeated_V_Assignments;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine (T, Test_Process_Field_Separator'Access, "process -F");
      Registration.Register_Routine
        (T, Test_Process_Attached_Field_Separator_Final_Wins'Access,
         "process attached -F final wins");
      Registration.Register_Routine (T, Test_Process_V_Assignment'Access, "process -v");
      Registration.Register_Routine
        (T, Test_Process_Repeated_V_Assignments'Access,
         "process repeated -v");
   end Register;
end Awk_Tests.Process_Options.Assignment_Cases;
