with System.Address_To_Access_Conversions;

package body Awk_CLI.Inputs.Live is
   use type U.Unbounded_String;
   use type Awk_CLI.Operands.Operand_Kind;
   use type Awk_CLI.Platform.Read_Status;

   Chunk_Size : constant Natural := 8192;

   package State_Access is new System.Address_To_Access_Conversions (Live_Input_State);

   function Write_Context_File
     (Context : in out Invocation_Context;
      Path    : String;
      Content : String;
      Append  : Boolean) return Awk_CLI.Redirections.Write_Status
   is
   begin
      if not Context.Files.Is_Empty then
         for Position in Context.Files.First_Index .. Context.Files.Last_Index loop
            if U.To_String (Context.Files.Element (Position).Path) = Path then
               if not Context.Files.Element (Position).Openable then
                  return Awk_CLI.Redirections.Open_Failed;
               end if;
               if not Context.Files.Element (Position).Writable then
                  return Awk_CLI.Redirections.Write_Failed;
               end if;
               if Append then
                  Context.Files.Replace_Element
                    (Position,
                     Virtual_File'
                       (Path     => Context.Files.Element (Position).Path,
                        Content  => Context.Files.Element (Position).Content
                          & U.To_Unbounded_String (Content),
                        Readable => Context.Files.Element (Position).Readable,
                        Writable => Context.Files.Element (Position).Writable,
                        Openable => Context.Files.Element (Position).Openable));
               else
                  Context.Files.Replace_Element
                    (Position,
                     Virtual_File'
                       (Path     => Context.Files.Element (Position).Path,
                        Content  => U.To_Unbounded_String (Content),
                        Readable => Context.Files.Element (Position).Readable,
                        Writable => Context.Files.Element (Position).Writable,
                        Openable => Context.Files.Element (Position).Openable));
               end if;
               Context.Writes.Append
                 (Write_Operation'
                    (Path => U.To_Unbounded_String (Path),
                     Content => U.To_Unbounded_String (Content),
                     Append => Append));
               if Context.Use_Process then
                  if Awk_CLI.Platform.Write_File (Path, Content, Append) then
                     return Awk_CLI.Redirections.Write_Success;
                  else
                     return Awk_CLI.Redirections.Write_Failed;
                  end if;
               end if;
               return Awk_CLI.Redirections.Write_Success;
            end if;
         end loop;
      end if;

      Context.Files.Append
        (Virtual_File'
           (Path     => U.To_Unbounded_String (Path),
            Content  => U.To_Unbounded_String (Content),
            Readable => True,
            Writable => True,
            Openable => True));
      Context.Writes.Append
        (Write_Operation'
           (Path => U.To_Unbounded_String (Path),
            Content => U.To_Unbounded_String (Content),
            Append => Append));
      if Context.Use_Process then
         if Awk_CLI.Platform.Write_File (Path, Content, Append) then
            return Awk_CLI.Redirections.Write_Success;
         else
            return Awk_CLI.Redirections.Write_Failed;
         end if;
      end if;
      return Awk_CLI.Redirections.Write_Success;
   end Write_Context_File;

   function Write_Context_Stdout
     (Context : in out Invocation_Context;
      Content : String) return Boolean
   is
   begin
      if Context.Stdout_Fails then
         return False;
      end if;
      U.Append (Context.Standard_Out, Content);
      if Context.Use_Process then
         return Awk_CLI.Platform.Write_Standard_Output (Content);
      end if;
      return True;
   end Write_Context_Stdout;

   procedure Initialize
     (State    : out Live_Input_State;
      Context  : in out Invocation_Context;
      Operands : aliased Awk_CLI.Operands.Operand_Vectors.Vector) is
   begin
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
      if Context.Use_Process then
         return Result;
      end if;

      for File of Context.Files loop
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

      if State.Context.Stdin_Fails then
         State.Active := False;
         return Awk_CLI.Platform.Read_Failed;
      elsif State.Context.Use_Process then
         State.Active_Process := True;
         return Awk_CLI.Platform.Open_Standard_Input (State.Process_Stream);
      else
         State.Active_Content := State.Context.Standard_In;
         return Awk_CLI.Platform.Read_Success;
      end if;
   end Activate_Standard_Input;

   function Activate_Named_Input
     (State : in out Live_Input_State;
      Path  : String) return Awk_CLI.Platform.Read_Status
   is
   begin
      State.Active := True;
      State.Active_Process := False;
      State.Active_Name := U.To_Unbounded_String (Path);
      State.Active_Content := U.Null_Unbounded_String;
      State.Active_Position := 1;

      for File of State.Context.Files loop
         if U.To_String (File.Path) = Path then
            if not File.Openable then
               State.Active := False;
               return Awk_CLI.Platform.Open_Failed;
            elsif not File.Readable then
               State.Active := False;
               return Awk_CLI.Platform.Read_Failed;
            else
               State.Active_Content := File.Content;
               return Awk_CLI.Platform.Read_Success;
            end if;
         end if;
      end loop;

      if State.Context.Use_Process then
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
            Content : constant String := U.To_String (State.Active_Content);
         begin
            Text := U.To_Unbounded_String (Content (State.Active_Position .. Last));
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
      return Write_Context_Stdout (State.Context.all, Content);
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
      return Write_Context_File (State.Context.all, Path, Content, Append);
   end Write_Redirection;

   function Read_Command
     (User_Data : System.Address;
      Command   : String;
      Output    : out U.Unbounded_String) return Boolean
   is
      State : constant State_Access.Object_Pointer :=
        State_Access.To_Pointer (User_Data);
   begin
      for Item of State.Context.Commands loop
         if U.To_String (Item.Command) = Command then
            Output := Item.Output;
            return True;
         end if;
      end loop;

      if State.Context.Use_Process then
         return Awk_CLI.Platform.Run_Command (Command, Output);
      end if;

      Output := U.Null_Unbounded_String;
      return False;
   end Read_Command;
end Awk_CLI.Inputs.Live;
