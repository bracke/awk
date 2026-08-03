with Awk_CLI.Context_IO;
with Awk_CLI.Live_Context_Callbacks;
with System.Address_To_Access_Conversions;

package body Awk_CLI.Inputs.Live is
   use type U.Unbounded_String;
   use type Awk_CLI.Operands.Operand_Kind;
   use type Awk_CLI.Platform.Read_Status;

   Chunk_Size : constant Natural := 8192;

   package State_Access is new System.Address_To_Access_Conversions (Live_Input_State);

   procedure Initialize
     (State    : out Live_Input_State;
      Context  : in out Invocation_Context;
      Operands : aliased Awk_CLI.Operands.Operand_Vectors.Vector) is
   begin
      --  Callback lifetime invariant: Context and Operands are owned by
      --  Awk_CLI.Invocation.Execute and outlive the synchronous awklib run
      --  that receives State'Address.
      State.Context := Context'Unchecked_Access;
      State.Operands := Operands'Unchecked_Access;
      State.Operand_Index := 0;
      State.Implicit_Stdin_Used := False;
      State.Active := False;
      State.Active_Process := False;
      State.Active_Name := U.Null_Unbounded_String;
      State.Active_Content := U.Null_Unbounded_String;
      State.Active_Position := 1;
      Awk_CLI.Platform.Close_Input (State.Process_Stream);
   end Initialize;

   procedure Close (State : in out Live_Input_State) is
   begin
      Awk_CLI.Platform.Close_Input (State.Process_Stream);
   end Close;

   function Auxiliary_Files
     (Context : Invocation_Context) return Input_File_Vectors.Vector
   is
      Result : Input_File_Vectors.Vector;
   begin
      if Context.Config.Use_Process then
         return Result;
      end if;

      for File of Context.IO.Files loop
         if File.Openable and then File.Readable then
            Result.Append (Input_File'(Name => File.Path, Content => File.Content));
         end if;
      end loop;
      return Result;
   end Auxiliary_Files;

   function Activate_Standard_Input
     (State : in out Live_Input_State) return Awk_CLI.Platform.Read_Status
   is
   begin
      State.Active := True;
      State.Active_Process := False;
      State.Active_Name := U.To_Unbounded_String ("-");
      State.Active_Content := U.Null_Unbounded_String;
      State.Active_Position := 1;

      if State.Context.IO.Stdin_Fails then
         State.Active := False;
         return Awk_CLI.Platform.Read_Failed;
      elsif State.Context.Config.Use_Process then
         State.Active_Process := True;
         return Awk_CLI.Platform.Open_Standard_Input (State.Process_Stream);
      else
         State.Active_Content := State.Context.IO.Standard_In;
         return Awk_CLI.Platform.Read_Success;
      end if;
   end Activate_Standard_Input;

   function Activate_Named_Input
     (State : in out Live_Input_State;
      Path  : String) return Awk_CLI.Platform.Read_Status
   is
      Found  : Boolean;
      Status : Awk_CLI.Platform.Read_Status;
   begin
      State.Active := True;
      State.Active_Process := False;
      State.Active_Name := U.To_Unbounded_String (Path);
      State.Active_Content := U.Null_Unbounded_String;
      State.Active_Position := 1;

      Status :=
        Awk_CLI.Context_IO.Read_Virtual_File
          (State.Context.all, Path, State.Active_Content, Found);
      if Found then
         if Status /= Awk_CLI.Platform.Read_Success then
            State.Active := False;
         end if;
         return Status;
      end if;

      if State.Context.Config.Use_Process then
         State.Active_Process := True;
         return Awk_CLI.Platform.Open_Input_File (Path, State.Process_Stream);
      end if;

      State.Active := False;
      State.Active_Process := False;
      return Awk_CLI.Platform.Open_Failed;
   end Activate_Named_Input;

   function Read_Active_In_Memory
     (State         : in out Live_Input_State;
      Filename      : out U.Unbounded_String;
      Text          : out U.Unbounded_String;
      End_Of_Input  : out Boolean) return Awk_CLI.Platform.Read_Status
   is
      Content_Length : constant Natural := U.Length (State.Active_Content);
   begin
      Filename := State.Active_Name;
      Text := U.Null_Unbounded_String;
      End_Of_Input := False;

      if Content_Length = 0 then
         State.Active := False;
         End_Of_Input := True;
         return Awk_CLI.Platform.Read_Success;
      elsif State.Active_Position <= Content_Length then
         declare
            Last : constant Natural :=
              Natural'Min (Content_Length, State.Active_Position + Chunk_Size - 1);
         begin
            Text :=
              U.To_Unbounded_String
                (U.Slice (State.Active_Content, State.Active_Position, Last));
            State.Active_Position := Last + 1;
            if State.Active_Position > Content_Length then
               State.Active := False;
            end if;
            return Awk_CLI.Platform.Read_Success;
         end;
      else
         State.Active := False;
      end if;

      return Awk_CLI.Platform.Read_Success;
   end Read_Active_In_Memory;

   function Read
     (User_Data    : System.Address;
      Operand_Index : Positive;
      Filename     : out U.Unbounded_String;
      Text         : out U.Unbounded_String;
      End_Of_Input : out Boolean) return Awk_CLI.Platform.Read_Status
   is
      State : constant State_Access.Object_Pointer :=
        State_Access.To_Pointer (User_Data);
      Status : Awk_CLI.Platform.Read_Status;
   begin
      Filename := U.Null_Unbounded_String;
      Text := U.Null_Unbounded_String;
      End_Of_Input := False;

      loop
         if State.Active and then State.Operand_Index /= Operand_Index then
            Awk_CLI.Platform.Close_Input (State.Process_Stream);
            State.Active := False;
            State.Active_Process := False;
         end if;

         if not State.Active then
            if State.Operand_Index = Operand_Index then
               End_Of_Input := True;
               return Awk_CLI.Platform.Read_Success;
            end if;

            State.Operand_Index := Operand_Index;
            if Operand_Index > Natural (State.Operands.Length) then
               State.Implicit_Stdin_Used := True;
               Status := Activate_Standard_Input (State.all);
               State.Active_Name := U.Null_Unbounded_String;
            else
               declare
                  Item : constant Awk_CLI.Operands.Classified_Operand :=
                    State.Operands.Element (Operand_Index);
               begin
                  case Item.Kind is
                     when Awk_CLI.Operands.Named_File =>
                        Status := Activate_Named_Input (State.all, U.To_String (Item.Text));
                     when Awk_CLI.Operands.Standard_Input =>
                        if State.Implicit_Stdin_Used then
                           State.Active := True;
                           State.Active_Process := False;
                           State.Active_Name := U.To_Unbounded_String ("-");
                           State.Active_Content := U.Null_Unbounded_String;
                           State.Active_Position := 1;
                           Status := Awk_CLI.Platform.Read_Success;
                        else
                           State.Implicit_Stdin_Used := True;
                           Status := Activate_Standard_Input (State.all);
                        end if;
                     when Awk_CLI.Operands.Runtime_Assignment =>
                        Status := Awk_CLI.Platform.Read_Success;
                  end case;
               end;
            end if;
            if Status /= Awk_CLI.Platform.Read_Success then
               Filename := State.Active_Name;
               End_Of_Input := True;
               return Status;
            end if;
            if not State.Active then
               End_Of_Input := True;
               return Awk_CLI.Platform.Read_Success;
            end if;
         end if;

         if State.Active_Process then
            declare
               EOF : Boolean;
            begin
               Status :=
                 Awk_CLI.Platform.Read_Input_Chunk
                   (State.Process_Stream, Text, EOF);
               Filename := State.Active_Name;
               if Status /= Awk_CLI.Platform.Read_Success then
                  Awk_CLI.Platform.Close_Input (State.Process_Stream);
                  State.Active := False;
                  State.Active_Process := False;
                  End_Of_Input := True;
                  return Status;
               elsif EOF then
                  Awk_CLI.Platform.Close_Input (State.Process_Stream);
                  State.Active := False;
                  State.Active_Process := False;
               elsif U.Length (Text) > 0 then
                  return Awk_CLI.Platform.Read_Success;
               end if;
            end;
         else
            Status := Read_Active_In_Memory (State.all, Filename, Text, End_Of_Input);
            if Status /= Awk_CLI.Platform.Read_Success or else U.Length (Text) > 0 then
               return Status;
            elsif Filename /= U.Null_Unbounded_String and then not State.Active then
               return Awk_CLI.Platform.Read_Success;
            end if;
         end if;
      end loop;
   end Read;

   function Write_Output
     (User_Data : System.Address;
      Content   : String) return Boolean
   is
      State : constant State_Access.Object_Pointer :=
        State_Access.To_Pointer (User_Data);
   begin
      return
        Awk_CLI.Live_Context_Callbacks.Write_Output (State.Context.all, Content);
   end Write_Output;

   function Write_Redirection
     (User_Data : System.Address;
      Path      : String;
      Content   : String;
      Append    : Boolean) return Awk_CLI.Redirections.Write_Status
   is
      State : constant State_Access.Object_Pointer :=
        State_Access.To_Pointer (User_Data);
   begin
      return
        Awk_CLI.Live_Context_Callbacks.Write_Redirection
          (State.Context.all, Path, Content, Append);
   end Write_Redirection;

   function Read_Command
     (User_Data : System.Address;
      Command   : String;
      Output    : out U.Unbounded_String) return Boolean
   is
      State : constant State_Access.Object_Pointer :=
        State_Access.To_Pointer (User_Data);
   begin
      return
        Awk_CLI.Live_Context_Callbacks.Read_Command
          (State.Context.all, Command, Output);
   end Read_Command;
end Awk_CLI.Inputs.Live;
