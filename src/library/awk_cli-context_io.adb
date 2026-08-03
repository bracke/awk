with Awk_CLI.Platform;

package body Awk_CLI.Context_IO is
   use type U.Unbounded_String;

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
end Awk_CLI.Context_IO;
