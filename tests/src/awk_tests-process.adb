with AUnit.Assertions;

with Awk_Tests.Process_Diagnostics;
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
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument
              ("BEGIN { print ENVIRON[""AWK_PROCESS_ENV""]; "
               & "print ""empty="" ENVIRON[""AWK_PROCESS_EMPTY""] }"),
            Argument ("unused=value")]);
   begin
      declare
         Result : constant Captured_Process :=
           Run_Awk_With_Environment
             ("awk process environment",
              [Argument ("AWK_PROCESS_ENV=visible"), Argument ("AWK_PROCESS_EMPTY=")],
              Args);
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
