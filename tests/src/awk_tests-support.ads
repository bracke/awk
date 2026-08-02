package Awk_Tests.Support is
   function Contains (Text, Pattern : String) return Boolean;
   function File_Text (Path : String) return String;
   procedure Write_Text_File (Path, Content : String);
end Awk_Tests.Support;
