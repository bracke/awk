with Ada.Strings.Unbounded;

with Project_Tools.Ada_Source;
with Project_Tools.Files;

package body Awk_Workflow_Source_Policy.Workflow_Checks.Delegation is
   package Ada_Source renames Project_Tools.Ada_Source;
   package Files renames Project_Tools.Files;
   package U renames Ada.Strings.Unbounded;

   procedure Run is
   begin
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
        ("src/awk_workflow_catalogs.adb",
         "Awk_Workflow_Catalogs.Completeness.Run",
         "catalog workflow must delegate completeness checks",
         Quiet => False);
      Files.Require_Contains
        ("src/awk_workflow_catalogs.adb",
         "Awk_Workflow_Catalogs.Consistency.Run",
         "catalog workflow must delegate consistency checks",
         Quiet => False);
      Files.Require_Contains
        ("src/awk_workflow_catalogs.adb",
         "Awk_Workflow_Catalogs.Fallbacks.Run",
         "catalog workflow must delegate fallback checks",
         Quiet => False);
      Files.Require_Contains
        ("src/awk_workflow_catalogs.adb",
         "Awk_Workflow_Catalogs.Reference_Cues.Run",
         "catalog workflow must delegate reference-cue checks",
         Quiet => False);
      Files.Require_Contains
        ("src/awk_workflow_drift.adb", "with Awk_CLI.Diagnostics",
         "exit status drift checks must use compiled diagnostic constants",
         Quiet => False);
      Files.Require_Contains
        ("src/awk_workflows.adb", "Awk_Workflow_Drift.Exit_Statuses;",
         "workflow main must delegate exit-status drift checks",
         Quiet => False);
      Files.Require_Contains
        ("src/awk_workflows.adb", "Awk_Workflow_Conformance.Run;",
         "workflow main must delegate conformance checks",
         Quiet => False);
      Files.Require_Contains
        ("src/awk_workflows.adb", "Awk_Workflow_Install.Boundary;",
         "workflow main must delegate install boundary checks",
         Quiet => False);
      Files.Require_Contains
        ("src/awk_workflows.adb", "Awk_Workflow_Build_Output.Run;",
         "workflow main must delegate build-output checks",
         Quiet => False);
      Ada_Source.Require_No_Code_Tokens
        ("src/awk_workflows.adb",
         [U.To_Unbounded_String ("Exit_Constant_Value")],
         Quiet => False);
   end Run;

end Awk_Workflow_Source_Policy.Workflow_Checks.Delegation;
