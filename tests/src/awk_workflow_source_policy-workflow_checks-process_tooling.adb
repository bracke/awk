with Ada.Strings.Unbounded;

with Project_Tools.Ada_Source;
with Project_Tools.Files;
with Project_Tools.Release_Checks;

package body Awk_Workflow_Source_Policy.Workflow_Checks.Process_Tooling is
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
   begin
      Files.Require_Contains
        ("src/awk_tests-process_support-processes.adb", "Project_Tools.Processes.Capture",
         "process execution must use project_tools managed capture helpers",
         Quiet => False);
      Require
        (Ada_Source.First_Source_File_Containing
           ("src",
            "Project_Tools.Processes.Run_Status",
            Allowed_Files =>
              [U.To_Unbounded_String
                 ("src/awk_workflow_source_policy-workflow_checks-process_tooling.adb")]) = "",
         "raw process status execution must stay in workflow tooling");
      Files.Require_Contains
        ("src/awk_tests-process_support-processes.adb",
         "Project_Tools.Processes.Capture_Command",
         "stderr-merged process capture must use project_tools managed capture helpers",
         Quiet => False);
      Files.Require_Contains
        ("src/awk_tests-process_support.ads", "subtype Process_Arguments",
         "process tests must expose a support-level argument vector",
         Quiet => False);
      Ada_Source.Require_No_Code_Tokens
        ("src/awk_tests-process_support.ads",
         [U.To_Unbounded_String ("with GNAT.OS_Lib"),
          U.To_Unbounded_String ("GNAT.OS_Lib.Argument_List")],
         Quiet => False);
      Files.Require_Contains
        ("src/awk_tests-process_support.ads", "Project_Tools.Processes.Argument_Vectors.Vector",
         "GNAT process argument conversion must be centralized in project_tools",
         Quiet => False);
      Require
        (Ada_Source.First_Source_File_Containing
           ("src",
            "with GNAT.OS_Lib",
            Allowed_Files =>
              [U.To_Unbounded_String ("src/awk_workflows.adb"),
               U.To_Unbounded_String ("src/awk_workflow_install.adb"),
               U.To_Unbounded_String
                 ("src/awk_workflow_source_policy-workflow_checks-process_tooling.adb")]) = "",
         "raw GNAT process access must stay in workflow tooling");
      Require
        (Ada_Source.First_Source_File_Containing
           ("src",
            "GNAT.OS_Lib.Argument_List",
            Allowed_Files =>
              [U.To_Unbounded_String ("src/awk_workflows.adb"),
               U.To_Unbounded_String ("src/awk_workflow_install.adb"),
               U.To_Unbounded_String
                 ("src/awk_workflow_source_policy-workflow_checks-process_tooling.adb")]) = "",
         "raw GNAT argument lists must stay in workflow tooling");
      Require
        (Ada_Source.First_Source_File_Containing
           ("src",
            "Project_Tools.Processes.Command_Output",
            Allowed_Files =>
              [U.To_Unbounded_String
                 ("src/awk_workflow_source_policy-workflow_checks-process_tooling.adb")]) = "",
         "raw process output capture must stay in project_tools");
   end Run;

end Awk_Workflow_Source_Policy.Workflow_Checks.Process_Tooling;
