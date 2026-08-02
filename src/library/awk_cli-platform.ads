with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded;
with Awk_CLI.Options;

package Awk_CLI.Platform is
   --  Small host adapter for process, filesystem, terminal, and locale state.
   --
   --  Platform code must stay free of AWK syntax and runtime semantics.

   package U renames Ada.Strings.Unbounded;
   type Read_Status is (Read_Success, Open_Failed, Read_Failed);
   type Input_Stream is limited private;

   function Process_Arguments return Awk_CLI.Options.String_Vectors.Vector;
   --  Return raw process arguments excluding executable name.

   function Read_Standard_Input return U.Unbounded_String;
   --  Read all current standard input for memory-backed execution paths.

   function Read_File (Path : String; Content : out U.Unbounded_String) return Read_Status;
   --  Read a complete text file and distinguish open from read failures.

   function Open_Input_File (Path : String; Stream : in out Input_Stream) return Read_Status;
   --  Open Path for chunked input reading.

   function Open_Standard_Input (Stream : in out Input_Stream) return Read_Status;
   --  Prepare standard input for chunked input reading.

   function Read_Input_Chunk
     (Stream : in out Input_Stream;
      Content : out U.Unbounded_String;
      End_Of_File : out Boolean) return Read_Status;
   --  Read the next input chunk and report end-of-file deterministically.

   procedure Close_Input (Stream : in out Input_Stream);
   --  Close Stream if it owns an open file handle.

   function Run_Command (Command : String; Output : out U.Unbounded_String) return Boolean;
   --  Run a host command for awklib command-getline integration.

   function Write_File (Path : String; Content : String; Append : Boolean) return Boolean;
   --  Write Content to Path using overwrite or append semantics.

   function Write_Standard_Output (Content : String) return Boolean;
   --  Forward exact AWK standard output to the process standard output.

   function Write_Standard_Error (Content : String) return Boolean;
   --  Write CLI-owned diagnostics to the process standard error.

   function Standard_Output_Is_Terminal return Boolean;
   --  Return whether standard output is an interactive terminal.

   function Standard_Error_Is_Terminal return Boolean;
   --  Return whether standard error is an interactive terminal.

   function Locale return String;
   --  Return the host locale name used for CLI-owned text.

   function Catalog_Path return String;
   --  Return the best-known message catalog path for the current layout.

private
   package SIO renames Ada.Streams.Stream_IO;

   type Input_Stream is limited record
      File       : SIO.File_Type;
      Opened     : Boolean := False;
      Is_Stdin   : Boolean := False;
      Stdin_Done : Boolean := False;
   end record;
end Awk_CLI.Platform;
