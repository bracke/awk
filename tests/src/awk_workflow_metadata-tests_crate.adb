with Project_Tools.Files;
with Project_Tools.Release_Checks;
with Project_Tools.TOML;

package body Awk_Workflow_Metadata.Tests_Crate is
   package Files renames Project_Tools.Files;
   package TOML renames Project_Tools.TOML;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Project_Tools.Release_Checks.Fail (Message);
      end if;
   end Require;

   procedure Run (Tests_Alire, Root_Version : String) is
      Tests_Version : constant String :=
        TOML.String_Value_After (Tests_Alire, "version =", Tests_Alire'First);
   begin
      Require (Tests_Version = Root_Version,
               "tests crate version must match root crate version");
      Require
        (TOML.String_Value_After (Tests_Alire, "name =", Tests_Alire'First) = "awk_tests",
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
      Files.Require_Contains
        ("../docs/dependency-policy.md",
         "| `messages` | `~0.1.0` | `../../messages` |",
         "dependency policy must document the tests messages dependency",
         Quiet => True);
      Require
        (TOML.String_Value_After (Tests_Alire, "licenses =", Tests_Alire'First) = "MIT",
         "tests crate must declare MIT license");
   end Run;
end Awk_Workflow_Metadata.Tests_Crate;
