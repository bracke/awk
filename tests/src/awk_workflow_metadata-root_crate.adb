with Project_Tools.Files;
with Project_Tools.Release_Checks;
with Project_Tools.Text;
with Project_Tools.TOML;

package body Awk_Workflow_Metadata.Root_Crate is
   package Files renames Project_Tools.Files;
   package Text renames Project_Tools.Text;
   package TOML renames Project_Tools.TOML;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Project_Tools.Release_Checks.Fail (Message);
      end if;
   end Require;

   procedure Run
     (Root_Alire     : String;
      Root_Version   : String;
      Awklib_Version : String)
   is
   begin
      Require (TOML.String_Value_After (Root_Alire, "name =", Root_Alire'First) = "awk",
               "root crate name must be awk");
      Require (Root_Version /= "", "root crate version must be declared");
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
      Require
        (TOML.String_Value_After (Root_Alire, "licenses =", Root_Alire'First) = "MIT",
         "root crate must declare MIT license");
   end Run;
end Awk_Workflow_Metadata.Root_Crate;
