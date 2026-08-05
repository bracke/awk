with Ada.Strings.Unbounded;

with Project_Tools.Ada_Source;
with Project_Tools.Files;

package body Awk_Workflow_Source_Policy.Workflow_Checks.Fixtures is
   package Ada_Source renames Project_Tools.Ada_Source;
   package Files renames Project_Tools.Files;
   package U renames Ada.Strings.Unbounded;

   procedure Run is
   begin
      Files.Require_Contains
        ("src/awk_tests-process_support-fixture_files.adb",
         "with Project_Tools.Test_Fixtures",
         "process fixture file reads must use project_tools directly", Quiet => False);
      Files.Require_Contains
        ("src/awk_tests-process_support.ads", "function Fresh_Process_Temp_Dir",
         "process tests must expose isolated temporary directories",
         Quiet => False);
      Files.Require_Contains
        ("src/awk_tests-process_support.ads", "procedure Write_Text_File",
         "process tests must write temporary fixtures through process support",
         Quiet => False);
      Ada_Source.Require_No_Code_Tokens
        ("src/awk_tests-process_io-input_cases.adb",
         [U.To_Unbounded_String ("Write_Raw_File"),
          U.To_Unbounded_String ("Delete_File_If_Present"),
          U.To_Unbounded_String ("Ensure_Filesystem_Fixture_Directory"),
          U.To_Unbounded_String ("tests/fixtures/filesystem")],
         Quiet => False);
      Ada_Source.Require_No_Code_Tokens
        ("src/awk_tests-process_io-redirection_cases.adb",
         [U.To_Unbounded_String ("Write_Raw_File"),
          U.To_Unbounded_String ("Delete_File_If_Present"),
          U.To_Unbounded_String ("Ensure_Filesystem_Fixture_Directory"),
          U.To_Unbounded_String ("tests/fixtures/filesystem")],
         Quiet => False);
      Ada_Source.Require_No_Code_Tokens
        ("src/awk_tests-process_language.adb",
         [U.To_Unbounded_String ("Write_Raw_File"),
          U.To_Unbounded_String ("Delete_File_If_Present"),
          U.To_Unbounded_String ("Project_Tools.Files")],
         Quiet => False);
      Files.Require_Contains
        ("src/awk_tests-localization-catalog_cases.adb",
         "with Project_Tools.Test_Fixtures",
         "catalog fixture file reads must use project_tools directly",
         Quiet => False);
      Files.Require_Contains
        ("src/awk_tests-localization-rendering_cases-diagnostic_cases.adb",
         "with Project_Tools.Test_Fixtures",
         "localization rendering fixture file reads must use project_tools directly",
         Quiet => False);
      Files.Require_Contains
        ("src/awk_tests-compatibility.adb", "with Project_Tools.Test_Fixtures",
         "fixture file reads must use project_tools directly", Quiet => False);
   end Run;

end Awk_Workflow_Source_Policy.Workflow_Checks.Fixtures;
