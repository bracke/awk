with Ada.Command_Line;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Streams.Stream_IO;
with Ada.Text_IO;

package body Awk_CLI.Platform is
   package SIO renames Ada.Streams.Stream_IO;
   use type SIO.Count;

   function Process_Arguments return Awk_CLI.Options.String_Vectors.Vector is
      Result : Awk_CLI.Options.String_Vectors.Vector;
   begin
      for Index in 1 .. Ada.Command_Line.Argument_Count loop
         Result.Append (U.To_Unbounded_String (Ada.Command_Line.Argument (Index)));
      end loop;
      return Result;
   end Process_Arguments;

   function Read_Standard_Input return U.Unbounded_String is
      Result : U.Unbounded_String;
   begin
      while not Ada.Text_IO.End_Of_File loop
         U.Append (Result, Ada.Text_IO.Get_Line);
         if not Ada.Text_IO.End_Of_File then
            U.Append (Result, ASCII.LF);
         end if;
      end loop;
      return Result;
   exception
      when others =>
         return U.Null_Unbounded_String;
   end Read_Standard_Input;

   function Read_File (Path : String; Content : out U.Unbounded_String) return Read_Status is
      File   : SIO.File_Type;
      Size   : Ada.Streams.Stream_IO.Count;
      Opened : Boolean := False;
   begin
      Content := U.Null_Unbounded_String;
      if not Ada.Directories.Exists (Path) then
         return Open_Failed;
      end if;
      SIO.Open (File, SIO.In_File, Path);
      Opened := True;
      Size := SIO.Size (File);
      if Size > 0 then
         declare
            Buffer : Ada.Streams.Stream_Element_Array (1 .. Ada.Streams.Stream_Element_Offset (Size));
            Last   : Ada.Streams.Stream_Element_Offset;
            Text   : String (1 .. Natural (Size));
         begin
            SIO.Read (File, Buffer, Last);
            for Index in 1 .. Natural (Last) loop
               Text (Index) := Character'Val (Buffer (Ada.Streams.Stream_Element_Offset (Index)));
            end loop;
            Content := U.To_Unbounded_String (Text (1 .. Natural (Last)));
         end;
      end if;
      SIO.Close (File);
      return Read_Success;
   exception
      when others =>
         if SIO.Is_Open (File) then
            SIO.Close (File);
         end if;
         Content := U.Null_Unbounded_String;
         return (if Opened then Read_Failed else Open_Failed);
   end Read_File;

   function Write_File (Path : String; Content : String; Append : Boolean) return Boolean is
      File : SIO.File_Type;
      Mode : constant SIO.File_Mode := (if Append then SIO.Append_File else SIO.Out_File);
   begin
      if Append and then Ada.Directories.Exists (Path) then
         SIO.Open (File, Mode, Path);
      else
         SIO.Create (File, SIO.Out_File, Path);
      end if;
      declare
         Buffer : Ada.Streams.Stream_Element_Array (1 .. Content'Length);
      begin
         for Index in Content'Range loop
            Buffer (Ada.Streams.Stream_Element_Offset (Index - Content'First + 1)) :=
              Ada.Streams.Stream_Element (Character'Pos (Content (Index)));
         end loop;
         if Content'Length > 0 then
            SIO.Write (File, Buffer);
         end if;
      end;
      SIO.Close (File);
      return True;
   exception
      when others =>
         if SIO.Is_Open (File) then
            SIO.Close (File);
         end if;
         return False;
   end Write_File;

   function Write_Standard_Output (Content : String) return Boolean is
   begin
      Ada.Text_IO.Put (Content);
      return True;
   exception
      when others =>
         return False;
   end Write_Standard_Output;

   function Write_Standard_Error (Content : String) return Boolean is
   begin
      Ada.Text_IO.Put (Ada.Text_IO.Standard_Error, Content);
      return True;
   exception
      when others =>
         return False;
   end Write_Standard_Error;

   function Locale return String is
   begin
      if Ada.Environment_Variables.Exists ("LC_ALL") and then Ada.Environment_Variables.Value ("LC_ALL") /= "" then
         return Ada.Environment_Variables.Value ("LC_ALL");
      elsif Ada.Environment_Variables.Exists ("LANG") and then Ada.Environment_Variables.Value ("LANG") /= "" then
         return Ada.Environment_Variables.Value ("LANG");
      else
         return "en";
      end if;
   exception
      when others =>
         return "en";
   end Locale;

   function Catalog_Path return String is
   begin
      if Ada.Directories.Exists ("resources/messages/catalog.txt") then
         return "resources/messages/catalog.txt";
      else
         return "../resources/messages/catalog.txt";
      end if;
   end Catalog_Path;
end Awk_CLI.Platform;
