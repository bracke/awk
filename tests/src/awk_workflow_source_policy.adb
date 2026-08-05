with Ada.Text_IO;

with Awk_Workflow_Packaging;
with Awk_Workflow_Source_Policy.Dependency_Boundaries;
with Awk_Workflow_Source_Policy.Platform_Checks;
with Awk_Workflow_Source_Policy.Presentation;
with Awk_Workflow_Source_Policy.Project_Structure;
with Awk_Workflow_Source_Policy.Runtime_State;
with Awk_Workflow_Source_Policy.Source_Budget_Checks;
with Awk_Workflow_Source_Policy.Workflow_Checks;
with Awk_Workflow_Message_Key_Policy;
with Project_Tools.Files;
with Project_Tools.Release_Checks;

package body Awk_Workflow_Source_Policy is
   package Files renames Project_Tools.Files;

   procedure Put_Info (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Message);
   end Put_Info;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Project_Tools.Release_Checks.Fail (Message);
      end if;
   end Require;

   procedure Package_Manifest_Policy is
      function Package_Includes (Path : String) return Boolean is
      begin
         for Index in 1 .. Awk_Workflow_Packaging.File_Count loop
            if Awk_Workflow_Packaging.File_Path (Index) = Path then
               return True;
            end if;
         end loop;

         return False;
      end Package_Includes;

      procedure Require_Packaged (Path : String) is
      begin
         Require
           (Package_Includes (Path),
            "package file list missing: " & Path);
      end Require_Packaged;
   begin
      for Index in 1 .. Awk_Workflow_Packaging.File_Count loop
         declare
            Path : constant String := Awk_Workflow_Packaging.File_Path (Index);
         begin
            if Path /= "bin/awk" then
               Files.Require_File ("../" & Path,
                                   "packaged source file missing: " & Path);
            end if;
         end;
      end loop;

      Require_Packaged ("resources/messages/catalog.txt");
      Require_Packaged ("resources/messages/en/catalog.txt");
      Require_Packaged ("resources/messages/da/catalog.txt");
      Require_Packaged ("docs/compatibility.md");
      Require_Packaged ("docs/final-acceptance.md");
      Require_Packaged ("LICENSE");
      Files.Require_File
        ("source-budgets.toml",
         "source budget manifest missing", Quiet => True);
      Files.Require_Contains
        ("../docs/releasing.md", "message catalogs",
         "release/testing docs must describe packaged resources", Quiet => True);
      Files.Require_Contains
        ("../docs/releasing.md", "MANIFEST.txt",
         "release/testing docs must describe packaged resources", Quiet => True);
      Files.Require_Contains
        ("../docs/testing.md", "package manifest",
         "release/testing docs must describe packaged resources", Quiet => True);
      Put_Info ("package manifest policy checks passed");
   end Package_Manifest_Policy;

   procedure Run is
   begin
      Put_Info ("source policy: dependency boundaries");
      Awk_Workflow_Source_Policy.Dependency_Boundaries.Run;
      Put_Info ("source policy: presentation");
      Awk_Workflow_Source_Policy.Presentation.Run;
      Put_Info ("source policy: runtime state");
      Awk_Workflow_Source_Policy.Runtime_State.Run;
      Put_Info ("source policy: platform checks");
      Awk_Workflow_Source_Policy.Platform_Checks.Run;
      Put_Info ("source policy: catalog keys");
      Awk_Workflow_Message_Key_Policy.Require_Production_Key_Literals;
      Put_Info ("source policy: project structure");
      Awk_Workflow_Source_Policy.Project_Structure.Run;
      Put_Info ("source policy: source budgets");
      Awk_Workflow_Source_Policy.Source_Budget_Checks.Run;
      Put_Info ("source policy: workflow checks");
      Awk_Workflow_Source_Policy.Workflow_Checks.Run;
      Put_Info ("source policy checks passed");
   end Run;
end Awk_Workflow_Source_Policy;
