with Awk_CLI.Diagnostics;
with Awk_CLI.Environment;
with Awk_CLI.Execution;
with Awk_CLI.Inputs;
with Awk_CLI.Localization;
with Awk_CLI.Operands;
with Awk_CLI.Options;
with Awk_CLI.Output;
with Awk_CLI.Platform;
with Awk_CLI.Programs;
with Awk_CLI.Redirections;
with System;
with System.Address_To_Access_Conversions;

package body Awk_CLI is
   package D renames Awk_CLI.Diagnostics;
   use type U.Unbounded_String;
   use type Awk_CLI.Operands.Operand_Kind;
   use type Awk_CLI.Platform.Read_Status;

   package Context_Access is new System.Address_To_Access_Conversions (Invocation_Context);
   Chunk_Size : constant Natural := 8192;

   type Operand_Vector_Access is access constant Awk_CLI.Operands.Operand_Vectors.Vector;

   type Live_Input_State is limited record
      Context            : Context_Access.Object_Pointer;
      Operands           : Operand_Vector_Access;
      Has_Explicit_Input : Boolean := False;
      Operand_Index      : Natural := 0;
      Implicit_Stdin_Used : Boolean := False;
      Active             : Boolean := False;
      Active_Process     : Boolean := False;
      Active_Name        : U.Unbounded_String;
      Active_Content     : U.Unbounded_String;
      Active_Position    : Natural := 1;
      Active_Empty_Sent  : Boolean := False;
      Process_Stream     : Awk_CLI.Platform.Input_Stream;
   end record;

   package Live_Input_Access is new System.Address_To_Access_Conversions (Live_Input_State);

   procedure Clear (Context : in out Invocation_Context) is
   begin
      Context.Arguments.Clear;
      Context.Standard_In := U.Null_Unbounded_String;
      Context.Locale := U.To_Unbounded_String ("en");
      Context.Catalog_Path := U.To_Unbounded_String ("resources/messages/catalog.txt");
      Context.Files.Clear;
      Context.Commands.Clear;
      Context.Environment.Clear;
      Context.Standard_Out := U.Null_Unbounded_String;
      Context.Standard_Err := U.Null_Unbounded_String;
      Context.Diagnostic_Set := False;
      Context.Diagnostic_Id := U.Null_Unbounded_String;
      Context.Diagnostic_Category := U.Null_Unbounded_String;
      Context.Diagnostic_Severity := U.Null_Unbounded_String;
      Context.Writes.Clear;
      Context.Use_Process := False;
      Context.Stdin_Fails := False;
      Context.Stdout_Fails := False;
      Context.Stderr_Fails := False;
   end Clear;

   procedure Initialize_From_Process (Context : in out Invocation_Context) is
   begin
      Clear (Context);
      for Argument of Awk_CLI.Platform.Process_Arguments loop
         Context.Arguments.Append (Argument);
      end loop;
      Context.Locale := U.To_Unbounded_String (Awk_CLI.Platform.Locale);
      Context.Catalog_Path := U.To_Unbounded_String (Awk_CLI.Platform.Catalog_Path);
      Context.Use_Process := True;
   end Initialize_From_Process;

   procedure Add_Argument (Context : in out Invocation_Context; Value : String) is
   begin
      Context.Arguments.Append (U.To_Unbounded_String (Value));
   end Add_Argument;

   procedure Set_Standard_Input (Context : in out Invocation_Context; Value : String) is
   begin
      Context.Standard_In := U.To_Unbounded_String (Value);
   end Set_Standard_Input;

   procedure Set_Locale (Context : in out Invocation_Context; Value : String) is
   begin
      Context.Locale := U.To_Unbounded_String (Value);
   end Set_Locale;

   procedure Set_Catalog_Path (Context : in out Invocation_Context; Value : String) is
   begin
      Context.Catalog_Path := U.To_Unbounded_String (Value);
   end Set_Catalog_Path;

   procedure Add_File
     (Context : in out Invocation_Context;
      Path    : String;
      Content : String;
      Readable : Boolean := True;
      Writable : Boolean := True;
      Openable : Boolean := True) is
   begin
      Context.Files.Append
        (Virtual_File'
           (Path     => U.To_Unbounded_String (Path),
            Content  => U.To_Unbounded_String (Content),
            Readable => Readable,
            Writable => Writable,
            Openable => Openable));
   end Add_File;

   procedure Add_Command_Output
     (Context : in out Invocation_Context;
      Command : String;
      Output  : String) is
   begin
      Context.Commands.Append
        (Command_Output'
           (Command => U.To_Unbounded_String (Command),
            Output  => U.To_Unbounded_String (Output)));
   end Add_Command_Output;

   procedure Add_Environment
     (Context : in out Invocation_Context;
      Name    : String;
      Value   : String) is
   begin
      Context.Environment.Append
        (Env_Item'(Name => U.To_Unbounded_String (Name),
                   Value => U.To_Unbounded_String (Value)));
   end Add_Environment;

   procedure Fail_Standard_Output (Context : in out Invocation_Context; Enabled : Boolean) is
   begin
      Context.Stdout_Fails := Enabled;
   end Fail_Standard_Output;

   procedure Fail_Standard_Error (Context : in out Invocation_Context; Enabled : Boolean) is
   begin
      Context.Stderr_Fails := Enabled;
   end Fail_Standard_Error;

   procedure Fail_Standard_Input (Context : in out Invocation_Context; Enabled : Boolean) is
   begin
      Context.Stdin_Fails := Enabled;
   end Fail_Standard_Input;

   function Standard_Output (Context : Invocation_Context) return String is
     (U.To_String (Context.Standard_Out));

   function Standard_Error (Context : Invocation_Context) return String is
     (U.To_String (Context.Standard_Err));

   function Has_Diagnostic (Context : Invocation_Context) return Boolean is
     (Context.Diagnostic_Set);

   function Last_Diagnostic_Message_Id (Context : Invocation_Context) return String is
     (U.To_String (Context.Diagnostic_Id));

   function Last_Diagnostic_Category (Context : Invocation_Context) return String is
     (U.To_String (Context.Diagnostic_Category));

   function Last_Diagnostic_Severity (Context : Invocation_Context) return String is
     (U.To_String (Context.Diagnostic_Severity));

   function Written_File_Count (Context : Invocation_Context) return Natural is
     (Natural (Context.Writes.Length));

   function Written_File_Name (Context : Invocation_Context; Index : Positive) return String is
     (U.To_String (Context.Writes.Element (Index).Path));

   function Written_File_Content (Context : Invocation_Context; Index : Positive) return String is
     (U.To_String (Context.Writes.Element (Index).Content));

   function Written_File_Append (Context : Invocation_Context; Index : Positive) return Boolean is
     (Context.Writes.Element (Index).Append);

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

   function Activate_Standard_Input (State : in out Live_Input_State) return Awk_CLI.Platform.Read_Status is
   begin
      State.Active := True;
      State.Active_Process := False;
      State.Active_Name := U.To_Unbounded_String ("-");
      State.Active_Content := U.Null_Unbounded_String;
      State.Active_Position := 1;
      State.Active_Empty_Sent := False;

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
      State.Active_Empty_Sent := False;

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

   function Live_Context_Input
     (User_Data    : System.Address;
      Operand_Index : Positive;
      Filename     : out U.Unbounded_String;
      Text         : out U.Unbounded_String;
      End_Of_Input : out Boolean) return Awk_CLI.Platform.Read_Status
   is
      State : constant Live_Input_Access.Object_Pointer :=
        Live_Input_Access.To_Pointer (User_Data);
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
                           State.Active_Empty_Sent := False;
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
            Status :=
              Read_Active_In_Memory
                (State.all, Filename, Text, End_Of_Input);
            if Status /= Awk_CLI.Platform.Read_Success or else U.Length (Text) > 0 then
               return Status;
            elsif Filename /= U.Null_Unbounded_String and then not State.Active then
               return Awk_CLI.Platform.Read_Success;
            end if;
         end if;
      end loop;
   end Live_Context_Input;

   function Live_State_Output
     (User_Data : System.Address;
      Content   : String) return Boolean
   is
      State : constant Live_Input_Access.Object_Pointer :=
        Live_Input_Access.To_Pointer (User_Data);
   begin
      return Write_Context_Stdout (State.Context.all, Content);
   end Live_State_Output;

   function Live_State_Redirection
     (User_Data : System.Address;
      Path      : String;
      Content   : String;
      Append    : Boolean) return Awk_CLI.Redirections.Write_Status
   is
      State : constant Live_Input_Access.Object_Pointer :=
        Live_Input_Access.To_Pointer (User_Data);
   begin
      return Write_Context_File (State.Context.all, Path, Content, Append);
   end Live_State_Redirection;

   function Live_State_Command
     (User_Data : System.Address;
      Command   : String;
      Output    : out U.Unbounded_String) return Boolean
   is
      State : constant Live_Input_Access.Object_Pointer :=
        Live_Input_Access.To_Pointer (User_Data);
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
   end Live_State_Command;

   function Run (Context : in out Invocation_Context) return Exit_Code is
      Catalog : Awk_CLI.Localization.Catalog;

      function Parsed_Arguments return Awk_CLI.Options.String_Vectors.Vector is
         Result : Awk_CLI.Options.String_Vectors.Vector;
      begin
         for Argument of Context.Arguments loop
            Result.Append (Argument);
         end loop;
         return Result;
      end Parsed_Arguments;

      function Read_Context_File
        (Path : String;
         Content : out U.Unbounded_String) return Awk_CLI.Platform.Read_Status
      is
      begin
         for File of Context.Files loop
            if U.To_String (File.Path) = Path then
               if not File.Openable then
                  Content := U.Null_Unbounded_String;
                  return Awk_CLI.Platform.Open_Failed;
               elsif not File.Readable then
                  Content := U.Null_Unbounded_String;
                  return Awk_CLI.Platform.Read_Failed;
               else
                  Content := File.Content;
                  return Awk_CLI.Platform.Read_Success;
               end if;
            end if;
         end loop;

         if Context.Use_Process then
            return Awk_CLI.Platform.Read_File (Path, Content);
         end if;

         Content := U.Null_Unbounded_String;
         return Awk_CLI.Platform.Open_Failed;
      end Read_Context_File;

      function Write_Context_Stderr (Content : String) return Boolean is
      begin
         if Context.Stderr_Fails then
            return False;
         end if;
         U.Append (Context.Standard_Err, Content);
         if Context.Use_Process then
            return Awk_CLI.Platform.Write_Standard_Error (Content);
         end if;
         return True;
      end Write_Context_Stderr;

      function Current_Environment return Awk_CLI.Environment.Entry_Vectors.Vector is
         Result : Awk_CLI.Environment.Entry_Vectors.Vector;
      begin
         if Context.Use_Process and then Context.Environment.Is_Empty then
            return Awk_CLI.Environment.Collect;
         end if;

         for Item of Context.Environment loop
            Result.Append
              (Awk_CLI.Environment.Env_Entry'
                 (Name => Item.Name, Value => Item.Value));
         end loop;
         return Awk_CLI.Environment.Normalize (Result);
      end Current_Environment;

      function Auxiliary_Files return Awk_CLI.Inputs.Input_File_Vectors.Vector is
         Result : Awk_CLI.Inputs.Input_File_Vectors.Vector;
      begin
         if Context.Use_Process then
            return Result;
         end if;

         for File of Context.Files loop
            if File.Openable and then File.Readable then
               Result.Append
                 (Awk_CLI.Inputs.Input_File'
                    (Name => File.Path, Content => File.Content));
            end if;
         end loop;
         return Result;
      end Auxiliary_Files;

      function Emit_Diagnostic (Item : D.Diagnostic) return Exit_Code is
      begin
         Context.Diagnostic_Set := True;
         Context.Diagnostic_Id := Item.Message_Id;
         Context.Diagnostic_Category := U.To_Unbounded_String (D.Diagnostic_Category'Image (Item.Category));
         Context.Diagnostic_Severity := U.To_Unbounded_String (D.Diagnostic_Severity'Image (Item.Severity));
         if not Write_Context_Stderr (Awk_CLI.Output.Diagnostic_Text (Catalog, Item)) then
            return Exit_Code (D.IO_Exit);
         end if;
         return Exit_Code (D.Status_For (Item));
      end Emit_Diagnostic;

      Parsed : constant Awk_CLI.Options.Parse_Result :=
        Awk_CLI.Options.Parse (Parsed_Arguments);
   begin
      Awk_CLI.Localization.Initialize
        (Catalog, U.To_String (Context.Catalog_Path), U.To_String (Context.Locale));

      if not Parsed.Ok then
         return Emit_Diagnostic (Parsed.Diagnostic);
      end if;

      Awk_CLI.Output.Set_Color (Parsed.Options.Color);

      if Parsed.Options.Help_Requested then
         if Write_Context_Stdout (Context, Awk_CLI.Output.Help (Catalog)) then
            return Exit_Code (D.Success_Exit);
         else
            return Exit_Code (D.IO_Exit);
         end if;
      elsif Parsed.Options.Version_Requested then
         if Write_Context_Stdout (Context, Awk_CLI.Output.Version (Catalog)) then
            return Exit_Code (D.Success_Exit);
         else
            return Exit_Code (D.IO_Exit);
         end if;
      end if;

      declare
         Source_Result : constant Awk_CLI.Programs.Resolve_Result :=
           Awk_CLI.Programs.Resolve (Parsed.Options, Read_Context_File'Access);
      begin
         if not Source_Result.Ok then
            return Emit_Diagnostic (Source_Result.Diagnostic);
         end if;

         declare
            Classified : aliased constant Awk_CLI.Operands.Operand_Vectors.Vector :=
              Awk_CLI.Operands.Classify (Source_Result.Source.Operands);
            Has_Explicit_Input : Boolean := False;
         begin
            for Item of Classified loop
               if Item.Kind = Awk_CLI.Operands.Named_File
                 or else Item.Kind = Awk_CLI.Operands.Standard_Input
               then
                  Has_Explicit_Input := True;
               end if;
            end loop;

            declare
               Input_State : aliased Live_Input_State :=
                 (Context => Context_Access.To_Pointer (Context'Address),
                  Operands => Classified'Unchecked_Access,
                  Has_Explicit_Input => Has_Explicit_Input,
                  Operand_Index => 0,
                  Implicit_Stdin_Used => False,
                  Active => False,
                  Active_Process => False,
                  Active_Name => U.Null_Unbounded_String,
                  Active_Content => U.Null_Unbounded_String,
                  Active_Position => 1,
                  Active_Empty_Sent => False,
                  Process_Stream => <>);
               Exec_Result : constant Awk_CLI.Execution.Execution_Result :=
                 Awk_CLI.Execution.Execute_Live_Input
                   (U.To_String (Source_Result.Source.Text),
                    Parsed.Options, Classified, Current_Environment,
                    Live_Context_Input'Access,
                    Live_State_Output'Access,
                    Live_State_Redirection'Access,
                    Read_Command => Live_State_Command'Access,
                    User_Data => Input_State'Address,
                    Auxiliary_Files => Auxiliary_Files);
            begin
               Awk_CLI.Platform.Close_Input (Input_State.Process_Stream);
               if not Exec_Result.Ok then
                  return Emit_Diagnostic (Exec_Result.Diagnostic);
               end if;

               if Exec_Result.Exit_Status < 0 or else Exec_Result.Exit_Status > 255 then
                  return Exit_Code (D.Interpreter_Exit);
               else
                  return Exit_Code (Exec_Result.Exit_Status);
               end if;
            end;
         end;
      end;
   exception
      when others =>
         return Exit_Code (D.Internal_Exit);
   end Run;
end Awk_CLI;
