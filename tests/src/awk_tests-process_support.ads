with Ada.Strings.Unbounded;
with Project_Tools.Processes;

package Awk_Tests.Process_Support is
   --  Shared helpers for process-level AUnit suites.
   package U renames Ada.Strings.Unbounded;

   LF : constant String := [1 => ASCII.LF];

   --  @return Executable path usable when the child process runs from repo root.
   function Awk_From_Repository_Root return String;
   --  Return the built awk executable path relative to the repository root.

   --  @return Executable path usable when the child process runs from tests/.
   function Awk_From_Tests_Directory return String;
   --  Return the built awk executable path relative to tests/.

   function Repository_Path (Relative_Path : String) return String;
   --  Return an absolute path for a repository-relative file.

   --  @return True when project_tools process execution preserves empty arguments.
   function Project_Tools_Preserves_Empty_Arguments return Boolean;
   --  Return whether process tests can rely on empty command-line arguments.

   type Captured_Process is record
      Status : Integer := -1;
      Output : U.Unbounded_String;
   end record;

   subtype Process_Arguments is Project_Tools.Processes.Argument_Vectors.Vector;

   function Argument (Value : String) return U.Unbounded_String;
   --  Convert a string literal into a process argument item.

   function No_Arguments return Process_Arguments;
   --  Return an empty process argument vector.

   type Argument_Items is array (Positive range <>) of U.Unbounded_String;

   function Arguments
     (Items : Argument_Items) return Process_Arguments;
   --  Build a process argument vector without exposing GNAT.OS_Lib arrays.

   function Run_Awk_Err_To_Out
     (Args  : Process_Arguments;
      Input : String := "") return Captured_Process;
   --  Run the built awk executable from tests/ with stderr merged into output.

   function Run_Command_Err_To_Out
     (Command : String;
      Args    : Process_Arguments;
      Input   : String := "") return Captured_Process;
   --  Run an arbitrary command with stderr merged into output.

   function Run_Process
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : Process_Arguments) return Captured_Process;
   --  Run a process through the status harness and capture stdout.

   function Run_Awk
     (Label : String;
      Args  : Process_Arguments) return Captured_Process;
   --  Run the built awk executable from the repository root and capture stdout.

   function Run_Awk_In_Directory
     (Label : String;
      Dir   : String;
      Args  : Process_Arguments) return Captured_Process;
   --  Run the built awk executable from Dir and capture stdout.

   function Output_String (Result : Captured_Process) return String;
   --  Return captured process output as a String.

   function Fresh_Process_Temp_Dir (Name : String) return String;
   --  Return an isolated temporary directory for a process test.

   procedure Cleanup_Process_Temp_Dir (Path : String);
   --  Remove a temporary process test directory.

   --  @param Path File path to read.
   --  @return File content as text.
   function Read_Text_File (Path : String) return String;
   --  Read fixture text through project_tools.

   procedure Write_Text_File (Path : String; Content : String);
   --  Write fixture text through project_tools.

   function Locale_Text
     (Key       : String;
      Locale    : String := "en";
      Name      : String := "";
      Value     : String := "";
      Detail    : String := "") return String;
   --  Render a message through the production localization adapter.

   function English_Text
     (Key       : String;
      Name      : String := "";
      Value     : String := "";
      Detail    : String := "") return String;
   --  Render a message through the production localization adapter with the
   --  English catalog locale.

   function English_Hint (Hint_Key : String) return String;
   --  Render a complete English diagnostic hint line.

   function English_Error_Header (Primary : String) return String;
   --  Render a complete English CLI error header line.
end Awk_Tests.Process_Support;
