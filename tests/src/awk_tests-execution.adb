with Awk_Tests.Execution.Basic_Cases;
with Awk_Tests.Execution.Live_Cases;

package body Awk_Tests.Execution is
   overriding function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("awk execution");
   end Name;

   overriding procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases;
   begin
      Registration.Register_Routine
        (T, Awk_Tests.Execution.Basic_Cases.Test_Execution'Access,
         "awklib execution adapter");
      Registration.Register_Routine
        (T, Awk_Tests.Execution.Live_Cases.Test_Live_Callbacks'Access,
         "awklib live execution callbacks");
      Registration.Register_Routine
        (T, Awk_Tests.Execution.Live_Cases.Test_Live_Output_Failure'Access,
         "awklib live stdout failure");
   end Register_Tests;
end Awk_Tests.Execution;
