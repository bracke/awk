with Project_Tools.Test_Fixtures;

package body Awk_Tests.Process_Support.Fixture_Files is
   package Fixtures renames Project_Tools.Test_Fixtures;

   function Fresh_Process_Temp_Dir (Name : String) return String is
     (Fixtures.Fresh_Temp_Dir ("awk_process_" & Name));

   procedure Cleanup_Process_Temp_Dir (Path : String) is
   begin
      Fixtures.Cleanup (Path);
   end Cleanup_Process_Temp_Dir;

   function Read_Text_File (Path : String) return String is
     (Fixtures.Read_Text_File (Path));

   procedure Write_Text_File (Path : String; Content : String) is
   begin
      Fixtures.Write_Text_File (Path, Content);
   end Write_Text_File;
end Awk_Tests.Process_Support.Fixture_Files;
