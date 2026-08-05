with Ada.Directories;

with Project_Tools.Files;

package body Awk_Tests.Process_Support.Executable_Paths is
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

   function Absolute_Awk_Path return String is
   begin
      return Ada.Directories.Full_Name
        (if Project_Tools.Files.File_Exists ("../bin/awk.exe")
         then "../bin/awk.exe"
         else "../bin/awk");
   end Absolute_Awk_Path;

   function Preserves_Empty_Arguments return Boolean is
   begin
      --  The project_tools process helper drops an empty string argument on the Windows
      --  runner. The in-memory harness still tests empty direct programs.
      return not Project_Tools.Files.File_Exists ("../bin/awk.exe");
   end Preserves_Empty_Arguments;
end Awk_Tests.Process_Support.Executable_Paths;
