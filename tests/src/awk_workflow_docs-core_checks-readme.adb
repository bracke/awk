with Project_Tools.Files;

package body Awk_Workflow_Docs.Core_Checks.Readme is
   package Files renames Project_Tools.Files;

   procedure Run is
   begin
      Files.Require_Contains
        ("../README.md", "does not claim complete POSIX conformance",
         "README must not claim full POSIX conformance", Quiet => True);
      Files.Require_Contains
        ("../README.md", "./bin/awk_tests_main",
         "README must document the current AUnit executable", Quiet => True);
      Files.Require_Contains
        ("../README.md", "--color=auto|always|never",
         "README must document color policy", Quiet => True);
      Files.Require_Contains
        ("../README.md", "Windows",
         "README must include Windows quoting guidance", Quiet => True);
      Files.Require_Contains
        ("../LICENSE", "MIT License",
         "LICENSE must contain MIT license text", Quiet => True);
   end Run;
end Awk_Workflow_Docs.Core_Checks.Readme;
