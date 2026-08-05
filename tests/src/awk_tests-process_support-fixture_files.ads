package Awk_Tests.Process_Support.Fixture_Files is
   function Fresh_Process_Temp_Dir (Name : String) return String;
   procedure Cleanup_Process_Temp_Dir (Path : String);
   function Read_Text_File (Path : String) return String;
   procedure Write_Text_File (Path : String; Content : String);
end Awk_Tests.Process_Support.Fixture_Files;
