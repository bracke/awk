with Ada.Directories;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Awk_Workflow_Packaging.Manifest_Files;
with Project_Tools.Alire;
with Project_Tools.Files;
with Project_Tools.Release_Checks;

package body Awk_Workflow_Packaging is
   package Dir renames Ada.Directories;
   package Files renames Project_Tools.Files;
   package U renames Ada.Strings.Unbounded;

   Root : constant String := "..";

   function File_Count return Natural is
     (Awk_Workflow_Packaging.Manifest_Files.File_Count);

   function File_Path (Index : Positive) return String is
     (Awk_Workflow_Packaging.Manifest_Files.File_Path (Index));

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Project_Tools.Release_Checks.Fail (Message);
      end if;
   end Require;

   procedure Build is
   begin
      Project_Tools.Alire.Run_Build (Directory => Root);
      Project_Tools.Alire.Run_Build (Directory => ".");
   end Build;

   procedure Run (Release_Mode : Boolean := False) is
      Dist : constant String := "../dist/awk-0.1.0";

      procedure Create_Package_Directories is
      begin
         Dir.Create_Path (Dist);
         for Index in 1 .. File_Count loop
            Dir.Create_Path
              (Ada.Directories.Containing_Directory
                 (Files.Join (Dist, File_Path (Index))));
         end loop;
      end Create_Package_Directories;

      procedure Add_Manifest_Line
        (Buffer : in out U.Unbounded_String;
         Path   : String)
      is
      begin
         U.Append
           (Buffer,
            Project_Tools.Release_Checks.Manifest_Line (Dist, Path) & ASCII.LF);
      end Add_Manifest_Line;

      procedure Require_Package_File (Path : String) is
         Full_Path : constant String := Files.Join (Dist, Path);
      begin
         Files.Require_File (Full_Path, "missing package file: " & Path);
         Require
           (Project_Tools.Release_Checks.File_Length (Full_Path) > 0,
            "empty package file: " & Path);
      end Require_Package_File;

      procedure Copy_Package_File (Path : String) is
         Source : constant String :=
           (if Path = "bin/awk" then Files.Join ("..", "bin/awk")
            else Files.Join ("..", Path));
      begin
         Files.Copy_File
           (Source          => Source,
            Target          => Files.Join (Dist, Path),
            Failure_Message => "copy failed",
            Quiet           => True);
      end Copy_Package_File;

      Manifest : U.Unbounded_String;
      Manifest_Path : constant String := Files.Join (Dist, "MANIFEST.txt");
   begin
      if Release_Mode then
         Project_Tools.Alire.Run_Build (Directory => Root, Release_Mode => True);
         Project_Tools.Alire.Run_Build (Directory => ".", Release_Mode => True);
      else
         Build;
      end if;
      Files.Delete_Tree ("../dist");
      Create_Package_Directories;
      for Index in 1 .. File_Count loop
         Copy_Package_File (File_Path (Index));
         Require_Package_File (File_Path (Index));
         Add_Manifest_Line (Manifest, File_Path (Index));
      end loop;
      Files.Write_Text_File (Manifest_Path, U.To_String (Manifest));
      Require_Package_File ("MANIFEST.txt");
      Files.Require_Contains
        (Manifest_Path, "fnv1a64=",
         "package manifest must include FNV-1a-64 checksum fields",
         Quiet => True);
      Require
        (not Files.File_Contains (Manifest_Path, " checksum="),
         "package manifest must not use legacy checksum field");
      Require
        (Project_Tools.Release_Checks.Manifest_Line_Count (Manifest_Path) = File_Count,
         "package manifest must contain one line per packaged file");
      for Index in 1 .. File_Count loop
         Project_Tools.Release_Checks.Require_Manifest_Entry
           (Manifest_Path, Dist, File_Path (Index), Quiet => True);
      end loop;
      Ada.Text_IO.Put_Line ("packaged " & Dist);
   end Run;
end Awk_Workflow_Packaging;
