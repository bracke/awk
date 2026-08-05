with Ada.Text_IO;

with Awk_Workflow_Catalogs.Completeness;
with Awk_Workflow_Catalogs.Consistency;
with Awk_Workflow_Catalogs.Fallbacks;
with Awk_Workflow_Catalogs.Reference_Cues;
with Project_Tools.Test_Fixtures;

package body Awk_Workflow_Catalogs is
   package Fixtures renames Project_Tools.Test_Fixtures;

   procedure Put_Info (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Message);
   end Put_Info;

   procedure Run is
      Catalog    : constant String := Fixtures.Read_Text_File ("../resources/messages/catalog.txt");
      English    : constant String := Fixtures.Read_Text_File ("../resources/messages/en/catalog.txt");
      Danish     : constant String := Fixtures.Read_Text_File ("../resources/messages/da/catalog.txt");
   begin
      Awk_Workflow_Catalogs.Completeness.Run (Catalog, English, Danish);
      Awk_Workflow_Catalogs.Consistency.Run;
      Awk_Workflow_Catalogs.Fallbacks.Run (Catalog);
      Awk_Workflow_Catalogs.Reference_Cues.Run (Catalog);
      Put_Info ("catalog checks passed");
   end Run;
end Awk_Workflow_Catalogs;
