with Awk_Tests.Process_IO.Input_Cases;
with Awk_Tests.Process_IO.Redirection_Cases;

package body Awk_Tests.Process_IO is
   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      --  Inventory note: child registrars below own the Register_Routine calls.
      Awk_Tests.Process_IO.Input_Cases.Register (T);
      Awk_Tests.Process_IO.Redirection_Cases.Register (T);
   end Register;
end Awk_Tests.Process_IO;
