package Awk_Tests.Process_Support is
   --  Shared helpers for process-level AUnit suites.

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

   procedure Ensure_Filesystem_Fixture_Directory;
   --  Ensure the filesystem fixture directory exists.

   --  @param Path File path to read.
   --  @return File content as text.
   function Read_Text_File (Path : String) return String;
   --  Read fixture text through project_tools.

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
