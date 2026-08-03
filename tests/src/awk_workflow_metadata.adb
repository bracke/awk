with Ada.Text_IO;

with Project_Tools.Alire_Manifests.Validation;
with Project_Tools.Files;
with Project_Tools.Release_Checks;
with Project_Tools.Test_Fixtures;
with Project_Tools.Text;
with Project_Tools.TOML;

package body Awk_Workflow_Metadata is
   package Files renames Project_Tools.Files;
   package Fixtures renames Project_Tools.Test_Fixtures;
   package Manifests renames Project_Tools.Alire_Manifests.Validation;
   package Text renames Project_Tools.Text;
   package TOML renames Project_Tools.TOML;

   procedure Put_Info (Message : String) is
   begin
      Ada.Text_IO.Put_Line (Message);
   end Put_Info;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Project_Tools.Release_Checks.Fail (Message);
      end if;
   end Require;

   procedure Run is
      Root_Alire  : constant String := Fixtures.Read_Text_File ("../alire.toml");
      Tests_Alire : constant String := Fixtures.Read_Text_File ("alire.toml");
      Root_Version : constant String :=
        TOML.String_Value_After (Root_Alire, "version =", Root_Alire'First);
      Tests_Version : constant String :=
        TOML.String_Value_After (Tests_Alire, "version =", Tests_Alire'First);
      Awklib_Constraint : constant String :=
        TOML.String_Value_After (Root_Alire, "awklib =", Root_Alire'First);

      function Constraint_Version (Constraint : String) return String is
      begin
         if Constraint'Length > 0
           and then (Constraint (Constraint'First) = '~'
                     or else Constraint (Constraint'First) = '=')
         then
            return Constraint (Constraint'First + 1 .. Constraint'Last);
         else
            return Constraint;
         end if;
      end Constraint_Version;

      Awklib_Version : constant String := Constraint_Version (Awklib_Constraint);
   begin
      Require (TOML.String_Value_After (Root_Alire, "name =", Root_Alire'First) = "awk",
               "root crate name must be awk");
      Require (Root_Version /= "", "root crate version must be declared");
      Require (Tests_Version = Root_Version,
               "tests crate version must match root crate version");
      Require (Awklib_Version /= "", "awklib dependency version must be declared");
      Files.Require_Contains
        ("../config/awk_config.ads",
         "Crate_Version : constant String := """ & Root_Version & """",
         "generated Ada config must match root crate version", Quiet => True);
      Files.Require_Contains
        ("../config/awk_config.gpr",
         "Crate_Version := """ & Root_Version & """",
         "generated GPR config must match root crate version", Quiet => True);
      Files.Require_Contains
        ("../docs/releasing.md", "dist/awk-" & Root_Version,
         "release docs must document the current package directory",
         Quiet => True);
      Files.Require_Contains
        ("../src/library/awk_cli-compatibility.adb",
         "resolved awklib " & Awklib_Version & " behavior",
         "compatibility registry must document the current awklib version",
         Quiet => True);
      Files.Require_Contains
        ("../docs/compatibility.md",
         "resolved awklib " & Awklib_Version & " behavior",
         "compatibility docs must document the current awklib version",
         Quiet => True);
      Files.Require_Contains
        ("../alire.toml", "executables = [""awk""]",
         "root crate must install executable awk", Quiet => True);
      Files.Require_Contains
        ("../alire.toml", "project-files = [""awk.gpr""]",
         "root crate must use awk.gpr", Quiet => True);
      Files.Require_Contains
        ("../alire.toml", "awklib = ",
         "root crate must depend on awklib", Quiet => True);
      Files.Require_Contains
        ("../alire.toml", "terminal_styles = ",
         "root crate must depend on terminal_styles", Quiet => True);
      Files.Require_Contains
        ("../alire.toml", "messages = ",
         "root crate must depend on messages", Quiet => True);
      Files.Require_Contains
        ("../alire.toml", "hostkit = ",
         "root crate must depend on hostkit", Quiet => True);
      Require (not Text.Contains (Root_Alire, "awklib = ""*"""),
               "root awklib dependency must not use wildcard constraint");
      Require (not Text.Contains (Root_Alire, "terminal_styles = ""*"""),
               "root terminal_styles dependency must not use wildcard constraint");
      Require (not Text.Contains (Root_Alire, "messages = ""*"""),
               "root messages dependency must not use wildcard constraint");
      Require (not Text.Contains (Root_Alire, "hostkit = ""*"""),
               "root hostkit dependency must not use wildcard constraint");
      Files.Require_Contains
        ("../docs/dependency-policy.md", "terminal_styles = ""=0.1.0-dev""",
         "dependency policy must document the current terminal_styles dev constraint",
         Quiet => True);
      Files.Require_Contains
        ("../docs/dependency-policy.md", "hostkit = ""=0.1.0-dev""",
         "dependency policy must document the current hostkit dev constraint",
         Quiet => True);
      Files.Require_Contains
        ("../docs/dependency-policy.md",
         "| `messages` | `~0.1.0` | `../../messages` |",
         "dependency policy must document the tests messages dependency",
         Quiet => True);
      Require (TOML.String_Value_After (Tests_Alire, "name =", Tests_Alire'First) = "awk_tests",
               "tests crate name must be awk_tests");
      Files.Require_Contains
        ("alire.toml", "executables = [""awk_tests_main"", ""awk_workflows""]",
         "tests crate must expose the test and workflow executables",
         Quiet => True);
      Files.Require_Contains
        ("alire.toml", "awk = ",
         "tests crate must depend on awk", Quiet => True);
      Files.Require_Contains
        ("alire.toml", "aunit = ",
         "tests crate must depend on AUnit", Quiet => True);
      Files.Require_Contains
        ("alire.toml", "project_tools = ",
         "tests crate must depend on project_tools", Quiet => True);
      Files.Require_Contains
        ("alire.toml", "messages = ",
         "tests crate must depend on messages for catalog consistency checks",
         Quiet => True);
      Files.Require_Contains
        ("alire.toml", "awk = { path = "".."" }",
         "tests crate must pin awk relatively", Quiet => True);
      Manifests.Require_Workspace_Pin ("../alire.toml", "awklib", "../awklib", Quiet => True);
      Manifests.Require_Workspace_Pin
        ("../alire.toml", "terminal_styles", "../terminal_styles", Quiet => True);
      Manifests.Require_Workspace_Pin ("../alire.toml", "messages", "../messages", Quiet => True);
      Manifests.Require_Workspace_Pin ("../alire.toml", "hostkit", "../hostkit", Quiet => True);
      Manifests.Require_Workspace_Pin ("alire.toml", "awk", "..", Quiet => True);
      Manifests.Require_Workspace_Pin
        ("alire.toml", "project_tools", "../../project_tools", Quiet => True);
      Manifests.Require_Workspace_Pin
        ("alire.toml", "messages", "../../messages", Quiet => True);
      Files.Require_Contains
        ("../awk.gpr", "-gnat2022",
         "root project must compile with Ada 2022", Quiet => True);
      Files.Require_Contains
        ("awk_tests.gpr", "-gnat2022",
         "tests project must compile with Ada 2022", Quiet => True);
      Files.Require_Contains
        ("../awk.gpr", "for Main use (""awk.adb"")",
         "root project main must be awk.adb", Quiet => True);
      Files.Require_Contains
        ("awk_tests.gpr", "awk_workflows.adb",
         "tests project must build workflow executable", Quiet => True);
      Files.Require_Contains
        ("awk_tests.gpr", "awk_tests_main.adb",
         "tests project must build AUnit executable", Quiet => True);
      Require (TOML.String_Value_After (Root_Alire, "licenses =", Root_Alire'First) = "MIT",
               "root crate must declare MIT license");
      Require (TOML.String_Value_After (Tests_Alire, "licenses =", Tests_Alire'First) = "MIT",
               "tests crate must declare MIT license");
      Put_Info ("metadata checks passed");
   end Run;
end Awk_Workflow_Metadata;
