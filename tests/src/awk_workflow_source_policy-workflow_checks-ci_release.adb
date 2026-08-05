with Project_Tools.Files;
with Project_Tools.Release_Checks;

package body Awk_Workflow_Source_Policy.Workflow_Checks.CI_Release is
   package Files renames Project_Tools.Files;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Project_Tools.Release_Checks.Fail (Message);
      end if;
   end Require;

   procedure Run is
   begin
      Files.Require_Contains
        ("src/awk_workflows.adb", "Require_Clean_Repository;",
         "release workflow must check git status", Quiet => False);
      Files.Require_Contains
        ("src/awk_workflows.adb",
         "when Program_Error =>",
         "workflow Program_Error containment must catch expected gate failures",
         Quiet => False);
      Files.Require_Contains
        ("src/awk_workflows.adb",
         """workflow gate failed""",
         "workflow Program_Error containment must report expected gate failures",
         Quiet => False);
      Files.Require_Contains
        ("src/awk_workflows.adb",
         "CLI.Set_Exit_Status (CLI.Failure);",
         "workflow Program_Error containment must fail the process",
         Quiet => False);
      Require
        (not Files.File_Contains
           ("src/awk_workflows.adb",
            "when Program_Error =>" & ASCII.LF & "      null;"),
         "workflow Program_Error containment must not silently succeed");
      Files.Require_File
        ("../.github/workflows/ci.yml",
         "CI workflow must be present", Quiet => False);
      Files.Require_Contains
        ("../.github/workflows/ci.yml", "./bin/awk_workflows release",
         "CI workflow must delegate release gates to Ada tooling",
         Quiet => False);
      Files.Require_Contains
        ("../.github/workflows/ci.yml",
         "os: [ubuntu-latest, macos-15-intel, windows-latest]",
         "CI workflow must include native Linux, macOS, and Windows build/test coverage",
         Quiet => False);
      Require
        (not Files.File_Contains ("src/awk_workflows.adb", "release"") then" & ASCII.LF &
                                             "      Verify;"),
         "release workflow must not reuse development verify gate");
   end Run;

end Awk_Workflow_Source_Policy.Workflow_Checks.CI_Release;
