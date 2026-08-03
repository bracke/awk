with AUnit.Assertions;

with Awk_Tests.Process_Diagnostics;
with Awk_Tests.Process_Harness;
with Awk_Tests.Process_IO;
with Awk_Tests.Process_Language;
with Awk_Tests.Process_Options;
with Awk_Tests.Process_Support;
with Project_Tools.Text;

package body Awk_Tests.Process is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk process");
   end Name;

   procedure Test_Process_Environment_Propagation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Env    : constant String := Awk_Tests.Process_Harness.Locate_Command ("env");
      Args   : constant Awk_Tests.Process_Harness.Argument_List (1 .. 5) :=
        [new String'("AWK_PROCESS_ENV=visible"),
         new String'("AWK_PROCESS_EMPTY="),
         new String'(Awk_From_Repository_Root),
         new String'("BEGIN { print ENVIRON[""AWK_PROCESS_ENV""]; print ""empty="" ENVIRON[""AWK_PROCESS_EMPTY""] }"),
         new String'("unused=value")];
   begin
      Assert (Env /= "", "env executable is available for environment-bound process test");
      declare
         Result : constant Captured_Process :=
           Run_Process ("awk process environment", "..", Env, Args);
      begin
         Assert (Result.Status = 0, "process environment propagation exits successfully");
         Assert (Project_Tools.Text.Contains (Output_String (Result), "visible" & LF),
                 "process environment reaches awklib ENVIRON");
         Assert (Project_Tools.Text.Contains (Output_String (Result), "empty=" & LF),
                 "empty process environment values are preserved");
      end;
   end Test_Process_Environment_Propagation;

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
      Awk_Tests.Process_Options.Register (T);
      Awk_Tests.Process_IO.Register (T);
      Awk_Tests.Process_Diagnostics.Register (T);
      Registration.Register_Routine
        (T, Test_Process_Environment_Propagation'Access,
         "process environment propagation");
      Awk_Tests.Process_Language.Register (T);
   end Register_Tests;
end Awk_Tests.Process;
