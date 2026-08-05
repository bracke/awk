with Ada.Strings.Unbounded;

with System;

with Awk_CLI.Platform;
with Awk_CLI.Redirections;

package Awk_Tests.Execution.Support is
   package U renames Ada.Strings.Unbounded;

   LF : constant String := [1 => ASCII.LF];

   type Live_State is record
      Output          : U.Unbounded_String;
      Redirection_Log : U.Unbounded_String;
      Fail_Output     : Boolean := False;
      Fail_Redirect   : Boolean := False;
   end record;

   function Read_Test_File
     (Path    : String;
      Content : out U.Unbounded_String) return Awk_CLI.Platform.Read_Status;

   function Live_Output
     (User_Data : System.Address;
      Content   : String) return Boolean;

   function Live_Redirection
     (User_Data : System.Address;
      Path      : String;
      Content   : String;
      Append    : Boolean) return Awk_CLI.Redirections.Write_Status;
end Awk_Tests.Execution.Support;
