with AUnit.Assertions;

with Awk_Tests.Process_Support;
with Project_Tools.Text;

package body Awk_Tests.Process_Diagnostics.Locale_Cases.Rendering_Cases.Safety_Cases is
   use AUnit.Assertions;
   use Awk_Tests.Process_Support;

   procedure Test_Process_Diagnostic_Sanitizes_Hostile_Argument
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Escape : constant String := [1 => Character'Val (27)];
      Args   : constant Process_Arguments :=
        Arguments
          ([Argument ("--bad" & LF & "awk: error: forged" & Escape & "[2J")]);
   begin
      declare
         Result : constant Captured_Process := Run_Awk_Err_To_Out (Args);
         Output : constant String := Output_String (Result);
      begin
         Assert (Result.Status = 2, "hostile process argument exits with usage status");
         Assert
           (not Project_Tools.Text.Contains (Output, LF & "awk: error: forged"),
            "process diagnostic cannot be forged with an embedded newline");
         Assert (not Project_Tools.Text.Contains (Output, Escape),
                 "process diagnostic emits no raw terminal escape");
         Assert
           (Project_Tools.Text.Contains (Output, "\nawk: error: forged\e[2J"),
            "process diagnostic renders unsafe characters visibly");
      end;
   end Test_Process_Diagnostic_Sanitizes_Hostile_Argument;

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Test_Process_Diagnostic_Sanitizes_Hostile_Argument'Access,
         "process diagnostic sanitizes hostile argument");
   end Register;
end Awk_Tests.Process_Diagnostics.Locale_Cases.Rendering_Cases.Safety_Cases;
