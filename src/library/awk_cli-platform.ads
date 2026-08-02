with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded;
with Awk_CLI.Options;

package Awk_CLI.Platform is
   package U renames Ada.Strings.Unbounded;
   type Read_Status is (Read_Success, Open_Failed, Read_Failed);
   type Input_Stream is limited private;

   function Process_Arguments return Awk_CLI.Options.String_Vectors.Vector;
   function Read_Standard_Input return U.Unbounded_String;
   function Read_File (Path : String; Content : out U.Unbounded_String) return Read_Status;
   function Open_Input_File (Path : String; Stream : in out Input_Stream) return Read_Status;
   function Open_Standard_Input (Stream : in out Input_Stream) return Read_Status;
   function Read_Input_Chunk
     (Stream : in out Input_Stream;
      Content : out U.Unbounded_String;
      End_Of_File : out Boolean) return Read_Status;
   procedure Close_Input (Stream : in out Input_Stream);
   function Run_Command (Command : String; Output : out U.Unbounded_String) return Boolean;
   function Write_File (Path : String; Content : String; Append : Boolean) return Boolean;
   function Write_Standard_Output (Content : String) return Boolean;
   function Write_Standard_Error (Content : String) return Boolean;
   function Standard_Output_Is_Terminal return Boolean;
   function Standard_Error_Is_Terminal return Boolean;
   function Locale return String;
   function Catalog_Path return String;

private
   package SIO renames Ada.Streams.Stream_IO;

   type Input_Stream is limited record
      File       : SIO.File_Type;
      Opened     : Boolean := False;
      Is_Stdin   : Boolean := False;
      Stdin_Done : Boolean := False;
   end record;
end Awk_CLI.Platform;
