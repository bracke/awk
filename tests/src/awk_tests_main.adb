with Ada.Command_Line;
with AUnit;
with AUnit.Reporter.Text;
with AUnit.Run;
with Awk_Tests.Suite;

procedure Awk_Tests_Main is
   use type AUnit.Status;
   function Run is new AUnit.Run.Test_Runner_With_Status (Awk_Tests.Suite.Suite);
   Reporter : AUnit.Reporter.Text.Text_Reporter;
begin
   if Run (Reporter) /= AUnit.Success then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Awk_Tests_Main;
