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

package body Awk_CLI is
   package D renames Awk_CLI.Diagnostics;
   use type U.Unbounded_String;

   procedure Clear (Context : in out Invocation_Context) is
   begin
      Context.Arguments.Clear;
      Context.Standard_In := U.Null_Unbounded_String;
      Context.Locale := U.To_Unbounded_String ("en");
      Context.Catalog_Path := U.To_Unbounded_String ("resources/messages/catalog.txt");
      Context.Files.Clear;
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

      function Write_Context_File
        (Path : String;
         Content : String;
         Append : Boolean) return Awk_CLI.Redirections.Write_Status
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

      function Write_Context_Stdout (Content : String) return Boolean is
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

      function Current_Stdin (Content : out U.Unbounded_String) return Boolean is
      begin
         if Context.Stdin_Fails then
            Content := U.Null_Unbounded_String;
            return False;
         end if;

         if Context.Use_Process then
            Content := Awk_CLI.Platform.Read_Standard_Input;
         else
            Content := Context.Standard_In;
         end if;
         return True;
      end Current_Stdin;

      function Requires_Stdin
        (Operands : Awk_CLI.Operands.Operand_Vectors.Vector) return Boolean
      is
         Has_Named_Input : Boolean := False;
      begin
         if Operands.Is_Empty then
            return True;
         end if;

         for Item of Operands loop
            case Item.Kind is
               when Awk_CLI.Operands.Standard_Input =>
                  return True;
               when Awk_CLI.Operands.Named_File =>
                  Has_Named_Input := True;
               when Awk_CLI.Operands.Runtime_Assignment =>
                  null;
            end case;
         end loop;

         return not Has_Named_Input;
      end Requires_Stdin;

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
         if Write_Context_Stdout (Awk_CLI.Output.Help (Catalog)) then
            return Exit_Code (D.Success_Exit);
         else
            return Exit_Code (D.IO_Exit);
         end if;
      elsif Parsed.Options.Version_Requested then
         if Write_Context_Stdout (Awk_CLI.Output.Version (Catalog)) then
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
            Classified : constant Awk_CLI.Operands.Operand_Vectors.Vector :=
              Awk_CLI.Operands.Classify (Source_Result.Source.Operands);
            Stdin_Content : U.Unbounded_String;
         begin
            if Requires_Stdin (Classified)
              and then not Current_Stdin (Stdin_Content)
            then
               return Emit_Diagnostic
                 (D.Make ("awk.standard_input.read_failed", D.Error, D.Input));
            end if;

            declare
               Input_Result : constant Awk_CLI.Inputs.Load_Result :=
                 Awk_CLI.Inputs.Load
                   (Classified, U.To_String (Stdin_Content), Read_Context_File'Access);
            begin
            if not Input_Result.Ok then
               return Emit_Diagnostic (Input_Result.Diagnostic);
            end if;

            declare
               Exec_Result : constant Awk_CLI.Execution.Execution_Result :=
                 Awk_CLI.Execution.Execute
                   (U.To_String (Source_Result.Source.Text),
                    Parsed.Options, Classified, Input_Result.Files, Current_Environment);
            begin
               if not Exec_Result.Ok then
                  return Emit_Diagnostic (Exec_Result.Diagnostic);
               end if;

               declare
                  Redir_Result : constant Awk_CLI.Redirections.Materialize_Result :=
                    Awk_CLI.Redirections.Materialize
                      (Exec_Result.Redirections, Write_Context_File'Access);
               begin
                  if not Redir_Result.Ok then
                     return Emit_Diagnostic (Redir_Result.Diagnostic);
                  end if;
               end;

               if not Write_Context_Stdout (U.To_String (Exec_Result.Standard_Output)) then
                  return Emit_Diagnostic
                    (D.Make ("awk.standard_output.write_failed", D.Error, D.Output));
               end if;

               if Exec_Result.Exit_Status < 0 or else Exec_Result.Exit_Status > 255 then
                  return Exit_Code (D.Interpreter_Exit);
               else
                  return Exit_Code (Exec_Result.Exit_Status);
               end if;
            end;
            end;
         end;
      end;
   exception
      when others =>
         return Exit_Code (D.Internal_Exit);
   end Run;
end Awk_CLI;
