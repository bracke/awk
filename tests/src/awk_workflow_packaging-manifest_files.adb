with Ada.Strings.Unbounded;

with Project_Tools.Files;

package body Awk_Workflow_Packaging.Manifest_Files is
   package Files renames Project_Tools.Files;
   package U renames Ada.Strings.Unbounded;

   Package_Files : constant Files.Path_List :=
     [U.To_Unbounded_String ("bin/awk"),
      U.To_Unbounded_String ("LICENSE"),
      U.To_Unbounded_String ("README.md"),
      U.To_Unbounded_String ("CHANGELOG.md"),
      U.To_Unbounded_String ("CONTRIBUTING.md"),
      U.To_Unbounded_String ("SECURITY.md"),
      U.To_Unbounded_String ("docs/quickstart.md"),
      U.To_Unbounded_String ("docs/command-line-reference.md"),
      U.To_Unbounded_String ("docs/compatibility.md"),
      U.To_Unbounded_String ("docs/architecture.md"),
      U.To_Unbounded_String ("docs/diagnostics.md"),
      U.To_Unbounded_String ("docs/localization.md"),
      U.To_Unbounded_String ("docs/localization-reference.md"),
      U.To_Unbounded_String ("docs/testing.md"),
      U.To_Unbounded_String ("docs/building.md"),
      U.To_Unbounded_String ("docs/releasing.md"),
      U.To_Unbounded_String ("docs/dependency-policy.md"),
      U.To_Unbounded_String ("docs/final-acceptance.md"),
      U.To_Unbounded_String ("docs/ai/project-map.md"),
      U.To_Unbounded_String ("docs/ai/package-contracts.md"),
      U.To_Unbounded_String ("docs/ai/invariants.md"),
      U.To_Unbounded_String ("docs/ai/workflows.md"),
      U.To_Unbounded_String ("docs/ai/prohibited-designs.md"),
      U.To_Unbounded_String ("docs/ai/traceability.md"),
      U.To_Unbounded_String ("resources/messages/catalog.txt"),
      U.To_Unbounded_String ("resources/messages/en/catalog.txt"),
      U.To_Unbounded_String ("resources/messages/da/catalog.txt")];

   function File_Count return Natural is (Natural (Package_Files'Length));

   function File_Path (Index : Positive) return String is
     (U.To_String (Package_Files (Index)));
end Awk_Workflow_Packaging.Manifest_Files;
