package body Awk_CLI.Context_IO is
   use type U.Unbounded_String;

   function Read_File
     (Context : Invocation_Context;
      Path    : String;
      Content : out U.Unbounded_String) return Awk_CLI.Platform.Read_Status
   is
   begin
      for File of Context.IO.Files loop
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

      if Context.Config.Use_Process then
         return Awk_CLI.Platform.Read_File (Path, Content);
      end if;

      Content := U.Null_Unbounded_String;
      return Awk_CLI.Platform.Open_Failed;
   end Read_File;

   function Write_Standard_Output
     (Context : in out Invocation_Context;
      Content : String) return Boolean
   is
   begin
      if Context.IO.Stdout_Fails then
         return False;
      end if;

      U.Append (Context.IO.Standard_Out, Content);
      if Context.Config.Use_Process then
         return Awk_CLI.Platform.Write_Standard_Output (Content);
      end if;

      return True;
   end Write_Standard_Output;

   function Write_Standard_Error
     (Context : in out Invocation_Context;
      Content : String) return Boolean
   is
   begin
      if Context.IO.Stderr_Fails then
         return False;
      end if;

      U.Append (Context.IO.Standard_Err, Content);
      if Context.Config.Use_Process then
         return Awk_CLI.Platform.Write_Standard_Error (Content);
      end if;

      return True;
   end Write_Standard_Error;

   function Write_File
     (Context : in out Invocation_Context;
      Path    : String;
      Content : String;
      Append  : Boolean) return Awk_CLI.Redirections.Write_Status
   is
      procedure Record_Write is
      begin
         Context.IO.Writes.Append
           (Write_Operation'
              (Path    => U.To_Unbounded_String (Path),
               Content => U.To_Unbounded_String (Content),
               Append  => Append));
      end Record_Write;

      procedure Add_New_Virtual_File is
      begin
         Context.IO.Files.Append
           (Virtual_File'
              (Path     => U.To_Unbounded_String (Path),
               Content  => U.To_Unbounded_String (Content),
               Readable => True,
               Writable => True,
               Openable => True));
         Record_Write;
      end Add_New_Virtual_File;

      procedure Update_Virtual_File (Position : Positive) is
      begin
         if Append then
            Context.IO.Files.Replace_Element
              (Position,
               Virtual_File'
                 (Path     => Context.IO.Files.Element (Position).Path,
                  Content  => Context.IO.Files.Element (Position).Content
                    & U.To_Unbounded_String (Content),
                  Readable => Context.IO.Files.Element (Position).Readable,
                  Writable => Context.IO.Files.Element (Position).Writable,
                  Openable => Context.IO.Files.Element (Position).Openable));
         else
            Context.IO.Files.Replace_Element
              (Position,
               Virtual_File'
                 (Path     => Context.IO.Files.Element (Position).Path,
                  Content  => U.To_Unbounded_String (Content),
                  Readable => Context.IO.Files.Element (Position).Readable,
                  Writable => Context.IO.Files.Element (Position).Writable,
                  Openable => Context.IO.Files.Element (Position).Openable));
         end if;

         Record_Write;
      end Update_Virtual_File;
   begin
      if not Context.IO.Files.Is_Empty then
         for Position in Context.IO.Files.First_Index .. Context.IO.Files.Last_Index loop
            if U.To_String (Context.IO.Files.Element (Position).Path) = Path then
               if not Context.IO.Files.Element (Position).Openable then
                  return Awk_CLI.Redirections.Open_Failed;
               end if;
               if not Context.IO.Files.Element (Position).Writable then
                  return Awk_CLI.Redirections.Write_Failed;
               end if;

               if Context.Config.Use_Process then
                  if Awk_CLI.Platform.Write_File (Path, Content, Append) then
                     Update_Virtual_File (Position);
                     return Awk_CLI.Redirections.Write_Success;
                  else
                     return Awk_CLI.Redirections.Write_Failed;
                  end if;
               end if;

               Update_Virtual_File (Position);
               return Awk_CLI.Redirections.Write_Success;
            end if;
         end loop;
      end if;

      if Context.Config.Use_Process then
         if Awk_CLI.Platform.Write_File (Path, Content, Append) then
            Add_New_Virtual_File;
            return Awk_CLI.Redirections.Write_Success;
         else
            return Awk_CLI.Redirections.Write_Failed;
         end if;
      end if;

      Add_New_Virtual_File;
      return Awk_CLI.Redirections.Write_Success;
   end Write_File;

   function Current_Environment
     (Context : Invocation_Context) return Awk_CLI.Environment.Entry_Vectors.Vector
   is
      Result : Awk_CLI.Environment.Entry_Vectors.Vector;
   begin
      if Context.Config.Use_Process and then Context.IO.Environment.Is_Empty then
         return Awk_CLI.Platform.Process_Environment;
      end if;

      for Item of Context.IO.Environment loop
         Result.Append
           (Awk_CLI.Environment.Env_Entry'
              (Name => Item.Name, Value => Item.Value));
      end loop;

      return Awk_CLI.Environment.Normalize (Result);
   end Current_Environment;
end Awk_CLI.Context_IO;
