package body Awk_CLI.Context_IO is
   use type U.Unbounded_String;

   function Read_File
     (Context : Invocation_Context;
      Path    : String;
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
   end Read_File;

   function Write_Standard_Output
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
   end Write_Standard_Output;

   function Write_Standard_Error
     (Context : in out Invocation_Context;
      Content : String) return Boolean
   is
   begin
      if Context.Stderr_Fails then
         return False;
      end if;

      U.Append (Context.Standard_Err, Content);
      if Context.Use_Process then
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
                    (Path    => U.To_Unbounded_String (Path),
                     Content => U.To_Unbounded_String (Content),
                     Append  => Append));

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
           (Path    => U.To_Unbounded_String (Path),
            Content => U.To_Unbounded_String (Content),
            Append  => Append));

      if Context.Use_Process then
         if Awk_CLI.Platform.Write_File (Path, Content, Append) then
            return Awk_CLI.Redirections.Write_Success;
         else
            return Awk_CLI.Redirections.Write_Failed;
         end if;
      end if;

      return Awk_CLI.Redirections.Write_Success;
   end Write_File;

   function Current_Environment
     (Context : Invocation_Context) return Awk_CLI.Environment.Entry_Vectors.Vector
   is
      Result : Awk_CLI.Environment.Entry_Vectors.Vector;
   begin
      if Context.Use_Process and then Context.Environment.Is_Empty then
         return Awk_CLI.Platform.Process_Environment;
      end if;

      for Item of Context.Environment loop
         Result.Append
           (Awk_CLI.Environment.Env_Entry'
              (Name => Item.Name, Value => Item.Value));
      end loop;

      return Awk_CLI.Environment.Normalize (Result);
   end Current_Environment;
end Awk_CLI.Context_IO;
