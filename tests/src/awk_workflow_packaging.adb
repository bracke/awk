with Ada.Directories;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Project_Tools.Alire;
with Project_Tools.Files;
with Project_Tools.Release_Checks;

package body Awk_Workflow_Packaging is
   package Dir renames Ada.Directories;
   package Files renames Project_Tools.Files;
   package U renames Ada.Strings.Unbounded;

   Root : constant String := "..";

   Package_Files : constant Files.Path_List :=
     [U.To_Unbounded_String ("bin/awk"),
      U.To_Unbounded_String ("LICENSE"),
      U.To_Unbounded_String ("README.md"),
      U.To_Unbounded_String ("CHANGELOG.md"),
      U.To_Unbounded_String ("CONTRIBUTING.md"),
      U.To_Unbounded_String ("SECURITY.md"),
      U.To_Unbounded_String ("docs/quickstart.md"),
      U.To_Unbounded_String ("docs/command-line-reference.md"),
      U.To_Unbounded_String ("docs/compatibility.md"),
      U.To_Unbounded_String ("docs/architecture.md"),
      U.To_Unbounded_String ("docs/diagnostics.md"),
      U.To_Unbounded_String ("docs/localization.md"),
      U.To_Unbounded_String ("docs/localization-reference.md"),
      U.To_Unbounded_String ("docs/testing.md"),
      U.To_Unbounded_String ("docs/building.md"),
      U.To_Unbounded_String ("docs/releasing.md"),
      U.To_Unbounded_String ("docs/dependency-policy.md"),
      U.To_Unbounded_String ("docs/final-acceptance.md"),
      U.To_Unbounded_String ("docs/ai/project-map.md"),
      U.To_Unbounded_String ("docs/ai/package-contracts.md"),
      U.To_Unbounded_String ("docs/ai/invariants.md"),
      U.To_Unbounded_String ("docs/ai/workflows.md"),
      U.To_Unbounded_String ("docs/ai/prohibited-designs.md"),
      U.To_Unbounded_String ("docs/ai/traceability.md"),
      U.To_Unbounded_String ("resources/messages/catalog.txt"),
      U.To_Unbounded_String ("resources/messages/en/catalog.txt"),
      U.To_Unbounded_String ("resources/messages/da/catalog.txt")];

   function File_Count return Natural is (Natural (Package_Files'Length));

   function File_Path (Index : Positive) return String is
     (U.To_String (Package_Files (Index)));

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
         for Path of Package_Files loop
            Dir.Create_Path
              (Ada.Directories.Containing_Directory
                 (Files.Join (Dist, U.To_String (Path))));
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
      for Path of Package_Files loop
         Copy_Package_File (U.To_String (Path));
         Require_Package_File (U.To_String (Path));
         Add_Manifest_Line (Manifest, U.To_String (Path));
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
        (Project_Tools.Release_Checks.Manifest_Line_Count (Manifest_Path) = Package_Files'Length,
         "package manifest must contain one line per packaged file");
      for Path of Package_Files loop
         Project_Tools.Release_Checks.Require_Manifest_Entry
           (Manifest_Path, Dist, U.To_String (Path), Quiet => True);
      end loop;
      Ada.Text_IO.Put_Line ("packaged " & Dist);
   end Run;
end Awk_Workflow_Packaging;
