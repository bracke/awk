with Ada.Strings.Unbounded;

with Awk_CLI.Platform;

package Awk_Tests.Program_Sources.Support is

   function Read_Test_File
     (Path : String;
      Content : out Ada.Strings.Unbounded.Unbounded_String)
      return Awk_CLI.Platform.Read_Status;

end Awk_Tests.Program_Sources.Support;
