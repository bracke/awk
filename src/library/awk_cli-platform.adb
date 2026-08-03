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

   function Read_File (Path : String; Content : out U.Unbounded_String) return Read_Status is
      File   : SIO.File_Type;
      Opened : Boolean := False;

   begin
      Content := U.Null_Unbounded_String;
      if not Ada.Directories.Exists (Path) then
         return Open_Failed;
      end if;
      SIO.Open (File, SIO.In_File, Path);
      Opened := True;

      while not SIO.End_Of_File (File) loop
         declare
            Buffer : Ada.Streams.Stream_Element_Array (1 .. Byte_IO.Chunk_Size);
            Last   : Ada.Streams.Stream_Element_Offset;
         begin
            SIO.Read (File, Buffer, Last);
            U.Append (Content, Byte_IO.To_String (Buffer, Last));
         end;
      end loop;

      SIO.Close (File);
      return Read_Success;
   exception
      when Ada.IO_Exceptions.Name_Error
         | Ada.IO_Exceptions.Use_Error
         | Ada.IO_Exceptions.Device_Error
         | Ada.IO_Exceptions.End_Error
         | Ada.IO_Exceptions.Data_Error
         | Ada.IO_Exceptions.Status_Error
         | Ada.IO_Exceptions.Mode_Error
         | Ada.Directories.Name_Error
         | Ada.Directories.Use_Error
         | Constraint_Error
         | Storage_Error =>
         if SIO.Is_Open (File) then
            SIO.Close (File);
         end if;
         Content := U.Null_Unbounded_String;
         return (if Opened then Read_Failed else Open_Failed);
   end Read_File;

   function Open_Input_File (Path : String; Stream : in out Input_Stream) return Read_Status is
   begin
      Close_Input (Stream);
      if not Ada.Directories.Exists (Path) then
         return Open_Failed;
      end if;
      SIO.Open (Stream.File, SIO.In_File, Path);
      Stream.Opened := True;
      Stream.Is_Stdin := False;
      Stream.Stdin_Done := False;
      return Read_Success;
   exception
      when Ada.IO_Exceptions.Name_Error
         | Ada.IO_Exceptions.Use_Error
         | Ada.IO_Exceptions.Device_Error
         | Ada.IO_Exceptions.Status_Error
         | Ada.Directories.Name_Error
         | Ada.Directories.Use_Error =>
         Close_Input (Stream);
         return Open_Failed;
   end Open_Input_File;

   function Open_Standard_Input (Stream : in out Input_Stream) return Read_Status is
      use type System.Address;

      Handle : constant Interfaces.C_Streams.int :=
        Interfaces.C_Streams.fileno (Interfaces.C_Streams.stdin);
   begin
      Close_Input (Stream);
      if Interfaces.C_Streams.stdin = Interfaces.C_Streams.NULL_Stream
        or else Handle < 0
      then
         return Open_Failed;
      end if;
      Interfaces.C_Streams.set_binary_mode (Handle);
      Stream.Opened := True;
      Stream.Is_Stdin := True;
      Stream.Stdin_Done := False;
      return Read_Success;
   end Open_Standard_Input;

   function Read_Input_Chunk
     (Stream : in out Input_Stream;
      Content : out U.Unbounded_String;
      End_Of_File : out Boolean) return Read_Status
   is
   begin
      Content := U.Null_Unbounded_String;
      End_Of_File := False;

      if not Stream.Opened then
         End_Of_File := True;
         return Read_Failed;
      end if;

      if Stream.Is_Stdin then
         if Stream.Stdin_Done then
            Stream.Stdin_Done := True;
            End_Of_File := True;
            return Read_Success;
         end if;

         declare
            use type Interfaces.C_Streams.size_t;

            Text : String (1 .. Natural (Byte_IO.Chunk_Size));
            Read : constant Interfaces.C_Streams.size_t :=
              Interfaces.C_Streams.fread
                (Text (Text'First)'Address,
                 1,
                 Interfaces.C_Streams.size_t (Text'Length),
                 Interfaces.C_Streams.stdin);
         begin
            if Read = 0 then
               Stream.Stdin_Done := True;
               End_Of_File := True;
               if Interfaces.C_Streams.ferror (Interfaces.C_Streams.stdin) /= 0 then
                  return Read_Failed;
               end if;
               return Read_Success;
            end if;

            Content := U.To_Unbounded_String (Text (1 .. Natural (Read)));
            return Read_Success;
         end;
      end if;

      if SIO.End_Of_File (Stream.File) then
         End_Of_File := True;
         return Read_Success;
      end if;

      declare
         Buffer : Ada.Streams.Stream_Element_Array (1 .. Byte_IO.Chunk_Size);
         Last   : Ada.Streams.Stream_Element_Offset;
      begin
         SIO.Read (Stream.File, Buffer, Last);
         if Last < Buffer'First then
            End_Of_File := True;
            return Read_Success;
         end if;

         Content := U.To_Unbounded_String (Byte_IO.To_String (Buffer, Last));
      end;

      End_Of_File := False;
      return Read_Success;
   exception
      when Ada.IO_Exceptions.Use_Error
         | Ada.IO_Exceptions.Device_Error
         | Ada.IO_Exceptions.End_Error
         | Ada.IO_Exceptions.Data_Error
         | Ada.IO_Exceptions.Status_Error
         | Ada.IO_Exceptions.Mode_Error
         | Constraint_Error
         | Storage_Error =>
         Content := U.Null_Unbounded_String;
         End_Of_File := True;
         return Read_Failed;
   end Read_Input_Chunk;

   procedure Close_Input (Stream : in out Input_Stream) is
   begin
      if Stream.Opened and then not Stream.Is_Stdin and then SIO.Is_Open (Stream.File) then
         SIO.Close (Stream.File);
      end if;
      Stream.Opened := False;
      Stream.Is_Stdin := False;
      Stream.Stdin_Done := False;
   exception
      when Ada.IO_Exceptions.Use_Error | Ada.IO_Exceptions.Status_Error =>
         Stream.Opened := False;
         Stream.Is_Stdin := False;
         Stream.Stdin_Done := False;
   end Close_Input;

   function Run_Command (Command : String; Output : out U.Unbounded_String) return Boolean is
      --  This is the host service for awklib's command-getline callback. It is
      --  deliberately isolated here so no CLI package shells out as an AWK
      --  parser/runtime fallback.
      Args        : Hostkit.String_Vectors.Vector;
      Status      : Hostkit.Process.Process_Outcome;
      Ignored     : Integer := -1;
      Temp_Dir    : constant String :=
        Hostkit.Fs.Create_Temporary_Directory ("awk-command-getline");
      Stdin_Path  : constant String := Join (Temp_Dir, "stdin");
      Stdout_Path : constant String := Join (Temp_Dir, "stdout");
      Stderr_Path : constant String := Join (Temp_Dir, "stderr");

      procedure Cleanup is
      begin
         if Temp_Dir /= "" then
            Delete_If_Present (Stdin_Path);
            Delete_If_Present (Stdout_Path);
            Delete_If_Present (Stderr_Path);
            Delete_Tree_If_Present (Temp_Dir);
         end if;
      end Cleanup;
   begin
      Output := U.Null_Unbounded_String;

      if Temp_Dir = "" or else Hostkit.Shell.Executable = "" then
         Cleanup;
         return False;
      end if;

      if not Write_File (Stdin_Path, "", Append => False) then
         Cleanup;
         return False;
      end if;

      Args.Append (Hostkit.UString'(U.To_Unbounded_String (Hostkit.Shell.Command_Option)));
      Args.Append (Hostkit.UString'(U.To_Unbounded_String (Command)));

      Status :=
        Hostkit.Process.Run_Captured
          (Program     => Hostkit.Shell.Executable,
           Arguments   => Args,
           Stdin_Path  => Stdin_Path,
           Stdout_Path => Stdout_Path,
           Stderr_Path => Stderr_Path);

      if Status.Started
        and then not Status.Timed_Out
        and then Read_File (Stdout_Path, Output) = Read_Success
      then
         Cleanup;
         Ignored := Status.Exit_Status;
         return Ignored >= 0;
      end if;

      Cleanup;
      return False;
   exception
      when Ada.Directories.Name_Error | Ada.Directories.Use_Error
         | Constraint_Error | Program_Error | Storage_Error =>
         Output := U.Null_Unbounded_String;
         Cleanup;
         return False;
   end Run_Command;

   function Write_File (Path : String; Content : String; Append : Boolean) return Boolean is
      File : SIO.File_Type;
      Mode : constant SIO.File_Mode := (if Append then SIO.Append_File else SIO.Out_File);
      Position : Natural := Content'First;
   begin
      if Append and then Ada.Directories.Exists (Path) then
         SIO.Open (File, Mode, Path);
      else
         SIO.Create (File, SIO.Out_File, Path);
      end if;

      while Position <= Content'Last loop
         declare
            Remaining : constant Natural := Content'Last - Position + 1;
            Count     : constant Natural :=
              Natural'Min (Remaining, Natural (Byte_IO.Chunk_Size));
            Last      : constant Ada.Streams.Stream_Element_Offset :=
              Ada.Streams.Stream_Element_Offset (Count);
            Buffer    : Ada.Streams.Stream_Element_Array (1 .. Byte_IO.Chunk_Size);
         begin
            for Offset in 0 .. Count - 1 loop
               Buffer (Ada.Streams.Stream_Element_Offset (Offset + 1)) :=
                 Ada.Streams.Stream_Element (Character'Pos (Content (Position + Offset)));
            end loop;
            SIO.Write (File, Buffer (1 .. Last));
            Position := Position + Count;
         end;
      end loop;

      SIO.Close (File);
      return True;
   exception
      when Ada.IO_Exceptions.Name_Error
         | Ada.IO_Exceptions.Use_Error
         | Ada.IO_Exceptions.Device_Error
         | Ada.IO_Exceptions.Status_Error
         | Ada.IO_Exceptions.Mode_Error
         | Ada.Directories.Name_Error
         | Ada.Directories.Use_Error
         | Constraint_Error
         | Storage_Error =>
         if SIO.Is_Open (File) then
            SIO.Close (File);
         end if;
         return False;
   end Write_File;

   function Write_Standard_Stream
     (Stream : Interfaces.C_Streams.FILEs;
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
   end Write_Standard_Stream;

   function Write_Standard_Output (Content : String) return Boolean is
   begin
      return Write_Standard_Stream (Interfaces.C_Streams.stdout, Content);
   end Write_Standard_Output;

   function Write_Standard_Error (Content : String) return Boolean is
   begin
      return Write_Standard_Stream (Interfaces.C_Streams.stderr, Content);
   end Write_Standard_Error;

   function Is_Terminal (File_Descriptor : Interfaces.C_Streams.int) return Boolean is
   begin
      return Interfaces.C_Streams.isatty (File_Descriptor) = 1;
   exception
      when Constraint_Error | Program_Error =>
         return False;
   end Is_Terminal;

   function Standard_Output_Is_Terminal return Boolean is
     (Is_Terminal (1));

   function Standard_Error_Is_Terminal return Boolean is
     (Is_Terminal (2));

   function No_Color_Active return Boolean is
   begin
      return Ada.Environment_Variables.Exists ("NO_COLOR");
   exception
      when Constraint_Error | Program_Error =>
         return False;
   end No_Color_Active;

   function Locale return String is
      Native : constant String := Hostkit.Host.Native_Locale;
   begin
      if Ada.Environment_Variables.Exists ("LC_ALL") and then Ada.Environment_Variables.Value ("LC_ALL") /= "" then
         return Ada.Environment_Variables.Value ("LC_ALL");
      elsif Ada.Environment_Variables.Exists ("LANG") and then Ada.Environment_Variables.Value ("LANG") /= "" then
         return Ada.Environment_Variables.Value ("LANG");
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
end Awk_CLI.Platform;
