with System.Address_To_Access_Conversions;

package body Awk_Tests.Execution.Support is
   package Live_State_Access is new System.Address_To_Access_Conversions (Live_State);

   function Read_Test_File
     (Path    : String;
      Content : out U.Unbounded_String) return Awk_CLI.Platform.Read_Status
   is
   begin
      if Path = "input" then
         Content := U.To_Unbounded_String ("x y" & LF);
         return Awk_CLI.Platform.Read_Success;
      else
         Content := U.Null_Unbounded_String;
         return Awk_CLI.Platform.Open_Failed;
      end if;
   end Read_Test_File;

   function Live_Output
     (User_Data : System.Address;
      Content   : String) return Boolean
   is
      State : constant Live_State_Access.Object_Pointer :=
        Live_State_Access.To_Pointer (User_Data);
   begin
      if State.Fail_Output then
         return False;
      end if;

      U.Append (State.Output, Content);
      return True;
   end Live_Output;

   function Live_Redirection
     (User_Data : System.Address;
      Path      : String;
      Content   : String;
      Append    : Boolean) return Awk_CLI.Redirections.Write_Status
   is
      State : constant Live_State_Access.Object_Pointer :=
        Live_State_Access.To_Pointer (User_Data);
   begin
      if State.Fail_Redirect then
         return Awk_CLI.Redirections.Write_Failed;
      end if;

      U.Append (State.Redirection_Log, Path);
      U.Append (State.Redirection_Log, ":");
      U.Append (State.Redirection_Log, (if Append then "append" else "write"));
      U.Append (State.Redirection_Log, ":");
      U.Append (State.Redirection_Log, Content);
      return Awk_CLI.Redirections.Write_Success;
   end Live_Redirection;
end Awk_Tests.Execution.Support;
