with Ada.Strings.Unbounded;

with Project_Tools.Ada_Source;
with Project_Tools.Files;
with Project_Tools.Release_Checks;

package body Awk_Workflow_Source_Policy.Workflow_Checks is
   package Ada_Source renames Project_Tools.Ada_Source;
   package Files renames Project_Tools.Files;
   package U renames Ada.Strings.Unbounded;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Project_Tools.Release_Checks.Fail (Message);
      end if;
   end Require;

   procedure Run is
      Workflow_Script : constant String :=
        Files.First_File_Name_Containing
          ("..",
           Name_Tokens =>
             [U.To_Unbounded_String (".sh"),
              U.To_Unbounded_String (".py"),
              U.To_Unbounded_String (".ps1"),
              U.To_Unbounded_String ("Makefile"),
              U.To_Unbounded_String (".js")],
           Skip_Entries =>
             [U.To_Unbounded_String (".git"),
              U.To_Unbounded_String ("alire"),
              U.To_Unbounded_String ("obj"),
              U.To_Unbounded_String ("bin"),
              U.To_Unbounded_String ("dist"),
              U.To_Unbounded_String ("config")]);
   begin
      Ada_Source.Require_No_Code_Tokens_In_Tree
        ("../src",
         ([U.To_Unbounded_String ("gawk"),
           U.To_Unbounded_String ("mawk"),
           U.To_Unbounded_String ("nawk")]),
         Quiet => False);
      Files.Require_Contains
        ("src/awk_tests-process_support.adb", "with Project_Tools.Test_Fixtures",
         "process fixture file reads must use project_tools directly", Quiet => False);
      Files.Require_Contains
        ("src/awk_tests-process_support.adb", "Project_Tools.Processes.Run_Status",
         "raw process status execution must be centralized in process support",
         Quiet => False);
      Require
        (Ada_Source.First_Source_File_Containing
           ("src",
            "Project_Tools.Processes.Run_Status",
            Allowed_Files =>
              [U.To_Unbounded_String ("src/awk_tests-process_support.adb"),
               U.To_Unbounded_String
                 ("src/awk_workflow_source_policy-workflow_checks.adb")]) = "",
         "raw process status execution must stay in process support");
      Files.Require_Contains
        ("src/awk_tests-process_support.adb", "Project_Tools.Processes.Command_Output",
         "raw process output capture must be centralized in process support",
         Quiet => False);
      Require
        (Ada_Source.First_Source_File_Containing
           ("src",
            "Project_Tools.Processes.Command_Output",
            Allowed_Files =>
              [U.To_Unbounded_String ("src/awk_tests-process_support.adb"),
               U.To_Unbounded_String
                 ("src/awk_workflow_source_policy-workflow_checks.adb")]) = "",
         "raw process output capture must stay in process support");
      Files.Require_Contains
        ("src/awk_tests-localization-catalog_cases.adb",
         "with Project_Tools.Test_Fixtures",
         "catalog fixture file reads must use project_tools directly",
         Quiet => False);
      Files.Require_Contains
        ("src/awk_tests-localization-rendering_cases.adb",
         "with Project_Tools.Test_Fixtures",
         "localization rendering fixture file reads must use project_tools directly",
         Quiet => False);
      Files.Require_Contains
        ("src/awk_tests-compatibility.adb", "with Project_Tools.Test_Fixtures",
         "fixture file reads must use project_tools directly", Quiet => False);
      Files.Require_Contains
        ("src/awk_workflows.adb", "Release_Mode => True",
         "release workflow must use Alire release builds", Quiet => False);
      Files.Require_Contains
        ("src/awk_workflows.adb", "procedure Core_Quality_Gates",
         "shared workflow quality gates must be centralized", Quiet => False);
      Files.Require_Contains
        ("src/awk_workflows.adb", "Run_AUnit;",
         "workflow AUnit execution must be reusable across build modes", Quiet => False);
      Files.Require_Contains
        ("src/awk_workflows.adb", "with Awk_CLI.Diagnostics",
         "exit status drift checks must use compiled diagnostic constants",
         Quiet => False);
      Ada_Source.Require_No_Code_Tokens
        ("src/awk_workflows.adb",
         [U.To_Unbounded_String ("Exit_Constant_Value")],
         Quiet => False);
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
      Require
        (Workflow_Script = "",
         "workflow logic must not use shell or scripting files: " & Workflow_Script);
   end Run;
end Awk_Workflow_Source_Policy.Workflow_Checks;
