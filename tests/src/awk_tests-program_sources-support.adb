package body Awk_Tests.Program_Sources.Support is
   package U renames Ada.Strings.Unbounded;

   LF : constant String := [1 => ASCII.LF];

   function Read_Test_File
     (Path : String;
      Content : out U.Unbounded_String) return Awk_CLI.Platform.Read_Status
   is
   begin
      if Path = "a.awk" then
         Content := U.To_Unbounded_String ("BEGIN { print ""a"" }");
         return Awk_CLI.Platform.Read_Success;
      elsif Path = "b.awk" then
         Content := U.To_Unbounded_String ("BEGIN { print ""b"" }");
         return Awk_CLI.Platform.Read_Success;
      elsif Path = "empty.awk" then
         Content := U.Null_Unbounded_String;
         return Awk_CLI.Platform.Read_Success;
      elsif Path = "newline.awk" then
         Content := U.To_Unbounded_String ("BEGIN { print ""n"" }" & LF);
         return Awk_CLI.Platform.Read_Success;
      elsif Path = "tail.awk" then
         Content := U.To_Unbounded_String ("BEGIN { print ""tail"" }");
         return Awk_CLI.Platform.Read_Success;
      elsif Path = "space name.awk" then
         Content := U.To_Unbounded_String ("  BEGIN { print ""spaced"" }  ");
         return Awk_CLI.Platform.Read_Success;
      elsif Path = "read-fails.awk" then
         Content := U.Null_Unbounded_String;
         return Awk_CLI.Platform.Read_Failed;
      else
         Content := U.Null_Unbounded_String;
         return Awk_CLI.Platform.Open_Failed;
      end if;
   end Read_Test_File;

end Awk_Tests.Program_Sources.Support;
