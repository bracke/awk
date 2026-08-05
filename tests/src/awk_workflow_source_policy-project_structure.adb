with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Project_Tools.Ada_Source;
with Project_Tools.AUnit_Checks;
with Project_Tools.Files;
with Project_Tools.Release_Checks;

package body Awk_Workflow_Source_Policy.Project_Structure is
   package Ada_Source renames Project_Tools.Ada_Source;
   package Files renames Project_Tools.Files;
   package U renames Ada.Strings.Unbounded;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Project_Tools.Release_Checks.Fail (Message);
      end if;
   end Require;

   procedure Public_Spec_Docs is
      Specs : constant Files.Path_List := Files.List_Tree ("../src/library", "*.ads");
   begin
      for Path of Specs loop
         Ada_Source.Require_Public_GNATdoc_Tags
           (Spec_Path => U.To_String (Path));
      end loop;
      Ada.Text_IO.Put_Line ("public spec documentation checks passed");
   end Public_Spec_Docs;

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
      Project_Tools.AUnit_Checks.Require_Registered_Test_Packages
        (Test_Dir             => "src",
         Spec_Pattern         => "awk_tests-*.ads",
         Suite_Path           => "src/awk_tests-suite.adb",
         Documentation_Path     => "../docs/testing.md",
         Documented_Stem_Prefix => "`",
         Suite_Add_Prefix     => "Result.Add_Test (new ",
         Suite_Add_Suffix     => ".Case_Type)",
         Section_Marker       => "type Case_Type is new AUnit.Test_Cases.Test_Case",
         Quiet                => True);
      Project_Tools.Release_Checks.Require_GPR_Main_Inventory
        (Project_File       => "../awk.gpr",
         Documentation_File => "../README.md",
         Source_Directory   => "../src/main",
         Quiet              => True);
      Project_Tools.Release_Checks.Require_GPR_Main_Inventory
        (Project_File       => "awk_tests.gpr",
         Documentation_File => "../docs/testing.md",
         Source_Directory   => "src",
         Quiet              => True);
      Public_Spec_Docs;
      Files.Require_Contains
        ("src/awk_cli-testing.ads", "package Awk_CLI.Testing",
         "in-memory invocation harness must live in the tests crate",
         Quiet => True);
      Require
        (Ada_Source.First_Source_File_Containing
           ("../src/library",
            "package Awk_CLI.Testing") = "",
         "test harness child package must not live in production sources");
      Files.Require_Contains
        ("../src/library/awk_cli.ads", "type Invocation_Configuration is record",
         "invocation context must group process configuration state",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli.ads", "type Virtual_IO_State is record",
         "invocation context must group in-memory I/O state",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli.ads", "type Diagnostic_State is record",
         "invocation context must group diagnostic state",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli.adb", "procedure Record_Diagnostic",
         "top-level runner must centralize diagnostic state recording",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-execution.adb", "function Build_Run_Result",
         "execution adapter must centralize awklib run-result conversion",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-execution.adb",
         "Ada.Exceptions.Exception_Name",
         "execution internal diagnostics should retain sanitized exception identity",
         Quiet => True);
      Ada_Source.Require_No_Code_Tokens
        ("../src/library/awk_cli-execution.adb",
         [U.To_Unbounded_String ("Exception_Information")],
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-inputs-live.adb",
         "Callback lifetime invariant: Context and Operands",
         "live input unchecked callback access must document object lifetimes",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-execution.adb",
         "Callback lifetime invariant: Inputs, Output, Redirs, and State",
         "execution unchecked callback access must document object lifetimes",
         Quiet => True);
      Ada_Source.Require_No_Code_Tokens
        ("../src/library/awk_cli.ads",
         [U.To_Unbounded_String ("procedure Add_Argument"),
          U.To_Unbounded_String ("procedure Set_Standard_Input"),
          U.To_Unbounded_String ("procedure Add_File"),
          U.To_Unbounded_String ("procedure Add_Environment"),
          U.To_Unbounded_String ("function Standard_Output"),
          U.To_Unbounded_String ("function Written_File_Count")],
         Quiet => True);
   end Run;
end Awk_Workflow_Source_Policy.Project_Structure;
