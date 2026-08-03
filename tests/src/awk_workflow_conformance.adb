with Ada.Text_IO;

with Awk_Conformance_Cases;
with Project_Tools.Files;
with Project_Tools.Release_Checks;

package body Awk_Workflow_Conformance is
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

   procedure Run is
      procedure Require_Case (Index : Positive) is
         Id        : constant String := Awk_Conformance_Cases.Id (Index);
         Case_File : constant String := Awk_Conformance_Cases.Case_File (Index);
         Expected  : constant String := Awk_Conformance_Cases.Expected_File (Index);
      begin
         Require
           (Files.Has_Line
              ("conformance/manifest/cases.txt",
               Awk_Conformance_Cases.Manifest_Line (Index)),
            "conformance manifest missing case: " & Id);
         Files.Require_File
           ("conformance/" & Case_File,
            "conformance case file missing: " & Case_File);
         Files.Require_File
           ("conformance/" & Expected,
            "conformance expected file missing: " & Expected);
         Require
           (Project_Tools.Release_Checks.File_Length ("conformance/" & Case_File) > 0,
            "conformance case file is empty: " & Case_File);
         Require
           (Project_Tools.Release_Checks.File_Length ("conformance/" & Expected) > 0,
            "conformance expected file is empty: " & Expected);
      end Require_Case;
   begin
      Files.Require_File
        ("conformance/manifest/cases.txt",
         "conformance manifest is missing or empty");
      Require
        (Project_Tools.Release_Checks.File_Length ("conformance/manifest/cases.txt") > 0,
         "conformance manifest is missing or empty");
      for Index in 1 .. Awk_Conformance_Cases.Case_Count loop
         Require_Case (Index);
      end loop;
      Put_Info ("conformance checks passed");
   end Run;
end Awk_Workflow_Conformance;
