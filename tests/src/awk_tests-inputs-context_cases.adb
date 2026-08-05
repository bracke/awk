with Awk_Tests.Inputs.Context_Cases.Failure_Cases;
with Awk_Tests.Inputs.Context_Cases.Ordering_Cases;

package body Awk_Tests.Inputs.Context_Cases is
   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      Awk_Tests.Inputs.Context_Cases.Failure_Cases.Register (T);
      Awk_Tests.Inputs.Context_Cases.Ordering_Cases.Register (T);
   end Register;
end Awk_Tests.Inputs.Context_Cases;
