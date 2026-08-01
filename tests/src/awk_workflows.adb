with Ada.Command_Line;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with GNAT.OS_Lib;

with Project_Tools.Files;
with Project_Tools.Processes;

procedure Awk_Workflows is
   package CLI renames Ada.Command_Line;
   package Dir renames Ada.Directories;
   package Proc renames Project_Tools.Processes;
   package Files renames Project_Tools.Files;
   package U renames Ada.Strings.Unbounded;

   Root : constant String := "..";
   Alr  : constant String := Proc.Locate_Command ("alr");
   Env  : constant String := Proc.Locate_Command ("env");
   Git  : constant String := Proc.Locate_Command ("git");

   procedure Put_Info (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Message);
   end Put_Info;

   procedure Fail (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, Message);
      CLI.Set_Exit_Status (CLI.Failure);
      raise Program_Error;
   end Fail;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Fail (Message);
      end if;
   end Require;

   procedure Run_Alr_Build (Directory : String; Release_Mode : Boolean := False) is
      function Derived_Home return String is
         Marker : constant String := "/.getada/bin/alr";
      begin
         if Alr'Length > Marker'Length
           and then Alr (Alr'Last - Marker'Length + 1 .. Alr'Last) = Marker
         then
            return Alr (Alr'First .. Alr'Last - Marker'Length);
         else
            return "";
         end if;
      end Derived_Home;

      Home : constant String := Derived_Home;
   begin
      Require (Alr /= "", "alr executable not found");
      if Env /= "" and then Home /= "" then
         declare
            Args : constant GNAT.OS_Lib.Argument_List :=
              (if Release_Mode
               then
                 [new String'("HOME=" & Home),
                  new String'("XDG_DATA_HOME=" & Home & "/.local/share"),
                  new String'("XDG_CONFIG_HOME=" & Home & "/.config"),
                  new String'(Alr),
                  new String'("-n"),
                  new String'("build"),
                  new String'("--release"),
                  new String'("--profiles=*=release")]
               else
                 [new String'("HOME=" & Home),
                  new String'("XDG_DATA_HOME=" & Home & "/.local/share"),
                  new String'("XDG_CONFIG_HOME=" & Home & "/.config"),
                  new String'(Alr),
                  new String'("-n"),
                  new String'("build"),
                  new String'("--development")]);
         begin
            if Proc.Run_Status ("alr build", Directory, Env, Args) /= 0 then
               Fail ("alr build failed in " & Directory);
            end if;
         end;
      else
         declare
            Args : constant GNAT.OS_Lib.Argument_List :=
              (if Release_Mode
               then [new String'("-n"), new String'("build"), new String'("--release"),
                     new String'("--profiles=*=release")]
               else [new String'("-n"), new String'("build"), new String'("--development")]);
         begin
            if Proc.Run_Status ("alr build", Directory, Alr, Args) /= 0 then
               Fail ("alr build failed in " & Directory);
            end if;
         end;
      end if;
   end Run_Alr_Build;

   procedure Run_Binary (Directory, Program : String) is
      Args : GNAT.OS_Lib.Argument_List (1 .. 0);
   begin
      if Proc.Run_Status (Program, Directory, Program, Args) /= 0 then
         Fail (Program & " failed");
      end if;
   end Run_Binary;

   procedure Build is
   begin
      Run_Alr_Build (Root);
      Run_Alr_Build (".");
   end Build;

   procedure Test is
   begin
      Run_Alr_Build (".");
      Run_Binary (".", "./bin/awk_tests_main");
   end Test;

   procedure Require_Clean_Repository is
      Output : Proc.Unbounded_String;
      Args   : constant GNAT.OS_Lib.Argument_List (1 .. 2) :=
        [new String'("status"), new String'("--porcelain")];
   begin
      Require (Git /= "", "git executable not found");
      if Proc.Run_Status ("git status --porcelain", Root, Git, Args, Output, Quiet => True) /= 0 then
         Fail ("git status failed");
      end if;
      Require (U.Length (Output) = 0, "release requires a clean git working tree");
   end Require_Clean_Repository;

   function File_Text (Path : String) return String is
      File   : Ada.Text_IO.File_Type;
      Buffer : U.Unbounded_String;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         U.Append (Buffer, Ada.Text_IO.Get_Line (File));
         if not Ada.Text_IO.End_Of_File (File) then
            U.Append (Buffer, ASCII.LF);
         end if;
      end loop;
      Ada.Text_IO.Close (File);
      return U.To_String (Buffer);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return "";
   end File_Text;

   function Contains (Text, Pattern : String) return Boolean is
   begin
      if Pattern'Length = 0 then
         return True;
      end if;
      if Text'Length < Pattern'Length then
         return False;
      end if;
      for Index in Text'First .. Text'Last - Pattern'Length + 1 loop
         if Text (Index .. Index + Pattern'Length - 1) = Pattern then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   procedure Docs is
      procedure Require_Path (Path : String) is
      begin
         Require (Dir.Exists (Path), "missing required documentation: " & Path);
      end Require_Path;
   begin
      Require_Path ("../README.md");
      Require_Path ("../CHANGELOG.md");
      Require_Path ("../CONTRIBUTING.md");
      Require_Path ("../SECURITY.md");
      Require_Path ("../LICENSE");
      Require_Path ("../docs/quickstart.md");
      Require_Path ("../docs/command-line-reference.md");
      Require_Path ("../docs/compatibility.md");
      Require_Path ("../docs/architecture.md");
      Require_Path ("../docs/diagnostics.md");
      Require_Path ("../docs/localization.md");
      Require_Path ("../docs/testing.md");
      Require_Path ("../docs/building.md");
      Require_Path ("../docs/releasing.md");
      Require_Path ("../docs/ai/project-map.md");
      Require_Path ("../docs/ai/package-contracts.md");
      Require_Path ("../docs/ai/invariants.md");
      Require_Path ("../docs/ai/workflows.md");
      Require_Path ("../docs/ai/prohibited-designs.md");
      Require
        (Contains (File_Text ("../README.md"), "does not claim complete POSIX conformance"),
         "README must not claim full POSIX conformance");
      Require
        (Contains (File_Text ("../README.md"), "./bin/awk_tests_main"),
         "README must document the current AUnit executable");
      Require
        (Contains (File_Text ("../README.md"), "--color=auto|always|never"),
         "README must document color policy");
      Require
        (Contains (File_Text ("../README.md"), "Windows"),
         "README must include Windows quoting guidance");
      Require
        (Contains (File_Text ("../docs/compatibility.md"), "AWK-COMPAT-ASSIGNMENT-001"),
         "compatibility registry is missing assignment limitation");
      Require
        (Contains (File_Text ("../docs/releasing.md"), "--release --profiles=*=release"),
         "release docs must document release-profile builds");
      Require
        (Contains (File_Text ("../docs/releasing.md"), "clean git working tree"),
         "release docs must document clean-tree enforcement");
      Put_Info ("documentation checks passed");
   end Docs;

   procedure Catalogs is
      Catalog    : constant String := File_Text ("../resources/messages/catalog.txt");
      English    : constant String := File_Text ("../resources/messages/en/catalog.txt");
      Danish     : constant String := File_Text ("../resources/messages/da/catalog.txt");

      procedure Require_Key (Key : String) is
      begin
         Require (Contains (Catalog, Key & " ="), "message catalog missing key: " & Key);
      end Require_Key;

      procedure Require_Shard_Key (Shard, Key, Name : String) is
      begin
         Require (Contains (Shard, Key & " ="),
                  Name & " catalog shard missing key: " & Key);
      end Require_Shard_Key;
   begin
      Require (Catalog /= "", "message catalog is missing or empty");
      Require (English /= "", "English catalog shard is missing or empty");
      Require (Danish /= "", "Danish catalog shard is missing or empty");
      Require_Key ("en.awk.help.title");
      Require_Key ("en.awk.usage.missing_program");
      Require_Key ("en.awk.interpreter.runtime_failed");
      Require_Key ("en.awk.standard_output.write_failed");
      Require_Key ("da.awk.help.title");
      Require_Key ("da.awk.usage.missing_program");
      Require_Key ("da.awk.interpreter.runtime_failed");
      Require_Key ("da.awk.standard_output.write_failed");
      Require_Shard_Key (English, "en.awk.help.title", "English");
      Require_Shard_Key (English, "en.awk.usage.missing_program", "English");
      Require_Shard_Key (English, "en.awk.interpreter.runtime_failed", "English");
      Require_Shard_Key (English, "en.awk.standard_output.write_failed", "English");
      Require_Shard_Key (Danish, "da.awk.help.title", "Danish");
      Require_Shard_Key (Danish, "da.awk.usage.missing_program", "Danish");
      Require_Shard_Key (Danish, "da.awk.interpreter.runtime_failed", "Danish");
      Require_Shard_Key (Danish, "da.awk.standard_output.write_failed", "Danish");
      Put_Info ("catalog checks passed");
   end Catalogs;

   procedure Source_Policy is
      function Allowed_Path (Path, Allowed : String) return Boolean is
      begin
         return Path = Allowed;
      end Allowed_Path;

      function First_Unexpected_Dependency
        (Pattern      : String;
         Allowed_Body : String;
         Allowed_Spec : String := "") return String
      is
         Ads_Files : constant Files.Path_List := Files.List_Tree ("../src", "*.ads");
         Adb_Files : constant Files.Path_List := Files.List_Tree ("../src", "*.adb");
      begin
         for Path of Ads_Files loop
            declare
               Name : constant String := U.To_String (Path);
            begin
               if Contains (File_Text (Name), Pattern)
                 and then not Allowed_Path (Name, Allowed_Body)
                 and then (Allowed_Spec = "" or else not Allowed_Path (Name, Allowed_Spec))
               then
                  return Name;
               end if;
            end;
         end loop;

         for Path of Adb_Files loop
            declare
               Name : constant String := U.To_String (Path);
            begin
               if Contains (File_Text (Name), Pattern)
                 and then not Allowed_Path (Name, Allowed_Body)
                 and then (Allowed_Spec = "" or else not Allowed_Path (Name, Allowed_Spec))
               then
                  return Name;
               end if;
            end;
         end loop;

         return "";
      end First_Unexpected_Dependency;

      Unexpected : U.Unbounded_String;
   begin
      Require
        (Contains (File_Text ("../src/library/awk_cli-execution.adb"), "with Awklib"),
         "execution adapter must bridge to awklib");
      Require
        (First_Unexpected_Dependency ("with Awklib", "../src/library/awk_cli-execution.adb") = "",
         "only execution adapter may depend on awklib");
      Require
        (Contains (File_Text ("../src/library/awk_cli-localization.adb"), "with Messages"),
         "localization adapter must bridge to messages");
      Unexpected :=
        U.To_Unbounded_String
          (First_Unexpected_Dependency
             ("with Messages",
              "../src/library/awk_cli-localization.adb",
              "../src/library/awk_cli-localization.ads"));
      Require (U.To_String (Unexpected) = "",
               "only localization adapter may depend on messages: " & U.To_String (Unexpected));
      Require
        (Contains (File_Text ("../src/library/awk_cli-output.adb"), "with Terminal_Styles"),
         "presentation layer must bridge to terminal_styles");
      Require
        (First_Unexpected_Dependency ("with Terminal_Styles", "../src/library/awk_cli-output.adb") = "",
         "only presentation layer may depend on terminal_styles");
      Require
        (not Contains (File_Text ("../src/library/awk_cli-output.adb"), "Character'Val (27)"),
         "presentation layer must not emit handwritten ANSI escapes");
      Require
        (not Files.Any_File_Contains ("../src", "gawk"),
         "production source must not invoke or reference external gawk fallback");
      Require
        (not Files.Any_File_Contains ("../src", "mawk"),
         "production source must not invoke or reference external mawk fallback");
      Require
        (not Files.Any_File_Contains ("../src", "nawk"),
         "production source must not invoke or reference external nawk fallback");
      Require
        (Contains (File_Text ("src/awk_workflows.adb"), "--release"),
         "release workflow must use Alire release builds");
      Require
        (Contains (File_Text ("src/awk_workflows.adb"), "status"),
         "release workflow must check git status");
      Require
        (not Contains (File_Text ("src/awk_workflows.adb"), "release"") then" & ASCII.LF &
                                                     "      Verify;"),
         "release workflow must not reuse development verify gate");
      Put_Info ("source policy checks passed");
   end Source_Policy;

   procedure Verify is
   begin
      Build;
      Test;
      Docs;
      Catalogs;
      Source_Policy;
   end Verify;

   procedure Remove_If_Exists (Path : String) is
   begin
      if Dir.Exists (Path) then
         Dir.Delete_Tree (Path);
      end if;
   end Remove_If_Exists;

   procedure Clean is
   begin
      Remove_If_Exists ("../obj");
      Remove_If_Exists ("../bin");
      Remove_If_Exists ("obj");
      Remove_If_Exists ("bin");
      Put_Info ("cleaned build outputs");
   end Clean;

   procedure Copy_File (Source, Target : String) is
   begin
      if Dir.Exists (Target) then
         Dir.Delete_File (Target);
      end if;
      Dir.Copy_File (Source, Target);
   exception
      when others =>
         Fail ("copy failed: " & Source & " -> " & Target);
   end Copy_File;

   procedure Package_Artifact (Release_Mode : Boolean := False) is
      Dist : constant String := "../dist/awk-0.1.0";

      function Checksum (Path : String) return Natural is
         package SIO renames Ada.Streams.Stream_IO;
         File   : SIO.File_Type;
         Buffer : Ada.Streams.Stream_Element_Array (1 .. 8192);
         Last   : Ada.Streams.Stream_Element_Offset;
         Result : Long_Long_Integer := 0;
      begin
         SIO.Open (File, SIO.In_File, Path);
         while not SIO.End_Of_File (File) loop
            SIO.Read (File, Buffer, Last);
            for Index in Buffer'First .. Last loop
               Result := (Result * 131 + Long_Long_Integer (Buffer (Index))) mod 2_147_483_647;
            end loop;
         end loop;
         SIO.Close (File);
         return Natural (Result);
      exception
         when others =>
            if SIO.Is_Open (File) then
               SIO.Close (File);
            end if;
            return 0;
      end Checksum;

      function Length_Of (Path : String) return Natural is
        (Natural (Dir.Size (Path)));

      procedure Add_Manifest_Line
        (Buffer : in out U.Unbounded_String;
         Path   : String)
      is
      begin
         U.Append
           (Buffer,
            Path & " bytes=" & Natural'Image (Length_Of (Dist & "/" & Path))
            & " checksum=" & Natural'Image (Checksum (Dist & "/" & Path))
            & ASCII.LF);
      end Add_Manifest_Line;

      procedure Require_Package_File (Path : String) is
      begin
         Require (Files.File_Exists (Dist & "/" & Path), "missing package file: " & Path);
         Require (Length_Of (Dist & "/" & Path) > 0, "empty package file: " & Path);
      end Require_Package_File;

      Manifest : U.Unbounded_String;
   begin
      if Release_Mode then
         Run_Alr_Build (Root, Release_Mode => True);
         Run_Alr_Build (".", Release_Mode => True);
      else
         Build;
      end if;
      Remove_If_Exists ("../dist");
      Dir.Create_Path (Dist & "/bin");
      Dir.Create_Path (Dist & "/resources/messages");
      Dir.Create_Path (Dist & "/resources/messages/en");
      Dir.Create_Path (Dist & "/resources/messages/da");
      Dir.Create_Path (Dist & "/docs");
      Copy_File ("../bin/awk", Dist & "/bin/awk");
      Copy_File ("../LICENSE", Dist & "/LICENSE");
      Copy_File ("../README.md", Dist & "/README.md");
      Copy_File ("../docs/compatibility.md", Dist & "/docs/compatibility.md");
      Copy_File ("../resources/messages/catalog.txt", Dist & "/resources/messages/catalog.txt");
      Copy_File ("../resources/messages/en/catalog.txt", Dist & "/resources/messages/en/catalog.txt");
      Copy_File ("../resources/messages/da/catalog.txt", Dist & "/resources/messages/da/catalog.txt");
      Require_Package_File ("bin/awk");
      Require_Package_File ("LICENSE");
      Require_Package_File ("README.md");
      Require_Package_File ("docs/compatibility.md");
      Require_Package_File ("resources/messages/catalog.txt");
      Require_Package_File ("resources/messages/en/catalog.txt");
      Require_Package_File ("resources/messages/da/catalog.txt");
      Add_Manifest_Line (Manifest, "bin/awk");
      Add_Manifest_Line (Manifest, "LICENSE");
      Add_Manifest_Line (Manifest, "README.md");
      Add_Manifest_Line (Manifest, "docs/compatibility.md");
      Add_Manifest_Line (Manifest, "resources/messages/catalog.txt");
      Add_Manifest_Line (Manifest, "resources/messages/en/catalog.txt");
      Add_Manifest_Line (Manifest, "resources/messages/da/catalog.txt");
      Files.Write_Text_File (Dist & "/MANIFEST.txt", U.To_String (Manifest));
      Require_Package_File ("MANIFEST.txt");
      Put_Info ("packaged " & Dist);
   end Package_Artifact;

   procedure Usage is
   begin
      Ada.Text_IO.Put_Line
        ("usage: awk_workflows build|test|verify|docs|clean|package|release");
   end Usage;

   Command : constant String := (if CLI.Argument_Count = 0 then "verify" else CLI.Argument (1));
begin
   if Command = "build" then
      Build;
   elsif Command = "test" then
      Test;
   elsif Command = "verify" then
      Verify;
   elsif Command = "docs" then
      Docs;
   elsif Command = "clean" then
      Clean;
   elsif Command = "package" then
      Package_Artifact;
   elsif Command = "release" then
      Require_Clean_Repository;
      Run_Alr_Build (Root, Release_Mode => True);
      Run_Alr_Build (".", Release_Mode => True);
      Run_Binary (".", "./bin/awk_tests_main");
      Docs;
      Catalogs;
      Source_Policy;
      Package_Artifact (Release_Mode => True);
   elsif Command = "--help" or else Command = "-h" then
      Usage;
   else
      Usage;
      CLI.Set_Exit_Status (CLI.Failure);
   end if;
exception
   when Program_Error =>
      null;
   when Error : others =>
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "unexpected workflow failure: " & Ada.Exceptions.Exception_Information (Error));
      CLI.Set_Exit_Status (CLI.Failure);
end Awk_Workflows;
