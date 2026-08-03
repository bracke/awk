with Ada.Command_Line;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.IO_Exceptions;
with Interfaces.C_Streams;
with System;
with Hostkit;
with Hostkit.Fs;
with Hostkit.Host;
with Hostkit.Process;
with Hostkit.Shell;

package body Awk_CLI.Platform is
   use type Ada.Streams.Stream_Element_Offset;

   package Byte_IO is
      Chunk_Size : constant Ada.Streams.Stream_Element_Offset := 8192;

      function To_String
        (Buffer : Ada.Streams.Stream_Element_Array;
         Last   : Ada.Streams.Stream_Element_Offset) return String;
   end Byte_IO;

   package body Byte_IO is
      function To_String
        (Buffer : Ada.Streams.Stream_Element_Array;
         Last   : Ada.Streams.Stream_Element_Offset) return String
      is
      begin
         if Last < Buffer'First then
            return "";
         end if;

         declare
            Text : String (1 .. Natural (Last - Buffer'First + 1));
         begin
            for Index in Text'Range loop
               Text (Index) :=
                 Character'Val
                   (Buffer
                      (Buffer'First
                       + Ada.Streams.Stream_Element_Offset (Index - Text'First)));
            end loop;
            return Text;
         end;
      end To_String;
   end Byte_IO;

   function Join (Directory, Name : String) return String is
     (Ada.Directories.Compose (Containing_Directory => Directory, Name => Name));

   procedure Delete_If_Present (Path : String) is
   begin
      if Path /= "" and then Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   exception
      when Ada.Directories.Name_Error | Ada.Directories.Use_Error =>
         null;
   end Delete_If_Present;

   procedure Delete_Tree_If_Present (Path : String) is
   begin
      if Path /= "" and then Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_Tree (Path);
      end if;
   exception
      when Ada.Directories.Name_Error | Ada.Directories.Use_Error =>
         null;
   end Delete_Tree_If_Present;

   function Process_Arguments return Awk_CLI.Options.String_Vectors.Vector is
      Result : Awk_CLI.Options.String_Vectors.Vector;
   begin
      for Index in 1 .. Ada.Command_Line.Argument_Count loop
         Result.Append (U.To_Unbounded_String (Ada.Command_Line.Argument (Index)));
      end loop;
      return Result;
   end Process_Arguments;

   function Process_Environment return Awk_CLI.Environment.Entry_Vectors.Vector is
      Result : Awk_CLI.Environment.Entry_Vectors.Vector;

      procedure Add (Name, Value : String) is
      begin
         Result.Append
           (Awk_CLI.Environment.Env_Entry'
              (Name  => U.To_Unbounded_String (Name),
               Value => U.To_Unbounded_String (Value)));
      end Add;
   begin
      Ada.Environment_Variables.Iterate (Add'Access);
      return Awk_CLI.Environment.Normalize (Result);
   exception
      when Constraint_Error | Program_Error | Storage_Error =>
         return Awk_CLI.Environment.Normalize (Result);
   end Process_Environment;

   package File_IO is
      function Read_File
        (Path    : String;
         Content : out U.Unbounded_String) return Read_Status;

      function Write_File
        (Path    : String;
         Content : String;
         Append  : Boolean) return Boolean;
   end File_IO;

   package body File_IO is separate;

   package Input_Streams is
      function Open_File
        (Path   : String;
         Stream : in out Input_Stream) return Read_Status;

      function Open_Standard_Input
        (Stream : in out Input_Stream) return Read_Status;

      function Read_Chunk
        (Stream      : in out Input_Stream;
         Content     : out U.Unbounded_String;
         End_Of_File : out Boolean) return Read_Status;

      procedure Close (Stream : in out Input_Stream);
   end Input_Streams;

   package body Input_Streams is separate;

   function Read_File (Path : String; Content : out U.Unbounded_String) return Read_Status is
   begin
      return File_IO.Read_File (Path, Content);
   end Read_File;

   function Open_Input_File (Path : String; Stream : in out Input_Stream) return Read_Status is
   begin
      return Input_Streams.Open_File (Path, Stream);
   end Open_Input_File;

   function Open_Standard_Input (Stream : in out Input_Stream) return Read_Status is
   begin
      return Input_Streams.Open_Standard_Input (Stream);
   end Open_Standard_Input;

   function Read_Input_Chunk
     (Stream : in out Input_Stream;
      Content : out U.Unbounded_String;
      End_Of_File : out Boolean) return Read_Status
   is
   begin
      return Input_Streams.Read_Chunk (Stream, Content, End_Of_File);
   end Read_Input_Chunk;

   procedure Close_Input (Stream : in out Input_Stream) is
   begin
      Input_Streams.Close (Stream);
   end Close_Input;

   function Write_File (Path : String; Content : String; Append : Boolean) return Boolean is
   begin
      return File_IO.Write_File (Path, Content, Append);
   end Write_File;

   package Command_Execution is
      function Run_Command
        (Command : String;
         Output  : out U.Unbounded_String) return Boolean;
   end Command_Execution;

   package body Command_Execution is separate;

   function Run_Command (Command : String; Output : out U.Unbounded_String) return Boolean is
   begin
      return Command_Execution.Run_Command (Command, Output);
   end Run_Command;

   package Standard_Streams is
      function Write_Output (Content : String) return Boolean;
      function Write_Error (Content : String) return Boolean;
   end Standard_Streams;

   package body Standard_Streams is
      function Write_Stream
        (Stream  : Interfaces.C_Streams.FILEs;
         Content : String) return Boolean
      is
         use type Interfaces.C_Streams.size_t;
         use type System.Address;

         Handle  : constant Interfaces.C_Streams.int :=
           Interfaces.C_Streams.fileno (Stream);
         Position  : Natural := Content'First;
         Remaining : Natural := Content'Length;
      begin
         if Stream = Interfaces.C_Streams.NULL_Stream or else Handle < 0 then
            return False;
         end if;

         Interfaces.C_Streams.set_binary_mode (Handle);

         while Remaining > 0 loop
            declare
               Written : constant Interfaces.C_Streams.size_t :=
                 Interfaces.C_Streams.fwrite
                   (Content (Position)'Address,
                    1,
                    Interfaces.C_Streams.size_t (Remaining),
                    Stream);
               Count : constant Natural := Natural (Written);
            begin
               if Count = 0 then
                  return False;
               end if;

               Position := Position + Count;
               Remaining := Remaining - Count;
            end;
         end loop;

         return Interfaces.C_Streams.fflush (Stream) = 0;
      exception
         when Constraint_Error | Program_Error | Storage_Error =>
            return False;
      end Write_Stream;

      function Write_Output (Content : String) return Boolean is
      begin
         return Write_Stream (Interfaces.C_Streams.stdout, Content);
      end Write_Output;

      function Write_Error (Content : String) return Boolean is
      begin
         return Write_Stream (Interfaces.C_Streams.stderr, Content);
      end Write_Error;
   end Standard_Streams;

   function Write_Standard_Output (Content : String) return Boolean is
   begin
      return Standard_Streams.Write_Output (Content);
   end Write_Standard_Output;

   function Write_Standard_Error (Content : String) return Boolean is
   begin
      return Standard_Streams.Write_Error (Content);
   end Write_Standard_Error;

   package Host_Metadata is
      function Is_Terminal (File_Descriptor : Interfaces.C_Streams.int) return Boolean;
      function No_Color_Active return Boolean;
      function Locale return String;
      function Catalog_Path return String;
   end Host_Metadata;

   package body Host_Metadata is
      function Environment_Value_Or_Empty (Name : String) return String is
      begin
         if Ada.Environment_Variables.Exists (Name) then
            return Ada.Environment_Variables.Value (Name);
         else
            return "";
         end if;
      exception
         when Constraint_Error | Program_Error =>
            return "";
      end Environment_Value_Or_Empty;

      function Is_Terminal (File_Descriptor : Interfaces.C_Streams.int) return Boolean is
      begin
         return Interfaces.C_Streams.isatty (File_Descriptor) = 1;
      exception
         when Constraint_Error | Program_Error =>
            return False;
      end Is_Terminal;

      function No_Color_Active return Boolean is
      begin
         return Ada.Environment_Variables.Exists ("NO_COLOR");
      exception
         when Constraint_Error | Program_Error =>
            return False;
      end No_Color_Active;

      function Locale return String is
         LC_All : constant String := Environment_Value_Or_Empty ("LC_ALL");
         Lang   : constant String := Environment_Value_Or_Empty ("LANG");
         Native : constant String := Hostkit.Host.Native_Locale;
      begin
         if LC_All /= "" then
            return LC_All;
         elsif Lang /= "" then
            return Lang;
         elsif Native /= "" then
            return Native;
         else
            return "en";
         end if;
      exception
         when Constraint_Error | Program_Error =>
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
   end Host_Metadata;

   function Standard_Output_Is_Terminal return Boolean is
     (Host_Metadata.Is_Terminal (1));

   function Standard_Error_Is_Terminal return Boolean is
     (Host_Metadata.Is_Terminal (2));

   function No_Color_Active return Boolean is
     (Host_Metadata.No_Color_Active);

   function Locale return String is
     (Host_Metadata.Locale);

   function Catalog_Path return String is
     (Host_Metadata.Catalog_Path);
end Awk_CLI.Platform;
