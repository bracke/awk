with Ada.Strings.Unbounded;

with Awk_Workflow_Docs.Core_Checks.Architecture;
with Awk_Workflow_Docs.Core_Checks.Command_Line;
with Awk_Workflow_Docs.Core_Checks.Compatibility;
with Awk_Workflow_Docs.Core_Checks.Diagnostics;
with Awk_Workflow_Docs.Core_Checks.Localization;
with Awk_Workflow_Docs.Core_Checks.Readme;
with Project_Tools.Files;
with Project_Tools.Release_Checks;

package body Awk_Workflow_Docs.Core_Checks is
   package Files renames Project_Tools.Files;
   package U renames Ada.Strings.Unbounded;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Project_Tools.Release_Checks.Fail (Message);
      end if;
   end Require;

   procedure Run is
      Required_Docs : constant Files.Path_List :=
        [U.To_Unbounded_String ("../README.md"),
         U.To_Unbounded_String ("../CHANGELOG.md"),
         U.To_Unbounded_String ("../CONTRIBUTING.md"),
         U.To_Unbounded_String ("../SECURITY.md"),
         U.To_Unbounded_String ("../LICENSE"),
         U.To_Unbounded_String ("../docs/quickstart.md"),
         U.To_Unbounded_String ("../docs/command-line-reference.md"),
         U.To_Unbounded_String ("../docs/compatibility.md"),
         U.To_Unbounded_String ("../docs/architecture.md"),
         U.To_Unbounded_String ("../docs/diagnostics.md"),
         U.To_Unbounded_String ("../docs/localization.md"),
         U.To_Unbounded_String ("../docs/localization-reference.md"),
         U.To_Unbounded_String ("../docs/testing.md"),
         U.To_Unbounded_String ("../docs/building.md"),
         U.To_Unbounded_String ("../docs/releasing.md"),
         U.To_Unbounded_String ("../docs/dependency-policy.md"),
         U.To_Unbounded_String ("../docs/final-acceptance.md"),
         U.To_Unbounded_String ("../docs/ai/project-map.md"),
         U.To_Unbounded_String ("../docs/ai/package-contracts.md"),
         U.To_Unbounded_String ("../docs/ai/invariants.md"),
         U.To_Unbounded_String ("../docs/ai/workflows.md"),
         U.To_Unbounded_String ("../docs/ai/prohibited-designs.md"),
         U.To_Unbounded_String ("../docs/ai/traceability.md")];
      Stale_Docs : constant String :=
        Project_Tools.Release_Checks.Stale_Doc_Scaffolding ("..");
   begin
      Files.Require_Files (Required_Docs, "missing required documentation");
      Require
        (Stale_Docs = "",
         "documentation contains stale scaffolding language: " & Stale_Docs);
      Awk_Workflow_Docs.Core_Checks.Readme.Run;
      Awk_Workflow_Docs.Core_Checks.Command_Line.Run;
      Awk_Workflow_Docs.Core_Checks.Compatibility.Run;
      Awk_Workflow_Docs.Core_Checks.Diagnostics.Run;
      Awk_Workflow_Docs.Core_Checks.Architecture.Run;
      Awk_Workflow_Docs.Core_Checks.Localization.Run;
   end Run;
end Awk_Workflow_Docs.Core_Checks;
