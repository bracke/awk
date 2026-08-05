with Project_Tools.Files;

package body Awk_Workflow_Metadata.Project_Files is
   package Files renames Project_Tools.Files;

   procedure Run is
   begin
      Files.Require_Contains
        ("../awk.gpr", "-gnat2022",
         "root project must compile with Ada 2022", Quiet => True);
      Files.Require_Contains
        ("awk_tests.gpr", "-gnat2022",
         "tests project must compile with Ada 2022", Quiet => True);
      Files.Require_Contains
        ("../awk.gpr", "for Main use (""awk.adb"")",
         "root project main must be awk.adb", Quiet => True);
      Files.Require_Contains
        ("awk_tests.gpr", "awk_workflows.adb",
         "tests project must build workflow executable", Quiet => True);
      Files.Require_Contains
        ("awk_tests.gpr", "awk_tests_main.adb",
         "tests project must build AUnit executable", Quiet => True);
   end Run;
end Awk_Workflow_Metadata.Project_Files;
