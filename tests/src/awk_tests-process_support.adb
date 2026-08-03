with Project_Tools.Files;
with Project_Tools.Test_Fixtures;

package body Awk_Tests.Process_Support is
   package Fixtures renames Project_Tools.Test_Fixtures;

   function Awk_From_Repository_Root return String is
   begin
      if Project_Tools.Files.File_Exists ("../bin/awk.exe") then
         return "./bin/awk.exe";
      end if;

      return "./bin/awk";
   end Awk_From_Repository_Root;

   function Awk_From_Tests_Directory return String is
   begin
      if Project_Tools.Files.File_Exists ("../bin/awk.exe") then
         return "../bin/awk.exe";
      end if;

      return "../bin/awk";
   end Awk_From_Tests_Directory;

   function Process_Harness_Preserves_Empty_Arguments return Boolean is
   begin
      --  The process harness drops an empty string argument on the Windows
      --  runner. The in-memory harness still tests empty direct programs.
      return not Project_Tools.Files.File_Exists ("../bin/awk.exe");
   end Process_Harness_Preserves_Empty_Arguments;

   procedure Ensure_Filesystem_Fixture_Directory is
   begin
      Fixtures.Make_Directory ("../tests/fixtures/filesystem");
   end Ensure_Filesystem_Fixture_Directory;

   function Read_Text_File (Path : String) return String is
     (Fixtures.Read_Text_File (Path));
end Awk_Tests.Process_Support;
