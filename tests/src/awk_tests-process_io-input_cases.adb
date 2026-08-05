with Awk_Tests.Process_IO.Input_Cases.Assignment_Cases;
with Awk_Tests.Process_IO.Input_Cases.File_Cases;
with Awk_Tests.Process_IO.Input_Cases.Program_File_Cases;
with Awk_Tests.Process_IO.Input_Cases.Stdin_Cases;

package body Awk_Tests.Process_IO.Input_Cases is
   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class) is
   begin
      --  Inventory note: child registrars below own the Register_Routine calls.
      Awk_Tests.Process_IO.Input_Cases.File_Cases.Register (T);
      Awk_Tests.Process_IO.Input_Cases.Program_File_Cases.Register (T);
      Awk_Tests.Process_IO.Input_Cases.Stdin_Cases.Register (T);
      Awk_Tests.Process_IO.Input_Cases.Assignment_Cases.Register (T);
   end Register;
end Awk_Tests.Process_IO.Input_Cases;
