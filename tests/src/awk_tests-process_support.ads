with Ada.Strings.Unbounded;
with Awk_Tests.Process_Harness;

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

   --  @return True when the host process harness preserves empty arguments.
   function Process_Harness_Preserves_Empty_Arguments return Boolean;
   --  Return whether process tests can rely on empty command-line arguments.

   type Captured_Process is record
      Status : Integer := -1;
      Output : U.Unbounded_String;
   end record;

   function Run_Awk_Err_To_Out
     (Args  : Awk_Tests.Process_Harness.Argument_List;
      Input : String := "") return Captured_Process;
   --  Run the built awk executable from tests/ with stderr merged into output.

   function Run_Command_Err_To_Out
     (Command : String;
      Args    : Awk_Tests.Process_Harness.Argument_List;
      Input   : String := "") return Captured_Process;
   --  Run an arbitrary command with stderr merged into output.

   function Run_Awk
     (Label : String;
      Args  : Awk_Tests.Process_Harness.Argument_List) return Captured_Process;
   --  Run the built awk executable from the repository root and capture stdout.

   function Output_String (Result : Captured_Process) return String;
   --  Return captured process output as a String.

   procedure Ensure_Filesystem_Fixture_Directory;
   --  Ensure the filesystem fixture directory exists.

   --  @param Path File path to read.
   --  @return File content as text.
   function Read_Text_File (Path : String) return String;
   --  Read fixture text through project_tools.

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
