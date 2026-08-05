with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Project_Tools.Ada_Source;
with Project_Tools.AUnit_Checks;
with Project_Tools.Files;
with Project_Tools.Release_Checks;

package body Awk_Workflow_Source_Policy.Project_Structure.Inventory_Checks is
   package Ada_Source renames Project_Tools.Ada_Source;
   package Files renames Project_Tools.Files;
   package U renames Ada.Strings.Unbounded;

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
   end Run;
end Awk_Workflow_Source_Policy.Project_Structure.Inventory_Checks;
