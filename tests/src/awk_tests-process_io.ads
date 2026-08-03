with AUnit.Test_Cases;

package Awk_Tests.Process_IO is
   --  Process-level input, output, file, redirection, and stdin cases.

   procedure Register (T : in out AUnit.Test_Cases.Test_Case'Class);
   --  Register process tests for host I/O behavior.
end Awk_Tests.Process_IO;
