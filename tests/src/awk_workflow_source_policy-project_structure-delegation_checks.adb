with Project_Tools.Files;

package body Awk_Workflow_Source_Policy.Project_Structure.Delegation_Checks is
   package Files renames Project_Tools.Files;

   procedure Run is
   begin
      Files.Require_Contains
        ("src/awk_workflow_source_policy.adb",
         "Awk_Workflow_Source_Policy.Dependency_Boundaries.Run;",
         "source policy dependency-boundary checks must stay delegated",
         Quiet => True);
      Files.Require_Contains
        ("src/awk_workflow_source_policy.adb",
         "Awk_Workflow_Source_Policy.Presentation.Run;",
         "source policy presentation checks must stay delegated",
         Quiet => True);
      Files.Require_Contains
        ("src/awk_workflow_source_policy.adb",
         "Awk_Workflow_Source_Policy.Runtime_State.Run;",
         "source policy runtime-state checks must stay delegated",
         Quiet => True);
      Files.Require_Contains
        ("src/awk_workflow_source_policy.adb",
         "Awk_Workflow_Source_Policy.Project_Structure.Run;",
         "source policy project-structure checks must stay delegated",
         Quiet => True);
      Files.Require_Contains
        ("src/awk_workflow_source_policy.adb",
         "Awk_Workflow_Source_Policy.Source_Budget_Checks.Run;",
         "source policy source-budget checks must stay delegated",
         Quiet => True);
      Files.Require_Contains
        ("src/awk_workflow_source_policy-platform_checks.adb",
         "procedure Run",
         "source policy platform checks must stay grouped",
         Quiet => True);
      Files.Require_Contains
        ("src/awk_workflow_source_policy-workflow_checks.adb",
         "procedure Run",
         "source policy workflow checks must stay grouped",
         Quiet => True);
   end Run;
end Awk_Workflow_Source_Policy.Project_Structure.Delegation_Checks;
